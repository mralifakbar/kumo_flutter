import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_control_parts.dart';

/// Radio styles. [base] is Kumo's `"default"`.
enum KumoRadioVariant {
  base,

  /// Red ring for a failed validation. Pair it with the group's error.
  error,
}

/// Radio group presentations.
enum KumoRadioAppearance {
  /// A 16px circle next to each label.
  base,

  /// Choice cards joined into one bordered surface, with a medium label and
  /// an optional description per item.
  card,

  /// A compact bar of joined buttons for a few short options (`1h`, `12h`,
  /// `24h`). Group-only; items keep their intrinsic width and never wrap.
  segmented,
}

/// Where the circle sits relative to its label.
enum KumoRadioControlPosition { start, end }

/// One option of a [KumoRadioGroup] (Kumo's `Radio.Item`). Only valid as an
/// item of a group, which supplies its selection and focus.
///
/// ```dart
/// const KumoRadio(value: 'standard', label: 'Standard', description: 'Cached at every data center.')
/// ```
class KumoRadio<T> extends StatelessWidget {
  const KumoRadio({
    super.key,
    required this.value,
    required this.label,
    this.labelWidget,
    this.description,
    this.disabled = false,
    this.variant,
    this.appearance,
  }) : assert(appearance != KumoRadioAppearance.segmented, 'Segmented is a group-only appearance');

  final T value;

  /// Label text. Also the accessible name.
  final String label;

  /// Custom label in place of [label]; [label] stays the accessible name.
  final Widget? labelWidget;

  /// Helper text under the label.
  final String? description;
  final bool disabled;

  /// Overrides the group's error state for this item.
  final KumoRadioVariant? variant;

  /// Overrides a base or card group appearance for this item.
  final KumoRadioAppearance? appearance;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioItemScope>();
    assert(scope != null, 'KumoRadio must be an item of a KumoRadioGroup');
    final s = scope!;
    final appearance = s.groupAppearance == KumoRadioAppearance.segmented
        ? KumoRadioAppearance.segmented
        : (this.appearance ?? s.groupAppearance);
    final isError =
        (variant ?? (s.groupError ? KumoRadioVariant.error : KumoRadioVariant.base)) == KumoRadioVariant.error;
    final itemDisabled = s.disabled || disabled;
    final onPress = itemDisabled ? null : s.onSelect;

    if (appearance == KumoRadioAppearance.segmented) {
      return KumoPressable(
        onPress: onPress,
        disabled: itemDisabled,
        focusNode: s.focusNode,
        isButton: false,
        checked: s.selected,
        inMutuallyExclusiveGroup: true,
        semanticLabel: labelWidget != null ? label : null,
        excludeChildSemantics: labelWidget != null,
        showFocusRing: false,
        scaleOnPress: false,
        minTapTargetSize: 0,
        haptic: KumoHaptic.selection,
        builder: (context, state) {
          final kumo = context.kumo;
          final off = kumo.color(KumoColor.textDefault);
          final on = kumo.color(KumoColor.textInverse);
          final p = s.segment!;
          Widget surface = SegmentSurface(
            position: p,
            state: state,
            selected: s.selected,
            selection: s.selection,
            height: 34,
            touchPad: s.touchPad,
            padding: EdgeInsetsDirectional.only(start: p.first ? 11 : KumoSpace.s3, end: p.last ? 11 : KumoSpace.s3),
            // The label turns inverse as the sliding fill covers it.
            builder: (context, covered) => DefaultTextStyle(
              style: kumo
                  .text(size: KumoTextSize.sm, weight: KumoTypography.medium)
                  .copyWith(color: Color.lerp(off, on, covered)),
              maxLines: 1,
              softWrap: false,
              child: labelWidget ?? Text(label),
            ),
          );
          if (itemDisabled) surface = Opacity(opacity: 0.5, child: surface);
          return surface;
        },
      );
    }

    final card = appearance == KumoRadioAppearance.card;
    final controlAtStart =
        (s.controlPosition ?? (card ? KumoRadioControlPosition.end : KumoRadioControlPosition.start)) ==
        KumoRadioControlPosition.start;
    final joined = card && s.groupAppearance == KumoRadioAppearance.card;

