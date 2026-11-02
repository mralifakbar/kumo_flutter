import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Link styles from Kumo's `Link`.
enum KumoLinkVariant {
  /// Link blue with a soft underline that firms up on hover. The default.
  inline,

  /// Inherits the surrounding text color, keeps the underline. For links
  /// inside colored text such as an error message.
  current,

  /// Link blue, no underline; dims to 70% on hover.
  plain,
}

/// Kumo's `Link`: a styled text link.
///
/// Flutter has no `href`, so navigation happens in [onPress] (push a route,
/// call `launchUrl`). The link announces itself as a link to screen readers.
///
/// ```dart
/// KumoLink(label: 'View deployment logs', onPress: () => context.go('/logs'))
/// ```
///
/// [external] adds Kumo's `Link.ExternalIcon` and the hint that the link
/// opens a new window:
///
/// ```dart
/// KumoLink(label: 'Workers documentation', external: true, onPress: openDocs)
/// ```
///
/// Size and weight follow the surrounding [DefaultTextStyle]. Inside running
/// text, place it in a [WidgetSpan] and turn off [padTapTarget]:
///
/// ```dart
/// Text.rich(TextSpan(children: [
///   const TextSpan(text: 'Read the '),
///   WidgetSpan(
///     alignment: PlaceholderAlignment.baseline,
///     baseline: TextBaseline.alphabetic,
///     child: KumoLink(label: 'routing guide', padTapTarget: false, onPress: openGuide),
///   ),
///   const TextSpan(text: ' before adding a custom domain.'),
/// ]))
/// ```
class KumoLink extends StatelessWidget {
  const KumoLink({
    super.key,
    required this.label,
    required this.onPress,
    this.variant = KumoLinkVariant.inline,
    this.external = false,
    this.size,
    this.icon,
    this.disabled = false,
    this.padTapTarget = true,
    this.externalHint,
    this.semanticLabel,
    this.focusNode,
  });

  final String label;

  /// Navigates. Null renders the link as plain, inactive text.
  final VoidCallback? onPress;
  final KumoLinkVariant variant;

  /// Shows the external arrow icon after the label and adds [externalHint]
  /// for screen readers.
  final bool external;

  /// Text size. Null inherits the surrounding text style.
  final KumoTextSize? size;

  /// Optional leading icon, sized to the text.
  final IconData? icon;
  final bool disabled;

  /// Grow the hit area to 44x44 on touch platforms. Turn off for links
  /// inside a paragraph, where the line height is the target (an inline
  /// exception in WCAG 2.5.8).
  final bool padTapTarget;

  /// Screen reader hint for [external] links. Defaults to
  /// [KumoStrings.opensInNewWindow].
  final String? externalHint;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final inherited = DefaultTextStyle.of(context).style;
    final base = size == null
        ? inherited
        : inherited.merge(kumo.text(size: size!, weight: inherited.fontWeight ?? KumoTypography.normal));
    final fontSize = base.fontSize ?? 14;
    final inactive = disabled || onPress == null;

    return KumoPressable(
      onPress: inactive ? null : onPress,
      disabled: disabled,
      isLink: true,
      scaleOnPress: false,
      focusNode: focusNode,
      minTapTargetSize: padTapTarget ? null : 0,
      borderRadius: BorderRadius.circular(KumoRadius.sm),
      semanticLabel: semanticLabel,
      semanticHint: external ? (externalHint ?? context.kumoStrings.opensInNewWindow) : null,
      builder: (context, state) {
        final hover = state.active;
        final Color color;
        switch (variant) {
          case KumoLinkVariant.inline:
            color = c.textLink;
          case KumoLinkVariant.current:
            color = inherited.color ?? c.textDefault;
          case KumoLinkVariant.plain:
            color = hover ? c.textLink.withValues(alpha: c.textLink.a * 0.7) : c.textLink;
        }
        final underlined = variant != KumoLinkVariant.plain;
        // Kumo's `link-current`: the underline is the text color at 35%
        // (65% in dark mode) and goes solid on hover.
        final lineColor = hover ? color : color.withValues(alpha: color.a * (kumo.isDark ? 0.65 : 0.35));
        final style = base.copyWith(
          color: disabled ? c.textInactive : color,
          decoration: underlined ? TextDecoration.underline : TextDecoration.none,
          decorationColor: disabled ? c.textInactive : lineColor,
          decorationThickness: 1,
        );
        final gap = fontSize * 0.1875;
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: [
            if (icon != null) KumoIcon(icon!, size: fontSize, dangerouslySetColor: style.color),
            Flexible(child: Text(label, style: style)),
            if (external) KumoIcon(KumoIcons.arrowSquareOut, size: fontSize, dangerouslySetColor: style.color),
          ],
        );
      },
    );
  }
}
