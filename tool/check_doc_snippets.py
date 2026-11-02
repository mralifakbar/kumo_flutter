"""Compiles every ```dart block in doc/ against the package and reports API
errors (wrong parameter names, missing required arguments, unknown types or
enum values). Free variables used by snippets (callbacks, state) are ignored.

Usage: python3 tool/check_doc_snippets.py   (run from the package root)
"""
import json, os, re, shutil, subprocess, sys, pathlib

OUT = pathlib.Path('example/lib/_doc_snippets')
API_ERRORS = {
    'undefined_named_parameter', 'missing_required_argument', 'not_enough_positional_arguments',
    'extra_positional_arguments', 'extra_positional_arguments_could_be_named', 'undefined_enum_constant',
    'new_with_undefined_constructor_default', 'undefined_constructor_in_initializer', 'creation_with_non_type',
}
HEADER = """// ignore_for_file: type=lint, unused_local_variable, unused_element, dead_code
import 'dart:async';
import 'package:kumo_flutter/kumo_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
"""

def wrap(code):
    top = re.search(r'^(class |enum |typedef |final \w+ = |const \w+ = |Future<|void main|[A-Z]\w+ \w+\(.*\) \{)', code, re.M)
    if top:
        return code
    body = code.rstrip()
    if not body.endswith((';', '}')):
        body += ';'
    return 'void _snippet(BuildContext context, dynamic setState) async {\n' + body + '\n}\n'

def main():
    if OUT.exists(): shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    index = {}
    n = 0
    for doc in sorted(pathlib.Path('doc').rglob('*.md')):
        for i, block in enumerate(re.findall(r'```dart\n(.*?)```', doc.read_text(), re.S)):
            if 'import ' in block and block.strip().startswith('import') and block.count('\n') <= 3:
                continue
            code = '\n'.join(l for l in block.split('\n') if not l.startswith('import '))
            f = OUT / f's{n:04d}.dart'
            f.write_text(HEADER + wrap(code))
            index[f.name] = f'{doc}#{i + 1}'
            n += 1
    res = subprocess.run(['flutter', 'analyze', '--no-pub', str(OUT)], cwd='.', capture_output=True, text=True)
    problems = {}
    syntax = {index[pathlib.Path(m.group(1)).name] for m in re.finditer(r'error • .* • (\S+):\d+:\d+ • (expected_token|missing_identifier|unexpected_token|expected_executable)', res.stdout)}
    for line in res.stdout.splitlines():
        m = re.match(r'\s*error • (.*) • (\S+):(\d+):\d+ • (\w+)', line)
        if not m: continue
        msg, path, ln, code = m.groups()
        if code not in API_ERRORS: continue
        if code == 'creation_with_non_type' and "'Kumo" not in msg: continue  # the reader's own widgets
        problems.setdefault(index[pathlib.Path(path).name], []).append(f'{code}: {msg}')
    shutil.rmtree(OUT)
    if syntax:
        print(f'{len(syntax)} snippets are fragments that do not parse on their own (not checked):', ', '.join(sorted(syntax)[:8]), '...' if len(syntax) > 8 else '')
    print(f'{n} snippets checked, {sum(len(v) for v in problems.values())} API errors in {len(problems)} snippets')
    for k, v in problems.items():
        print(k)
        for e in v: print('   ', e)
    sys.exit(1 if problems else 0)

main()
