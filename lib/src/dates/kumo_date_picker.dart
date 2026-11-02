import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../forms/src/forms_internal.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_calendar.dart';
import 'kumo_dates_internal.dart';

/// A shortcut beside a range picker's calendar, such as "Last 7 days".
/// [range] gets today (from `clock.now()`) when the preset is pressed, so a
/// preset stays correct across midnight.
///
/// ```dart
/// KumoDatePickerPreset(
///   label: 'Last 14 days',
///   range: (today) => KumoDateRange(from: today.subtract(const Duration(days: 13)), to: today),
/// )
/// ```
@immutable
class KumoDatePickerPreset {
  const KumoDatePickerPreset({required this.label, required this.range});

  final String label;
  final KumoDateRange Function(DateTime today) range;

  /// The presets Kumo's range demo shows: Today, Last 7 days, Last 30 days,
  /// Last 90 days, This month and Last month. English labels; build your
  /// own list to translate them.
  static const List<KumoDatePickerPreset> kumoDefaults = [
    KumoDatePickerPreset(label: 'Today', range: _today),
    KumoDatePickerPreset(label: 'Last 7 days', range: _last7),
    KumoDatePickerPreset(label: 'Last 30 days', range: _last30),
    KumoDatePickerPreset(label: 'Last 90 days', range: _last90),
    KumoDatePickerPreset(label: 'This month', range: _thisMonth),
    KumoDatePickerPreset(label: 'Last month', range: _lastMonth),
  ];

  static KumoDateRange _today(DateTime t) => KumoDateRange(from: t, to: t);
  static KumoDateRange _last7(DateTime t) => KumoDateRange(from: kumoAddDays(t, -6), to: t);
  static KumoDateRange _last30(DateTime t) => KumoDateRange(from: kumoAddDays(t, -29), to: t);
  static KumoDateRange _last90(DateTime t) => KumoDateRange(from: kumoAddDays(t, -89), to: t);
  static KumoDateRange _thisMonth(DateTime t) =>
      KumoDateRange(from: DateTime(t.year, t.month), to: DateTime(t.year, t.month + 1, 0));
  static KumoDateRange _lastMonth(DateTime t) =>
      KumoDateRange(from: DateTime(t.year, t.month - 1), to: DateTime(t.year, t.month, 0));
}

/// A date field that opens a [KumoCalendar]: Kumo's `DatePicker` composed
/// with a `Popover`, as the Kumo docs show it.
///
/// The field shows the formatted value or a placeholder. On wide screens
/// the calendar opens in an anchored popover; below 768px it opens in a
/// bottom sheet that follows the finger ([presentation]). Range pickers can
/// list [presets] beside the calendar, as in Kumo's range demo.
///
/// ```dart
/// KumoDatePicker.single(
///   label: 'Certificate expiry',
///   value: expiry,
///   onValueChange: (d) => setState(() => expiry = d),
/// )
///
/// KumoDatePicker.range(
///   label: 'Analytics period',
///   value: period,
///   presets: KumoDatePickerPreset.kumoDefaults,
///   onValueChange: (r) => setState(() => period = r),
/// )
/// ```
///
/// Controlled: the field shows the value it is given. A single-date picker
/// closes when a day is picked; range and multiple pickers stay open until
/// dismissed (outside tap, Escape, the sheet's Done button or a swipe down).
class KumoDatePicker extends StatefulWidget {
  /// Picks one day.
  const KumoDatePicker.single({
    super.key,
    DateTime? value,
    ValueChanged<DateTime?>? onValueChange,
    this.closeOnSelect = true,
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
    this.minDate,
    this.maxDate,
    this.isDateDisabled,
    this.numberOfMonths,
    this.formatDate,
    this.footer,
    this.today,
    this.showOptional = false,
    this.required = false,
    this.doneLabel,
    this.semanticLabel,
  }) : mode = KumoCalendarMode.single,
       singleValue = value,
       rangeValue = null,
       multipleValue = const [],
       onSingleChange = onValueChange,
       onRangeChange = null,
       onMultipleChange = null,
       presets = const [],
       min = null,
       max = null;

