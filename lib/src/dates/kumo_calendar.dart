import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
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

/// How a [KumoCalendar] selects days: react-day-picker's `mode`.
enum KumoCalendarMode {
  /// One day. Tapping the selected day clears it unless `required`.
  single,

  /// A continuous run of days from a start to an end.
  range,

  /// Any number of separate days, toggled one by one.
  multiple,
}

/// A run of days picked in a range calendar. [to] is null while only the
/// start has been picked. Both ends are inclusive local days.
///
/// ```dart
/// final lastWeek = KumoDateRange(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 7));
/// lastWeek.contains(DateTime(2026, 3, 4)); // true
/// lastWeek.nights; // 6
/// ```
@immutable
class KumoDateRange {
  const KumoDateRange({required this.from, this.to});

  /// First day of the range.
  final DateTime from;

  /// Last day of the range, or null while it is still being picked.
  final DateTime? to;

  /// Both ends are picked.
  bool get isComplete => to != null;

  /// Days between [from] and [to] (react-day-picker counts range length in
  /// nights): 0 for a one-day range, 6 for a week.
  int get nights => to == null ? 0 : kumoDaysBetween(from, to!);

  /// True when [day] falls on or between the ends.
  bool contains(DateTime day) {
    final end = to ?? from;
    final d = kumoDay(day);
    return !d.isBefore(kumoDay(from)) && !d.isAfter(kumoDay(end));
  }

  @override
  bool operator ==(Object other) =>
      other is KumoDateRange &&
      kumoSameDay(other.from, from) &&
      (other.to == null ? to == null : kumoSameDay(other.to, to));

  @override
  int get hashCode => Object.hash(kumoDay(from), to == null ? null : kumoDay(to!));

  @override
  String toString() => 'KumoDateRange(${kumoDay(from)} - ${to == null ? '...' : kumoDay(to!)})';
}

/// Kumo's `DatePicker` calendar: the month grid Kumo renders with
/// react-day-picker, for single days, ranges and sets of days.
///
/// Each mode has its own constructor, so values stay typed:
///
/// ```dart
/// KumoCalendar.single(value: date, onValueChange: (d) => setState(() => date = d))
/// KumoCalendar.range(value: range, onValueChange: (r) => setState(() => range = r), numberOfMonths: 2)
/// KumoCalendar.multiple(value: days, onValueChange: (d) => setState(() => days = d), max: 5)
/// ```
///
/// The calendar is controlled: it shows the value it is given and reports
/// taps through `onValueChange`. The month being browsed is transient UI
/// state; pass [month] and [onMonthChange] to control it too (to jump to a
/// preset range, for example).
///
/// * Weeks start on [KumoStrings.firstDayOfWeek] (Sunday by default) and
///   every month and weekday name comes from [KumoStrings].
/// * Today is semibold link-blue. Days from other months are muted; they are
///   hidden when more than one month is shown, as in Kumo.
/// * Changing month slides the weeks in the direction of travel (Kumo's
///   200ms ease-out). On touch the grid follows a horizontal swipe and the
///   release velocity picks the previous or next month. Reduced motion
///   cross-fades instead.
/// * Keyboard: the grid is one Tab stop. Arrows move by day and week,
///   Page Up and Page Down by month (with Shift, by year), Home and End to
///   the start and end of the week, Enter and Space select. Unavailable
///   days are skipped.
/// * Screen readers hear each day as [KumoStrings.fullDate] with its
///   selected and disabled state.
///
/// Like Kumo, the calendar has no padding of its own; the container sets
/// it, or pass [padding].
class KumoCalendar extends StatefulWidget {
  /// Selects one day.
  ///
  /// ```dart
  /// KumoCalendar.single(
  ///   value: renewal,
  ///   minDate: DateTime(2026, 1, 1),
  ///   onValueChange: (d) => setState(() => renewal = d),
  /// )
  /// ```
  const KumoCalendar.single({
    super.key,
    DateTime? value,
    ValueChanged<DateTime?>? onValueChange,
    this.required = false,
    this.month,
    this.initialMonth,
    this.onMonthChange,
    this.numberOfMonths = 1,
    this.showOutsideDays,
    this.fixedWeeks = false,
    this.minDate,
    this.maxDate,
    this.isDateDisabled,
    this.disabled = false,
    this.today,
    this.footer,
    this.autofocus = false,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  }) : mode = KumoCalendarMode.single,
       singleValue = value,
       rangeValue = null,
       multipleValue = const [],
       onSingleChange = onValueChange,
       onRangeChange = null,
       onMultipleChange = null,
       min = null,
       max = null;