    return KumoPressable(
      onPress: onPress,
      disabled: itemDisabled,
      focusNode: s.focusNode,
      isButton: false,
      checked: s.selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: labelWidget != null ? label : null,
      showFocusRing: false,
      scaleOnPress: false,
      builder: (context, state) {
        final kumo = context.kumo;
        final c = kumo.colors;
        // The row is the hit area; the circle answers the press.
        final dot = PressScale(
          pressed: state.pressed && !itemDisabled,
          child: _RadioDot(
            selected: s.selected,
            error: isError,
            focused: state.focused,
            hovered: state.active && !itemDisabled,
          ),
        );
        final labelText =
            labelWidget ?? Text(label, style: kumo.text(weight: card ? KumoTypography.medium : KumoTypography.normal));
        final text = ControlLabelStack(label: labelText, description: description);
        Widget result;
        if (card) {
          final aligned = Padding(
            padding: const EdgeInsets.only(top: KumoSpace.s0_5),
            child: dot,
          );
          final background = s.selected && !isError
              ? c.tint
              : (state.active && !s.selected && !itemDisabled && !isError ? c.elevated : c.base);
          result = Container(
            padding: const EdgeInsets.all(KumoSpace.s3),
            decoration: BoxDecoration(
              color: background,
              border: joined ? null : Border.all(color: isError ? c.danger : (s.selected ? c.interact : c.hairline)),
              borderRadius: joined ? null : BorderRadius.circular(KumoRadius.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s3,
              children: [
                if (controlAtStart) aligned,
                Expanded(child: text),
                if (!controlAtStart) aligned,
              ],
            ),
          );
        } else {
          result = ControlRow(control: dot, label: text, controlFirst: controlAtStart);
        }
        if (itemDisabled) result = Opacity(opacity: 0.5, child: result);
        return result;
      },
    );
  }
}

class _RadioItemScope extends InheritedWidget {
  const _RadioItemScope({
    required this.selected,
    required this.onSelect,
    required this.focusNode,
    required this.groupAppearance,
    required this.controlPosition,
    required this.groupError,
    required this.disabled,
    required this.segment,
    required this.touchPad,
    required this.selection,
    required super.child,
  });

  final bool selected;
  final VoidCallback? onSelect;
  final FocusNode focusNode;
  final KumoRadioAppearance groupAppearance;
  final KumoRadioControlPosition? controlPosition;
  final bool groupError;
  final bool disabled;
  final SegmentPosition? segment;
  final double touchPad;
  final SegmentSelection? selection;

  @override
  bool updateShouldNotify(_RadioItemScope old) =>
      old.selected != selected ||
      old.onSelect != onSelect ||
      old.focusNode != focusNode ||
      old.groupAppearance != groupAppearance ||
      old.controlPosition != controlPosition ||
      old.groupError != groupError ||
      old.disabled != disabled ||
      old.segment != segment ||
      old.touchPad != touchPad ||
      old.selection != selection;
}

/// Kumo's `Radio.Group`: a legend over mutually exclusive [KumoRadio] items,
/// with an error and a description below.
///
/// ```dart
/// KumoRadioGroup<String>(
///   legend: 'Cache level',
///   value: level,
///   onValueChange: (next) => setState(() => level = next),
///   items: const [
///     KumoRadio(value: 'basic', label: 'No query string'),
///     KumoRadio(value: 'simplified', label: 'Ignore query string'),
///     KumoRadio(value: 'aggressive', label: 'Standard'),
///   ],
/// )
/// ```
///
/// Keyboard: Tab reaches the group once, at the selected item (or the first
/// enabled one). Arrow keys move the selection to the previous or next
/// enabled item and wrap around; Home and End jump to the ends.
class KumoRadioGroup<T> extends StatefulWidget {
  const KumoRadioGroup({
    super.key,
    required this.items,
    required this.value,
    this.onValueChange,
    this.legend,
    this.hideLegend = false,
    this.description,
    this.error,
    this.orientation = Axis.vertical,
    this.appearance = KumoRadioAppearance.base,
    this.controlPosition,
    this.disabled = false,
  });

  final List<KumoRadio<T>> items;

  /// The selected value, or null for none.
  final T? value;

  /// Called with the newly selected value. Null disables the group.
  final ValueChanged<T>? onValueChange;

  /// Group title, medium weight above the items. Also the group's accessible
  /// name.
  final String? legend;

  /// Keep the legend for screen readers only (Kumo's `sr-only` legend).
  final bool hideLegend;
  final String? description;

  /// Error for the whole group. Items switch to the error ring.
  final String? error;

  /// Vertical stacks the items; horizontal wraps them in rows (a two-column
  /// grid for cards). Segmented groups are always one row.
  final Axis orientation;
  final KumoRadioAppearance appearance;

  /// Defaults to [KumoRadioControlPosition.start], and to
  /// [KumoRadioControlPosition.end] for cards.
  final KumoRadioControlPosition? controlPosition;
  final bool disabled;

  @override
  State<KumoRadioGroup<T>> createState() => _KumoRadioGroupState<T>();
}

class _KumoRadioGroupState<T> extends State<KumoRadioGroup<T>> with TickerProviderStateMixin {
  final RovingFocus _focus = RovingFocus();
  late final SegmentSelection _selection;

  bool _enabled(int i) => !widget.disabled && widget.onValueChange != null && !widget.items[i].disabled;

  int? get _selectedIndex {
    final i = widget.items.indexWhere((item) => item.value == widget.value);
    return i < 0 ? null : i;
  }

  @override
  void initState() {
    super.initState();
    _selection = SegmentSelection(vsync: this, selected: _selectedIndex);
  }

