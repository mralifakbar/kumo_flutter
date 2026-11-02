import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../feedback/kumo_loader.dart';
import '../icons/kumo_icon.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_pressable.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../utils/kumo_color_utils.dart';
import 'kumo_control_parts.dart';

class _ButtonGroupScope extends InheritedWidget {
  const _ButtonGroupScope({
    required this.index,
    required this.count,
    required this.size,
    required this.variant,
    required super.child,
  });

  final int index;
  final int count;
  final KumoButtonSize size;
  final KumoButtonVariant variant;

  @override
  bool updateShouldNotify(_ButtonGroupScope old) =>
      old.index != index || old.count != count || old.size != size || old.variant != variant;
}

/// Kumo's `ButtonGroup`: a few tightly coupled buttons joined into one
/// control, most often a split button (an action next to a menu trigger
/// for related actions).
///
/// ```dart
/// KumoButtonGroup(
///   semanticLabel: 'Deploy',
///   variant: KumoButtonVariant.primary,
///   children: [
///     KumoButtonGroupButton(label: 'Deploy', onPress: deploy),
///     KumoButtonGroupButton(
///       icon: KumoIcons.caretDown,
///       semanticLabel: 'More deploy options',
///       onPress: openDeployMenu,
///     ),
///   ],
/// )
/// ```
///
/// The buttons share one ring and one seam between neighbors. Only the
/// outer corners are rounded, with the size's radius; inner corners are
/// square. Per-button shadows are dropped so the group reads as one flat
/// control. A [KumoButtonGroupButton] can be wrapped (in a tooltip or a menu
/// trigger) and still find its place in the group.
///
/// For a row of independent buttons, use a toolbar or a plain [Row] instead.
class KumoButtonGroup extends StatelessWidget {
  const KumoButtonGroup({
    super.key,
    required this.children,
    this.size = KumoButtonSize.base,
    this.variant = KumoButtonVariant.secondary,
    this.semanticLabel,
  });

  /// Usually [KumoButtonGroupButton]s, possibly wrapped.
  final List<Widget> children;

  /// Default size of every button. Keep all buttons the same size so the
  /// group stays aligned.
  final KumoButtonSize size;

  /// Default style of every button.
  final KumoButtonVariant variant;

  /// Names the group for screen readers (Kumo pairs `role="group"` with an
  /// `aria-label`).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      // Kumo's group keeps its intrinsic width (`w-max`); when that is wider
      // than a phone screen, it scrolls rather than overflowing. Unclipped,
      // so the outside ring and focus ring stay visible at rest.
      child: OverflowScroll(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++)
              _ButtonGroupScope(index: i, count: children.length, size: size, variant: variant, child: children[i]),
          ],
        ),
      ),
    );
  }
}

/// A button inside a [KumoButtonGroup]. With only an [icon] it is square
/// and needs a [semanticLabel] or [title].
///
/// ```dart
/// KumoButtonGroupButton(label: 'Save', icon: KumoIcons.floppyDisk, onPress: save)
/// ```
class KumoButtonGroupButton extends StatelessWidget {
  const KumoButtonGroupButton({
    super.key,
    this.label,
    this.icon,
    this.endIcon,
    this.onPress,
    this.variant,
    this.size,
    this.disabled = false,
    this.loading = false,
    this.title,
    this.semanticLabel,
    this.focusNode,
  }) : assert(label != null || icon != null, 'Pass a label or an icon'),
       assert(
         label != null || semanticLabel != null || title != null,
         'Icon-only buttons need a semanticLabel or title',
       );

  final String? label;

  /// Leading icon, or the only content of a square button.
  final IconData? icon;

  /// Trailing icon (a caret for menus).
  final IconData? endIcon;

  /// Null renders the button disabled.
  final VoidCallback? onPress;

  /// Overrides the group's variant.
  final KumoButtonVariant? variant;

  /// Overrides the group's size.
  final KumoButtonSize? size;
  final bool disabled;

  /// Shows a spinner in place of the icon and ignores presses.
  final bool loading;

  /// Tooltip text; doubles as the accessible name of icon-only buttons.
  final String? title;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ButtonGroupScope>();
    final kumo = context.kumo;
    final c = kumo.colors;
    final size = this.size ?? scope?.size ?? KumoButtonSize.base;
    final variant = this.variant ?? scope?.variant ?? KumoButtonVariant.secondary;
    final index = scope?.index ?? 0;
    final count = scope?.count ?? 1;
    final first = index == 0;
    final last = index == count - 1;
    final square = label == null;
    final isDisabled = disabled || onPress == null;
    final touchPad = math.max(0.0, (kumo.minTapTarget - size.height) / 2);

