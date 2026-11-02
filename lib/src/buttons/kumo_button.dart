import 'package:flutter/widgets.dart';

import '../feedback/kumo_loader.dart';
import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../utils/kumo_color_utils.dart';

/// Button styles.
enum KumoButtonVariant {
  /// High emphasis, brand blue with a soft top-lit gradient. One per view.
  primary,

  /// The default: base surface with a 1px ring.
  secondary,

  /// No background until hovered. Toolbars and tertiary actions.
  ghost,

  /// Red emphasis for destructive actions (delete, revoke).
  destructive,

  /// Secondary surface with red text, for less prominent destructive actions.
  secondaryDestructive,

  /// Transparent with a ring.
  outline,
}

/// Button heights: `xs` 20, `sm` 26, `base` 36, `lg` 40.
enum KumoButtonSize {
  xs(20, 12, KumoRadius.sm, 6, 4, 4, 12),
  sm(26, 12, KumoRadius.md, 8, 4, 6, 14),
  base(36, 14, KumoRadius.lg, 12, 6, 10, 16),
  lg(40, 14, KumoRadius.lg, 16, 8, 14, 16);

  const KumoButtonSize(
    this.height,
    this.fontSize,
    this.radius,
    this.paddingX,
    this.gap,
    this.iconLeadingPadding,
    this.iconSize,
  );
  final double height;
  final double fontSize;
  final double radius;
  final double paddingX;
  final double gap;

  /// Icons carry whitespace in their glyph box, so icon + text buttons trim
  /// the leading padding to look even with the trailing side.
  final double iconLeadingPadding;
  final double iconSize;

  /// Lowercase text sits below its line box center; Kumo lifts it this much.
  double get textLift => this == xs || this == sm ? 0.5 : 1;
}

/// Button shapes. [square] and [circle] are icon-only and need a
/// [KumoButton.semanticLabel].
enum KumoButtonShape { base, square, circle }

/// Kumo's `Button`.
///
/// ```dart
/// KumoButton(label: 'Deploy', variant: KumoButtonVariant.primary, onPress: deploy)
/// KumoButton(label: 'Add route', icon: KumoIcons.plus, onPress: addRoute)
/// KumoButton(
///   icon: KumoIcons.trash,
///   shape: KumoButtonShape.square,
///   variant: KumoButtonVariant.ghost,
///   semanticLabel: 'Delete route',
///   onPress: delete,
/// )
/// ```
///
/// Feedback starts on pointer-down (a 0.98 spring scale); hover colors switch
/// instantly. While [loading], the icon becomes a spinner and presses are
/// ignored, with the label kept so the width does not jump. A [title] adds a
/// tooltip, and doubles as the accessible name of icon-only buttons.
class KumoButton extends StatelessWidget {
  const KumoButton({
    super.key,
    this.label,
    this.child,
    this.onPress,
    this.onLongPress,
    this.variant = KumoButtonVariant.secondary,
    this.size = KumoButtonSize.base,
    this.shape = KumoButtonShape.base,
    this.icon,
    this.iconWidget,
    this.endIcon,
    this.loading = false,
    this.disabled = false,
    this.block = false,
    this.title,
    this.semanticLabel,
    this.isLink = false,
    this.haptic = KumoHaptic.none,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius,
    this.dangerouslySetEmphasisColor,
    this.expanded,
    this.shadow = true,
  }) : assert(
         shape == KumoButtonShape.base || semanticLabel != null || title != null,
         'Icon-only buttons need a semanticLabel or title',
       );

  /// Button text, sentence case.
  final String? label;

  /// Custom content in place of [label].
  final Widget? child;

  /// Null renders the button disabled.
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final KumoButtonVariant variant;
  final KumoButtonSize size;
  final KumoButtonShape shape;

  /// Leading icon.
  final IconData? icon;

  /// Leading widget in place of [icon].
  final Widget? iconWidget;

  /// Trailing icon (a caret for menus).
  final IconData? endIcon;
  final bool loading;
  final bool disabled;

  /// Stretch to the parent's width.
  final bool block;

  /// Tooltip text. Icon-only buttons also use it as their accessible name.
  final String? title;
  final String? semanticLabel;

  /// Announce as a link (Kumo's `LinkButton`).
  final bool isLink;
  final KumoHaptic haptic;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Overrides the size's corner radius, for joined buttons (split buttons,
  /// button groups) that square off their inner corners.
  final BorderRadius? borderRadius;

  /// Replaces the brand (primary) or danger (destructive) color of emphasis
  /// buttons, and the text and hover ring of the other variants. For accent
  /// actions inside colored containers such as banners.
  final Color? dangerouslySetEmphasisColor;

  /// Announces the disclosure state of a button that opens a menu or panel.
  final bool? expanded;