  /// Picks a run of days. [min] and [max] bound its length in nights.
  const KumoDatePicker.range({
    super.key,
    KumoDateRange? value,
    ValueChanged<KumoDateRange?>? onValueChange,
    this.presets = const [],
    this.min,
    this.max,
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
    this.minDate,
    this.maxDate,
    this.isDateDisabled,
    this.numberOfMonths,
    this.formatDate,
    this.footer,
    this.today,
    this.showOptional = false,
    this.required = false,
    this.doneLabel,
    this.semanticLabel,
  }) : mode = KumoCalendarMode.range,
       singleValue = null,
       rangeValue = value,
       multipleValue = const [],
       onSingleChange = null,
       onRangeChange = onValueChange,
       onMultipleChange = null,
       closeOnSelect = false;

  /// Picks separate days. [max] bounds how many.
  const KumoDatePicker.multiple({
    super.key,
    List<DateTime> value = const [],
    ValueChanged<List<DateTime>>? onValueChange,
    this.min,
    this.max,
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
    this.minDate,
    this.maxDate,
    this.isDateDisabled,
    this.numberOfMonths,
    this.formatDate,
    this.footer,
    this.today,
    this.showOptional = false,
    this.required = false,
    this.doneLabel,
    this.semanticLabel,
  }) : mode = KumoCalendarMode.multiple,
       singleValue = null,
       rangeValue = null,
       multipleValue = value,
       onSingleChange = null,
       onRangeChange = null,
       onMultipleChange = onValueChange,
       presets = const [],
       closeOnSelect = false;

  final KumoCalendarMode mode;
  final DateTime? singleValue;
  final KumoDateRange? rangeValue;
  final List<DateTime> multipleValue;
  final ValueChanged<DateTime?>? onSingleChange;
  final ValueChanged<KumoDateRange?>? onRangeChange;
  final ValueChanged<List<DateTime>>? onMultipleChange;

  /// Shortcuts listed beside a range calendar. See [KumoDatePickerPreset.kumoDefaults].
  final List<KumoDatePickerPreset> presets;

  /// Range: fewest nights. Multiple: fewest days.
  final int? min;

  /// Range: most nights. Multiple: most days.
  final int? max;

  /// Close the panel when a day is picked. Single mode only.
  final bool closeOnSelect;

  /// Field label above the trigger.
  final String? label;
  final String? description;

  /// Error message below the field; also draws the field's error ring.
  final String? error;

  /// Shown while nothing is picked. Defaults to [KumoStrings.pickDate]
  /// (single) or [KumoStrings.pickDates] (range and multiple).
  final String? placeholder;
  final KumoFieldSize size;
  final bool disabled;

  /// Show a clear button in the field while a value is set.
  final bool clearable;

  /// Popover or bottom sheet. `auto` uses a sheet below 768px.
  final KumoPresentation presentation;

  /// Whether the panel is open, when the parent controls it.
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool Function(DateTime day)? isDateDisabled;

  /// Months shown in the popover. Defaults to 2 for ranges and 1 otherwise.
  /// The sheet always shows one month and swipes between months.
  final int? numberOfMonths;

  /// Formats each date in the field. Defaults to [KumoStrings.shortDate]
  /// ("Mar 4, 2026").
  final String Function(DateTime date)? formatDate;

  /// Shown under the calendar.
  final Widget? footer;

  /// The day marked as today and used by presets. Defaults to `clock.now()`.
  final DateTime? today;
  final bool showOptional;
  final bool required;

  /// Label of the button that closes the sheet on narrow screens. Default
  /// [KumoStrings.done].
  final String? doneLabel;

  /// Accessible name when there is no [label].
  final String? semanticLabel;

  @override
  State<KumoDatePicker> createState() => _KumoDatePickerState();
}

class _KumoDatePickerState extends State<KumoDatePicker> {
  bool _ownOpen = false;
  DateTime? _month;

