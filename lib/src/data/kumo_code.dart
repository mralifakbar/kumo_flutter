import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'copy_feedback.dart';
import 'data_scroll_fade.dart';
import 'kumo_code_highlighter.dart';

/// Frame of a code block.
enum KumoCodeVariant {
  /// Kumo's `default`: `bg-kumo-base`, a 1px `kumo-fill` border, `rounded-md`
  /// and inner padding.
  standard,

  /// No frame and no padding, for code that sits inside another surface.
  plain,
}

/// A `{{key}}` template value for [KumoCode.values].
///
/// ```dart
/// KumoCode(
///   code: 'export CLOUDFLARE_API_TOKEN={{token}}',
///   lang: 'bash',
///   values: {'token': KumoCodeValue('your-token', highlight: true)},
/// )
/// ```
@immutable
class KumoCodeValue {
  const KumoCodeValue(this.value, {this.highlight = false});

  final String value;

  /// Emphasize the value (medium weight, strong text) so a reader spots
  /// the part they need to replace.
  final bool highlight;

  @override
  bool operator ==(Object other) => other is KumoCodeValue && other.value == value && other.highlight == highlight;

  @override
  int get hashCode => Object.hash(value, highlight);
}

/// Kumo's `Code` and `Code.Block`: monospace code without syntax colors,
/// in `text-kumo-subtle` at 13px on a 20px line.
///
/// ```dart
/// const KumoCode(code: 'npx wrangler deploy')
/// const KumoCode.block(code: 'npx wrangler deploy', showCopyButton: true)
/// ```
///
/// Use [KumoCodeHighlighted] for colored code. Both share the same block:
/// optional line numbers, highlighted lines, a copy button, horizontal
/// scrolling for long lines (with a fade on the cut-off edge) or wrapping.
class KumoCode extends StatelessWidget {
  /// Bare code, no frame (Kumo `Code`).
  const KumoCode({
    super.key,
    required this.code,
    this.lang,
    this.values,
    this.variant = KumoCodeVariant.plain,
    this.showLineNumbers = false,
    this.highlightLines = const [],
    this.showCopyButton = false,
    this.wrap = false,
    this.maxHeight,
    this.onCopy,
  });

  /// Code in a bordered block (Kumo `Code.Block`, `p-2.5`).
  const KumoCode.block({
    super.key,
    required this.code,
    this.lang,
    this.values,
    this.showLineNumbers = false,
    this.highlightLines = const [],
    this.showCopyButton = false,
    this.wrap = false,
    this.maxHeight,
    this.onCopy,
  }) : variant = KumoCodeVariant.standard;

  final String code;

  /// Language hint. Kumo's `Code` does not color code; use
  /// [KumoCodeHighlighted] for that.
  final String? lang;

  /// Values for `{{key}}` placeholders in [code]. The copy button copies
  /// the filled-in code.
  final Map<String, KumoCodeValue>? values;
  final KumoCodeVariant variant;

  /// Number every line. Single-line code never shows numbers (as in Kumo).
  final bool showLineNumbers;

  /// 1-based line numbers to tint.
  final List<int> highlightLines;
  final bool showCopyButton;

  /// Wrap long lines instead of scrolling sideways.
  final bool wrap;

  /// Scroll vertically past this height.
  final double? maxHeight;

  /// Called after the code was copied.
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final base = kumo.code(color: KumoColor.textSubtle).copyWith(height: 20 / 13);
    final strong = base.copyWith(color: kumo.colors.textStrong, fontWeight: KumoTypography.medium);
    final lines = <List<InlineSpan>>[[]];
    final copy = StringBuffer();
    final pattern = RegExp(r'\{\{\s*([\w.-]+)\s*\}\}');
    var last = 0;
    void addText(String text, TextStyle style) {
      final parts = text.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) lines.add([]);
        if (parts[i].isNotEmpty) lines.last.add(TextSpan(text: parts[i], style: style));
      }
    }

    for (final m in values == null ? const <RegExpMatch>[] : pattern.allMatches(code)) {
      final value = values![m[1]!];
      if (value == null) continue;
      addText(code.substring(last, m.start), base);
      addText(value.value, value.highlight ? strong : base);
      copy
        ..write(code.substring(last, m.start))
        ..write(value.value);
      last = m.end;
    }
    addText(code.substring(last), base);
    copy.write(code.substring(last));

    return DataCodeBlock(
      lines: lines,
      copyText: copy.toString(),
      style: base,
      variant: variant,
      padding: KumoSpace.s2_5,
      showLineNumbers: showLineNumbers,
      highlightLines: highlightLines,
      highlightColor: KumoCodeColors.of(kumo).lineHighlight,
      showCopyButton: showCopyButton,
      wrap: wrap,
      maxHeight: maxHeight,
      onCopy: onCopy,
    );
  }
}

