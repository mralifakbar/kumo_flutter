import 'package:flutter/widgets.dart';

import '../theme/kumo_theme_data.dart';
import '../utils/kumo_color_utils.dart';

/// What a run of source text is, for coloring.
enum KumoCodeTokenType {
  /// Identifiers, whitespace and anything without a more specific type.
  plain,

  /// Language keywords (`const`, `return`, `if`), and shell keywords.
  keyword,

  /// String literals, and plain YAML values.
  string,

  /// Numbers, booleans, `null`, dates, CSS units and colors.
  number,

  /// Comments.
  comment,

  /// Function names at a call or declaration, shell commands, decorators.
  function,

  /// Type names (capitalized identifiers, built-in types), TOML tables.
  type,

  /// Object keys, properties after a dot, CSS properties, YAML and TOML keys.
  property,

  /// HTML and JSX tag names.
  tag,

  /// HTML and JSX attributes, shell flags.
  attribute,

  /// Operators (`=>`, `===`, `&&`, `|`).
  operator,

  /// Brackets, separators and other punctuation.
  punctuation,

  /// Shell variables, YAML anchors.
  variable,

  /// Added lines in a diff.
  inserted,

  /// Removed lines in a diff.
  deleted,

  /// Annotations, doctypes, diff headers and YAML document markers.
  meta,
}

/// One run of source text and its [type].
@immutable
class KumoCodeToken {
  const KumoCodeToken(this.type, this.text);

  final KumoCodeTokenType type;
  final String text;

  @override
  bool operator ==(Object other) => other is KumoCodeToken && other.type == type && other.text == text;

  @override
  int get hashCode => Object.hash(type, text);

  @override
  String toString() => '${type.name}(${text.replaceAll('\n', r'\n')})';
}

/// Token colors for [KumoCodeHighlighted], derived from Kumo's text tokens so
/// every pairing keeps 4.5:1 contrast on `bg-kumo-base` in both modes.
///
/// ```dart
/// final colors = KumoCodeColors.of(context.kumo);
/// final keyword = colors.of(KumoCodeTokenType.keyword);
/// ```
@immutable
class KumoCodeColors {
  const KumoCodeColors({
    required this.plain,
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
    required this.function,
    required this.type,
    required this.property,
    required this.tag,
    required this.attribute,
    required this.operator,
    required this.punctuation,
    required this.variable,
    required this.inserted,
    required this.deleted,
    required this.meta,
    required this.lineHighlight,
  });

  /// The Kumo palette for [theme]'s mode.
  factory KumoCodeColors.of(KumoThemeData theme) {
    final c = theme.colors;
    // There is no purple text token; the light badge purple already reads at
    // 5:1 on white, and the dark one needs lifting to clear 4.5:1 on black.
    final purple = theme.isDark ? KumoColorUtils.lighten(c.badgePurple, 0.45) : c.badgePurple;
    return KumoCodeColors(
      plain: c.textDefault,
      keyword: c.textDanger,
      string: c.textSuccess,
      number: c.textBadgeOrangeSubtle,
      comment: c.textSubtle,
      function: purple,
      type: c.textBadgeTealSubtle,
      property: c.textInfo,
      tag: c.textBadgeTealSubtle,
      attribute: purple,
      operator: c.textDanger,
      punctuation: c.textDefault,
      variable: c.textInfo,
      inserted: c.textSuccess,
      deleted: c.textDanger,
      meta: c.textSubtle,
      // kumo.css: --kumo-code-highlight-bg.
      lineHighlight: theme.isDark ? const Color(0x14FFFFFF) : const Color(0x0D000000),
    );
  }

  final Color plain;
  final Color keyword;
  final Color string;
  final Color number;
  final Color comment;
  final Color function;
  final Color type;
  final Color property;
  final Color tag;
  final Color attribute;
  final Color operator;
  final Color punctuation;
  final Color variable;
  final Color inserted;
  final Color deleted;
  final Color meta;