  /// Kumo's `shadow-xs` under the button. Joined groups turn it off.
  final bool shadow;

  bool get _disabled => disabled || (onPress == null && onLongPress == null);

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final compact = shape != KumoButtonShape.base;
    final radius = shape == KumoButtonShape.circle ? size.height / 2 : size.radius;
    final borderRadius = this.borderRadius ?? BorderRadius.circular(radius);
    final accent = dangerouslySetEmphasisColor;
    final emphasisToken = switch (variant) {
      KumoButtonVariant.primary => accent ?? c.brand,
      KumoButtonVariant.destructive => accent ?? c.danger,
      _ => null,
    };

    final textColor = switch (variant) {
      KumoButtonVariant.primary || KumoButtonVariant.destructive => const Color(0xFFFFFFFF),
      KumoButtonVariant.secondaryDestructive => accent ?? c.textDanger,
      _ => accent ?? c.textDefault,
    };

    final hasLabel = label != null || child != null;
    // Each leading state carries its own key so the slot cross-fades between
    // icon and spinner. A caller's iconWidget keeps its key, so a keyed swap
    // (copy to check) cross-fades too, while an unkeyed one updates in place.
    final Widget? leading = loading
        ? KumoLoader(
            key: const ValueKey('kumo-button-loader'),
            dimension: size == KumoButtonSize.lg ? 16 : 14,
            dangerouslySetColor: textColor,
          )
        : iconWidget != null
        ? KeyedSubtree(key: iconWidget!.key ?? const ValueKey('kumo-button-icon'), child: iconWidget!)
        : (icon != null
              ? KumoIcon(icon!, key: ValueKey(icon), size: size.iconSize, dangerouslySetColor: textColor)
              : null);

    final effectiveLabel = semanticLabel ?? title;
    final pressable = KumoPressable(
      onPress: _disabled ? null : onPress,
      onLongPress: _disabled ? null : onLongPress,
      disabled: _disabled,
      loading: loading,
      borderRadius: borderRadius,
      haptic: haptic,
      focusNode: focusNode,
      autofocus: autofocus,
      isLink: isLink,
      expanded: expanded,
      semanticLabel: effectiveLabel,
      excludeChildSemantics: compact || (effectiveLabel != null && semanticLabel != null),
      builder: (context, state) {
        final hover = state.active;
        Color? background;
        Gradient? gradient;
        Border? border;
        var shadows = shadow ? KumoShadow.xs.boxShadows : const <BoxShadow>[];
        var fg = textColor;

        if (emphasisToken != null) {
          final top = KumoColorUtils.mix(emphasisToken, const Color(0xFFFFFFFF), hover ? 0.3 : 0.15);
          gradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, emphasisToken],
          );
          border = KumoRing.border(KumoColorUtils.mix(emphasisToken, const Color(0xFF000000), 0.1));
        } else {
          switch (variant) {
            case KumoButtonVariant.secondary:
              background = hover ? c.tint : c.base;
              border = KumoRing.border(c.line);
            case KumoButtonVariant.secondaryDestructive:
              background = c.base;
              border = KumoRing.border(hover ? c.danger.withValues(alpha: 0.3) : c.line);
            case KumoButtonVariant.ghost:
              background = hover ? (accent?.withValues(alpha: 0.1) ?? c.tint) : null;
              shadows = const [];
            case KumoButtonVariant.outline:
              background = null;
              // CSS paints box-shadow only outside the box; Flutter paints it
              // under the whole box, where a transparent fill lets it show
              // through as a grey wash. Outline buttons go without it.
              shadows = const [];
              border = KumoRing.border(
                hover ? (accent ?? c.focus).withValues(alpha: accent == null ? 0.25 : 0.5) : c.line,
              );
              if (hover && accent == null) fg = c.textStrong;
            default:
              break;
          }
        }
        if (state.focused) border = null; // the 2px focus ring replaces the 1px ring

        final textStyle = kumo.typography.body(
          size: size.fontSize == 12 ? KumoTextSize.xs : KumoTextSize.base,
          weight: KumoTypography.medium,
          color: fg,
          height: 1.25,
        );

