import 'package:flutter/widgets.dart';

import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';

/// Text styles from Kumo's `Text` component.
enum KumoTextVariant {
  /// Semibold heading: 16px, or 20px with [KumoText.size] `lg`.
  heading,

  /// Default body text (`text-kumo-default`).
  body,

  /// Muted text for descriptions and metadata (`text-kumo-subtle`).
  secondary,

  /// Positive text. Kumo maps it to the link blue, not green.
  success,

  /// Error text (`text-kumo-danger`).
  error,

  /// Monospace, 13px (14px with size `lg`).
  mono,

  /// Muted monospace.
  monoSecondary,
}

/// Kumo's `Text`: every string in a Kumo UI goes through it.
///
/// Content text is 14px. Headings are sentence case and semibold; [bold]
/// emphasis is medium weight (Kumo never uses bold 700).
///
/// ```dart
/// const KumoText('Workers', variant: KumoTextVariant.heading, size: KumoTextSize.lg, headingLevel: 1)
/// const KumoText('Deployed 3 minutes ago', variant: KumoTextVariant.secondary, size: KumoTextSize.sm)
/// const KumoText('wrangler.toml', variant: KumoTextVariant.mono)
/// ```
class KumoText extends StatelessWidget {
  const KumoText(
    this.text, {
    super.key,
    this.variant = KumoTextVariant.body,
    this.size = KumoTextSize.base,
    this.bold = false,
    this.truncate = false,
    this.maxLines,
    this.textAlign,
    this.color,
    this.dangerouslySetColor,
    this.headingLevel,
    this.tabularNumbers = false,
    this.semanticsLabel,
  });

  final String text;
  final KumoTextVariant variant;

  /// Body sizes `xs` 12, `sm` 13, `base` 14, `lg` 16. For [KumoTextVariant.heading]
  /// only `lg` changes the size (to 20px); mono variants use `lg` for 14px.
  final KumoTextSize size;

  /// Medium weight emphasis. Ignored by headings and mono variants.
  final bool bold;

  /// One line with an ellipsis.
  final bool truncate;
  final int? maxLines;
  final TextAlign? textAlign;

  /// Overrides the variant's color token.
  final KumoColor? color;
  final Color? dangerouslySetColor;

  /// Marks the text as a heading for screen readers (the `h1`-`h6` of Kumo's
  /// `as` prop). Headings without a level are styled text only.
  final int? headingLevel;

  /// Fixed-width digits, for numbers in tables and counters.
  final bool tabularNumbers;
  final String? semanticsLabel;

  /// Resolves the style a [KumoText] with these settings uses.
  static TextStyle styleOf(
    BuildContext context, {
    KumoTextVariant variant = KumoTextVariant.body,
    KumoTextSize size = KumoTextSize.base,
    bool bold = false,
  }) {
    final kumo = context.kumo;
    return switch (variant) {
      KumoTextVariant.heading =>
        kumo.heading(size: size == KumoTextSize.lg ? KumoHeadingSize.lg : KumoHeadingSize.base),
      KumoTextVariant.mono => kumo.code(large: size == KumoTextSize.lg),
      KumoTextVariant.monoSecondary => kumo.code(large: size == KumoTextSize.lg, color: KumoColor.textSubtle),
      _ => kumo.text(
          size: size,
          weight: bold ? KumoTypography.medium : KumoTypography.normal,
          color: switch (variant) {
            KumoTextVariant.secondary => KumoColor.textSubtle,
            KumoTextVariant.success => KumoColor.textLink,
            KumoTextVariant.error => KumoColor.textDanger,
            _ => KumoColor.textDefault,
          },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    var style = styleOf(context, variant: variant, size: size, bold: bold);
    if (color != null) style = style.copyWith(color: context.kumo.color(color!));
    if (dangerouslySetColor != null) style = style.copyWith(color: dangerouslySetColor);
    if (tabularNumbers) style = style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final lines = truncate ? 1 : maxLines;
    final overflow = truncate || maxLines != null ? TextOverflow.ellipsis : null;
    // Wrap a region in SelectionArea to make it selectable.
    Widget result =
        Text(text, style: style, textAlign: textAlign, maxLines: lines, overflow: overflow, semanticsLabel: semanticsLabel);
    if (headingLevel != null) {
      result = Semantics(header: true, headingLevel: headingLevel!.clamp(1, 6), child: result);
    }
    return result;
  }
}
