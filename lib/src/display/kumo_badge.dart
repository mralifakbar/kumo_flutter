import 'package:flutter/widgets.dart';

import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Color variants of [KumoBadge], matching Kumo's `variant` prop.
///
/// The semantic variants ([primary] through [outline]) are the ones to reach
/// for first. The color variants ([red] through [blue]) are for product
/// categories where a semantic color would say the wrong thing.
enum KumoBadgeVariant {
  /// Inverted fill (`bg-kumo-badge-inverted`). Kumo's default.
  primary,

  /// Neutral fill with the subtle neutral text token.
  secondary,

  /// Danger tint with danger text.
  error,

  /// Warning tint with warning text.
  warning,

  /// Success tint with success text.
  success,

  /// Info tint with info text.
  info,

  /// Dashed brand border, link-colored text. Marks beta or experimental features.
  beta,

  /// 1px fill-colored border on the base surface.
  outline,

  /// Solid red with white text.
  red,

  /// Solid green with white text.
  green,

  /// Solid neutral gray with white text.
  neutral,

  /// Solid orange with black text.
  orange,

  /// Solid purple with white text.
  purple,

  /// Solid teal with white text.
  teal,

  /// Teal tint with `text-kumo-badge-teal-subtle`.
  tealSubtle,

  /// Orange tint with `text-kumo-badge-orange-subtle`. The token exists in
  /// Kumo's theme; the variant is an addition of this port.
  orangeSubtle,

  /// Solid blue with white text.
  blue,

  /// Kept for parity with Kumo, where it is deprecated.
  @Deprecated('Use KumoBadgeVariant.red')
  destructive;

  /// Kumo's docs list `inverted` among the token variants; it is the
  /// [primary] badge (`bg-kumo-badge-inverted text-kumo-badge-inverted`).
  static const KumoBadgeVariant inverted = primary;

  /// Kumo's docs list `neutral-subtle`; it is the [secondary] badge
  /// (`bg-kumo-fill text-kumo-badge-neutral-subtle`).
  static const KumoBadgeVariant neutralSubtle = secondary;

  /// The color a dot badge's dot takes, or null when the variant has no dot.
  /// Kumo only draws dots for [success], [warning], [error] and [neutral].
  KumoColor? get dotColor => switch (this) {
    success => KumoColor.success,
    warning => KumoColor.badgeOrange,
    error => KumoColor.badgeRed,
    neutral => KumoColor.badgeNeutral,
    _ => null,
  };
}

/// How a [KumoBadge] draws its variant.
enum KumoBadgeAppearance {
  /// Filled with the variant's background. The default.
  filled,

  /// Transparent with a hairline ring and a 7px status dot before the text.
  /// Only [KumoBadgeVariant.success], `warning`, `error` and `neutral` show a
  /// dot; dot badges never take an icon.
  dot,
}

/// Badge sizes. Kumo has one size ([base]); [lg] is an addition of this port
/// for page headers where a 12px badge reads too small next to a 20px title.
enum KumoBadgeSize {
  /// `px-2 py-0.5 text-xs`: 20px tall.
  base(KumoTextSize.xs, 4 / 3, KumoSpace.s2, KumoSpace.s0_5, 12),

  /// `px-2.5 py-1 text-sm`: about 23px tall.
  lg(KumoTextSize.sm, 1 / 0.85, KumoSpace.s2_5, KumoSpace.s1, 13);

  const KumoBadgeSize(this.textSize, this.lineHeight, this.paddingX, this.paddingY, this.iconSize);
  final KumoTextSize textSize;

  /// Line height multiplier (Kumo's `--text-xs--line-height` is 1/0.75).
  final double lineHeight;
  final double paddingX;
  final double paddingY;
  final double iconSize;
}

/// Resolved colors for one badge variant in one theme. Exposed so tests and
/// custom chips can check or reuse the exact pairs a badge draws.
@immutable
class KumoBadgeColors {
  const KumoBadgeColors({required this.background, required this.foreground, this.border, this.dashed = false});

  /// Fill. May be translucent (the semantic tints are); composite it over
  /// the surface behind the badge before measuring contrast.
  final Color background;
  final Color foreground;