    final outer = Radius.circular(size.radius);
    final radius = BorderRadiusDirectional.only(
      topStart: first ? outer : Radius.zero,
      bottomStart: first ? outer : Radius.zero,
      topEnd: last ? outer : Radius.zero,
      bottomEnd: last ? outer : Radius.zero,
    );
    final emphasis = switch (variant) {
      KumoButtonVariant.primary => c.brand,
      KumoButtonVariant.destructive => c.danger,
      _ => null,
    };
    final textColor = switch (variant) {
      KumoButtonVariant.primary || KumoButtonVariant.destructive => const Color(0xFFFFFFFF),
      KumoButtonVariant.secondaryDestructive => c.textDanger,
      _ => c.textDefault,
    };
    final effectiveLabel = semanticLabel ?? title;

    Widget result = KumoPressable(
      onPress: isDisabled ? null : onPress,
      disabled: isDisabled,
      loading: loading,
      focusNode: focusNode,
      semanticLabel: effectiveLabel,
      excludeChildSemantics: square || semanticLabel != null,
      showFocusRing: false,
      // Scaling one segment would open gaps at the seams; the press shows
      // through the hover color instead.
      scaleOnPress: false,
      minTapTargetSize: 0,
      builder: (context, state) {
        final hover = state.active;
        final dir = Directionality.of(context);
        Color? background;
        Gradient? gradient;
        Color? ring;
        var fg = textColor;
        if (emphasis != null) {
          gradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KumoColorUtils.mix(emphasis, const Color(0xFFFFFFFF), hover ? 0.3 : 0.15), emphasis],
          );
          ring = KumoColorUtils.mix(emphasis, const Color(0xFF000000), 0.1);
        } else {
          switch (variant) {
            case KumoButtonVariant.secondary:
              background = hover ? c.tint : c.base;
              ring = c.line;
            case KumoButtonVariant.secondaryDestructive:
              background = c.base;
              ring = hover ? c.danger.withValues(alpha: 0.3) : c.line;
            case KumoButtonVariant.ghost:
              background = hover ? c.tint : null;
            case KumoButtonVariant.outline:
              ring = hover ? c.focus.withValues(alpha: 0.25) : c.line;
              if (hover) fg = c.textStrong;
            default:
              break;
          }
        }

        final textStyle = kumo.typography.body(
          size: size.fontSize == 12 ? KumoTextSize.xs : KumoTextSize.base,
          weight: KumoTypography.medium,
          color: fg,
          height: 1.25,
        );
        final leading = loading
            ? KumoLoader(dimension: size == KumoButtonSize.lg ? 16 : 14, dangerouslySetColor: fg)
            : (icon != null ? KumoIcon(icon!, size: size.iconSize, dangerouslySetColor: fg) : null);
        Widget content;
        if (square) {
          content = Center(child: leading);
        } else {
          final leadingPad = leading != null ? size.iconLeadingPadding : size.paddingX;
          content = Padding(
            padding: EdgeInsetsDirectional.only(start: leadingPad, end: size.paddingX),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: size.gap,
              children: [
                ?leading,
                Flexible(
                  child: Transform.translate(
                    offset: Offset(0, -size.textLift),
                    child: Text(
                      label!,
                      style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
                if (endIcon != null) KumoIcon(endIcon!, size: size.iconSize, dangerouslySetColor: fg),
              ],
            ),
          );
        }

        final resolved = radius.resolve(dir);
        Widget surface = Container(
          height: size.height,
          // On touch a square button widens to the 44px hit area; joined
          // buttons cannot be padded apart the way single buttons are.
          width: square ? math.max(size.height, kumo.minTapTarget) : null,
          decoration: BoxDecoration(
            color: background,
            gradient: gradient,
            borderRadius: resolved,
            border: ring == null || state.focused ? null : KumoRing.border(ring),
          ),
          child: DefaultTextStyle(style: textStyle, child: content),
        );
        if (emphasis != null) {
          surface = Stack(
            children: [
              surface,
              // The 1px inset highlight along the top edge of emphasis buttons.
              PositionedDirectional(
                start: first ? size.radius / 2 : 0,
                end: last ? size.radius / 2 : 0,
                top: 0,
                height: 1,
                child: ColoredBox(color: KumoColorUtils.mix(emphasis, const Color(0xFFFFFFFF), 0.3)),
              ),
            ],
          );
        }
        // Drawn just inside the edge so the next button's seam cannot cover it.
        surface = KumoFocusRing(visible: state.focused, borderRadius: resolved, offset: -2, child: surface);
        if (isDisabled) surface = Opacity(opacity: 0.5, child: surface);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: touchPad),
          child: surface,
        );
      },
    );
    if (title != null) result = KumoTooltip(content: title!, child: result);
    return result;
  }
}
