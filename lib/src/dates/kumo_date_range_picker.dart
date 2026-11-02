import 'package:flutter/widgets.dart';

import '../system/kumo_field_box.dart';
import 'kumo_calendar.dart';
import 'kumo_date_picker.dart';

/// Kumo's deprecated `DateRangePicker`. Kumo replaced it with
/// `DatePicker mode="range"`; here it forwards every argument to
/// [KumoDatePicker.range], so existing code keeps working while it moves.
///
/// ```dart
/// // Before
/// KumoDateRangePicker(value: period, onValueChange: setPeriod)
/// // After
/// KumoDatePicker.range(value: period, onValueChange: setPeriod)
/// ```
@Deprecated('Use KumoDatePicker.range instead. Kumo deprecated DateRangePicker in favor of DatePicker mode="range".')
class KumoDateRangePicker extends StatelessWidget {
  @Deprecated('Use KumoDatePicker.range instead.')
  const KumoDateRangePicker({
    super.key,
    this.value,
    this.onValueChange,
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
    this.doneLabel,
    this.semanticLabel,
  });

  final KumoDateRange? value;
  final ValueChanged<KumoDateRange?>? onValueChange;
  final List<KumoDatePickerPreset> presets;
  final int? min;
  final int? max;
  final String? label;
  final String? description;
  final String? error;
  final String? placeholder;
  final KumoFieldSize size;
  final bool disabled;
  final bool clearable;
  final KumoPresentation presentation;
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool Function(DateTime day)? isDateDisabled;
  final int? numberOfMonths;
  final String Function(DateTime date)? formatDate;
  final Widget? footer;
  final DateTime? today;
  final String? doneLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => KumoDatePicker.range(
    value: value,
    onValueChange: onValueChange,
    presets: presets,
    min: min,
    max: max,
    label: label,
    description: description,
    error: error,
    placeholder: placeholder,
    size: size,
    disabled: disabled,
    clearable: clearable,
    presentation: presentation,
    open: open,
    onOpenChange: onOpenChange,
    minDate: minDate,
    maxDate: maxDate,
    isDateDisabled: isDateDisabled,
    numberOfMonths: numberOfMonths,
    formatDate: formatDate,
    footer: footer,
    today: today,
    doneLabel: doneLabel,
    semanticLabel: semanticLabel,
  );
}
