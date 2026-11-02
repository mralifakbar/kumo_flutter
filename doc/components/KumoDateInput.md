# KumoDateInput

Typed date entry with validation and a calendar button. Separators are inserted as you type, impossible or unavailable days show an inline error, and the button opens a `KumoCalendar`.

Kumo reference: https://kumo-ui.com/components/input (field styling) and https://kumo-ui.com/components/date-picker (calendar)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoDateInput(
  label: 'API token expires on',
  value: expiry,
  minDate: DateTime.now(),
  onValueChange: (day) => setState(() => expiry = day),
)
```

## When to use / when not to

Use it when people usually know the date (a birth date, an expiry from a contract) and typing is faster than browsing. Use `KumoDatePicker` when browsing a calendar is the common path, and for ranges.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `DateTime?` | | The day shown whenever the field is not being edited |
| `onValueChange` | `ValueChanged<DateTime?>?` | | A complete, real, allowed day, or `null` when the text is cleared |
| `format` | `KumoDateInputFormat` | `iso` | `iso` `YYYY-MM-DD`, `mdy` `MM/DD/YYYY`, `dmy` `DD/MM/YYYY` |
| `label`, `description` | `String?` | | Rendered through `KumoField` |
| `error` | `String?` | | Parent error; wins over the built-in messages |
| `placeholder` | `String?` | the format pattern | |
| `size` | `KumoFieldSize` | `base` | |
| `disabled` | `bool` | `false` | |
| `minDate`, `maxDate`, `isDateDisabled` | | | Allowed days, for typing and the calendar |
| `showCalendarButton` | `bool` | `true` | |
| `presentation` | `KumoPresentation` | `auto` | Calendar in a popover, or a bottom sheet below 768px |
| `invalidDateMessage` | `String?` | `'Enter a date as YYYY-MM-DD.'` (pattern of `format`) | For text that is not a real date |
| `unavailableDateMessage` | `String` | `'This date is not available. Pick another day.'` | For a real day outside the allowed days |
| `calendarButtonLabel` | `String?` | `KumoStrings.chooseDateFromCalendar` | Accessible name of the button |
| `autofocus`, `showOptional`, `required` | `bool` | `false` | |
| `semanticLabel` | `String?` | | Accessible name without a `label` |

`KumoDateInputFormat` also exposes `format(DateTime)`, `parse(String)` (null for incomplete text or days like February 30) and `pattern`.

## Examples

### Month-first, weekdays only

```dart
KumoDateInput(
  label: 'Launch date',
  format: KumoDateInputFormat.mdy,
  value: launch,
  isDateDisabled: (day) => day.weekday == DateTime.saturday || day.weekday == DateTime.sunday,
  unavailableDateMessage: 'Launches happen on weekdays. Pick Monday to Friday.',
  onValueChange: (day) => setState(() => launch = day),
)
```

### Without the calendar button

```dart
KumoDateInput(
  label: 'Date of incident',
  showCalendarButton: false,
  value: incident,
  onValueChange: (day) => setState(() => incident = day),
)
```

## Accessibility

- The text field is named by the label; the calendar button is a separate button with `calendarButtonLabel` and expanded state.
- Alt+Down opens the calendar from the field; focus moves to the selected day, Escape closes and returns focus.
- Errors appear once the text is complete, or on leaving the field or submitting while incomplete, and are announced by `KumoField` (a live region with a warning icon, not only red).

## Motion

The calendar popover and sheet animate as in `KumoDatePicker`; the field itself changes instantly. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once. A date error that appears while typing never takes focus away from the field.

## Mobile

- The field opens the date-time keyboard; only digits are kept.
- Below 768px the calendar opens in a bottom sheet and picking a day closes it.

## Kumo React mapping

Kumo has no typed date field; it combines Kumo's `Input` chrome with the `DatePicker` calendar.

| Kumo | Flutter parameter |
| --- | --- |
| `Input` `size`, `error`, `disabled`, `placeholder` | `size`, `error`, `disabled`, `placeholder` |
| `Field` `label`, `description` | `label`, `description` |
| `DatePicker` `disabled` matcher | `isDateDisabled`, `minDate`, `maxDate` |