  @override
  void didUpdateWidget(KumoRadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selection.select(context, _selectedIndex);
  }

  @override
  void dispose() {
    _selection.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _select(int i) {
    final next = widget.items[i].value;
    if (next != widget.value) widget.onValueChange?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    _focus.sync(items.length, 'KumoRadio');
    final selectedIndex = items.indexWhere((item) => item.value == widget.value);
    final tabStop = selectedIndex >= 0 && _enabled(selectedIndex)
        ? selectedIndex
        : (RovingFocus.first(items.length, _enabled) ?? 0);
    _focus.setTabStop(tabStop);

    final segmented = widget.appearance == KumoRadioAppearance.segmented;
    final touchPad = segmented ? ((context.kumo.minTapTarget - 34) / 2).clamp(0.0, 22.0) : 0.0;
    final groupError = widget.error != null;

    Widget scoped(int i) {
      final selected = i == selectedIndex;
      return _RadioItemScope(
        selected: selected,
        onSelect: widget.onValueChange == null ? null : () => _select(i),
        focusNode: _focus.nodes[i],
        groupAppearance: widget.appearance,
        controlPosition: widget.controlPosition,
        groupError: groupError,
        disabled: widget.disabled || widget.onValueChange == null,
        segment: segmented
            ? SegmentPosition(
                index: i,
                count: items.length,
                previousSelected: i - 1 == selectedIndex,
                nextSelected: i + 1 == selectedIndex,
              )
            : null,
        touchPad: touchPad,
        selection: segmented ? _selection : null,
        child: items[i],
      );
    }

    Widget body;
    switch (widget.appearance) {
      case KumoRadioAppearance.segmented:
        body = OverflowScroll(
          child: SegmentedBar(
            error: groupError,
            touchPad: touchPad,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  SegmentDivider(
                    beforeSelected: i - 1 == selectedIndex,
                    afterSelected: i == selectedIndex,
                    touchPad: touchPad,
                    selection: _selection,
                    index: i,
                  ),
                scoped(i),
              ],
            ],
          ),
        );
      case KumoRadioAppearance.card:
        body = JoinedCards(
          horizontal: widget.orientation == Axis.horizontal,
          children: [for (var i = 0; i < items.length; i++) scoped(i)],
        );
      case KumoRadioAppearance.base:
        final children = [for (var i = 0; i < items.length; i++) scoped(i)];
        final gap = controlRowGap(context, multiline: items.any((item) => item.description != null));
        body = widget.orientation == Axis.horizontal
            ? Wrap(spacing: KumoSpace.s2, runSpacing: gap, children: children)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: gap,
                children: children,
              );
    }

    body = RovingFocusKeys(
      focus: _focus,
      count: items.length,
      enabled: _enabled,
      onMove: (i) {
        _select(i);
        _focus.nodes[i].requestFocus();
      },
      child: Semantics(role: SemanticsRole.radioGroup, container: true, explicitChildNodes: true, child: body),
    );

    return ControlFieldset(
      legend: widget.legend,
      hideLegend: widget.hideLegend,
      description: widget.description,
      error: widget.error,
      gap: widget.appearance == KumoRadioAppearance.base ? KumoSpace.s4 : KumoSpace.s2,
      child: body,
    );
  }
}

/// The 16px circle (`rounded-full ring`) with its 8px inner dot. The dot
/// lands with [KumoCurves.bounce] when the item becomes selected.
class _RadioDot extends StatefulWidget {
  const _RadioDot({required this.selected, required this.error, required this.focused, required this.hovered});

  final bool selected;
  final bool error;
  final bool focused;
  final bool hovered;

  @override
  State<_RadioDot> createState() => _RadioDotState();
}

class _RadioDotState extends State<_RadioDot> with SingleTickerProviderStateMixin {
  late final AnimationController _dot;

  @override
  void initState() {
    super.initState();
    _dot = AnimationController(vsync: this, duration: KumoDurations.quick, value: widget.selected ? 1 : 0);
  }

  @override
  void didUpdateWidget(_RadioDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      if (KumoMotion.reduceMotion(context)) {
        _dot.value = 1;
      } else {
        _dot.forward(from: 0);
      }
    } else if (!widget.selected) {
      _dot.value = 0;
    }
  }

  @override
  void dispose() {
    _dot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final ring = widget.focused
        ? c.brand
        : widget.error
        ? c.danger
        : widget.hovered
        ? c.hairline
        : c.line;
    return SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.selected ? c.contrast : c.base,
          shape: BoxShape.circle,
          border: KumoRing.border(ring, width: widget.focused ? 2 : 1),
        ),
        child: AnimatedBuilder(
          animation: _dot,
          builder: (context, _) {
            final t = _dot.value;
            if (t == 0) return const SizedBox.shrink();
            final size = 8 * (0.4 + 0.6 * KumoCurves.bounce.transform(t));
            return Center(
              child: SizedBox(
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.base, shape: BoxShape.circle),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
