import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_control_parts.dart';

/// Toggle styles.
enum KumoToggleVariant {
  /// No surface until hovered. Toolbar toggles; in a group, separate
  /// toggles 4px apart.
  ghost,

  /// A control surface with a ring. In a group, the joined segmented bar
  /// of Kumo's segmented radio.
  outline,
}

/// Toggle heights: `sm` 26, `base` 34 (Kumo's segmented `h-8.5`), `lg` 40.
enum KumoToggleSize {
  sm(26, KumoTextSize.xs, KumoSpace.s2, KumoRadius.md, 14),
  base(34, KumoTextSize.sm, KumoSpace.s3, KumoRadius.lg, 16),
  lg(40, KumoTextSize.base, KumoSpace.s4, KumoRadius.lg, 16);

  const KumoToggleSize(this.height, this.textSize, this.paddingX, this.radius, this.iconSize);
  final double height;
  final KumoTextSize textSize;
  final double paddingX;
  final double radius;
  final double iconSize;
}

/// Content of a toggle: icon and label in the toggle's text color.
Widget _toggleContent(
  BuildContext context, {
  required String? label,
  required IconData? icon,
  required KumoToggleSize size,
  required bool on,
  double? covered,
}) {
  final kumo = context.kumo;
  // [covered] blends the color while a sliding segment fill passes over.
  final color = covered != null
      ? Color.lerp(kumo.color(KumoColor.textDefault), kumo.color(KumoColor.textInverse), covered)!
      : kumo.color(on ? KumoColor.textInverse : KumoColor.textDefault);
  final style = kumo.text(size: size.textSize, weight: KumoTypography.medium).copyWith(color: color);
  return Row(
    mainAxisSize: MainAxisSize.min,
    spacing: KumoSpace.s1_5,
    children: [
      if (icon != null) KumoIcon(icon, size: size.iconSize, dangerouslySetColor: color),
      if (label != null) Flexible(child: Text(label, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis)),
    ],
  );
}

/// A standalone toggle surface (ghost or outline).
Widget _toggleSurface(
  BuildContext context, {
  required KumoPressState state,
  required bool on,
  required KumoToggleVariant variant,
  required KumoToggleSize size,
  required Widget content,
  required bool square,
  required bool disabled,
}) {
  final c = context.kumo.colors;
  Color? background;
  Color? ring;
  if (on) {
    background = c.contrast;
    ring = variant == KumoToggleVariant.outline ? c.contrast : null;
  } else if (variant == KumoToggleVariant.outline) {
    background = state.active && !disabled ? c.tint : c.control;
    ring = c.line;
  } else if (state.active && !disabled) {
    background = c.contrast.withValues(alpha: 0.07);
  }
  Widget surface = Container(
    constraints: BoxConstraints(minHeight: size.height, minWidth: size.height),
    padding: square ? null : EdgeInsets.symmetric(horizontal: size.paddingX),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size.radius),
      border: ring == null || state.focused ? null : KumoRing.border(ring),
      boxShadow: variant == KumoToggleVariant.outline && !on ? KumoShadow.xs.boxShadows : null,
    ),
    child: Center(widthFactor: 1, heightFactor: 1, child: content),
  );
  if (disabled) surface = Opacity(opacity: 0.5, child: surface);
  return surface;
}

/// A two-state button that stays pressed: bold text, a filter, a view mode.
/// Not a Kumo component; it follows shadcn's Toggle with Kumo's segmented
/// styling (a pressed toggle fills with `bg-kumo-contrast`).
///
/// ```dart
/// KumoToggle(
///   icon: KumoIcons.funnel,
///   label: 'Errors only',
///   pressed: errorsOnly,
///   onPressedChange: (value) => setState(() => errorsOnly = value),
/// )
/// ```
///
/// Icon-only toggles are square and need a [semanticLabel] or [title].
/// Screen readers hear a toggle button with its on or off state.
class KumoToggle extends StatelessWidget {
  const KumoToggle({
    super.key,
    required this.pressed,
    this.onPressedChange,
    this.label,
    this.icon,
    this.variant = KumoToggleVariant.ghost,
    this.size = KumoToggleSize.base,
    this.disabled = false,
    this.title,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  }) : assert(label != null || icon != null, 'Pass a label or an icon'),
       assert(label != null || semanticLabel != null || title != null, 'Icon-only toggles need a semanticLabel or title');

  final bool pressed;

  /// Called with the next pressed state. Null disables the toggle.
  final ValueChanged<bool>? onPressedChange;
  final String? label;
  final IconData? icon;
  final KumoToggleVariant variant;
  final KumoToggleSize size;
  final bool disabled;