  /// Background of lines listed in `highlightLines`.
  final Color lineHighlight;

  /// The color for a token [type].
  Color of(KumoCodeTokenType type) => switch (type) {
        KumoCodeTokenType.plain => plain,
        KumoCodeTokenType.keyword => keyword,
        KumoCodeTokenType.string => string,
        KumoCodeTokenType.number => number,
        KumoCodeTokenType.comment => comment,
        KumoCodeTokenType.function => function,
        KumoCodeTokenType.type => this.type,
        KumoCodeTokenType.property => property,
        KumoCodeTokenType.tag => tag,
        KumoCodeTokenType.attribute => attribute,
        KumoCodeTokenType.operator => operator,
        KumoCodeTokenType.punctuation => punctuation,
        KumoCodeTokenType.variable => variable,
        KumoCodeTokenType.inserted => inserted,
        KumoCodeTokenType.deleted => deleted,
        KumoCodeTokenType.meta => meta,
      };

  @override
  bool operator ==(Object other) =>
      other is KumoCodeColors &&
      KumoCodeTokenType.values.every((t) => of(t) == other.of(t)) &&
      other.lineHighlight == lineHighlight;

  @override
  int get hashCode => Object.hashAll([for (final t in KumoCodeTokenType.values) of(t), lineHighlight]);
}

/// A small, dependency-free tokenizer for the languages Kumo's
/// `CodeHighlighted` bundles most often.
///
/// Supported (aliases in brackets): javascript [js, mjs, cjs, jsx],
/// typescript [ts, mts, cts, tsx], json, jsonc [json5], bash [sh, shell, zsh,
/// console], toml, yaml [yml], html [xml, svg], css [scss], dart, python
/// [py], sql, diff [patch] and hcl [tf, terraform]. Anything else returns a
/// single plain token, so unknown languages render as plain text.
///
/// It is a lexer, not a parser: it colors keywords, strings, numbers,
/// comments, calls, types and keys the way an editor's first pass would.
///
/// ```dart
/// final tokens = KumoCodeHighlighter.tokenize('const a = 1;', 'ts');
/// // keyword(const) plain( a ) operator(=) ...
/// ```
abstract final class KumoCodeHighlighter {
  /// Canonical name for [lang] (`ts` becomes `typescript`), or null when the
  /// language is not supported.
  static String? resolve(String? lang) {
    if (lang == null) return null;
    final key = lang.trim().toLowerCase();
    final canonical = _aliases[key] ?? key;
    return _grammars.containsKey(canonical) ? canonical : null;
  }

  /// Whether [lang] (or one of its aliases) gets colors.
  static bool supports(String? lang) => resolve(lang) != null;

  /// Splits [code] into tokens. Joining every token's text gives back [code].
  static List<KumoCodeToken> tokenize(String code, String? lang) {
    final name = resolve(lang);
    if (name == null || code.isEmpty) return [KumoCodeToken(KumoCodeTokenType.plain, code)];
    return _Lexer(_grammars[name]!, code).run();
  }

