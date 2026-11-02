# KumoTimePicker

A time field that opens a picker: scrolling columns in a popover on wide screens, snapping wheels in a bottom sheet on phones. Kumo has no time component; this follows shadcn's time picker in Kumo's field style.

Kumo reference: https://kumo-ui.com/components/date-picker (field and popover styling)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTimePicker(
  label: 'Cron trigger time',
  value: runAt,
  onValueChange: (time) => setState(() => runAt = time),
)
```

## When to use / when not to

Use it when people choose a time from a set (a schedule, a maintenance slot), especially on touch. Use `KumoTimeInput` when people type exact times, such as log timestamps.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `KumoTimeValue?` | | The time shown |
| `onValueChange` | `ValueChanged<KumoTimeValue?>?` | | Called on every column or wheel change, and with `null` from Clear |
| `use24Hour` | `bool` | `false` | 00-23 hours instead of 1-12 with AM/PM |
| `showSeconds` | `bool` | `false` | Adds a seconds column |
| `minuteStep` | `int` | `1` | Minutes listed (15 lists 00, 15, 30, 45). 1 to 30 |
| `label`, `description`, `error` | `String?` | | Rendered through `KumoField` |
| `placeholder` | `String?` | `KumoStrings.pickTime` | |
| `size` | `KumoFieldSize` | `base` | |
| `disabled` | `bool` | `false` | |
| `clearable` | `bool` | `true` | Clear button in the field |
| `presentation` | `KumoPresentation` | `auto` | Popover, or bottom sheet below 768px |
| `open`, `onOpenChange` | `bool?`, `ValueChanged<bool>?` | | Control the panel from outside |
| `labels` | `KumoTimeLabels` | from `KumoStrings` | Column names (`hours`, `minutes`, `seconds`, `dayPeriod`), AM/PM text, Done (`done`) |
| `showOptional`, `required` | `bool` | `false` | Label markers |
| `semanticLabel` | `String?` | | Accessible name without a `label` |

`KumoTimeValue(hour:, minute:, second:)` is a time of day with `hour` 0-23, `hour12`, `isPm`, `format(use24Hour:, showSeconds:, am:, pm:)`, `on(day)` to build a `DateTime`, `KumoTimeValue.fromDateTime` and `KumoTimeValue.now()` (from `clock.now()`).

## Examples

### 24-hour with seconds

```dart
KumoTimePicker(
  label: 'Purge cache at (UTC)',
  use24Hour: true,
  showSeconds: true,
  value: purgeAt,
  onValueChange: (time) => setState(() => purgeAt = time),
)
```

### 15-minute slots with validation

```dart
KumoTimePicker(
  label: 'Maintenance slot',
  minuteStep: 15,
  value: slot,
  error: slot != null && slot!.hour < 6 ? 'Pick a slot after 6:00 AM.' : null,
  onValueChange: (time) => setState(() => slot = time),
)
```

### Translated labels

```dart
KumoTimePicker(
  labels: const KumoTimeLabels(hour: 'Jam', minute: 'Menit', done: 'Selesai'),
  use24Hour: true,
  value: time,
  onValueChange: (t) => setState(() => time = t),
)
```

## Accessibility

- The field is a button with the label, the formatted time as value and expanded state.
- In the popover each column is one Tab stop announced as an adjustable value ("Minutes, 30") with increase and decrease actions. Arrow Up and Down change it, Home and End jump to the ends, Enter closes, Escape closes and returns focus to the field.
- Wheels in the sheet are adjustable values too, so screen reader swipe up and down turns them.
- The selected option is filled with `contrast`, not only colored.

## Motion

- The field shows its focus ring on pointer-down, before the panel opens.
- Popover columns scroll the chosen value into view only when it is out of view, so a click never moves the row under the pointer.
- Wheels follow the finger 1:1; on release the velocity carries them and they snap to the nearest value (`FixedExtentScrollPhysics`), with a selection haptic on each value. Hours and minutes loop like a clock. A wheel drag never drags the sheet.
- The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.
- Reduced motion: column and wheel adjustments jump instead of animating.

## Mobile

- Below 768px the picker is a bottom sheet with the label as heading, one wheel per part over a tinted selection band, and Clear and Done. Done on an empty value commits the time the wheels show (the current time on the minute grid).
- Wheel rows are 44px tall.

## Kumo React mapping

Kumo has no time picker. The closest pieces:

| Kumo / shadcn | Flutter parameter |
| --- | --- |
| Kumo `Input` field chrome | `KumoFieldBox` trigger (`size`, `error`, `disabled`) |
| Kumo `Popover` | popover panel (`presentation`) |
| shadcn `use24HourFormat` | `use24Hour` |
| shadcn `showSeconds` | `showSeconds` |
| shadcn `value`, `onChanged` | `value`, `onValueChange` |