  /// A CSS border (takes 1px of layout), drawn dashed when [dashed].
  final Color? border;
  final bool dashed;

  /// The colors [variant] draws in [theme] with the filled appearance.
  static KumoBadgeColors resolve(KumoThemeData theme, KumoBadgeVariant variant) {
    final c = theme.colors;
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    return switch (variant) {
      KumoBadgeVariant.primary => KumoBadgeColors(background: c.badgeInverted, foreground: c.textBadgeInverted),
      KumoBadgeVariant.secondary => KumoBadgeColors(background: c.fill, foreground: c.textBadgeNeutralSubtle),
      KumoBadgeVariant.error => KumoBadgeColors(background: c.dangerTint, foreground: c.textDanger),
      KumoBadgeVariant.warning => KumoBadgeColors(background: c.warningTint, foreground: c.textWarning),
      KumoBadgeVariant.success => KumoBadgeColors(background: c.successTint, foreground: c.textSuccess),
      KumoBadgeVariant.info => KumoBadgeColors(background: c.infoTint, foreground: c.textInfo),
      KumoBadgeVariant.beta => KumoBadgeColors(
        background: const Color(0x00000000),
        foreground: c.textLink,
        border: c.brand,
        dashed: true,
      ),
      KumoBadgeVariant.outline => KumoBadgeColors(background: c.base, foreground: c.textDefault, border: c.fill),
      KumoBadgeVariant.red ||
      // ignore: deprecated_member_use_from_same_package
      KumoBadgeVariant.destructive => KumoBadgeColors(background: c.badgeRed, foreground: white),
      KumoBadgeVariant.green => KumoBadgeColors(background: c.badgeGreen, foreground: white),
      KumoBadgeVariant.neutral => KumoBadgeColors(background: c.badgeNeutral, foreground: white),
      KumoBadgeVariant.orange => KumoBadgeColors(background: c.badgeOrange, foreground: black),
      KumoBadgeVariant.purple => KumoBadgeColors(background: c.badgePurple, foreground: white),
      KumoBadgeVariant.teal => KumoBadgeColors(background: c.badgeTeal, foreground: white),
      KumoBadgeVariant.blue => KumoBadgeColors(background: c.badgeBlue, foreground: white),
      // Kumo's teal-subtle names `bg-kumo-badge-teal-subtle`, which its theme
      // never defines, so the web badge has no fill. A light tint of the solid
      // badge color keeps the subtle text token readable on any surface.
      KumoBadgeVariant.tealSubtle => KumoBadgeColors(
        background: c.badgeTeal.withValues(alpha: theme.isDark ? 0.24 : 0.12),
        foreground: c.textBadgeTealSubtle,
      ),
      KumoBadgeVariant.orangeSubtle => KumoBadgeColors(
        background: c.badgeOrange.withValues(alpha: theme.isDark ? 0.2 : 0.16),
        foreground: c.textBadgeOrangeSubtle,
      ),
    };
  }
}

/// Kumo's `Badge`: a small label for status, categories or metadata.
///
/// ```dart
/// const KumoBadge('Active', variant: KumoBadgeVariant.green)
/// const KumoBadge('Healthy', variant: KumoBadgeVariant.success, appearance: KumoBadgeAppearance.dot)
/// const KumoBadge('Verified', variant: KumoBadgeVariant.success, icon: KumoIcons.checkCircle)
/// ```
///
/// A badge is text, so status always reads without its color. Keep the label
/// to one or two words in sentence case. Give it an [onPress] to make it a
/// link or button: it then shows Kumo's hover ring in its text color.
class KumoBadge extends StatelessWidget {
  const KumoBadge(
    this.label, {
    super.key,
    this.variant = KumoBadgeVariant.primary,
    this.appearance = KumoBadgeAppearance.filled,
    this.size = KumoBadgeSize.base,
    this.icon,
    this.iconWidget,
    this.onPress,
    this.isLink = false,
    this.semanticLabel,
  }) : assert(
         appearance == KumoBadgeAppearance.filled || (icon == null && iconWidget == null),
         'Dot badges use their status dot instead of an icon',
       );

  final String label;
  final KumoBadgeVariant variant;
  final KumoBadgeAppearance appearance;
  final KumoBadgeSize size;