  /// [tokenize], then split into lines. Tokens that span a newline (block
  /// comments, multi-line strings) are cut at each line break, and the
  /// newline itself is dropped. There is always one list per line.
  static List<List<KumoCodeToken>> tokenizeLines(String code, String? lang) {
    final lines = <List<KumoCodeToken>>[[]];
    for (final token in tokenize(code, lang)) {
      final parts = token.text.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) lines.add([]);
        if (parts[i].isNotEmpty) lines.last.add(KumoCodeToken(token.type, parts[i]));
      }
    }
    return lines;
  }

  static const Map<String, String> _aliases = {
    'js': 'javascript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'jsx': 'jsx',
    'ts': 'typescript',
    'mts': 'typescript',
    'cts': 'typescript',
    'json5': 'jsonc',
    'sh': 'bash',
    'shell': 'bash',
    'zsh': 'bash',
    'console': 'bash',
    'yml': 'yaml',
    'xml': 'html',
    'svg': 'html',
    'scss': 'css',
    'py': 'python',
    'patch': 'diff',
    'tf': 'hcl',
    'terraform': 'hcl',
  };

  static final Map<String, _Grammar> _grammars = {
    'javascript': _jsGrammar(typescript: false, jsx: false),
    'jsx': _jsGrammar(typescript: false, jsx: true),
    'typescript': _jsGrammar(typescript: true, jsx: false),
    'tsx': _jsGrammar(typescript: true, jsx: true),
    'json': _jsonGrammar(comments: false),
    'jsonc': _jsonGrammar(comments: true),
    'bash': _bashGrammar(),
    'toml': _tomlGrammar(),
    'yaml': _yamlGrammar(),
    'html': _htmlGrammar(),
    'css': _cssGrammar(),
    'dart': _dartGrammar(),
    'python': _pythonGrammar(),
    'sql': _sqlGrammar(),
    'diff': _diffGrammar(),
    'hcl': _hclGrammar(),
  };
}

typedef _Guard = bool Function(_Lexer lexer);

class _Rule {
  _Rule(String pattern, this.type, {this.push, this.pop = false, this.when, bool caseSensitive = true})
      : pattern = RegExp(pattern, caseSensitive: caseSensitive);

  final RegExp pattern;
  final KumoCodeTokenType type;

  /// State to enter after this token.
  final String? push;

  /// Leave the current state after this token.
  final bool pop;
  final _Guard? when;
}

class _Grammar {
  const _Grammar(this.states);
  final Map<String, List<_Rule>> states;
}

class _Lexer {
  _Lexer(this.grammar, this.src);

  final _Grammar grammar;
  final String src;
  int pos = 0;
  final List<String> _stack = ['root'];
  final List<KumoCodeToken> _out = [];

  /// The last token that is not whitespace.
  KumoCodeToken? prev;

  /// Only spaces and tabs sit between the last line break and [pos].
  bool get atLineStart {
    for (var i = pos - 1; i >= 0; i--) {
      final ch = src.codeUnitAt(i);
      if (ch == 0x0A) return true;
      if (ch != 0x20 && ch != 0x09) return false;
    }
    return true;
  }

  /// [prev] is on the current line.
  bool get prevOnLine {
    if (prev == null) return false;
    for (var i = pos - 1; i >= 0; i--) {
      final ch = src.codeUnitAt(i);
      if (ch == 0x0A) return false;
      if (ch != 0x20 && ch != 0x09) return true;
    }
    return false;
  }

  bool get afterSpace => pos == 0 || _isSpace(src.codeUnitAt(pos - 1));

  bool prevIs(Set<String> texts) => prev != null && texts.contains(prev!.text);

  static bool _isSpace(int ch) => ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D;

  List<KumoCodeToken> run() {
    while (pos < src.length) {
      final rules = grammar.states[_stack.last] ?? grammar.states['root']!;
      var matched = false;
      for (final rule in rules) {
        if (rule.when != null && !rule.when!(this)) continue;
        final m = rule.pattern.matchAsPrefix(src, pos);
        if (m == null || m.end == pos) continue;
        _emit(rule.type, m[0]!);
        pos = m.end;
        if (rule.pop && _stack.length > 1) _stack.removeLast();
        if (rule.push != null) _stack.add(rule.push!);
        matched = true;
        break;
      }
      if (!matched) {
        _emit(KumoCodeTokenType.plain, src[pos]);
        pos++;
      }
    }
    return _out;
  }

  void _emit(KumoCodeTokenType type, String text) {
    final token = KumoCodeToken(type, text);
    if (text.trim().isNotEmpty) prev = token;
    if (_out.isNotEmpty && _out.last.type == type) {
      _out[_out.length - 1] = KumoCodeToken(type, _out.last.text + text);
    } else {
      _out.add(token);
    }
  }
}