  /// Selects a run of days. [min] and [max] bound its length in nights.
  ///
  /// The first tap picks a one-day range; a later tap after the start moves
  /// the end, a tap before the start moves the start (react-day-picker's
  /// rules).
  ///
  /// ```dart
  /// KumoCalendar.range(
  ///   value: range,
  ///   numberOfMonths: 2,
  ///   onValueChange: (r) => setState(() => range = r),
  /// )
  /// ```
  const KumoCalendar.range({
    super.key,
    KumoDateRange? value,
    ValueChanged<KumoDateRange?>? onValueChange,
    this.min,
    this.max,
    this.required = false,
    this.month,
    this.initialMonth,
    this.onMonthChange,
    this.numberOfMonths = 1,
    this.showOutsideDays,
    this.fixedWeeks = false,
    this.minDate,
    this.maxDate,
    this.isDateDisabled,
    this.disabled = false,
    this.today,
    this.footer,
    this.autofocus = false,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  }) : mode = KumoCalendarMode.range,
       singleValue = null,
       rangeValue = value,
       multipleValue = const [],
       onSingleChange = null,
       onRangeChange = onValueChange,
       onMultipleChange = null;

  /// Toggles separate days. [min] and [max] bound how many can be picked;
  /// once [max] days are picked, the other days are disabled.
  ///
  /// ```dart
  /// KumoCalendar.multiple(
  ///   value: maintenanceDays,
  ///   max: 5,
  ///   onValueChange: (d) => setState(() => maintenanceDays = d),
  /// )
  /// ```
  const KumoCalendar.multiple({
    super.key,
    List<DateTime> value = const [],
    ValueChanged<List<DateTime>>? onValueChange,
    this.min,
    this.max,
    this.required = false,
    this.month,
    this.initialMonth,
    this.onMonthChange,
    this.numberOfMonths = 1,
    this.showOutsideDays,
    this.fixedWeeks = false,
    this.minDate,
    this.maxDate,
    this.isDateDisabled,
    this.disabled = false,
    this.today,
    this.footer,
    this.autofocus = false,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  }) : mode = KumoCalendarMode.multiple,
       singleValue = null,
       rangeValue = null,
       multipleValue = value,
       onSingleChange = null,
       onRangeChange = null,
       onMultipleChange = onValueChange;

  final KumoCalendarMode mode;

  /// The selected day in [KumoCalendarMode.single].
  final DateTime? singleValue;

  /// The selected range in [KumoCalendarMode.range].
  final KumoDateRange? rangeValue;

  /// The selected days in [KumoCalendarMode.multiple].
  final List<DateTime> multipleValue;
  final ValueChanged<DateTime?>? onSingleChange;
  final ValueChanged<KumoDateRange?>? onRangeChange;
  final ValueChanged<List<DateTime>>? onMultipleChange;

  /// Range: fewest nights. Multiple: fewest days (taps that would go below
  /// it are ignored). Kumo's `min`.
  final int? min;

  /// Range: most nights. Multiple: most days. Kumo's `max`.
  final int? max;

  /// The selection can not be cleared by tapping it again.
  final bool required;

  /// First month shown, when the parent controls browsing. Only the year
  /// and month are used.
  final DateTime? month;

  /// First month shown at start when [month] is null. Defaults to the
  /// month of the selection, then today's month.
  final DateTime? initialMonth;

  /// Called with the first shown month after a swipe, a nav button or a
  /// keyboard move to another month.
  final ValueChanged<DateTime>? onMonthChange;

  /// Months shown at once. Side by side when they fit, stacked otherwise
  /// (Kumo's `flex-col sm:flex-row`).
  final int numberOfMonths;

  /// Show the days of the previous and next month that fill the first and
  /// last week. Defaults to true for one month, false for several, as Kumo.
  final bool? showOutsideDays;

  /// Always show six weeks, so the grid height never changes.
  final bool fixedWeeks;

  /// Earliest day that can be picked. Browsing stops at its month.
  final DateTime? minDate;

  /// Latest day that can be picked. Browsing stops at its month.
  final DateTime? maxDate;

  /// Days that can not be picked, such as weekends or days already booked.
  ///
  /// ```dart
  /// isDateDisabled: (d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday,
  /// ```
  final bool Function(DateTime day)? isDateDisabled;

  /// Blocks every interaction.
  final bool disabled;

  /// The day marked as today. Defaults to `clock.now()`.
  final DateTime? today;

  /// Shown under the months, as wide as the calendar (usage hints, limits).
  final Widget? footer;

  /// Focus the selected day (or today) when the calendar appears. Pickers
  /// set this when they open.
  final bool autofocus;
  final EdgeInsetsGeometry padding;

  /// Accessible name of the whole calendar.
  final String? semanticLabel;

  @override
  State<KumoCalendar> createState() => _KumoCalendarState();
}

