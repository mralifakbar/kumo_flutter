import 'package:flutter/widgets.dart';

import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Control heights shared by inputs, selects, comboboxes and pickers. They
/// match [KumoButtonSize] so a field and a button line up in a row.
enum KumoFieldSize {
  /// 20px, `text-xs`.
  xs(20, KumoTextSize.xs, KumoRadius.sm, 6),

  /// 26px, `text-xs`.
  sm(26, KumoTextSize.xs, KumoRadius.md, 8),

  /// 36px, `text-base` (14px). The default.
  base(36, KumoTextSize.base, KumoRadius.lg, 12),

  /// 40px, `text-base`.
  lg(40, KumoTextSize.base, KumoRadius.lg, 16);

  const KumoFieldSize(this.height, this.textSize, this.radius, this.paddingX);
  final double height;
  final KumoTextSize textSize;
  final double radius;
  final double paddingX;
}

/// Where a floating panel (menu, select list, picker) appears.
enum KumoPresentation {
  /// Anchored popover on wide screens, bottom sheet below 768px.
  auto,

  /// Always an anchored popover.
  popover,

  /// Always a bottom sheet.
  sheet;

  /// Resolves [auto] for the current window.
  bool usesSheet(BuildContext context) => switch (this) {
    KumoPresentation.auto => context.kumoIsNarrow,
    KumoPresentation.popover => false,
    KumoPresentation.sheet => true,
  };
}

/// The chrome of every Kumo text field: `bg-kumo-control`, a 1px
/// `kumo-line` ring that becomes a 1.5px focus ring, and a danger ring for
/// errors. Content (usually a [KumoEditable] row) goes in [child].
///
/// ```dart
/// KumoFieldBox(
///   focused: focusNode.hasFocus,
///   error: errorText != null,
///   child: KumoEditable(focusNode: focusNode, placeholder: 'example.com'),
/// )
/// ```
class KumoFieldBox extends StatelessWidget {
  const KumoFieldBox({
    super.key,
    required this.child,
    this.size = KumoFieldSize.base,
    this.focused = false,
    this.error = false,
    this.disabled = false,
    this.readOnly = false,
    this.hovered = false,
    this.leading,
    this.trailing,
    this.multiline = false,
    this.minHeight,
    this.padding,
    this.borderRadius,
    this.gap,
  });

  final Widget child;
  final KumoFieldSize size;
  final bool focused;
  final bool error;
  final bool disabled;

  /// Read-only fields sit on a recessed fill.
  final bool readOnly;
  final bool hovered;

  /// Icon or addon at the start, inside the box.
  final Widget? leading;

  /// Icon, button or addon at the end, inside the box.
  final Widget? trailing;

  /// Top-aligned content that grows with its lines (textarea).
  final bool multiline;
  final double? minHeight;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Space between [leading], the content and [trailing]. Defaults to
  /// Kumo's `gap-1` for xs/sm and `gap-1.5` for base/lg.
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final radius = borderRadius ?? BorderRadius.circular(size.radius);
    final ringColor = error
        ? (focused ? c.danger.withValues(alpha: 0.5) : c.danger)
        : (focused ? c.focus.withValues(alpha: 0.5) : c.line);
    final ringWidth = focused ? 1.5 : 1.0;
    final gap = this.gap ?? (size == KumoFieldSize.xs || size == KumoFieldSize.sm ? KumoSpace.s1 : KumoSpace.s1_5);

    final content = Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      spacing: gap,
      children: [
        if (leading != null)
          IconTheme.merge(
            data: IconThemeData(color: c.textSubtle),
            child: leading!,
          ),
        Expanded(child: child),
        if (trailing != null)
          IconTheme.merge(
            data: IconThemeData(color: c.textSubtle),
            child: trailing!,
          ),
      ],
    );

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? size.height),
        // Focus and error rings ease in over Kumo's 100ms; hover never animates.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: ringWidth),
          duration: KumoMotion.duration(context, KumoDurations.fast),
          curve: KumoCurves.standard,
          builder: (context, width, child) => TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: ringColor),
            duration: KumoMotion.duration(context, KumoDurations.fast),
            curve: KumoCurves.standard,
            builder: (context, color, child) => DecoratedBox(
              decoration: BoxDecoration(
                color: readOnly || disabled ? c.recessed : c.control,
                borderRadius: radius,
                border: KumoRing.border(color ?? ringColor, width: width),
              ),
              child: child,
            ),
            child: child,
          ),
          child: Padding(
            padding:
                padding ??
                EdgeInsetsDirectional.symmetric(horizontal: size.paddingX, vertical: multiline ? KumoSpace.s2 : 0),
            // heightFactor 1 sizes to the content; the min height above still
            // applies, with the content centered in it.
            child: Align(
              alignment: multiline ? AlignmentDirectional.topStart : AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: DefaultTextStyle.merge(
                style: context.kumo.text(size: size.textSize),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