const _t = KumoCodeTokenType.plain;
const _kw = KumoCodeTokenType.keyword;
const _str = KumoCodeTokenType.string;
const _num = KumoCodeTokenType.number;
const _com = KumoCodeTokenType.comment;
const _fn = KumoCodeTokenType.function;
const _ty = KumoCodeTokenType.type;
const _prop = KumoCodeTokenType.property;
const _tag = KumoCodeTokenType.tag;
const _attr = KumoCodeTokenType.attribute;
const _op = KumoCodeTokenType.operator;
const _punc = KumoCodeTokenType.punctuation;
const _var = KumoCodeTokenType.variable;
const _meta = KumoCodeTokenType.meta;

String _words(Iterable<String> words) => '\\b(?:${words.join('|')})\\b';

final _ws = _Rule(r'\s+', _t);
final _dq = _Rule(r'"(?:\\.|[^"\\\n])*"?', _str);
final _sq = _Rule(r"'(?:\\.|[^'\\\n])*'?", _str);
final _lineComment = _Rule(r'//[^\n]*', _com);
final _blockComment = _Rule(r'/\*[\s\S]*?(?:\*/|$)', _com);
final _hashComment = _Rule(r'#[^\n]*', _com);
final _cNumber = _Rule(
  r'(?:0[xX][\da-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|(?:\d[\d_]*(?:\.\d[\d_]*)?|\.\d[\d_]*)(?:[eE][+-]?\d+)?n?)\b',
  _num,
);
final _cOperator = _Rule(r'=>|\?\?=?|\?\.|\.\.\.|[=!]==?|[<>]=?|&&=?|\|\|=?|[-+*/%&|^~!?:]=?|=', _op);
final _memberAccess = _Rule(r'[A-Za-z_$][\w$]*', _prop, when: (l) => l.prevIs(const {'.', '?.'}));

_Grammar _jsGrammar({required bool typescript, required bool jsx}) {
  const keywords = [
    'const', 'let', 'var', 'function', 'return', 'if', 'else', 'for', 'while', 'do', 'switch', 'case', //
    'break', 'continue', 'new', 'delete', 'typeof', 'instanceof', 'in', 'of', 'class', 'extends', 'super',
    'this', 'import', 'export', 'from', 'default', 'async', 'await', 'yield', 'try', 'catch', 'finally',
    'throw', 'void', 'static', 'get', 'set', 'with', 'debugger',
  ];
  const tsKeywords = [
    'interface', 'type', 'enum', 'implements', 'public', 'private', 'protected', 'readonly', 'as', //
    'satisfies', 'keyof', 'declare', 'namespace', 'abstract', 'is', 'infer', 'module', 'override',
  ];
  const tsTypes = ['string', 'number', 'boolean', 'any', 'unknown', 'never', 'object', 'bigint', 'symbol'];
  final expressionStart = {'(', '[', '{', ',', '=', ':', '?', '&&', '||', '??', '=>', 'return', '>'};
  final root = <_Rule>[
    _ws,
    _lineComment,
    _blockComment,
    if (jsx) ...[
      _Rule(r'</?>', _tag),
      // A closing tag is unambiguous; an opening one must start an expression.
      _Rule(r'</[A-Za-z][\w.:-]*', _tag, push: 'jsxTag'),
      _Rule(
        r'<[A-Za-z][\w.:-]*',
        _tag,
        push: 'jsxTag',
        when: (l) => l.prev == null || !l.prevOnLine || l.prevIs(expressionStart),
      ),
    ],
    _Rule(r'`(?:\\[\s\S]|[^\\`])*`?', _str),
    _dq,
    _sq,
    _cNumber,
    _Rule(_words(typescript ? [...keywords, ...tsKeywords] : keywords), _kw),
    _Rule(_words(['true', 'false', 'null', 'undefined', 'NaN', 'Infinity']), _num),
    if (typescript) _Rule(_words(tsTypes), _ty),
    _Rule(r'@[A-Za-z_]\w*', _meta),
    _memberAccess,
    _Rule(r'[A-Za-z_$][\w$]*(?=\s*(?:<[\w\s,.<>\[\]|]*>)?\()', _fn),
    _Rule(r'[A-Z][\w$]*', _ty),
    _Rule(
      r'[A-Za-z_$][\w$]*(?=\??\s*:)',
      _prop,
      when: (l) => l.atLineStart || l.prevIs(const {'{', ','}),
    ),
    _Rule(r'[A-Za-z_$][\w$]*', _t),
    _Rule(r'\{', _punc, push: 'root'),
    _Rule(r'\}', _punc, pop: true),
    _cOperator,
    _Rule(r'[()\[\];,.]', _punc),
  ];
  return _Grammar({
    'root': root,
    if (jsx)
      'jsxTag': [
        _ws,
        _Rule(r'/?>', _tag, pop: true),
        _Rule(r'[A-Za-z_][\w:-]*', _attr),
        _Rule(r'=', _op),
        _dq,
        _sq,
        _Rule(r'\{', _punc, push: 'root'),
      ],
  });
}