  /// Tooltip text; doubles as the accessible name of icon-only toggles.
  final String? title;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onPressedChange == null;
    final square = label == null;
    Widget result = KumoPressable(
      onPress: isDisabled ? null : () => onPressedChange!(!pressed),
      disabled: isDisabled,
      toggled: pressed,
      semanticLabel: semanticLabel ?? title,
      excludeChildSemantics: square || semanticLabel != null,
      borderRadius: BorderRadius.circular(size.radius),
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, state) => _toggleSurface(
        context,
        state: state,
        on: pressed,
        variant: variant,
        size: size,
        square: square,
        disabled: isDisabled,
        content: _toggleContent(context, label: label, icon: icon, size: size, on: pressed),
      ),
    );
    if (title != null) result = KumoTooltip(content: title!, child: result);
    return result;
  }
}

/// One option of a [KumoToggleGroup].
///
/// ```dart
/// const KumoToggleGroupItem(value: 'list', icon: KumoIcons.rows, semanticLabel: 'List view')
/// ```
@immutable
class KumoToggleGroupItem<T> {
  const KumoToggleGroupItem({
    required this.value,
    this.label,
    this.icon,
    this.disabled = false,
    this.title,
    this.semanticLabel,
  }) : assert(label != null || icon != null, 'Pass a label or an icon');

  final T value;
  final String? label;
  final IconData? icon;
  final bool disabled;

  /// Tooltip text; doubles as the accessible name of icon-only items.
  final String? title;
  final String? semanticLabel;
}

/// A row of [KumoToggle]s that act together: one at a time (a view mode) or
/// any number (formatting, filters). Not a Kumo component; it follows
/// shadcn's ToggleGroup, drawn as Kumo's segmented bar by default.
///
/// ```dart
/// KumoToggleGroup<String>(
///   semanticLabel: 'Log level',
///   value: level,
///   onValueChange: (next) => setState(() => level = next),
///   items: const [
///     KumoToggleGroupItem(value: 'info', label: 'Info'),
///     KumoToggleGroupItem(value: 'warn', label: 'Warn'),
///     KumoToggleGroupItem(value: 'error', label: 'Error'),
///   ],
/// )
/// ```
///
/// Keyboard: Tab reaches the group once; arrow keys move focus between items
/// (wrapping, mirrored in RTL), Home and End jump to the ends, and Space or
/// Enter toggles the focused item. For a required single choice, prefer
/// [KumoToggleGroup] with `allowDeselect: false`, or a segmented radio group
/// inside a form.
class KumoToggleGroup<T> extends StatefulWidget {
  /// One item pressed at a time. Pressing the pressed item clears the value
  /// unless [allowDeselect] is false.
  const KumoToggleGroup({
    super.key,
    required this.items,
    required this.value,
    this.onValueChange,
    this.allowDeselect = true,
    this.variant = KumoToggleVariant.outline,
    this.size = KumoToggleSize.base,
    this.disabled = false,
    this.semanticLabel,
  })  : multiple = false,
        values = const [],
        onValuesChange = null;

  /// Any number of items pressed.
  ///
  /// ```dart
  /// KumoToggleGroup<String>.multiple(
  ///   semanticLabel: 'HTTP methods',
  ///   values: methods,
  ///   onValuesChange: (next) => setState(() => methods = next),
  ///   items: const [
  ///     KumoToggleGroupItem(value: 'GET', label: 'GET'),
  ///     KumoToggleGroupItem(value: 'POST', label: 'POST'),
  ///   ],
  /// )
  /// ```
  const KumoToggleGroup.multiple({
    super.key,
    required this.items,
    required this.values,
    this.onValuesChange,
    this.variant = KumoToggleVariant.outline,
    this.size = KumoToggleSize.base,
    this.disabled = false,
    this.semanticLabel,
  })  : multiple = true,
        value = null,
        onValueChange = null,
        allowDeselect = true;

  final List<KumoToggleGroupItem<T>> items;

  /// Single mode: the pressed value, or null for none.
  final T? value;

  /// Single mode: called with the next value (null when cleared).
  final ValueChanged<T?>? onValueChange;

  /// Single mode: pressing the pressed item clears the value.
  final bool allowDeselect;

  /// Multiple mode: the pressed values.
  final List<T> values;

  /// Multiple mode: called with the next list; a newly pressed value is
  /// appended.
  final ValueChanged<List<T>>? onValuesChange;
  final bool multiple;
  final KumoToggleVariant variant;
  final KumoToggleSize size;
  final bool disabled;

  /// Names the group for screen readers.
  final String? semanticLabel;

  @override
  State<KumoToggleGroup<T>> createState() => _KumoToggleGroupState<T>();
}

class _KumoToggleGroupState<T> extends State<KumoToggleGroup<T>> with TickerProviderStateMixin {
  final RovingFocus _focus = RovingFocus();
  late final SegmentSelection _selection;
  int? _tabStop;

  int? get _selectedIndex {
    if (widget.multiple) return null;
    final i = widget.items.indexWhere((item) => item.value == widget.value);
    return i < 0 || widget.value == null ? null : i;
  }

  /// Single-choice segmented groups slide one fill between items.
  bool get _slides => !widget.multiple && widget.variant == KumoToggleVariant.outline;

