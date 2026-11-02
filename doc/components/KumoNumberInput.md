# KumoNumberInput

A numeric field with minus and plus steppers, bounds, decimals and keyboard stepping, in Kumo's input style. Use it for counts, ports, rates and durations.

Kumo has no number input of its own; this follows shadcn's feature set, drawn with Kumo's field chrome and compact ghost buttons (the same as `KumoInputGroupButton`). Kumo reference for the styling: https://kumo-ui.com/components/input

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoNumberInput(
  label: 'Max retries',
  value: retries,
  min: 0,
  max: 10,
  onValueChange: (v) => setState(() => retries = v),
)
```

## When to use / when not to

Use it for a number the user may type or nudge. For a value picked along a range by feel use `KumoSlider`; for an ID or a phone number (digits that are not quantities) use `KumoInput` with `keyboardType: TextInputType.number`.

## Behavior

- Steppers add or remove `step`. Holding one steps once at pointer-down, waits `repeatDelay` (400ms), then repeats every `repeatInterval` (60ms) until the finger lifts or a bound is reached. Release always stops it.
- ArrowUp and ArrowDown step; PageUp, PageDown and Shift+Arrow step by `largeStep` (ten steps by default).
- While typing, a number inside `min` and `max` is reported at once. Text that is not a number, or is out of range, shows the error ring and is not reported. On blur or submit it is clamped into range and rounded, or reverted to the last valid value if it is not a number. A lone `-` or `.` while typing is not flagged.
- Clearing the field reports `null`. Stepping from empty starts at `min` (or 0).
- Steps never drift (0.1 + 0.2 lands on 0.3): results are rounded to `fractionDigits`, or to the decimals of `step`.
- The default filter accepts digits, one decimal point (unless `fractionDigits` is 0) and a leading minus (only when `min` is null or negative).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `double?` | | The number, or null when empty |
| `onValueChange` | `ValueChanged<double?>?` | | Next number, or null when cleared |
| `min`, `max` | `double?` | | Bounds; steppers disable at them |
| `step` | `double` | `1` | Stepper and arrow-key amount |
| `largeStep` | `double?` | `step * 10` | PageUp, PageDown, Shift+Arrow |
| `fractionDigits` | `int?` | | Fixed decimals for display and rounding; null shows integers without decimals |
| `format` | `String Function(double)?` | | Custom display text; pair with `parse` and `inputFormatters` |
| `parse` | `double? Function(String)?` | | Reads typed text; return null for invalid |
| `size` | `KumoFieldSize` | `base` | |
| `label`, `labelTooltip`, `description`, `error` | `String?` | | As in `KumoInput` |
| `required`, `showOptional` | `bool` | `false` | |
| `placeholder`, `semanticLabel` | `String?` | | |
| `disabled`, `readOnly` | `bool` | `false` | Steppers and keys do nothing |
| `showSteppers` | `bool` | `true` | |
| `focusNode`, `autofocus` | | | |
| `textInputAction` | `TextInputAction?` | `done` | |
| `inputFormatters` | `List<TextInputFormatter>?` | | Replaces the default numeric filter |
| `onSubmitted` | `ValueChanged<double?>?` | | Called with the committed number |
| `repeatDelay` | `Duration` | `400ms` | Hold time before repeating |
| `repeatInterval` | `Duration` | `60ms` | Time between repeated steps |
| `scrollPadding` | `EdgeInsets` | `(20, 56, 20, 56)` | |

## Examples

### Decimals

```dart
KumoNumberInput(
  label: 'Sample rate',
  value: rate,
  min: 0,
  max: 1,
  step: 0.05,
  fractionDigits: 2,
  onValueChange: (v) => setState(() => rate = v),
)
```

### Required with validation

```dart
KumoNumberInput(
  label: 'Origin port',
  required: true,
  value: port,
  min: 1,
  max: 65535,
  error: port == null ? 'Enter a port.' : null,
  onValueChange: (v) => setState(() => port = v),
)
```

### Large steps and an empty default

```dart
KumoNumberInput(
  label: 'Cache TTL in seconds',
  showOptional: true,
  placeholder: 'Respect origin',
  value: ttl,
  min: 0,
  step: 60,
  largeStep: 3600,
  onValueChange: (v) => setState(() => ttl = v),
)
```

## Accessibility

- One text-field node named by the label, with increase and decrease actions (swipe up and down with TalkBack and VoiceOver) that announce the next value.
- The steppers are buttons named "Increase" and "Decrease" from `KumoStrings`. They stay out of the Tab order; the arrow keys step from the field.
- Errors mark the field invalid and are announced.

## Motion

A stepper press or arrow key lands the new number with a 4px rise (or drop, when decreasing) and fade over 150ms. While a stepper is held the repeats come faster than that, so the number just counts. Steppers press with the standard spring scale. The press-and-hold repeat runs only while a finger or pointer is down and stops at the bounds. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once. Under reduced motion the number does not move.

## Mobile

- The keyboard is numeric (`numberWithOptions`, signed and decimal as the bounds and `fractionDigits` allow).
- Stepper hit areas are 44px wide and as tall as the field, so the field keeps Kumo's height.
- The first step fires on pointer-down, not after release.

## Kumo React mapping

Kumo has no number input. It maps to the native `<Input type="number">` this way:

| HTML / Kumo | Flutter parameter |
| --- | --- |
| `type="number"` | `KumoNumberInput` |
| `min`, `max`, `step` | `min`, `max`, `step` |
| `value`, `onValueChange` | `value` (`double?`), `onValueChange` |
| `label`, `description`, `error`, `size`, `disabled`, `readOnly` | same names |