_Grammar _dartGrammar() {
  const keywords = [
    'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case', 'catch', 'class', 'const', //
    'continue', 'covariant', 'default', 'deferred', 'do', 'else', 'enum', 'export', 'extends', 'extension',
    'external', 'factory', 'final', 'finally', 'for', 'get', 'hide', 'if', 'implements', 'import', 'in',
    'interface', 'is', 'late', 'library', 'mixin', 'new', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'try',
    'typedef', 'var', 'when', 'while', 'with', 'yield',
  ];
  const types = ['int', 'double', 'num', 'bool', 'void', 'dynamic', 'Never'];
  return _Grammar({
    'root': [
      _ws,
      _Rule(r'///[^\n]*', _com),
      _lineComment,
      _blockComment,
      _Rule(r"r?'''[\s\S]*?(?:'''|$)", _str),
      _Rule(r'r?"""[\s\S]*?(?:"""|$)', _str),
      _Rule(r"r'[^'\n]*'?", _str),
      _Rule(r'r"[^"\n]*"?', _str),
      _dq,
      _sq,
      _cNumber,
      _Rule(_words(keywords), _kw),
      _Rule(_words(['true', 'false', 'null']), _num),
      _Rule(_words(types), _ty),
      _Rule(r'@[A-Za-z_]\w*', _meta),
      _memberAccess,
      _Rule(r'[A-Za-z_$][\w$]*(?=\s*(?:<[\w\s,.<>?]*>)?\()', _fn),
      _Rule(r'_?[A-Z][\w$]*', _ty),
      _Rule(r'[A-Za-z_$][\w$]*', _t),
      _cOperator,
      _Rule(r'[{}()\[\];,.]', _punc),
    ],
  });
}

_Grammar _pythonGrammar() {
  const keywords = [
    'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', //
    'except', 'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal', 'not',
    'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield', 'match', 'case', 'self',
  ];
  return _Grammar({
    'root': [
      _ws,
      _hashComment,
      _Rule(r'''[rRbBfFuU]{0,2}"""[\s\S]*?(?:"""|$)''', _str),
      _Rule(r"""[rRbBfFuU]{0,2}'''[\s\S]*?(?:'''|$)""", _str),
      _Rule(r'''[rRbBfFuU]{1,2}"(?:\\.|[^"\\\n])*"?''', _str),
      _Rule(r"""[rRbBfFuU]{1,2}'(?:\\.|[^'\\\n])*'?""", _str),
      _dq,
      _sq,
      _cNumber,
      _Rule(_words(keywords), _kw),
      _Rule(_words(['True', 'False', 'None']), _num),
      _Rule(r'@[A-Za-z_][\w.]*', _meta),
      _memberAccess,
      _Rule(r'[A-Za-z_]\w*(?=\s*\()', _fn),
      _Rule(r'[A-Z]\w*', _ty),
      _Rule(r'[A-Za-z_]\w*', _t),
      _Rule(r'->|\*\*=?|//=?|[<>!=]=|[-+*/%&|^~<>]=?|:=|=', _op),
      _Rule(r'[{}()\[\];,.:]', _punc),
    ],
  });
}