  bool get _open => widget.open ?? _ownOpen;

  void _setOpen(bool value) {
    if (value == _open) return;
    if (value) _month = null;
    if (widget.open == null) setState(() => _ownOpen = value);
    widget.onOpenChange?.call(value);
  }

  bool get _hasValue => switch (widget.mode) {
    KumoCalendarMode.single => widget.singleValue != null,
    KumoCalendarMode.range => widget.rangeValue != null,
    KumoCalendarMode.multiple => widget.multipleValue.isNotEmpty,
  };

  String? _display(KumoStrings strings) {
    final format = widget.formatDate ?? strings.shortDate;
    switch (widget.mode) {
      case KumoCalendarMode.single:
        final v = widget.singleValue;
        return v == null ? null : format(v);
      case KumoCalendarMode.range:
        final r = widget.rangeValue;
        if (r == null) return null;
        if (r.to == null) return format(r.from);
        return '${format(r.from)} – ${format(r.to!)}';
      case KumoCalendarMode.multiple:
        final days = [...widget.multipleValue]..sort();
        return days.isEmpty ? null : days.map(format).join(', ');
    }
  }

  void _clear() {
    switch (widget.mode) {
      case KumoCalendarMode.single:
        widget.onSingleChange?.call(null);
      case KumoCalendarMode.range:
        widget.onRangeChange?.call(null);
      case KumoCalendarMode.multiple:
        widget.onMultipleChange?.call(const []);
    }
  }

  void _applyPreset(KumoDatePickerPreset preset) {
    final range = preset.range(kumoDay(widget.today ?? clock.now()));
    setState(() => _month = kumoFirstOfMonth(range.from));
    widget.onRangeChange?.call(range);
  }

  Widget _calendar(BuildContext context, {required bool inSheet}) {
    final months = inSheet ? 1 : (widget.numberOfMonths ?? (widget.mode == KumoCalendarMode.range ? 2 : 1));
    void monthChanged(DateTime m) => setState(() => _month = m);
    switch (widget.mode) {
      case KumoCalendarMode.single:
        return KumoCalendar.single(
          value: widget.singleValue,
          onValueChange: (d) {
            widget.onSingleChange?.call(d);
            if (widget.closeOnSelect && d != null) _setOpen(false);
          },
          required: widget.required,
          month: _month,
          onMonthChange: monthChanged,
          numberOfMonths: months,
          minDate: widget.minDate,
          maxDate: widget.maxDate,
          isDateDisabled: widget.isDateDisabled,
          today: widget.today,
          footer: widget.footer,
          autofocus: true,
        );
      case KumoCalendarMode.range:
        return KumoCalendar.range(
          value: widget.rangeValue,
          onValueChange: widget.onRangeChange,
          min: widget.min,
          max: widget.max,
          required: widget.required,
          month: _month,
          onMonthChange: monthChanged,
          numberOfMonths: months,
          minDate: widget.minDate,
          maxDate: widget.maxDate,
          isDateDisabled: widget.isDateDisabled,
          today: widget.today,
          footer: widget.footer,
          autofocus: true,
        );
      case KumoCalendarMode.multiple:
        return KumoCalendar.multiple(
          value: widget.multipleValue,
          onValueChange: widget.onMultipleChange,
          min: widget.min,
          max: widget.max,
          required: widget.required,
          month: _month,
          onMonthChange: monthChanged,
          numberOfMonths: months,
          minDate: widget.minDate,
          maxDate: widget.maxDate,
          isDateDisabled: widget.isDateDisabled,
          today: widget.today,
          footer: widget.footer,
          autofocus: true,
        );
    }
  }

