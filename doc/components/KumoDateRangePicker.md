# KumoDateRangePicker

Deprecated. Kumo replaced `DateRangePicker` with `DatePicker mode="range"`; this alias forwards every argument to `KumoDatePicker.range` so code can move over gradually.

Kumo reference: https://kumo-ui.com/components/date-range-picker

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
// ignore: deprecated_member_use
KumoDateRangePicker(
  label: 'Log retention window',
  value: window,
  onValueChange: (range) => setState(() => window = range),
)
```

## When to use / when not to

Do not use it in new code. Replace it with `KumoDatePicker.range`, which takes the same arguments:

```dart
KumoDatePicker.range(
  label: 'Log retention window',
  value: window,
  onValueChange: (range) => setState(() => window = range),
)
```

## Parameters

The same as `KumoDatePicker.range`: `value`, `onValueChange`, `presets`, `min`, `max`, `label`, `description`, `error`, `placeholder`, `size`, `disabled`, `clearable`, `presentation`, `open`, `onOpenChange`, `minDate`, `maxDate`, `isDateDisabled`, `numberOfMonths`, `formatDate`, `footer`, `today`, `doneLabel`, `semanticLabel`. See [KumoDatePicker](KumoDatePicker.md).

## Examples

### With presets

```dart
// ignore: deprecated_member_use
KumoDateRangePicker(
  value: window,
  presets: KumoDatePickerPreset.kumoDefaults,
  onValueChange: (range) => setState(() => window = range),
)
```

## Accessibility

As `KumoDatePicker`.

## Motion

As `KumoDatePicker`.

## Mobile

As `KumoDatePicker`: a bottom sheet below 768px.

## Kumo React mapping

Kumo's deprecated component had its own uncontrolled API; the port keeps only the name and the controlled range API.

| Kumo prop | Flutter parameter |
| --- | --- |
| `onStartDateChange`, `onEndDateChange` | `onValueChange` with a `KumoDateRange` (`from`, `to`) |
| `size`, `variant` | not ported; the calendar follows `KumoDatePicker` |
| `timezone` | not ported; put it in `description` or `footer` |
| "Reset Dates" | the field's clear button and the sheet's Clear |