/// Sizes of one day slot. Kumo: `--cell-size` 32px squares in
/// `--cell-width` 36px columns, weeks `mt-2` apart.
class _Metrics {
  const _Metrics({required this.square, required this.column, required this.pitch, required this.weekdayHeight});

  final double square;
  final double column;

  /// Row height including the gap above the week.
  final double pitch;
  final double weekdayHeight;

  double get monthWidth => column * 7;

  static _Metrics resolve(BuildContext context, double maxWidth) {
    final touch = context.kumo.minTapTarget > 0;
    // On touch the squares grow so each slot is a 44px target.
    var square = touch ? 40.0 : 32.0;
    var gapX = 4.0;
    final gapY = touch ? 4.0 : 8.0;
    final scale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6);
    square *= scale;
    if (maxWidth.isFinite && (square + gapX) * 7 > maxWidth) {
      final column = maxWidth / 7;
      gapX = math.min(gapX, column * 0.1);
      square = column - gapX;
    }
    return _Metrics(square: square, column: square + gapX, pitch: square + gapY, weekdayHeight: 20 * scale);
  }
}

class _KumoCalendarState extends State<KumoCalendar> with TickerProviderStateMixin {
  late DateTime _month;

  /// Horizontal position of the shown months in month widths. 0 at rest;
  /// positive puts the earlier month in view, negative the later one.
  late final AnimationController _slide;

  /// Reduced motion: 0 to 1 while the new month fades in over [_fadeFrom].
  late final AnimationController _fade;
  DateTime? _fadeFrom;

  /// Months drawn beside the current one while sliding. Normally the
  /// adjacent months; after a jump of several months, the month left behind.
  DateTime? _before;
  DateTime? _after;

  List<List<FocusNode>> _nodes = const [];
  DateTime? _focusDate;
  DateTime? _pendingFocus;
  DateTime? _requestedMonth;

  double _dragPx = 0;
  bool _dragging = false;
  double _monthWidth = 252;