  /// Leading 12px icon (filled appearance only). Decorative: the label carries
  /// the meaning.
  final IconData? icon;

  /// Leading widget in place of [icon].
  final Widget? iconWidget;

  /// Makes the badge tappable. Kumo badges become interactive by sitting in
  /// a `Link`; here the badge owns the press and draws the same hover ring.
  final VoidCallback? onPress;

  /// Announce as a link instead of a button when [onPress] is set.
  final bool isLink;

  /// Replaces [label] for screen readers, for example "Status: healthy".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final dot = appearance == KumoBadgeAppearance.dot;
    final colors = dot
        ? KumoBadgeColors(background: const Color(0x00000000), foreground: kumo.colors.textDefault)
        : KumoBadgeColors.resolve(kumo, variant);
    final dotColor = dot ? variant.dotColor : null;
    final hasIcon = !dot && (icon != null || iconWidget != null);
    final radius = BorderRadius.circular(KumoRadius.full);
    // A CSS border takes 1px of layout. Container adds a solid Border's width
    // itself; the dashed border is painted, so its 1px is added here.
    final dashInset = colors.dashed ? 1.0 : 0.0;
    final lineBox = size.textSize.fontSize * size.lineHeight;

    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: kumo
          .text(size: size.textSize, weight: KumoTypography.medium, height: size.lineHeight)
          .copyWith(color: colors.foreground),
    );

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dotColor != null) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: kumo.color(dotColor), shape: BoxShape.circle),
          ),
          const SizedBox(width: KumoSpace.s1_5),
        ],
        if (hasIcon) ...[
          // `h-lh w-3`: the icon box is one line tall so it sits on the text's first line.
          SizedBox(
            height: lineBox,
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(size: size.iconSize, color: colors.foreground),
                child: iconWidget ?? KumoIcon(icon!, size: size.iconSize, dangerouslySetColor: colors.foreground),
              ),
            ),
          ),
          const SizedBox(width: KumoSpace.s1),
        ],
        Flexible(child: text),
      ],
    );

    Widget badge(bool hovered) {
      final padding = EdgeInsetsDirectional.fromSTEB(
        (hasIcon ? KumoSpace.s1_5 : size.paddingX) + dashInset,
        size.paddingY + dashInset,
        size.paddingX + dashInset,
        size.paddingY + dashInset,
      );
      Border? ring;
      if (dot) ring = KumoRing.border(kumo.colors.hairline);
      // `[a:hover_&]:ring ring-current`
      if (hovered) ring = KumoRing.border(colors.foreground);
      Widget box = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: radius,
          border: colors.border != null && !colors.dashed ? Border.all(color: colors.border!) : ring,
        ),
        foregroundDecoration: colors.border != null && !colors.dashed && ring != null
            ? BoxDecoration(borderRadius: radius, border: ring)
            : null,
        child: content,
      );
      if (colors.dashed) {
        box = CustomPaint(
          foregroundPainter: _DashedPillPainter(color: colors.border!, ring: hovered ? colors.foreground : null),
          child: box,
        );
      }
      return box;
    }

    // A new status (Deploying to Active) cross-fades the pill and eases its
    // width, so the row it sits in does not jump. Hover stays instant.
    final appearanceKey = ValueKey((label, variant, appearance, size, icon, iconWidget?.key));
    Widget swap(Widget pill) => KumoSwap(
      animateSize: true,
      child: KeyedSubtree(key: appearanceKey, child: pill),
    );

    if (onPress == null) {
      return Semantics(label: semanticLabel, excludeSemantics: semanticLabel != null, child: swap(badge(false)));
    }
    return KumoPressable(
      onPress: onPress,
      isLink: isLink,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      excludeChildSemantics: semanticLabel != null,
      builder: (context, state) => swap(badge(state.hovered)),
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter({required this.color, this.ring});

  final Color color;
  final Color? ring;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(size.height / 2));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    // CSS dashed borders at 1px draw roughly 3px dashes with 3px gaps.
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
        d += 6;
      }
    }
    if (ring != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius((Offset.zero & size).inflate(0.5), Radius.circular(size.height / 2 + 0.5)),
        paint..color = ring!,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter old) => old.color != color || old.ring != ring;
}
