import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../forms/src/forms_internal.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_dates_internal.dart';
import 'kumo_time_input.dart';

/// A time field that opens a picker, shadcn style.
///
/// On wide screens the panel is a popover with one scrolling column per
/// part (hours, minutes, optional seconds, AM/PM). Below 768px it is a
/// bottom sheet with wheels that follow the finger and snap to the nearest
/// value by release velocity, with a selection tick on each value
/// ([presentation]).
///
/// ```dart
/// KumoTimePicker(
///   label: 'Cron trigger time',
///   value: runAt,
///   minuteStep: 15,
///   onValueChange: (t) => setState(() => runAt = t),
/// )
/// ```
///
/// Keyboard: each popover column is one Tab stop; Arrow Up and Down change
/// its value, Home and End jump to the first and last, Enter closes.
/// Screen readers hear each column as an adjustable value.
///
/// Controlled: the field shows [value]. Picking a part while the value is
/// empty starts from the current time (`clock.now()`); the sheet's Done
/// button commits the time the wheels show.
class KumoTimePicker extends StatefulWidget {
  const KumoTimePicker({
    super.key,
    this.value,
    this.onValueChange,
    this.use24Hour = false,
    this.showSeconds = false,
    this.minuteStep = 1,
    this.label,
    this.description,
    this.error,
    this.placeholder,
    this.size = KumoFieldSize.base,
    this.disabled = false,
    this.clearable = true,
    this.presentation = KumoPresentation.auto,
    this.open,
    this.onOpenChange,
    this.labels = const KumoTimeLabels(),
    this.showOptional = false,
    this.required = false,
    this.semanticLabel,
  }) : assert(minuteStep > 0 && minuteStep <= 30);

  final KumoTimeValue? value;
  final ValueChanged<KumoTimeValue?>? onValueChange;
  final bool use24Hour;
  final bool showSeconds;

  /// Minutes listed: 15 lists 00, 15, 30 and 45.
  final int minuteStep;
  final String? label;
  final String? description;
  final String? error;

  /// Shown while no time is picked. Default [KumoStrings.pickTime].
  final String? placeholder;
  final KumoFieldSize size;
  final bool disabled;
  final bool clearable;
  final KumoPresentation presentation;
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final KumoTimeLabels labels;
  final bool showOptional;
  final bool required;
  final String? semanticLabel;

  @override
  State<KumoTimePicker> createState() => _KumoTimePickerState();
}

/// One column of the picker: its options and how a choice changes a time.
class _Column {
  const _Column({required this.label, required this.options, required this.indexOf, required this.apply});

  final String label;
  final List<String> options;
  final int? Function(KumoTimeValue value) indexOf;
  final KumoTimeValue Function(KumoTimeValue base, int index) apply;
}

class _KumoTimePickerState extends State<KumoTimePicker> {
  bool _ownOpen = false;

  bool get _open => widget.open ?? _ownOpen;

  void _setOpen(bool value) {
    if (value == _open) return;
    if (widget.open == null) setState(() => _ownOpen = value);
    widget.onOpenChange?.call(value);
  }

  /// Where a choice starts when nothing is picked yet: now, on the grid.
  KumoTimeValue get _base {
    final v = widget.value;
    if (v != null) return v;
    final now = KumoTimeValue.now();
    return KumoTimeValue(hour: now.hour, minute: now.minute - now.minute % widget.minuteStep);
  }

  List<_Column> _columns() {
    final labels = widget.labels.resolve(context.kumoStrings);
    final step = widget.minuteStep;
    return [
      if (widget.use24Hour)
        _Column(
          label: labels.hour,
          options: [for (var h = 0; h < 24; h++) kumoTwoDigits(h)],
          indexOf: (v) => v.hour,
          apply: (b, i) => b.copyWith(hour: i),
        )
      else
        _Column(
          label: labels.hour,
          options: [for (var i = 0; i < 12; i++) kumoTwoDigits(i == 0 ? 12 : i)],
          indexOf: (v) => v.hour % 12,
          apply: (b, i) => b.copyWith(hour: i + (b.isPm ? 12 : 0)),
        ),
      _Column(
        label: labels.minute,
        options: [for (var m = 0; m < 60; m += step) kumoTwoDigits(m)],
        indexOf: (v) => v.minute % step == 0 ? v.minute ~/ step : null,
        apply: (b, i) => b.copyWith(minute: i * step),
      ),
      if (widget.showSeconds)
        _Column(
          label: labels.second,
          options: [for (var s = 0; s < 60; s++) kumoTwoDigits(s)],
          indexOf: (v) => v.second,
          apply: (b, i) => b.copyWith(second: i),
        ),
      if (!widget.use24Hour)
        _Column(
          label: labels.period,
          options: [labels.am, labels.pm],
          indexOf: (v) => v.isPm ? 1 : 0,
          apply: (b, i) => b.copyWith(hour: b.hour % 12 + (i == 1 ? 12 : 0)),
        ),
    ];
  }

  void _pick(_Column column, int index) {
    final next = column.apply(_base, index);
    if (next != widget.value) widget.onValueChange?.call(next);
  }