  @override
  void initState() {
    super.initState();
    _selection = SegmentSelection(vsync: this, selected: _selectedIndex);
  }

  @override
  void didUpdateWidget(KumoToggleGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selection.select(context, _selectedIndex);
  }

  bool get _interactive =>
      !widget.disabled && (widget.multiple ? widget.onValuesChange != null : widget.onValueChange != null);

  bool _enabled(int i) => _interactive && !widget.items[i].disabled;

  bool _isOn(int i) {
    final v = widget.items[i].value;
    return widget.multiple ? widget.values.contains(v) : widget.value == v;
  }

  @override
  void dispose() {
    _selection.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _press(int i) {
    _tabStop = i;
    final v = widget.items[i].value;
    if (widget.multiple) {
      final on = widget.values.contains(v);
      widget.onValuesChange!(on ? [for (final x in widget.values) if (x != v) x] : [...widget.values, v]);
    } else if (widget.value == v) {
      if (widget.allowDeselect) widget.onValueChange!(null);
    } else {
      widget.onValueChange!(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final kumo = context.kumo;
    _focus.sync(items.length, 'KumoToggleGroup');
    var tabStop = _tabStop;
    if (tabStop == null || tabStop >= items.length || !_enabled(tabStop)) {
      final pressed = [for (var i = 0; i < items.length; i++) if (_isOn(i) && _enabled(i)) i];
      tabStop = pressed.isNotEmpty ? pressed.first : (RovingFocus.first(items.length, _enabled) ?? 0);
    }
    _focus.setTabStop(tabStop);
    final size = widget.size;
    final segmented = widget.variant == KumoToggleVariant.outline;
    final touchPad = segmented ? math.max(0.0, (kumo.minTapTarget - size.height) / 2) : 0.0;

    Widget item(int i) {
      final it = items[i];
      final on = _isOn(i);
      final enabled = _enabled(i);
      final square = it.label == null;
      final name = it.semanticLabel ?? it.title;
      Widget result = KumoPressable(
        onPress: enabled ? () => _press(i) : null,
        disabled: !enabled,
        focusNode: _focus.nodes[i],
        isButton: widget.multiple,
        toggled: widget.multiple ? on : null,
        checked: widget.multiple ? null : on,
        inMutuallyExclusiveGroup: widget.multiple ? null : true,
        semanticLabel: name,
        excludeChildSemantics: square || it.semanticLabel != null,
        showFocusRing: !segmented,
        borderRadius: BorderRadius.circular(size.radius),
        scaleOnPress: !segmented,
        minTapTargetSize: segmented ? 0 : null,
        haptic: KumoHaptic.selection,
        builder: (context, state) {
          final content = _toggleContent(context, label: it.label, icon: it.icon, size: size, on: on);
          if (!segmented) {
            return _toggleSurface(
              context,
              state: state,
              on: on,
              variant: KumoToggleVariant.ghost,
              size: size,
              content: content,
              square: square,
              disabled: !enabled,
            );
          }
          final slides = _slides;
          Widget surface = SegmentSurface(
            position: SegmentPosition(
              index: i,
              count: items.length,
              previousSelected: i > 0 && _isOn(i - 1),
              nextSelected: i < items.length - 1 && _isOn(i + 1),
            ),
            state: state,
            selected: on,
            selection: slides ? _selection : null,
            builder: slides
                ? (context, covered) =>
                      _toggleContent(context, label: it.label, icon: it.icon, size: size, on: on, covered: covered)
                : null,
            height: size.height,
            radius: size.radius,
            touchPad: touchPad,
            minWidth: square ? math.max(size.height, kumo.minTapTarget) : 0,
            padding: square
                ? EdgeInsetsDirectional.zero
                : EdgeInsetsDirectional.symmetric(horizontal: size.paddingX),
            child: slides ? null : content,
          );
          if (!enabled) surface = Opacity(opacity: 0.5, child: surface);
          return surface;
        },
      );
      if (it.title != null) result = KumoTooltip(content: it.title!, child: result);
      return result;
    }

    Widget body;
    if (segmented) {
      body = SegmentedBar(
        radius: size.radius,
        touchPad: touchPad,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              SegmentDivider(
                beforeSelected: _isOn(i - 1),
                afterSelected: _isOn(i),
                touchPad: touchPad,
                selection: _slides ? _selection : null,
                index: i,
              ),
            item(i),
          ],
        ],
      );
    } else {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: KumoSpace.s1,
        children: [for (var i = 0; i < items.length; i++) item(i)],
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: widget.multiple ? null : SemanticsRole.radioGroup,
      label: widget.semanticLabel,
      child: RovingFocusKeys(
        focus: _focus,
        count: items.length,
        enabled: _enabled,
        onMove: (i) {
          setState(() => _tabStop = i);
          _focus.nodes[i].requestFocus();
        },
        child: OverflowScroll(padding: EdgeInsets.all(segmented ? 1 : 2), child: body),
      ),
    );
  }
}