_Grammar _jsonGrammar({required bool comments}) => _Grammar({
      'root': [
        _ws,
        if (comments) ...[_lineComment, _blockComment],
        _Rule(r'"(?:\\.|[^"\\\n])*"(?=\s*:)', _prop),
        _dq,
        _Rule(r'-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?', _num),
        _Rule(_words(['true', 'false', 'null']), _num),
        _Rule(r'[{}\[\],:]', _punc),
      ],
    });

_Grammar _bashGrammar() {
  const keywords = [
    'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'until', 'do', 'done', 'case', 'esac', 'in', //
    'function', 'select', 'return', 'exit', 'export', 'local', 'readonly', 'declare', 'unset', 'source',
    'alias',
  ];
  const commandAfter = {'|', '||', '&&', ';', r'$(', r'$', '(', '`', 'then', 'do', 'else', 'sudo', 'exec', 'time'};
  bool commandPosition(_Lexer l) => !l.prevOnLine || l.prevIs(commandAfter);
  return _Grammar({
    'root': [
      _Rule(r'[ \t]+|\n', _t),
      _Rule(r'#[^\n]*', _com, when: (l) => l.afterSpace),
      _Rule(r'"(?:\\[\s\S]|[^"\\])*"?', _str),
      _Rule(r"\$'(?:\\.|[^'\\])*'?", _str),
      _Rule(r"'[^']*'?", _str),
      _Rule(r'\$\{[^}\n]*\}?|\$\(|\$[A-Za-z_]\w*|\$[0-9@#?$!*-]', _var),
      _Rule(_words(keywords), _kw, when: commandPosition),
      _Rule(
        r'[A-Za-z_]\w*(?==)',
        _var,
        when: (l) => commandPosition(l) || l.prevIs(const {'export', 'local', 'readonly', 'declare'}),
      ),
      _Rule(r'--?[A-Za-z0-9][\w-]*', _attr, when: (l) => l.afterSpace),
      _Rule(r'[A-Za-z_./~][\w./~:+@-]*', _fn, when: commandPosition),
      _Rule(r'\d+\b', _num),
      _Rule(r'&&|\|\||>>|<<|[|&;<>]|=', _op),
      _Rule(r'[(){}\[\]]', _punc),
      _Rule('[^\\s"\'\$|&;<>(){}\\[\\]=#]+', _t),
    ],
  });
}

_Grammar _tomlGrammar() => _Grammar({
      'root': [
        _ws,
        _hashComment,
        _Rule(r'\[\[?[^\]\n]*\]\]?', _ty, when: (l) => l.atLineStart),
        _Rule(
          r'(?:[A-Za-z0-9_-]+|"[^"\n]*"|' "'[^'\\n]*')" r'(?:\s*\.\s*(?:[A-Za-z0-9_-]+|"[^"\n]*"))*(?=\s*=)',
          _prop,
          when: (l) => l.atLineStart || l.prevIs(const {'{', ','}),
        ),
        _Rule(r'"""[\s\S]*?(?:"""|$)', _str),
        _Rule(r"'''[\s\S]*?(?:'''|$)", _str),
        _dq,
        _Rule(r"'[^'\n]*'?", _str),
        _Rule(r'\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?)?(?:Z|[+-]\d{2}:\d{2})?', _num),
        _Rule(r'[+-]?(?:0x[\da-fA-F_]+|0o[0-7_]+|0b[01_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?|inf\b|nan\b)', _num),
        _Rule(_words(['true', 'false']), _num),
        _Rule(r'[=\[\]{},.]', _punc),
      ],
    });