        Widget? labelWidget;
        if (hasLabel && !compact) {
          labelWidget = Transform.translate(
            offset: Offset(0, -size.textLift),
            // A new label ("Copy" to "Copied") cross-fades and the button
            // eases to its new width instead of jumping.
            child:
                child ??
                KumoSwap(
                  animateSize: true,
                  child: Text(
                    label!,
                    key: ValueKey(label),
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
          );
        }

        final trailing = endIcon == null ? null : KumoIcon(endIcon!, size: size.iconSize, dangerouslySetColor: fg);
        final motion = KumoMotion.duration(context, KumoDurations.moderate);
        Widget content;
        if (compact) {
          content = Center(
            child: KumoSwap(
              child:
                  leading ??
                  (child != null
                      ? KeyedSubtree(
                          key: child!.key ?? const ValueKey('kumo-button-child'),
                          child: DefaultTextStyle(style: textStyle, child: child!),
                        )
                      : null),
            ),
          );
        } else {
          final leadingPad = leading != null && hasLabel ? size.iconLeadingPadding : size.paddingX;
          final gapAfterLeading = hasLabel || trailing != null;
          // The leading slot is always present so a spinner that appears in a
          // label-only button fades in while the button widens smoothly.
          final leadingSlot = KumoSwap(
            animateSize: true,
            alignment: AlignmentDirectional.centerStart,
            child: leading == null
                ? null
                : KeyedSubtree(
                    key: leading.key,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: gapAfterLeading ? size.gap : 0),
                      child: leading,
                    ),
                  ),
          );
          content = AnimatedPadding(
            duration: motion,
            curve: KumoCurves.standard,
            padding: EdgeInsetsDirectional.only(start: leadingPad, end: size.paddingX),
            child: Row(
              mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leadingSlot,
                if (labelWidget != null) Flexible(child: labelWidget),
                if (trailing != null) ...[
                  if (labelWidget != null || leading != null) SizedBox(width: size.gap),
                  trailing,
                ],
              ],
            ),
          );
        }

        Widget surface = Container(
          height: size.height,
          width: compact ? size.height : (block ? double.infinity : null),
          decoration: BoxDecoration(
            color: background,
            gradient: gradient,
            borderRadius: borderRadius,
            border: border,
            boxShadow: shadows,
          ),
          child: DefaultTextStyle(
            style: textStyle,
            child: IconTheme(
              data: IconThemeData(color: fg),
              child: content,
            ),
          ),
        );
        if (emphasisToken != null) {
          // The 1px inset highlight along the top edge of emphasis buttons.
          surface = Stack(
            children: [
              surface,
              Positioned(
                left: radius / 2,
                right: radius / 2,
                top: 0,
                height: 1,
                child: ColoredBox(color: KumoColorUtils.mix(emphasisToken, const Color(0xFFFFFFFF), 0.3)),
              ),
            ],
          );
        }
        // Kumo's `opacity-50`, eased so enabling a button reads as a change.
        return AnimatedOpacity(
          opacity: _disabled ? 0.5 : 1,
          duration: KumoMotion.duration(context, KumoDurations.fast),
          curve: KumoCurves.standard,
          child: surface,
        );
      },
    );

    Widget result = pressable;
    if (title != null) result = KumoTooltip(content: title!, child: result);
    if (block) result = SizedBox(width: double.infinity, child: result);
    return result;
  }
}

/// Kumo's `RefreshButton`: a square refresh button whose arrows turn while
/// [loading], and only then.
class KumoRefreshButton extends StatelessWidget {
  const KumoRefreshButton({
    super.key,
    required this.onPress,
    this.loading = false,
    this.size = KumoButtonSize.base,
    this.variant = KumoButtonVariant.secondary,
    this.semanticLabel,
  });

  final VoidCallback? onPress;
  final bool loading;
  final KumoButtonSize size;
  final KumoButtonVariant variant;

  /// Defaults to [KumoStrings.refresh].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconSize = switch (size) {
      KumoButtonSize.xs => 12.0,
      KumoButtonSize.sm => 16.0,
      KumoButtonSize.base => 18.0,
      KumoButtonSize.lg => 20.0,
    };
    return KumoButton(
      shape: KumoButtonShape.square,
      size: size,
      variant: variant,
      semanticLabel: semanticLabel ?? context.kumoStrings.refresh,
      onPress: loading ? null : onPress,
      disabled: false,
      iconWidget: _Spinning(
        spinning: loading,
        child: KumoIcon(KumoIcons.arrowsClockwise, size: iconSize),
      ),
    );
  }
}

class _Spinning extends StatefulWidget {
  const _Spinning({required this.spinning, required this.child});

  final bool spinning;
  final Widget child;

  @override
  State<_Spinning> createState() => _SpinningState();
}

class _SpinningState extends State<_Spinning> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Spinning oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spinning != widget.spinning) _sync();
  }

  void _sync() {
    // Spins only while loading and never under reduced motion; stopping
    // finishes the current turn so the arrows come to rest upright.
    if (widget.spinning && !KumoMotion.reduceMotion(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else if (_c.isAnimating) {
      _c.forward().whenComplete(() {
        if (mounted) _c.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (KumoMotion.reduceMotion(context)) return widget.child;
    return RotationTransition(turns: _c, child: widget.child);
  }
}