/// Kumo's `CodeHighlighted`: a syntax-colored code block.
///
/// Colors come from a built-in tokenizer (no Shiki, no dependencies) and a
/// palette derived from Kumo tokens for light and dark ([KumoCodeColors]).
/// See [KumoCodeHighlighter] for the supported languages; any other [lang]
/// renders as plain text, readable and unstyled.
///
/// ```dart
/// const KumoCodeHighlighted(
///   code: 'export default {\n  async fetch(request) {\n    return new Response("Hello");\n  },\n};',
///   lang: 'ts',
///   showLineNumbers: true,
///   highlightLines: [3],
///   showCopyButton: true,
/// )
/// ```
///
/// The copy button appears on hover and keyboard focus with a mouse, and
/// always on touch screens, where there is no hover.
class KumoCodeHighlighted extends StatefulWidget {
  const KumoCodeHighlighted({
    super.key,
    required this.code,
    required this.lang,
    this.variant = KumoCodeVariant.standard,
    this.showLineNumbers = false,
    this.highlightLines = const [],
    this.showCopyButton = false,
    this.copyLabel,
    this.copiedLabel,
    this.wrap = false,
    this.maxHeight,
    this.colors,
    this.onCopy,
  });

  final String code;

  /// Language name or alias: `ts`, `tsx`, `js`, `json`, `jsonc`, `bash`,
  /// `sh`, `toml`, `yaml`, `html`, `css`, `dart`, `python`, `sql`, `diff`,
  /// `hcl`.
  final String lang;
  final KumoCodeVariant variant;

  /// Number every line. Single-line code never shows numbers.
  final bool showLineNumbers;

  /// 1-based line numbers to tint (`rgba(0,0,0,.05)`, `rgba(255,255,255,.08)` in dark).
  final List<int> highlightLines;
  final bool showCopyButton;

  /// Copy button label. Defaults to [KumoStrings.copy].
  final String? copyLabel;

  /// Label after copying. Defaults to [KumoStrings.copied].
  final String? copiedLabel;

  /// Wrap long lines instead of scrolling sideways.
  final bool wrap;

  /// Scroll vertically past this height.
  final double? maxHeight;

  /// Overrides the token palette.
  final KumoCodeColors? colors;

  /// Called after the code was copied.
  final VoidCallback? onCopy;

  @override
  State<KumoCodeHighlighted> createState() => _KumoCodeHighlightedState();
}

class _KumoCodeHighlightedState extends State<KumoCodeHighlighted> {
  late List<List<KumoCodeToken>> _lines;

  @override
  void initState() {
    super.initState();
    _lines = KumoCodeHighlighter.tokenizeLines(widget.code, widget.lang);
  }