  KumoStrings get _strings => context.kumoStrings;
  int get _firstDay => _strings.firstDayOfWeek;
  int get _count => math.max(1, widget.numberOfMonths);
  DateTime get _today => kumoDay(widget.today ?? clock.now());
  DateTime? get _min => widget.minDate == null ? null : kumoDay(widget.minDate!);
  DateTime? get _max => widget.maxDate == null ? null : kumoDay(widget.maxDate!);
  bool get _showOutside => widget.showOutsideDays ?? _count == 1;
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController.unbounded(vsync: this)..addStatusListener(_onSlideStatus);
    _fade = AnimationController(vsync: this, duration: KumoDurations.fast, value: 1);
    _month = _clampMonth(kumoFirstOfMonth(widget.month ?? widget.initialMonth ?? _firstSelected() ?? _today));
    _buildNodes();
    if (widget.autofocus) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final day = _tabStop();
        if (day != null) _nodeFor(day)?.requestFocus();
      });
    }
  }

  DateTime? _firstSelected() => switch (widget.mode) {
    KumoCalendarMode.single => widget.singleValue,
    KumoCalendarMode.range => widget.rangeValue?.from,
    KumoCalendarMode.multiple => widget.multipleValue.isEmpty ? null : widget.multipleValue.first,
  };

  void _buildNodes() {
    final old = _nodes;
    _nodes = [
      for (var p = 0; p < _count; p++)
        p < old.length
            ? old[p]
            : List.generate(31, (i) {
                final node = FocusNode(debugLabel: 'KumoCalendar day ${i + 1}');
                node.addListener(() => _onNodeFocus(p, i + 1, node));
                return node;
              }),
    ];
    for (var p = _count; p < old.length; p++) {
      for (final n in old[p]) {
        n.dispose();
      }
    }
  }

  @override
  void didUpdateWidget(KumoCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.numberOfMonths != oldWidget.numberOfMonths) _buildNodes();
    final controlled = widget.month;
    if (controlled != null) {
      final next = kumoFirstOfMonth(controlled);
      if (next != _month) _showMonth(next);
      _requestedMonth = null;
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _fade.dispose();
    for (final panel in _nodes) {
      for (final n in panel) {
        n.dispose();
      }
    }
    super.dispose();
  }

  void _onSlideStatus(AnimationStatus status) {
    if (!status.isAnimating && !_dragging && _slide.value == 0) {
      setState(() {
        _before = null;
        _after = null;
      });
    }
  }

  void _onNodeFocus(int panel, int day, FocusNode node) {
    if (!node.hasFocus) return;
    final date = DateTime(_month.year, _month.month + panel, day);
    if (!kumoSameDay(date, _focusDate)) setState(() => _focusDate = date);
  }

  FocusNode? _nodeFor(DateTime day) {
    final panel = kumoMonthsBetween(_month, day);
    if (panel < 0 || panel >= _count) return null;
    return _nodes[panel][day.day - 1];
  }

  DateTime _clampMonth(DateTime month) {
    var m = month;
    final max = _max;
    if (max != null) {
      final last = kumoAddMonths(kumoFirstOfMonth(max), -(_count - 1));
      if (m.isAfter(last)) m = last;
    }
    final min = _min;
    if (min != null && m.isBefore(kumoFirstOfMonth(min))) m = kumoFirstOfMonth(min);
    return m;
  }

  DateTime get _lastShown => kumoAddMonths(_month, _count - 1);
  bool _shown(DateTime day) => !kumoDay(day).isBefore(_month) && day.isBefore(kumoAddMonths(_month, _count));

  bool get _canPrevious {
    if (widget.disabled) return false;
    final min = _min;
    return min == null || kumoFirstOfMonth(min).isBefore(_month);
  }

  bool get _canNext {
    if (widget.disabled) return false;
    final max = _max;
    return max == null || kumoFirstOfMonth(max).isAfter(_lastShown);
  }

  bool _isSelected(DateTime day) => switch (widget.mode) {
    KumoCalendarMode.single => kumoSameDay(widget.singleValue, day),
    KumoCalendarMode.range => widget.rangeValue?.contains(day) ?? false,
    KumoCalendarMode.multiple => widget.multipleValue.any((d) => kumoSameDay(d, day)),
  };

  bool _isDisabled(DateTime day) {
    if (widget.disabled) return true;
    final min = _min;
    final max = _max;
    if (min != null && day.isBefore(min)) return true;
    if (max != null && day.isAfter(max)) return true;
    if (widget.isDateDisabled?.call(day) ?? false) return true;
    if (widget.mode == KumoCalendarMode.multiple &&
        widget.max != null &&
        widget.multipleValue.length >= widget.max! &&
        !_isSelected(day)) {
      return true;
    }
    return false;
  }

  bool get _interactive =>
      !widget.disabled &&
      switch (widget.mode) {
        KumoCalendarMode.single => widget.onSingleChange != null,
        KumoCalendarMode.range => widget.onRangeChange != null,
        KumoCalendarMode.multiple => widget.onMultipleChange != null,
      };

  void _select(DateTime day) {
    switch (widget.mode) {
      case KumoCalendarMode.single:
        if (kumoSameDay(widget.singleValue, day)) {
          if (!widget.required) widget.onSingleChange?.call(null);
        } else {
          widget.onSingleChange?.call(day);
        }
      case KumoCalendarMode.multiple:
        final current = widget.multipleValue;
        if (current.any((d) => kumoSameDay(d, day))) {
          if (widget.min != null && current.length <= widget.min!) return;
          if (widget.required && current.length == 1) return;
          widget.onMultipleChange?.call([
            for (final d in current)
              if (!kumoSameDay(d, day)) d,
          ]);
        } else {
          if (widget.max != null && current.length >= widget.max!) return;
          widget.onMultipleChange?.call([...current, day]);
        }
      case KumoCalendarMode.range:
        final next = _addToRange(day, widget.rangeValue);
        if (next != widget.rangeValue || next == null) widget.onRangeChange?.call(next);
    }
  }

  /// react-day-picker's `addToRange`.
  KumoDateRange? _addToRange(DateTime day, KumoDateRange? range) {
    final min = widget.min ?? 0;
    final max = widget.max ?? 0;
    KumoDateRange? next;
    final from = range?.from;
    final to = range?.to;
    if (from == null) {
      next = KumoDateRange(from: day, to: min > 0 ? null : day);
    } else if (to == null) {
      if (kumoSameDay(from, day)) {
        if (min == 0) {
          next = KumoDateRange(from: from, to: day);
        } else if (widget.required) {
          next = KumoDateRange(from: from);
        } else {
          next = null;
        }
      } else if (day.isBefore(from)) {
        next = KumoDateRange(from: day, to: from);
      } else {
        next = KumoDateRange(from: from, to: day);
      }
    } else {
      if (kumoSameDay(from, day) && kumoSameDay(to, day)) {
        next = widget.required ? range : null;
      } else if (kumoSameDay(from, day)) {
        next = KumoDateRange(from: from, to: min > 0 ? null : day);
      } else if (kumoSameDay(to, day)) {
        next = KumoDateRange(from: day, to: min > 0 ? null : day);
      } else if (day.isBefore(from)) {
        next = KumoDateRange(from: day, to: to);
      } else {
        next = KumoDateRange(from: from, to: day);
      }
    }
    if (next != null && next.to != null) {
      final nights = next.nights;
      if ((max > 0 && nights > max) || (min > 1 && nights < min)) next = KumoDateRange(from: day);
    }
    return next;
  }

  /// Asks for [month] as the first shown month: directly when browsing is
  /// internal, through [KumoCalendar.onMonthChange] when it is controlled.
  void _requestMonth(DateTime month, {double? fromOffset, double velocity = 0}) {
    final target = _clampMonth(kumoFirstOfMonth(month));
    if (target == _month) {
      _settle(velocity);
      return;
    }
    if (widget.month == null) {
      _showMonth(target, fromOffset: fromOffset, velocity: velocity);
      widget.onMonthChange?.call(target);
      return;
    }
    _requestedMonth = target;
    _pendingSlide = (fromOffset, velocity);
    widget.onMonthChange?.call(target);
    // A parent that keeps the old month gets the grid back where it was.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _requestedMonth == target) {
        _requestedMonth = null;
        _pendingSlide = null;
        _settle(0);
      }
    });
  }

  (double?, double)? _pendingSlide;

  void _showMonth(DateTime month, {double? fromOffset, double velocity = 0}) {
    final pending = _pendingSlide;
    _pendingSlide = null;
    fromOffset ??= pending?.$1;
    if (pending != null) velocity = pending.$2;
    final delta = kumoMonthsBetween(_month, month);
    final old = _month;
    setState(() {
      _month = month;
      // Draw the month left behind beside the new one, so a jump of several
      // months still slides the old month out.
      _before = delta > 0 ? old : null;
      _after = delta < 0 ? old : null;
    });
    if (KumoMotion.reduceMotion(context)) {
      // Reduced motion: no slide, a short cross-fade from the old month.
      _slide.value = 0;
      _fadeFrom = old;
      _fade.forward(from: 0);
      return;
    }
    if (fromOffset != null) {
      _slide.value = fromOffset;
      _settle(velocity);
      return;
    }
    // The new month enters from the side it lies on; the old one leaves the
    // other way (Kumo's rdp-weeks slide, 200ms ease-out). A press while a
    // slide is still running continues from where the old month is, so
    // rapid presses never snap it back to the middle first.
    _slide.value = _slide.value + (delta > 0 ? 1 : -1);
    _slide.animateTo(0, duration: KumoDurations.moderate, curve: KumoCurves.enter);
  }

  void _settle(double velocity) {
    if (KumoMotion.reduceMotion(context)) {
      _slide.value = 0;
      return;
    }
    if (_slide.value == 0) return;
    KumoMotion.springTo(_slide, 0, spring: KumoSprings.momentum, velocity: velocity);
  }

  void _goBy(int months) => _requestMonth(kumoAddMonths(_month, months));

  // Swipe: the weeks follow the finger 1:1; the release velocity, projected
  // forward, picks the previous or next month.

  double get _dir => _rtl ? -1 : 1;

  void _onDragStart(DragStartDetails details) {
    _slide.stop();
    _dragging = true;
    _dragPx = _slide.value * _monthWidth * _dir;
    if (_before != null || _after != null) {
      setState(() {
        _before = null;
        _after = null;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _dragPx += details.primaryDelta ?? 0;
    final raw = _dragPx * _dir / _monthWidth;
    var value = raw;
    // Past the first or last month the grid resists instead of revealing a
    // month that can not be shown.
    if (raw > 0 && !_canPrevious) value = KumoMotion.rubberband(raw * _monthWidth, _monthWidth) / _monthWidth;
    if (raw < 0 && !_canNext) value = KumoMotion.rubberband(raw * _monthWidth, _monthWidth) / _monthWidth;
    _slide.value = value.clamp(-1.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = (details.primaryVelocity ?? 0) * _dir / _monthWidth;
    final current = _slide.value;
    final projected = current + KumoMotion.project(velocity * _monthWidth) / _monthWidth;
    var step = 0;
    if (projected > 0.5 && velocity >= 0 && _canPrevious) step = -1;
    if (projected < -0.5 && velocity <= 0 && _canNext) step = 1;
    if (step == 0) {
      _settle(velocity);
      return;
    }
    kumoHaptic(KumoHaptic.selection);
    // The new month continues from where the finger left the old one.
    _requestMonth(kumoAddMonths(_month, step), fromOffset: current + step, velocity: velocity);
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _settle(0);
  }

  // Keyboard.

  DateTime? _findEnabled(DateTime start, int step) {
    final min = _min;
    final max = _max;
    var day = start;
    for (var i = 0; i < 366; i++) {
      if ((min != null && day.isBefore(min)) || (max != null && day.isAfter(max))) return null;
      if (!_isDisabled(day)) return day;
      day = kumoAddDays(day, step);
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final from = _focusDate;
    if (from == null || !_shown(from)) return KeyEventResult.ignored;
    final focused = _nodeFor(from);
    if (focused == null || !focused.hasFocus) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final column = kumoWeekColumn(from, _firstDay);
    DateTime target;
    var step = 1;
    if (key == LogicalKeyboardKey.arrowLeft) {
      step = _rtl ? 1 : -1;
      target = kumoAddDays(from, step);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      step = _rtl ? -1 : 1;
      target = kumoAddDays(from, step);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      step = -1;
      target = kumoAddDays(from, -7);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      target = kumoAddDays(from, 7);
    } else if (key == LogicalKeyboardKey.pageUp) {
      step = -1;
      target = kumoAddMonthsKeepDay(from, shift ? -12 : -1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      target = kumoAddMonthsKeepDay(from, shift ? 12 : 1);
    } else if (key == LogicalKeyboardKey.home) {
      target = kumoAddDays(from, -column);
    } else if (key == LogicalKeyboardKey.end) {
      step = -1;
      target = kumoAddDays(from, 6 - column);
    } else {
      return KeyEventResult.ignored;
    }
    final resolved = _findEnabled(target, step);
    if (resolved != null) _moveFocus(resolved);
    return KeyEventResult.handled;
  }

  void _moveFocus(DateTime day) {
    _focusDate = day;
    if (_shown(day)) {
      setState(() {});
      _nodeFor(day)?.requestFocus();
      return;
    }
    final month = kumoFirstOfMonth(day);
    _requestMonth(month.isBefore(_month) ? month : kumoAddMonths(month, -(_count - 1)));
    _pendingFocus = day;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final pending = _pendingFocus;
      _pendingFocus = null;
      if (mounted && pending != null && _shown(pending)) _nodeFor(pending)?.requestFocus();
    });
  }

  /// The one day Tab lands on, so the grid is a single tab stop.
  DateTime? _tabStop() {
    final candidates = <DateTime?>[
      _focusDate,
      switch (widget.mode) {
        KumoCalendarMode.single => widget.singleValue,
        KumoCalendarMode.range => widget.rangeValue?.from,
        KumoCalendarMode.multiple => null,
      },
      ...widget.multipleValue,
      _today,
    ];
    for (final c in candidates) {
      if (c == null) continue;
      final day = kumoDay(c);
      if (_shown(day) && !_isDisabled(day)) return day;
    }
    for (var p = 0; p < _count; p++) {
      final month = kumoAddMonths(_month, p);
      for (var d = 1; d <= kumoDaysInMonth(month); d++) {
        final day = DateTime(month.year, month.month, d);
        if (!_isDisabled(day)) return day;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: Builder(
        builder: (context) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final available = math.max(0.0, constraints.maxWidth - widget.padding.horizontal);
              var metrics = _Metrics.resolve(context, double.infinity);
              const gap = KumoSpace.s4;
              final rowWidth = metrics.monthWidth * _count + gap * (_count - 1);
              final sideBySide = _count > 1 && (!available.isFinite || rowWidth <= available);
              if (!sideBySide && available.isFinite && metrics.monthWidth > available) {
                metrics = _Metrics.resolve(context, available);
              }
              _monthWidth = metrics.monthWidth;
              final tabStop = _tabStop();

              final panels = <Widget>[
                for (var p = 0; p < _count; p++)
                  _buildMonth(context, p, metrics, tabStop, hostsNav: sideBySide ? p == _count - 1 : p == 0),
              ];
              final months = sideBySide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: gap,
                      children: panels,
                    )
                  : Column(mainAxisSize: MainAxisSize.min, spacing: gap, children: panels);

              Widget body = Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: _onKey,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  supportedDevices: const {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.invertedStylus,
                  },
                  onHorizontalDragStart: widget.disabled ? null : _onDragStart,
                  onHorizontalDragUpdate: widget.disabled ? null : _onDragUpdate,
                  onHorizontalDragEnd: widget.disabled ? null : _onDragEnd,
                  onHorizontalDragCancel: widget.disabled ? null : _onDragCancel,
                  child: months,
                ),
              );
              if (widget.footer != null) {
                final width = sideBySide ? rowWidth : metrics.monthWidth;
                body = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    body,
                    SizedBox(
                      width: width,
                      child: Padding(
                        padding: const EdgeInsets.only(top: KumoSpace.s3),
                        child: DefaultTextStyle.merge(
                          style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle),
                          child: widget.footer!,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Semantics(
                container: true,
                label: widget.semanticLabel,
                child: Opacity(
                  opacity: widget.disabled ? 0.5 : 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: kumo.colors.base,
                      borderRadius: BorderRadius.circular(KumoRadius.xl),
                    ),
                    child: Padding(padding: widget.padding, child: body),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonth(BuildContext context, int panel, _Metrics m, DateTime? tabStop, {required bool hostsNav}) {
    final kumo = context.kumo;
    final strings = _strings;
    final month = kumoAddMonths(_month, panel);
    final fade = KumoMotion.reduceMotion(context) ? KumoDurations.fast : KumoDurations.moderate;

    final caption = SizedBox(
      height: math.max(m.square, kumo.minTapTarget),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s0_5),
              child: AnimatedSwitcher(
                duration: fade,
                switchInCurve: KumoCurves.enter,
                switchOutCurve: KumoCurves.enter,
                layoutBuilder: (current, previous) =>
                    Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
                child: Semantics(
                  key: ValueKey(month),
                  header: true,
                  liveRegion: true,
                  child: Text(
                    strings.monthYear(month),
                    style: kumo.text(weight: KumoTypography.medium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          if (hostsNav)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: KumoSpace.s0_5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: KumoSpace.s1,
                children: [
                  _NavButton(
                    dimension: m.square,
                    icon: _rtl ? KumoIcons.caretRight : KumoIcons.caretLeft,
                    semanticLabel: strings.previousMonth,
                    onPress: _canPrevious ? () => _goBy(-1) : null,
                  ),
                  _NavButton(
                    dimension: m.square,
                    icon: _rtl ? KumoIcons.caretLeft : KumoIcons.caretRight,
                    semanticLabel: strings.nextMonth,
                    onPress: _canNext ? () => _goBy(1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final weekdays = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 7; i++)
            SizedBox(
              width: m.column,
              height: m.weekdayHeight,
              child: Center(
                child: Text(
                  strings.weekdayNamesShort[(_firstDay - 1 + i) % 7],
                  style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle),
                  maxLines: 1,
                ),
              ),
            ),
        ],
      ),
    );

    Widget still(DateTime month) => ExcludeFocus(
      child: ExcludeSemantics(child: IgnorePointer(child: _grid(context, month, m, null, interactive: false))),
    );
    final weeks = AnimatedBuilder(
      animation: Listenable.merge([_slide, _fade]),
      builder: (context, _) {
        final offset = _slide.value;
        final current = _grid(context, month, m, tabStop, interactive: true);
        final fadeFrom = _fadeFrom;
        if (_fade.value < 1 && fadeFrom != null) {
          return Stack(
            children: [
              Opacity(opacity: _fade.value, child: current),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(opacity: 1 - _fade.value, child: still(kumoAddMonths(fadeFrom, panel))),
              ),
            ],
          );
        }
        if (offset == 0) return current;
        final before = kumoAddMonths(_before ?? kumoAddMonths(_month, -1), panel);
        final after = kumoAddMonths(_after ?? kumoAddMonths(_month, 1), panel);
        Widget neighbor(DateTime month, double at) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FractionalTranslation(translation: Offset(at * _dir, 0), child: still(month)),
        );
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FractionalTranslation(translation: Offset(offset * _dir, 0), child: current),
              if (offset > 0) neighbor(before, offset - 1),
              if (offset < 0) neighbor(after, offset + 1),
            ],
          ),
        );
      },
    );

    return SizedBox(
      width: m.monthWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s3,
        children: [
          caption,
          Column(mainAxisSize: MainAxisSize.min, children: [weekdays, weeks]),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, DateTime month, _Metrics m, DateTime? tabStop, {required bool interactive}) {
    final offset = kumoWeekColumn(month, _firstDay);
    final days = kumoDaysInMonth(month);
    final weekCount = widget.fixedWeeks ? 6 : ((offset + days) / 7).ceil();
    final panel = kumoMonthsBetween(_month, month);
    final range = widget.mode == KumoCalendarMode.range ? widget.rangeValue : null;
    final canPick = _interactive && interactive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var w = 0; w < weekCount; w++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var c = 0; c < 7; c++)
                Builder(
                  builder: (context) {
                    final day = DateTime(month.year, month.month, 1 - offset + w * 7 + c);
                    final outside = !kumoSameMonth(day, month);
                    if (outside && !_showOutside) return SizedBox(width: m.column, height: m.pitch);
                    final selected = _isSelected(day);
                    final start = range != null && kumoSameDay(range.from, day);
                    final end = range != null && (range.to == null ? start : kumoSameDay(range.to, day));
                    final node = !outside && interactive && panel >= 0 && panel < _count
                        ? _nodes[panel][day.day - 1]
                        : null;
                    final isTabStop = node != null && kumoSameDay(tabStop, day);
                    if (node != null) node.skipTraversal = !isTabStop;
                    return _DaySlot(
                      day: day,
                      metrics: m,
                      column: c,
                      selected: selected,
                      rangeStart: range != null && start,
                      rangeEnd: range != null && end,
                      rangeMiddle: range != null && selected && !start && !end,
                      today: kumoSameDay(day, _today),
                      outside: outside,
                      disabled: _isDisabled(day),
                      focusNode: node,
                      canRequestFocus: node != null,
                      onPress: canPick ? () => _select(day) : null,
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.dimension, required this.icon, required this.semanticLabel, required this.onPress});

  final double dimension;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final radius = BorderRadius.circular(KumoRadius.md);
    return KumoPressable(
      onPress: onPress,
      disabled: onPress == null,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      borderRadius: radius,
      builder: (context, state) => Opacity(
        opacity: onPress == null ? 0.5 : 1,
        child: Container(
          width: dimension,
          height: dimension,
          decoration: BoxDecoration(color: state.active ? c.tint : null, borderRadius: radius),
          child: Center(child: KumoIcon(icon, color: KumoColor.textDefault)),
        ),
      ),
    );
  }
}

/// One day: the range band painted on the slot, the day square on top.
class _DaySlot extends StatelessWidget {
  const _DaySlot({
    required this.day,
    required this.metrics,
    required this.column,
    required this.selected,
    required this.rangeStart,
    required this.rangeEnd,
    required this.rangeMiddle,
    required this.today,
    required this.outside,
    required this.disabled,
    required this.focusNode,
    required this.canRequestFocus,
    required this.onPress,
  });

  final DateTime day;
  final _Metrics metrics;
  final int column;
  final bool selected;
  final bool rangeStart;
  final bool rangeEnd;
  final bool rangeMiddle;
  final bool today;
  final bool outside;
  final bool disabled;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final m = metrics;
    final firstColumn = column == 0;
    final lastColumn = column == 6;
    final filled = selected && !rangeMiddle;
    const r = Radius.circular(KumoRadius.md);

    // Range ends are square on the side that meets the band; a one-day
    // range, or an end at the edge of a week, stays round.
    final squareEnd = rangeStart && !rangeEnd && !lastColumn;
    final squareStart = rangeEnd && !rangeStart && !firstColumn;
    final squareRadius = BorderRadiusDirectional.only(
      topStart: squareStart ? Radius.zero : r,
      bottomStart: squareStart ? Radius.zero : r,
      topEnd: squareEnd ? Radius.zero : r,
      bottomEnd: squareEnd ? Radius.zero : r,
    );

    final label = today ? '${strings.fullDate(day)}, ${strings.today}' : strings.fullDate(day);
    final interactive = onPress != null && !disabled;

    return KumoPressable(
      onPress: interactive ? onPress : null,
      disabled: disabled,
      focusNode: focusNode,
      canRequestFocus: canRequestFocus,
      minTapTargetSize: 0,
      showFocusRing: false,
      semanticLabel: label,
      selected: selected,
      excludeChildSemantics: true,
      mouseCursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      builder: (context, state) {
        Color? squareColor;
        if (filled) {
          squareColor = c.contrast;
        } else if (interactive && state.active) {
          squareColor = rangeMiddle ? c.interact : c.tint;
        }
        final KumoColor textColor;
        if (filled) {
          textColor = KumoColor.textInverse;
        } else if (disabled || outside) {
          textColor = KumoColor.textInactive;
        } else if (today) {
          textColor = KumoColor.textLink;
        } else {
          textColor = KumoColor.textDefault;
        }
        final bold = today && !selected && !outside;

        Widget square = Container(
          width: m.square,
          height: m.square,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: squareColor, borderRadius: squareRadius),
          child: Text(
            '${day.day}',
            maxLines: 1,
            style: kumo
                .text(color: textColor, weight: bold ? KumoTypography.semibold : KumoTypography.normal)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        );
        if (state.focused) {
          square = CustomPaint(
            foregroundPainter: KumoFocusRingPainter(
              borderRadius: squareRadius.resolve(Directionality.of(context)),
              color: c.brand,
            ),
            child: square,
          );
        }

        // The band runs across the slot: the full width in the middle, the
        // inner half at each end, rounded where a week wraps.
        Widget? band;
        final bandColor = c.fill;
        if (rangeMiddle) {
          band = DecoratedBox(
            decoration: BoxDecoration(
              color: bandColor,
              borderRadius: BorderRadiusDirectional.horizontal(
                start: firstColumn ? r : Radius.zero,
                end: lastColumn ? r : Radius.zero,
              ),
            ),
          );
        } else if (squareEnd || squareStart) {
          band = Align(
            alignment: squareEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: FractionallySizedBox(widthFactor: 0.5, heightFactor: 1, child: ColoredBox(color: bandColor)),
          );
        }

        return SizedBox(
          width: m.column,
          height: m.pitch,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: m.column,
              height: m.square,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (band != null) Positioned.fill(child: band),
                  square,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
