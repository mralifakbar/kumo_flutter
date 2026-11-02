import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

typedef _T = KumoCodeTokenType;

/// The type of the first token whose text is exactly [text].
_T? _typeOf(List<KumoCodeToken> tokens, String text) {
  for (final t in tokens) {
    if (t.text == text) return t.type;
  }
  // Adjacent tokens of one type merge; look inside merged runs too.
  for (final t in tokens) {
    if (t.text.trim() == text) return t.type;
  }
  return null;
}

List<KumoCodeToken> tok(String code, String lang) => KumoCodeHighlighter.tokenize(code, lang);

void main() {
  group('language resolution', () {
    test('aliases map to their grammar', () {
      expect(KumoCodeHighlighter.resolve('ts'), 'typescript');
      expect(KumoCodeHighlighter.resolve('JS'), 'javascript');
      expect(KumoCodeHighlighter.resolve('sh'), 'bash');
      expect(KumoCodeHighlighter.resolve('shell'), 'bash');
      expect(KumoCodeHighlighter.resolve('yml'), 'yaml');
      expect(KumoCodeHighlighter.resolve('tf'), 'hcl');
      expect(KumoCodeHighlighter.resolve('tsx'), 'tsx');
      expect(KumoCodeHighlighter.resolve('jsonc'), 'jsonc');
    });

    test('unknown languages are unsupported and render as one plain token', () {
      expect(KumoCodeHighlighter.supports('cobol'), isFalse);
      expect(KumoCodeHighlighter.supports(null), isFalse);
      expect(tok('MOVE A TO B.', 'cobol'), [const KumoCodeToken(_T.plain, 'MOVE A TO B.')]);
    });
  });

  group('round trip', () {
    const samples = {
      'typescript': 'const a: number = 1;\n/* block\ncomment */\nlet s = `x \${a}`;',
      'tsx': '<div className="a">{count > 1 ? "many" : "one"}</div>',
      'json': '{"a": [1, 2.5e3, true, null]}',
      'jsonc': '{\n  // comment\n  "a": 1,\n}',
      'bash': 'echo "\$HOME" | grep -i home && ls -la # list',
      'toml': '[[routes]]\npattern = "example.com/*"\nzone_name = \'example.com\'',
      'yaml': 'a: 1\nb:\n  - "x"\n  - y # note\nc: { d: e }',
      'html': '<!-- c --><p class="x">a &lt; b</p>',
      'css': '@media (min-width: 768px) { .a > b::before { content: "x"; } }',
      'dart': "class A extends B { @override void f() => print(r'raw \$x'); }",
      'python': 'def f(x):\n    """doc"""\n    return f"{x}" # c',
      'sql': "SELECT id, name FROM workers WHERE status = 'active' LIMIT 10;",
      'diff': '--- a/x\n+++ b/x\n@@ -1 +1 @@\n-a\n+b',
      'hcl': 'resource "cloudflare_record" "www" {\n  name = "www"\n  ttl  = 3600\n}',
    };
    for (final entry in samples.entries) {
      test('${entry.key} tokens join back to the source', () {
        final tokens = tok(entry.value, entry.key);
        expect(tokens.map((t) => t.text).join(), entry.value);
        expect(tokens.where((t) => t.type != _T.plain), isNotEmpty);
      });
    }

    test('unterminated strings and comments do not throw', () {
      for (final lang in ['ts', 'json', 'bash', 'toml', 'yaml', 'html', 'css', 'dart', 'python']) {
        for (final code in ['"abc', "'abc", '/* abc', '<a href="x', '"""abc', '{', '`abc']) {
          expect(tok(code, lang).map((t) => t.text).join(), code, reason: '$lang: $code');
        }
      }
    });
  });

  group('javascript and typescript', () {
    test('keywords, calls, types, strings, numbers, comments', () {
      final t = tok('export async function fetchUser(id: string): Promise<User> {\n  return 42; // done\n}', 'ts');
      expect(_typeOf(t, 'export'), _T.keyword);
      expect(_typeOf(t, 'async'), _T.keyword);
      expect(_typeOf(t, 'fetchUser'), _T.function);
      expect(_typeOf(t, 'string'), _T.type);
      expect(_typeOf(t, 'Promise'), _T.type);
      expect(_typeOf(t, 'User'), _T.type);
      expect(_typeOf(t, '42'), _T.number);
      expect(_typeOf(t, '// done'), _T.comment);
    });

    test('object keys and member access are properties', () {
      final t = tok('const env = {\n  zone: "example.com",\n};\nenv.zone.trim();', 'js');
      expect(t.where((x) => x.text == 'zone').map((x) => x.type), everyElement(_T.property));
      expect(_typeOf(t, 'trim'), _T.property);
      expect(_typeOf(t, '"example.com"'), _T.string);
    });

    test('a keyword inside an identifier is not a keyword', () {
      final t = tok('constant iffy', 'js');
      expect(t.every((x) => x.type == _T.plain), isTrue);
    });

    test('template literals and booleans', () {
      final t = tok('const u = `/api/\${id}`; const ok = true;', 'ts');
      expect(_typeOf(t, '`/api/\${id}`'), _T.string);
      expect(_typeOf(t, 'true'), _T.number);
    });

    test('JSX tags and attributes, but comparisons stay operators', () {
      final t = tok('return <button onClick={go}>Go</button>;', 'tsx');
      expect(_typeOf(t, '<button'), _T.tag);
      expect(_typeOf(t, 'onClick'), _T.attribute);
      expect(_typeOf(t, '</button>'), _T.tag);
      final cmp = tok('if (a < b) {}', 'tsx');
      expect(_typeOf(cmp, '<'), _T.operator);
    });
  });

  test('json keys are properties, values keep their types', () {
    final t = tok('{"name": "kumo", "count": 3, "on": false}', 'json');
    expect(_typeOf(t, '"name"'), _T.property);
    expect(_typeOf(t, '"kumo"'), _T.string);
    expect(_typeOf(t, '3'), _T.number);
    expect(_typeOf(t, 'false'), _T.number);
  });

  test('jsonc allows comments, json does not color them', () {
    expect(_typeOf(tok('// c\n{}', 'jsonc'), '// c'), _T.comment);
    expect(_typeOf(tok('// c\n{}', 'json'), '// c'), isNot(_T.comment));
  });

  group('bash', () {
    test('commands, flags, variables, comments, operators', () {
      final t = tok('# deploy\nnpx wrangler deploy --env production && echo \$ACCOUNT_ID', 'bash');
      expect(_typeOf(t, '# deploy'), _T.comment);
      expect(_typeOf(t, 'npx'), _T.function);
      expect(_typeOf(t, '--env'), _T.attribute);
      expect(_typeOf(t, '&&'), _T.operator);
      expect(_typeOf(t, 'echo'), _T.function);
      expect(_typeOf(t, '\$ACCOUNT_ID'), _T.variable);
    });

    test('a hash inside a word is not a comment', () {
      final t = tok('curl https://example.com/#top', 'sh');
      expect(t.where((x) => x.type == _T.comment), isEmpty);
    });

    test('assignments and keywords', () {
      final t = tok('export TOKEN=abc\nif [ -n "\$TOKEN" ]; then echo ok; fi', 'bash');
      expect(_typeOf(t, 'export'), _T.keyword);
      expect(_typeOf(t, 'TOKEN'), _T.variable);
      expect(_typeOf(t, 'if'), _T.keyword);
      expect(_typeOf(t, 'then'), _T.keyword);
      expect(_typeOf(t, 'fi'), _T.keyword);
    });
  });

  test('toml tables, keys, strings, dates, booleans', () {
    final t = tok('name = "image-resizer"\ncompatibility_date = 2026-01-01\n[vars]\nDEBUG = false # off', 'toml');
    expect(_typeOf(t, 'name'), _T.property);
    expect(_typeOf(t, '"image-resizer"'), _T.string);
    expect(_typeOf(t, '2026-01-01'), _T.number);
    expect(_typeOf(t, '[vars]'), _T.type);
    expect(_typeOf(t, 'false'), _T.number);
    expect(_typeOf(t, '# off'), _T.comment);
  });

  test('yaml keys, plain values, numbers, booleans, comments, list items', () {
    final t = tok('name: deploy\nretries: 3\nenabled: true\nsteps:\n  - run: npx wrangler deploy # go', 'yaml');
    expect(_typeOf(t, 'name'), _T.property);
    expect(_typeOf(t, 'deploy'), _T.string);
    expect(_typeOf(t, '3'), _T.number);
    expect(_typeOf(t, 'true'), _T.number);
    expect(_typeOf(t, 'run'), _T.property);
    expect(_typeOf(t, 'npx wrangler deploy'), _T.string);
    expect(_typeOf(t, '# go'), _T.comment);
  });

  test('html tags, attributes, values, entities, comments', () {
    final t = tok('<!-- nav --><a href="/workers" class=\'link\'>Workers &amp; Pages</a>', 'html');
    expect(_typeOf(t, '<!-- nav -->'), _T.comment);
    expect(_typeOf(t, '<a'), _T.tag);
    expect(_typeOf(t, 'href'), _T.attribute);
    expect(_typeOf(t, '"/workers"'), _T.string);
    expect(_typeOf(t, '&amp;'), _T.number);
    expect(_typeOf(t, '</a>'), _T.tag);
  });

  test('css selectors, properties, values, at-rules', () {
    final t = tok('@media print {\n  .card:hover { color: #fff; margin: 0 4px !important; }\n}', 'css');
    expect(_typeOf(t, '@media'), _T.keyword);
    expect(_typeOf(t, '.card:hover'), _T.tag);
    expect(_typeOf(t, 'color'), _T.property);
    expect(_typeOf(t, '#fff'), _T.number);
    expect(_typeOf(t, '4px'), _T.number);
    expect(_typeOf(t, '!important'), _T.keyword);
  });

  test('dart annotations, types, raw and triple strings', () {
    final t = tok("@override\nWidget build(BuildContext context) => const Text(r'\$raw');\nfinal s = '''a\nb''';", 'dart');
    expect(_typeOf(t, '@override'), _T.meta);
    expect(_typeOf(t, 'Widget'), _T.type);
    expect(_typeOf(t, 'build'), _T.function);
    expect(_typeOf(t, 'const'), _T.keyword);
    expect(_typeOf(t, "r'\$raw'"), _T.string);
    expect(_typeOf(t, "'''a\nb'''"), _T.string);
  });

  test('diff lines', () {
    final t = tok('@@ -1 +1 @@\n-old\n+new\n same', 'diff');
    expect(_typeOf(t, '@@ -1 +1 @@'), _T.meta);
    expect(_typeOf(t, '-old'), _T.deleted);
    expect(_typeOf(t, '+new'), _T.inserted);
  });

  test('sql keywords are case-insensitive', () {
    final t = tok('select * FROM t', 'sql');
    expect(_typeOf(t, 'select'), _T.keyword);
    expect(_typeOf(t, 'FROM'), _T.keyword);
  });

  test('tokenizeLines splits multi-line tokens and keeps empty lines', () {
    final lines = KumoCodeHighlighter.tokenizeLines('/* a\nb */\n\nx', 'ts');
    expect(lines, hasLength(4));
    expect(lines[0].single, const KumoCodeToken(_T.comment, '/* a'));
    expect(lines[1].single, const KumoCodeToken(_T.comment, 'b */'));
    expect(lines[2], isEmpty);
    expect(lines[3].single.text, 'x');
  });

  test('token colors clear 4.5:1 on the code surface in light and dark', () {
    for (final theme in [KumoThemeData.light(), KumoThemeData.dark()]) {
      final colors = KumoCodeColors.of(theme);
      for (final type in KumoCodeTokenType.values) {
        final ratio = KumoColorUtils.contrastRatio(colors.of(type), theme.colors.base);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: '${theme.brightness.name} ${type.name}: $ratio');
      }
    }
  });
}
