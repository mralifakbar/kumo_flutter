# KumoDatePicker

A date field that opens a `KumoCalendar`: Kumo's `DatePicker` composed with a `Popover`, as the Kumo docs show it, for single days, ranges with presets and sets of days.

Kumo reference: https://kumo-ui.com/components/date-picker

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoDatePicker.single(
  label: 'Certificate expiry',
  value: expiry,
  onValueChange: (day) => setState(() => expiry = day),
)
```

## When to use / when not to

Use it in forms and filters where a date is one field among others. Use `KumoCalendar` when the calendar should stay visible, and `KumoDateInput` when people usually know the date and type it.

## Parameters

Three constructors: `KumoDatePicker.single`, `KumoDatePicker.range` and `KumoDatePicker.multiple`.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `DateTime?` / `KumoDateRange?` / `List<DateTime>` | `null` / `null` / `const []` | The selection, per constructor |
| `onValueChange` | matching `ValueChanged` | | Called with the next selection (and `null` or `[]` from the clear button) |
| `presets` | `List<KumoDatePickerPreset>` | `const []` | `range` only. Shortcuts beside the calendar |
| `min`, `max` | `int?` | | `range`: nights. `multiple`: days. Not on `single` |
| `closeOnSelect` | `bool` | `true` | `single` only. Close when a day is picked |
| `label`, `description`, `error` | `String?` | | Rendered through `KumoField`; `error` also rings the field |
| `placeholder` | `String?` | `KumoStrings.pickDate` / `KumoStrings.pickDates` | Shown while nothing is picked |
| `size` | `KumoFieldSize` | `base` | `xs` 20, `sm` 26, `base` 36, `lg` 40px |
| `disabled` | `bool` | `false` | |
| `clearable` | `bool` | `true` | Clear button in the field while a value is set |
| `presentation` | `KumoPresentation` | `auto` | Popover on wide screens, bottom sheet below 768px |
| `open`, `onOpenChange` | `bool?`, `ValueChanged<bool>?` | | Control the panel from outside; otherwise it manages itself |
| `minDate`, `maxDate`, `isDateDisabled` | | | Passed to the calendar |
| `numberOfMonths` | `int?` | 2 for `range`, else 1 | Months in the popover. The sheet shows one and swipes |
| `formatDate` | `String Function(DateTime)?` | `KumoStrings.shortDate` | How each date reads in the field ("Mar 4, 2026") |
| `footer` | `Widget?` | | Under the calendar |
| `today` | `DateTime?` | `clock.now()` | Today mark, and the day presets count from |
| `showOptional`, `required` | `bool` | `false` | Label markers |
| `doneLabel` | `String?` | `KumoStrings.done` | Button that closes the sheet |
| `semanticLabel` | `String?` | | Accessible name when there is no `label` |

`KumoDatePickerPreset(label:, range:)` takes a function from today to a `KumoDateRange`, so it stays right across midnight. `KumoDatePickerPreset.kumoDefaults` holds Kumo's six: Today, Last 7 days, Last 30 days, Last 90 days, This month, Last month.

## Examples

### Range with presets

```dart
KumoDatePicker.range(
  label: 'Analytics period',
  value: period,
  maxDate: DateTime.now(),
  presets: KumoDatePickerPreset.kumoDefaults,
  onValueChange: (range) => setState(() => period = range),
)
```

Picking a preset sets the range and moves the calendar to its first month. The active preset is filled and announced as selected.

### Custom presets

```dart
KumoDatePicker.range(
  value: period,
  presets: [
    KumoDatePickerPreset(
      label: 'Last 14 days',
      range: (today) => KumoDateRange(from: today.subtract(const Duration(days: 13)), to: today),
    ),
  ],
  onValueChange: (range) => setState(() => period = range),
)
```

### Multiple days

```dart
KumoDatePicker.multiple(
  label: 'Deploy freeze days',
  value: freezeDays,
  max: 3,
  onValueChange: (days) => setState(() => freezeDays = days),
)
```

### Error

```dart
KumoDatePicker.single(
  label: 'Rollout starts',
  value: start,
  error: start == null ? 'Pick the first day of the rollout.' : null,
  onValueChange: (day) => setState(() => start = day),
)
```

### Always a popover

```dart
KumoDatePicker.single(
  presentation: KumoPresentation.popover,
  value: day,
  onValueChange: (d) => setState(() => day = d),
)
```

## Accessibility

- The field is a button named by the label, with the formatted value as its value and expanded state while open. The clear button is a separate button named `KumoStrings.clear`.
- Enter or Space opens the panel; focus moves to the selected day (or today) and stays trapped in the popover. Escape and outside taps close it and focus returns to the field.
- All calendar keyboard and screen reader behavior applies (see `KumoCalendar`).

## Motion

- The field shows its focus ring on pointer-down, before the panel opens. It has no caret to rotate.
- The popover opens and closes along the same path from the field (`KumoAnchoredOverlay`).
- The sheet follows the finger, snaps by velocity and dismisses with a flick down (`showKumoSheet`). Months inside it change with a horizontal swipe; see `KumoCalendar` for the month slide.
- The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.
- Reduced motion: fades only.

## Mobile

- Below 768px (`KumoPresentation.auto`) the calendar opens in a bottom sheet with the label as a heading, presets as wrapping chips, one month, and Clear and Done buttons. Values update live while the sheet is open.
- The field keeps its 36px look and pads its hit area to 44px on touch.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Popover>` + `<Popover.Trigger>` + `<DatePicker>` | `KumoDatePicker` (one widget) |
| `mode` | named constructor |
| `selected`, `onChange` | `value`, `onValueChange` |
| `numberOfMonths` | `numberOfMonths` |
| `min`, `max`, `disabled`, `footer` | `min`, `max`, `isDateDisabled`/`minDate`/`maxDate`, `footer` |
| Presets demo (`DatePickerRangeWithPresetsDemo`) | `presets`, `KumoDatePickerPreset.kumoDefaults` |
| Trigger text `toLocaleDateString()` | `formatDate` |