_Grammar _yamlGrammar() {
  // A key sits at the start of a line, after a list dash, or inside a flow map.
  bool keyPosition(_Lexer l) => l.atLineStart || (l.prevOnLine && l.prevIs(const {'-', '{', ','}));
  bool valuePosition(_Lexer l) => l.prevOnLine && l.prevIs(const {':', '-'});
  const valueEnd = r'(?=[ \t]+#|[ \t]*(?:\n|$)|\s*[,\]}])';
  return _Grammar({
    'root': [
      _Rule(r'[ \t]+|\n', _t),
      _Rule(r'#[^\n]*', _com, when: (l) => l.afterSpace),
      _Rule(r'---|\.\.\.', _meta, when: (l) => l.atLineStart),
      _Rule(r'-(?=\s|$)', _punc),
      _Rule(
        r'''(?:"(?:\\.|[^"\\\n])*"|'[^'\n]*'|[^\s#:,\[\]{}"'-][^\n:#]*?|-[^\s:][^\n:#]*?)(?=[ \t]*:(?:\s|$))''',
        _prop,
        when: keyPosition,
      ),
      _Rule(r'[&*][\w-]+', _var),
      _Rule(r'![\w!/.-]*', _meta),
      _dq,
      _Rule(r"'(?:''|[^'])*'?", _str),
      _Rule(r'[|>][-+]?\d*(?=[ \t]*(?:#|\n|$))', _op),
      _Rule('(?:true|false|yes|no|on|off|null|~)$valueEnd', _num, when: valuePosition),
      _Rule('[-+]?(?:\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?|0x[\\da-fA-F]+|\\.inf|\\.nan)$valueEnd', _num),
      _Rule('[^\\s#,\\[\\]{}][^\\n#]*?$valueEnd', _str, when: valuePosition),
      _Rule(r'[:,\[\]{}?]', _punc),
      _Rule(r'[^\s:#,\[\]{}]+', _str),
    ],
  });
}

_Grammar _htmlGrammar() => _Grammar({
      'root': [
        _ws,
        _Rule(r'<!--[\s\S]*?(?:-->|$)', _com),
        _Rule(r'<![A-Za-z][^>]*>?|<\?[\s\S]*?(?:\?>|$)', _meta),
        _Rule(r'</?[A-Za-z][\w:.-]*', _tag, push: 'tag'),
        _Rule(r'&(?:#\d+|#x[\da-fA-F]+|\w+);', _num),
        _Rule(r'[^<&\s]+', _t),
      ],
      'tag': [
        _ws,
        _Rule(r'/?>', _tag, pop: true),
        _Rule(r'"[^"]*"?', _str),
        _Rule(r"'[^']*'?", _str),
        _Rule(r'=', _op),
        _Rule(r'''[^\s=/>"']+''', _attr),
      ],
    });

_Grammar _cssGrammar() {
  final value = <_Rule>[
    _Rule(r'!important\b', _kw),
    _Rule(r'#[\da-fA-F]{3,8}\b', _num),
    _Rule(r'-?(?:\d+\.?\d*|\.\d+)(?:%|[a-zA-Z]+)?', _num),
    _Rule(r'[\w-]+(?=\()', _fn),
  ];
  return _Grammar({
    'root': [
      _ws,
      _blockComment,
      _Rule(r'@[\w-]+', _kw),
      _dq,
      _sq,
      _Rule(r'\{', _punc, push: 'block'),
      _Rule(r'::?[\w-]+', _kw),
      _Rule(r'[.#][\w-]+', _attr),
      _Rule(r'&|[\w-]+', _tag),
      _Rule(r'[>+~*,]', _op),
      _Rule(r'[\[\]()=;:]', _punc),
    ],
    'block': [
      _ws,
      _blockComment,
      _Rule(r'\}', _punc, pop: true),
      // A nested rule (`&:hover {`) inside a block.
      _Rule(r'[&.#:]?[\w-]+(?=[^;{}]*\{)', _tag),
      _Rule(r'-{0,2}[A-Za-z][\w-]*(?=\s*:)', _prop),
      _dq,
      _sq,
      ...value,
      _Rule(r'\{', _punc, push: 'block'),
      _Rule(r'[\w-]+', _t),
      _Rule(r'[:;,()/]', _punc),
    ],
  });
}