  Widget _panel(BuildContext context, bool inSheet) {
    final columns = _columns();
    if (!inSheet) {
      return Padding(
        padding: const EdgeInsets.all(KumoSpace.s1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s1,
          children: [
            for (var i = 0; i < columns.length; i++)
              _ListColumn(
                column: columns[i],
                selected: widget.value == null ? null : columns[i].indexOf(widget.value!),
                autofocus: i == 0,
                onPick: (index) => _pick(columns[i], index),
                onDone: () => _setOpen(false),
              ),
          ],
        ),
      );
    }
    final strings = context.kumoStrings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KumoSpace.s4, KumoSpace.s2, KumoSpace.s4, KumoSpace.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s4,
        children: [
          if (widget.label != null) Text(widget.label!, style: context.kumo.heading()),
          _Wheels(columns: columns, value: _base, onPick: _pick),
          Row(
            spacing: KumoSpace.s2,
            children: [
              if (widget.clearable)
                Expanded(
                  child: KumoButton(
                    label: strings.clear,
                    block: true,
                    onPress: widget.value == null
                        ? null
                        : () {
                            widget.onValueChange?.call(null);
                            KumoSheetScope.closeFrom(context);
                          },
                  ),
                ),
              Expanded(
                child: KumoButton(
                  label: widget.labels.done ?? context.kumoStrings.done,
                  variant: KumoButtonVariant.primary,
                  block: true,
                  onPress: () {
                    // The wheels always show a time; Done keeps it.
                    if (widget.value == null) widget.onValueChange?.call(_base);
                    KumoSheetScope.closeFrom(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels.resolve(context.kumoStrings);
    final display = widget.value?.format(
      use24Hour: widget.use24Hour,
      showSeconds: widget.showSeconds,
      am: labels.am,
      pm: labels.pm,
    );
    final placeholder = widget.placeholder ?? context.kumoStrings.pickTime;
    final name = widget.label ?? widget.semanticLabel ?? placeholder;
    final trigger = KumoDatesPanelHost(
      open: _open && !widget.disabled,
      onOpenChange: _setOpen,
      presentation: widget.presentation,
      sheetLabel: name,
      popoverPadding: EdgeInsets.zero,
      panelBuilder: _panel,
      child: KumoDatesTrigger(
        size: widget.size,
        icon: KumoIcons.clock,
        text: display,
        placeholder: placeholder,
        open: _open,
        error: widget.error != null,
        disabled: widget.disabled,
        semanticLabel: name,
        onPress: () => _setOpen(!_open),
        onClear: widget.clearable && widget.value != null && !widget.disabled
            ? () => widget.onValueChange?.call(null)
            : null,
      ),
    );
    return FormsFieldFrame(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      showOptional: widget.showOptional,
      required: widget.required,
      controlLabeled: false,
      controlDescribed: false,
      child: trigger,
    );
  }
}

const double _rowHeight = 32;
const int _visibleRows = 7;

/// A popover column: a short scrolling list, one Tab stop, adjusted with
/// the arrow keys and announced as an adjustable value.
class _ListColumn extends StatefulWidget {
  const _ListColumn({
    required this.column,
    required this.selected,
    required this.autofocus,
    required this.onPick,
    required this.onDone,
  });

  final _Column column;
  final int? selected;
  final bool autofocus;
  final ValueChanged<int> onPick;
  final VoidCallback onDone;

  @override
  State<_ListColumn> createState() => _ListColumnState();
}

class _ListColumnState extends State<_ListColumn> {
  late final ScrollController _scroll;
  final FocusNode _node = FocusNode(debugLabel: 'KumoTimePicker column');

  int get _count => widget.column.options.length;

  double _offsetFor(int index) => (index * _rowHeight - (_visibleRows - 1) / 2 * _rowHeight)
      .clamp(0, (_count - _visibleRows).clamp(0, _count) * _rowHeight)
      .toDouble();

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(initialScrollOffset: widget.selected == null ? 0 : _offsetFor(widget.selected!));
    if (widget.autofocus) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _node.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(_ListColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = widget.selected;
    if (selected != null && selected != oldWidget.selected && _scroll.hasClients) {
      final target = _offsetFor(selected);
      final first = _scroll.offset / _rowHeight;
      // Only scroll when the choice is out of view, so a click never moves
      // the row under the pointer.
      if (selected < first || selected > first + _visibleRows - 1) {
        final duration = KumoMotion.duration(context, KumoDurations.moderate);
        if (duration == Duration.zero) {
          _scroll.jumpTo(target);
        } else {
          _scroll.animateTo(target, duration: duration, curve: KumoCurves.standard);
        }
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _node.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final current = widget.selected;
    final next = current == null ? (delta > 0 ? 0 : _count - 1) : (current + delta) % _count;
    widget.onPick(next < 0 ? next + _count : next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.home) {
      widget.onPick(0);
    } else if (key == LogicalKeyboardKey.end) {
      widget.onPick(_count - 1);
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      widget.onDone();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final options = widget.column.options;
    final selected = widget.selected;
    final scale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6);
    final list = ListView.builder(
      controller: _scroll,
      itemExtent: _rowHeight,
      itemCount: options.length,
      itemBuilder: (context, i) {
        final active = i == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: KumoPressable(
            onPress: () => widget.onPick(i),
            canRequestFocus: false,
            minTapTargetSize: 0,
            scaleOnPress: false,
            excludeChildSemantics: true,
            builder: (context, state) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? c.contrast : (state.active ? c.tint : null),
                borderRadius: BorderRadius.circular(KumoRadius.md),
              ),
              child: Text(
                options[i],
                maxLines: 1,
                style: kumo
                    .text(color: active ? KumoColor.textInverse : KumoColor.textDefault)
                    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
        );
      },
    );
    final current = selected == null ? null : options[selected];
    final count = options.length;
    return Semantics(
      label: widget.column.label,
      value: current,
      increasedValue: selected == null ? null : options[(selected + 1) % count],
      decreasedValue: selected == null ? null : options[(selected - 1 + count) % count],
      onIncrease: selected == null ? null : () => _move(1),
      onDecrease: selected == null ? null : () => _move(-1),
      child: Focus(
        focusNode: _node,
        onKeyEvent: _onKey,
        onFocusChange: (_) => setState(() {}),
        child: MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: KumoFocusRing(
            visible: _node.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
            borderRadius: BorderRadius.circular(KumoRadius.md),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.6,
              child: SizedBox(
                width: 48 * scale,
                height: _visibleRows * _rowHeight,
                child: ExcludeSemantics(child: list),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet's wheels: drag follows the finger, release velocity carries
/// the wheel and it snaps to the nearest value.
class _Wheels extends StatelessWidget {
  const _Wheels({required this.columns, required this.value, required this.onPick});

  final List<_Column> columns;
  final KumoTimeValue value;
  final void Function(_Column column, int index) onPick;

  static const double itemExtent = 44;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    // The sheet hands vertical scroll drags to itself; a wheel keeps its own
    // drags and momentum, so spinning it never moves the sheet.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(physics: const ClampingScrollPhysics()),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.6,
        child: SizedBox(
          height: itemExtent * 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The selection band the wheels turn behind.
              Container(
                height: itemExtent,
                decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(KumoRadius.lg)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final column in columns)
                    Expanded(
                      child: _Wheel(
                        column: column,
                        selected: column.indexOf(value) ?? 0,
                        onPick: (i) => onPick(column, i),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wheel extends StatefulWidget {
  const _Wheel({required this.column, required this.selected, required this.onPick});

  final _Column column;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final FixedExtentScrollController _controller;
  late int _shown = widget.selected;

  int get _count => widget.column.options.length;

  // Short lists (AM/PM) stop at their ends; long ones loop like a clock.
  bool get _loops => _count > 2;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.selected);
  }

  @override
  void didUpdateWidget(_Wheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A change that did not come from this wheel (the hour wheel crossing
    // noon flips AM/PM, for example) turns the wheel to match.
    if (widget.selected != _shown && _controller.hasClients) {
      _shown = widget.selected;
      final current = _controller.selectedItem;
      final delta = ((widget.selected - current) % _count + _count) % _count;
      final shortest = delta > _count / 2 ? delta - _count : delta;
      final target = _loops ? current + shortest : widget.selected;
      final duration = KumoMotion.duration(context, KumoDurations.moderate);
      if (duration == Duration.zero) {
        _controller.jumpToItem(target);
      } else {
        _controller.animateToItem(target, duration: duration, curve: KumoCurves.standard);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final options = widget.column.options;
    Widget item(int i) {
      final index = (i % _count + _count) % _count;
      return Center(
        child: Text(
          options[index],
          maxLines: 1,
          style: kumo.text(size: KumoTextSize.lg).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      );
    }

    final count = options.length;
    return Semantics(
      label: widget.column.label,
      value: options[_shown],
      increasedValue: options[(_shown + 1) % count],
      decreasedValue: options[(_shown - 1 + count) % count],
      onIncrease: () => _controller.animateToItem(
        _controller.selectedItem + 1,
        duration: KumoDurations.moderate,
        curve: KumoCurves.standard,
      ),
      onDecrease: () => _controller.animateToItem(
        _controller.selectedItem - 1,
        duration: KumoDurations.moderate,
        curve: KumoCurves.standard,
      ),
      child: ExcludeSemantics(
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: _Wheels.itemExtent,
          diameterRatio: 1.6,
          perspective: 0.004,
          overAndUnderCenterOpacity: 0.4,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) {
            final index = (i % _count + _count) % _count;
            if (index == _shown) return;
            _shown = index;
            kumoHaptic(KumoHaptic.selection);
            widget.onPick(index);
          },
          childDelegate: _loops
              ? ListWheelChildLoopingListDelegate(children: [for (var i = 0; i < count; i++) item(i)])
              : ListWheelChildBuilderDelegate(builder: (context, i) => item(i), childCount: count),
        ),
      ),
    );
  }
}