  Widget _panel(BuildContext context, bool inSheet) {
    // Resolve the browsed month once per open, from the value.
    _month ??= kumoFirstOfMonth(
      switch (widget.mode) {
            KumoCalendarMode.single => widget.singleValue,
            KumoCalendarMode.range => widget.rangeValue?.from,
            KumoCalendarMode.multiple => widget.multipleValue.isEmpty ? null : widget.multipleValue.first,
          } ??
          widget.today ??
          clock.now(),
    );
    final presets = widget.mode == KumoCalendarMode.range ? widget.presets : const <KumoDatePickerPreset>[];
    final calendar = _calendar(context, inSheet: inSheet);
    if (!inSheet) {
      final padded = Padding(padding: const EdgeInsets.all(KumoSpace.s3), child: calendar);
      if (presets.isEmpty) return padded;
      // The divider sits on the calendar side, which is the taller of the
      // two, so it runs the full height without measuring intrinsics.
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(KumoSpace.s2),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: KumoSpace.s1,
                children: [
                  for (final p in presets)
                    _PresetButton(preset: p, active: _isActive(p), onPress: () => _applyPreset(p)),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: context.kumo.colors.hairline)),
            ),
            child: padded,
          ),
        ],
      );
    }

    final strings = context.kumoStrings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KumoSpace.s4, KumoSpace.s2, KumoSpace.s4, KumoSpace.s4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s4,
          children: [
            if (widget.label != null) Text(widget.label!, style: context.kumo.heading()),
            if (presets.isNotEmpty)
              Wrap(
                spacing: KumoSpace.s1,
                runSpacing: KumoSpace.s1,
                children: [
                  for (final p in presets)
                    _PresetButton(preset: p, active: _isActive(p), onPress: () => _applyPreset(p)),
                ],
              ),
            Center(child: calendar),
            Row(
              spacing: KumoSpace.s2,
              children: [
                if (widget.clearable)
                  Expanded(
                    child: KumoButton(label: strings.clear, block: true, onPress: _hasValue ? _clear : null),
                  ),
                Expanded(
                  child: KumoButton(
                    label: widget.doneLabel ?? context.kumoStrings.done,
                    variant: KumoButtonVariant.primary,
                    block: true,
                    onPress: () => KumoSheetScope.closeFrom(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isActive(KumoDatePickerPreset preset) {
    final value = widget.rangeValue;
    if (value == null || value.to == null) return false;
    return preset.range(kumoDay(widget.today ?? clock.now())) == value;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final display = _display(strings);
    final placeholder = widget.placeholder ?? (widget.mode == KumoCalendarMode.single ? context.kumoStrings.pickDate : context.kumoStrings.pickDates);
    final trigger = KumoDatesPanelHost(
      open: _open && !widget.disabled,
      onOpenChange: _setOpen,
      presentation: widget.presentation,
      sheetLabel: widget.label ?? widget.semanticLabel ?? placeholder,
      popoverPadding: EdgeInsets.zero,
      panelBuilder: _panel,
      child: KumoDatesTrigger(
        size: widget.size,
        icon: KumoIcons.calendarDots,
        text: display,
        placeholder: placeholder,
        open: _open,
        error: widget.error != null,
        disabled: widget.disabled,
        semanticLabel: widget.label ?? widget.semanticLabel ?? placeholder,
        onPress: () => _setOpen(!_open),
        onClear: widget.clearable && _hasValue && !widget.disabled ? _clear : null,
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

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.preset, required this.active, required this.onPress});

  final KumoDatePickerPreset preset;
  final bool active;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final radius = BorderRadius.circular(KumoRadius.md);
    return KumoPressable(
      onPress: onPress,
      selected: active,
      borderRadius: radius,
      minTapTargetSize: kumo.minTapTarget > 0 ? 40 : 0,
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s1_5),
        decoration: BoxDecoration(
          color: active ? kumo.colors.contrast : (state.active ? kumo.colors.control : null),
          borderRadius: radius,
        ),
        child: Text(
          preset.label,
          maxLines: 1,
          softWrap: false,
          style: kumo.text(
            size: KumoTextSize.sm,
            color: active ? KumoColor.textInverse : KumoColor.textSubtle,
            weight: active ? KumoTypography.medium : KumoTypography.normal,
          ),
        ),
      ),
    );
  }
}