  @override
  void didUpdateWidget(KumoCodeHighlighted oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tokenize only when the source changes, not on hover or copy rebuilds.
    if (widget.code != oldWidget.code || widget.lang != oldWidget.lang) {
      _lines = KumoCodeHighlighter.tokenizeLines(widget.code, widget.lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final colors = widget.colors ?? KumoCodeColors.of(kumo);
    final supported = KumoCodeHighlighter.supports(widget.lang);
    // Unknown languages fall back to Kumo's plain-text styling.
    final base = kumo.code(color: supported ? KumoColor.textDefault : KumoColor.textSubtle).copyWith(height: 1.625);
    final styles = <KumoCodeTokenType, TextStyle>{
      for (final t in KumoCodeTokenType.values)
        t: t == KumoCodeTokenType.plain || !supported ? base : base.copyWith(color: colors.of(t)),
    };
    return DataCodeBlock(
      lines: [
        for (final line in _lines) [for (final token in line) TextSpan(text: token.text, style: styles[token.type])],
      ],
      copyText: widget.code,
      style: base,
      variant: widget.variant,
      padding: KumoSpace.s4,
      showLineNumbers: widget.showLineNumbers,
      highlightLines: widget.highlightLines,
      highlightColor: colors.lineHighlight,
      showCopyButton: widget.showCopyButton,
      copyLabel: widget.copyLabel,
      copiedLabel: widget.copiedLabel,
      wrap: widget.wrap,
      maxHeight: widget.maxHeight,
      onCopy: widget.onCopy,
    );
  }
}

/// The block both code widgets render. Not exported.
class DataCodeBlock extends StatefulWidget {
  const DataCodeBlock({
    super.key,
    required this.lines,
    required this.copyText,
    required this.style,
    required this.variant,
    required this.padding,
    required this.showLineNumbers,
    required this.highlightLines,
    required this.highlightColor,
    required this.showCopyButton,
    required this.wrap,
    this.copyLabel,
    this.copiedLabel,
    this.maxHeight,
    this.onCopy,
  });

  final List<List<InlineSpan>> lines;
  final String copyText;
  final TextStyle style;
  final KumoCodeVariant variant;
  final double padding;
  final bool showLineNumbers;
  final List<int> highlightLines;
  final Color highlightColor;
  final bool showCopyButton;
  final bool wrap;
  final String? copyLabel;
  final String? copiedLabel;
  final double? maxHeight;
  final VoidCallback? onCopy;

  @override
  State<DataCodeBlock> createState() => _DataCodeBlockState();
}

class _DataCodeBlockState extends State<DataCodeBlock> with SingleTickerProviderStateMixin, DataCopyFeedback {
  final ScrollController _horizontal = ScrollController();
  bool _hovered = false;
  bool _focused = false;

  @override
  Duration get copyFeedbackDuration => const Duration(milliseconds: 2000);

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final strings = context.kumoStrings;
    final ok = await copyText(
      widget.copyText,
      copied: widget.copiedLabel ?? strings.copied,
      failed: strings.copyFailed,
    );
    if (ok) widget.onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final plain = widget.variant == KumoCodeVariant.plain;
    final pad = plain ? 0.0 : widget.padding;
    final lineCount = widget.lines.length;
    final singleLine = lineCount == 1;
    final numbers = widget.showLineNumbers && !singleLine;
    final highlighted = widget.highlightLines.toSet();
    final textScaler = MediaQuery.textScalerOf(context);
    final strut = StrutStyle.fromTextStyle(widget.style, forceStrutHeight: true);

    Widget lineText(int i) => Text.rich(
      TextSpan(children: widget.lines[i].isEmpty ? const [TextSpan(text: ' ')] : widget.lines[i]),
      style: widget.style,
      strutStyle: strut,
      softWrap: widget.wrap,
      textScaler: textScaler,
    );

    Widget line(int i) {
      final tint = highlighted.contains(i + 1);
      return Container(
        color: tint ? widget.highlightColor : null,
        padding: EdgeInsetsDirectional.symmetric(horizontal: pad),
        child: lineText(i),
      );
    }

    // Line numbers sit outside the horizontal scroll, like Kumo's gutter
    // (`pl-3 pr-4`, 40% opacity).
    final numberStyle = widget.style.copyWith(color: c.textDefault.withValues(alpha: 0.4));
    Widget number(int i) =>
        Text('${i + 1}', style: numberStyle, strutStyle: strut, textAlign: TextAlign.end, textScaler: textScaler);
    final gutterPadding = EdgeInsetsDirectional.only(start: plain ? 0 : KumoSpace.s3, end: KumoSpace.s4);

    Widget code;
    if (widget.wrap) {
      // Wrapped lines can span several rows, so each number rides with its line.
      final digits = '$lineCount'.length;
      final probe = TextPainter(
        text: TextSpan(text: '8' * digits, style: numberStyle),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      final gutterWidth = probe.width + 1;
      probe.dispose();
      code = Padding(
        padding: EdgeInsets.symmetric(vertical: pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lineCount; i++)
              if (numbers)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: gutterPadding,
                      child: SizedBox(
                        width: gutterWidth,
                        child: ExcludeSemantics(child: number(i)),
                      ),
                    ),
                    Expanded(child: line(i)),
                  ],
                )
              else
                line(i),
          ],
        ),
      );
    } else {
      final scroller = LayoutBuilder(
        builder: (context, constraints) => DataScrollFade(
          controller: _horizontal,
          color: plain ? c.base.withValues(alpha: 0) : c.base,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(vertical: pad),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = 0; i < lineCount; i++) line(i)],
                ),
              ),
            ),
          ),
        ),
      );
      code = numbers
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: gutterPadding.add(EdgeInsets.symmetric(vertical: pad)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [for (var i = 0; i < lineCount; i++) number(i)],
                    ),
                  ),
                ),
                Expanded(child: scroller),
              ],
            )
          : scroller;
    }

    if (widget.maxHeight != null) {
      code = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: SingleChildScrollView(child: code),
      );
    }

    if (widget.showCopyButton) {
      final touch = kumo.tapTargetSize == KumoTapTargetSize.padded;
      final visible = touch || _hovered || _focused || copyStatus != DataCopyStatus.idle;
      final label = switch (copyStatus) {
        DataCopyStatus.copied => widget.copiedLabel ?? strings.copied,
        DataCopyStatus.failed => strings.copyFailed,
        DataCopyStatus.idle => widget.copyLabel ?? strings.copy,
      };
      final Widget button = AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: KumoMotion.duration(context, KumoDurations.quick),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (f) => setState(() => _focused = f),
          child: ScaleTransition(
            scale: copyBump,
            child: KumoButton(label: label, size: KumoButtonSize.sm, onPress: _copy),
          ),
        ),
      );
      if (singleLine) {
        code = Row(
          children: [
            Expanded(child: code),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2),
              child: button,
            ),
          ],
        );
      } else {
        code = Stack(
          children: [
            code,
            PositionedDirectional(top: plain ? 0 : KumoSpace.s2, end: plain ? 0 : KumoSpace.s2, child: button),
          ],
        );
      }
      code = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: code,
      );
    }

    if (plain) return code;
    const radius = BorderRadius.all(Radius.circular(KumoRadius.md));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: radius,
        border: Border.all(color: c.fill),
      ),
      child: ClipRRect(borderRadius: radius, child: code),
    );
  }
}
