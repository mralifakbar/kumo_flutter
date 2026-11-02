# KumoCalendar

The month grid of Kumo's `DatePicker`, for picking one day, a run of days or a set of days, inline on a page or inside your own panel.

Kumo reference: https://kumo-ui.com/components/date-picker

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoCalendar.single(
  padding: const EdgeInsets.all(KumoSpace.s3),
  value: renewal,
  onValueChange: (day) => setState(() => renewal = day),
)
```

## When to use / when not to

Use `KumoCalendar` when the calendar should stay on screen (a scheduling page, a booking panel) or inside a container you build. For a form field that opens a calendar, use `KumoDatePicker`. For keyboard-first entry of a known date, use `KumoDateInput`.

## Parameters

Three constructors keep the value typed: `KumoCalendar.single`, `KumoCalendar.range` and `KumoCalendar.multiple`.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `DateTime?` / `KumoDateRange?` / `List<DateTime>` | `null` / `null` / `const []` | The selection, per constructor. Only the day is used |
| `onValueChange` | `ValueChanged<DateTime?>?` / `ValueChanged<KumoDateRange?>?` / `ValueChanged<List<DateTime>>?` | | Called with the next selection. Null makes the days read-only |
| `min` | `int?` | | Range: fewest nights. Multiple: fewest days. Not on `single` |
| `max` | `int?` | | Range: most nights (a longer pick restarts the range). Multiple: most days (the other days become disabled). Not on `single` |
| `required` | `bool` | `false` | Tapping the only selected day does not clear it |
| `month` | `DateTime?` | | First shown month when the parent controls browsing |
| `initialMonth` | `DateTime?` | | First shown month when `month` is null. Defaults to the selection's month, then today's |
| `onMonthChange` | `ValueChanged<DateTime>?` | | First shown month after a swipe, nav button or keyboard move |
| `numberOfMonths` | `int` | `1` | Side by side when they fit, stacked otherwise |
| `showOutsideDays` | `bool?` | `numberOfMonths == 1` | Days of the adjacent months that fill the first and last week |
| `fixedWeeks` | `bool` | `false` | Always six weeks, so the height never changes |
| `minDate`, `maxDate` | `DateTime?` | | Earliest and latest pickable day; browsing stops at their months |
| `isDateDisabled` | `bool Function(DateTime)?` | | Days that can not be picked |
| `disabled` | `bool` | `false` | Blocks every interaction, dims the calendar |
| `today` | `DateTime?` | `clock.now()` | The day marked as today |
| `footer` | `Widget?` | | Under the months, as wide as the calendar, 12px subtle text |
| `autofocus` | `bool` | `false` | Focus the selected day (or today) on first build |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.zero` | Kumo's calendar has no padding; demos use `p-3` (12px) |
| `semanticLabel` | `String?` | | Accessible name of the whole calendar |

`KumoDateRange` holds `from` (required) and `to` (null while only the start is picked), with `isComplete`, `nights` and `contains(day)`. Equality compares days only.

## Examples

### Range across two months

```dart
KumoCalendar.range(
  padding: const EdgeInsets.all(KumoSpace.s3),
  numberOfMonths: 2,
  value: period,
  onValueChange: (range) => setState(() => period = range),
)
```

Range taps follow react-day-picker: the first tap picks a one-day range, a later tap after the start moves the end, a tap before the start moves the start.

### Range of 3 to 7 nights from today

```dart
KumoCalendar.range(
  value: stay,
  min: 3,
  max: 7,
  minDate: DateTime.now(),
  footer: const Text('Select 3-7 nights'),
  onValueChange: (range) => setState(() => stay = range),
)
```

### Multiple days with a limit and unavailable days

```dart
KumoCalendar.multiple(
  value: maintenanceDays,
  max: 5,
  fixedWeeks: true,
  isDateDisabled: (day) => day.weekday == DateTime.saturday || day.weekday == DateTime.sunday,
  footer: Text('${maintenanceDays.length}/5 days selected. Grayed dates are unavailable.'),
  onValueChange: (days) => setState(() => maintenanceDays = days),
)
```

### Controlled month

Pass `month` and `onMonthChange` to move the calendar from outside, for example to the start of a preset range.

```dart
KumoCalendar.range(
  value: period,
  month: shownMonth,
  onMonthChange: (month) => setState(() => shownMonth = month),
  onValueChange: (range) => setState(() => period = range),
)
```

### Week starting on Monday

Weeks start on `KumoStrings.firstDayOfWeek` (Sunday by default, like Kumo). Month and weekday names come from `KumoStrings` too.

```dart
KumoLocale(
  strings: const KumoStrings(firstDayOfWeek: DateTime.monday),
  child: KumoCalendar.single(value: day, onValueChange: (d) => setState(() => day = d)),
)
```

## Accessibility

- Each day is a button announced as `KumoStrings.fullDate` ("Wednesday, March 4, 2026"), with ", Today" for today, and selected and enabled state. Disabled days are announced as disabled.
- The month caption is a header and a live region, so month changes are read out.
- The grid is one Tab stop (the focused, selected, today or first available day), after the previous and next month buttons. Arrow keys move by day and week (left and right flip in RTL), Page Up and Page Down by month, Shift+Page Up and Down by year, Home and End to the start and end of the week, Enter and Space select. Moving past the shown months changes month. Unavailable days are skipped.
- Today is semibold link blue; selected days are filled with `contrast`; disabled and outside days use `text-inactive`.

## Motion

- Changing month with the buttons or keyboard slides the weeks in the direction of travel while the caption fades (Kumo's `rdp-weeks` slide, 200ms ease-out). A jump of several months slides the month left behind out. A press while a slide is still running continues from where the leaving month is, instead of recentering it first.
- On touch, the weeks follow a horizontal swipe 1:1. On release the velocity is projected forward: past half a month width the next or previous month springs in from where the finger left it (with a selection haptic), otherwise the grid springs back. At `minDate` or `maxDate` the grid rubberbands.
- A slide can be grabbed mid-flight.
- Reduced motion: no slide; the new month cross-fades in over 100ms.

## Mobile

- With a touch target size (`KumoTapTargetSize.padded`) day squares grow from 32px to 40px in 44px slots, so each day is a 44x44 target.
- Squares grow with the text scale (up to 1.6x) and shrink to fit narrow widths; several months stack vertically when they do not fit side by side.
- Swipe changes months on touch only; mouse drags select as clicks.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `mode="single" \| "range" \| "multiple"` | `KumoCalendar.single` / `.range` / `.multiple` |
| `selected` | `value` |
| `onChange` | `onValueChange` |
| `required` | `required` |
| `min`, `max` | `min`, `max` |
| `numberOfMonths` | `numberOfMonths` |
| `showOutsideDays` | `showOutsideDays` |
| `fixedWeeks` | `fixedWeeks` |
| `disabled` (matcher) | `isDateDisabled`, `minDate`, `maxDate` |
| `startMonth`, `endMonth` | `minDate`, `maxDate` (months) |
| `month`, `onMonthChange`, `defaultMonth` | `month`, `onMonthChange`, `initialMonth` |
| `today` | `today` |
| `footer` | `footer` |
| `weekStartsOn`, `locale` | `KumoStrings.firstDayOfWeek`, `KumoLocale` |
| `autoFocus` | `autofocus` |
| `className="p-3"` | `padding` |
| `captionLayout="dropdown"` | not ported; use the nav buttons, Page Up/Down or `month` |