_Grammar _sqlGrammar() {
  const keywords = [
    'select', 'from', 'where', 'and', 'or', 'not', 'insert', 'into', 'values', 'update', 'set', 'delete', //
    'create', 'table', 'drop', 'alter', 'add', 'index', 'view', 'join', 'left', 'right', 'inner', 'outer',
    'full', 'cross', 'on', 'as', 'group', 'by', 'order', 'having', 'limit', 'offset', 'distinct', 'union',
    'all', 'exists', 'in', 'is', 'like', 'between', 'case', 'when', 'then', 'else', 'end', 'primary', 'key',
    'foreign', 'references', 'default', 'unique', 'check', 'constraint', 'if', 'returning', 'with', 'asc',
    'desc', 'begin', 'commit', 'rollback', 'transaction', 'pragma', 'autoincrement',
  ];
  const types = ['integer', 'int', 'text', 'real', 'blob', 'numeric', 'varchar', 'char', 'boolean', 'date', 'timestamp'];
  return _Grammar({
    'root': [
      _ws,
      _Rule(r'--[^\n]*', _com),
      _blockComment,
      _Rule(r"'(?:''|[^'])*'?", _str),
      _Rule(r'"[^"\n]*"?|`[^`\n]*`?', _prop),
      _cNumber,
      _Rule(_words(keywords), _kw, caseSensitive: false),
      _Rule(_words(types), _ty, caseSensitive: false),
      _Rule(_words(['null', 'true', 'false']), _num, caseSensitive: false),
      _Rule(r'[A-Za-z_]\w*(?=\s*\()', _fn),
      _Rule(r'[A-Za-z_]\w*', _t),
      _Rule(r'[?:@$]\w+', _var),
      _Rule(r'<>|[<>!=]=|\|\||[-+*/%<>=]', _op),
      _Rule(r'[(),;.]', _punc),
    ],
  });
}

_Grammar _diffGrammar() {
  bool line(_Lexer l) => l.pos == 0 || l.src.codeUnitAt(l.pos - 1) == 0x0A;
  return _Grammar({
    'root': [
      _Rule(r'(?:diff |index |\+\+\+ |--- |@@)[^\n]*', _meta, when: line),
      _Rule(r'\+[^\n]*', KumoCodeTokenType.inserted, when: line),
      _Rule(r'-[^\n]*', KumoCodeTokenType.deleted, when: line),
      _Rule(r'[^\n]+|\n', _t),
    ],
  });
}

_Grammar _hclGrammar() => _Grammar({
      'root': [
        _ws,
        _hashComment,
        _lineComment,
        _blockComment,
        _Rule(r'<<-?\s*([A-Z]+)\n[\s\S]*?\n\s*\1', _str),
        _dq,
        _cNumber,
        _Rule(_words(['true', 'false', 'null']), _num),
        _Rule(_words(['for', 'in', 'if', 'else', 'endif', 'endfor']), _kw),
        _Rule(r'[A-Za-z_][\w-]*(?=\s+(?:"|\{|[A-Za-z_][\w-]*\s*\{))', _kw, when: (l) => l.atLineStart),
        _Rule(r'[A-Za-z_][\w-]*(?=\s*=(?!=))', _prop, when: (l) => l.atLineStart || l.prevIs(const {'{', ','})),
        _memberAccess,
        _Rule(r'[A-Za-z_][\w-]*(?=\()', _fn),
        _Rule(r'[A-Za-z_][\w-]*', _t),
        _Rule(r'=>|[<>!=]=|&&|\|\||[-+*/%<>=!?:]', _op),
        _Rule(r'[{}()\[\],.]', _punc),
      ],
    });
