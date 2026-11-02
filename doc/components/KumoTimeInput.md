# KumoTimeInput

A typed time field: hours, minutes and optionally seconds as separate parts in one Kumo field, with an AM/PM toggle in 12-hour mode. Kumo has no time component; this follows shadcn's time input in Kumo's field style.

Kumo reference: https://kumo-ui.com/components/input (field styling)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTimeInput(
  label: 'Backup window starts',
  value: start,
  onValueChange: (time) => setState(() => start = time),
)
```

## When to use / when not to

Use it when people type exact times or work from the keyboard. Use `KumoTimePicker` when picking from a set of times on touch matters more.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `KumoTimeValue?` | | Shown whenever the field is not being edited |
| `onValueChange` | `ValueChanged<KumoTimeValue?>?` | | Called with a complete time, or `null` when every part is cleared |
| `use24Hour` | `bool` | `false` | 00-23 hours, no AM/PM |
| `showSeconds` | `bool` | `false` | Adds a seconds part |
| `minuteStep` | `int` | `1` | Step for Arrow Up and Down in the minutes part (snaps to the grid) |
| `label`, `description`, `error` | `String?` | | Rendered through `KumoField` |
| `size` | `KumoFieldSize` | `base` | |
| `disabled` | `bool` | `false` | |
| `labels` | `KumoTimeLabels` | English | Accessible names of the parts, AM/PM text |
| `trailing` | `Widget?` | | Content at the end of the field |
| `autofocus` | `bool` | `false` | Focus the hour part on first build |
| `showOptional`, `required` | `bool` | `false` | Label markers |
| `semanticLabel` | `String?` | | Accessible name without a `label` |

See [KumoTimePicker](KumoTimePicker.md) for `KumoTimeValue`.

## Examples

### 24-hour with seconds

```dart
KumoTimeInput(
  label: 'Rate limit resets at',
  use24Hour: true,
  showSeconds: true,
  value: resetAt,
  onValueChange: (time) => setState(() => resetAt = time),
)
```

### Validating against another time

```dart
KumoTimeInput(
  label: 'Backup window ends',
  value: end,
  error: end != null && start != null && end!.compareTo(start!) <= 0 ? 'End the window after it starts.' : null,
  onValueChange: (time) => setState(() => end = time),
)
```

### Five-minute steps

```dart
KumoTimeInput(
  minuteStep: 5,
  value: start,
  onValueChange: (time) => setState(() => start = time),
)
```

## Accessibility

- Each part is a text field named by `KumoTimeLabels`, which default to `KumoStrings.hours`, `minutes` and `seconds` ("Hours", "Minutes", "Seconds"); the AM/PM toggle is a button named by `KumoStrings.dayPeriod` ("AM or PM") with the current period as its value.
- Typing fills a part and moves to the next once it is complete ("7" in the hour part is already 07); `:` also moves on. Arrow Up and Down step the focused part and wrap. Left and Right at the edge of a part move between parts, Backspace in an empty part goes back. In the AM/PM toggle, A and P (the first letter of the labels) set it, Up and Down flip it.
- Errors from `error` are shown and announced by `KumoField`.

## Motion

The field changes state instantly, like Kumo's inputs. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.

## Mobile

- Parts open the number keyboard. The AM/PM toggle has a 36px hit area on touch within the 36px field.
- At 2x text the parts grow with the text; the field keeps a minimum height and never clips.

## Kumo React mapping

Kumo has no time input.

| Kumo / shadcn | Flutter parameter |
| --- | --- |
| Kumo `Input` `size`, `error`, `disabled` | `size`, `error`, `disabled` |
| Kumo `Field` `label`, `description` | `label`, `description` |
| shadcn `use24HourFormat`, `showSeconds` | `use24Hour`, `showSeconds` |
