# KumoSlider

Kumo's `Slider`: pick a number, or a range between two numbers, by dragging a thumb along a recessed track. The value shows in a badge under each thumb, with the min and max at the ends.

Kumo reference: https://kumo-ui.com/components/slider

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoSlider(
  label: 'Edge cache TTL (minutes)',
  value: ttl,
  onValueChange: (value) => setState(() => ttl = value),
)
```

## When to use / when not to

Use a slider when an approximate value within a known range is fine and seeing it change helps (a sampling rate, a TTL). When people need an exact number, use a number input. The track, badges and end labels are laid out for a horizontal slider only, as in Kumo.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `double` | required (single) | The value of a one-thumb slider |
| `onValueChange` | `ValueChanged<double>?` | | Called while the value changes, snapped to `step`. Null disables the slider |
| `onValueCommitted` | `ValueChanged<double>?` | | Called once when a drag, tap or key press finishes |
| `values` | `KumoSliderRange` | required (`.range`) | `(start: 25, end: 75)` |
| `onValuesChange` | `ValueChanged<KumoSliderRange>?` | | Range form of `onValueChange` |
| `onValuesCommitted` | `ValueChanged<KumoSliderRange>?` | | Range form of `onValueCommitted` |
| `min`, `max` | `double` | `0`, `100` | |
| `step` | `double` | `1` | Granularity; values snap to `min + n * step` |
| `largeStep` | `double` | `10` | Page Up/Down and Shift+arrow, in value units |
| `size` | `KumoSliderSize` | `base` | `sm` 24px track (12px text), `base` 32px (13px text) |
| `label` | `String?` | | Medium label above the track; also the thumbs' accessible name |
| `disabled` | `bool` | `false` | 50% opacity, no input, not focusable |
| `format` | `KumoSliderFormat?` | decimals of `step` | Formats the badge, end labels and the announced value |
| `thumbSemanticLabel` | `String Function(int index)?` | | Accessible name per thumb (0 is the start thumb) |

## Examples

### Range

```dart
KumoSlider.range(
  label: 'Response time (ms)',
  values: window,
  max: 1000,
  step: 10,
  thumbSemanticLabel: (i) => i == 0 ? 'Minimum response time' : 'Maximum response time',
  onValuesChange: (range) => setState(() => window = range),
)
```

### Formatted values

```dart
KumoSlider(
  label: 'Log sampling rate',
  value: rate,
  min: 0,
  max: 1,
  step: 0.05,
  format: (v) => '${(v * 100).round()}%',
  onValueChange: (v) => setState(() => rate = v),
)
```

### Save on release

```dart
KumoSlider(
  label: 'Retry attempts',
  value: retries,
  max: 5,
  onValueChange: (v) => setState(() => retries = v),
  onValueCommitted: (v) => saveRetries(v.round()),
)
```

## Accessibility

- Each thumb is a slider in the semantics tree with its label, formatted value, and increase and decrease actions (one `step`).
- The visible label, the badges and the end labels are hidden from screen readers, because each thumb already announces its name and value.
- Keyboard: Tab focuses each thumb in turn. Arrow keys move one `step` (Left and Right mirrored in RTL), Page Up/Down and Shift+arrow move `largeStep`, Home and End go to the ends (or to the other thumb of a range). Keyboard focus draws a 2px `focus` ring on the thumb, as Kumo does.

## Motion

- The thumb follows the finger 1:1, keeping the offset from where it was grabbed; a drag that starts on the track brings the thumb under the finger. Range thumbs never cross.
- The grip line darkens on pointer-down, so a held thumb answers before any drag starts.
- On release the thumb springs (`KumoSprings.standard`) onto the snapped step value. Taps on the track and value changes from outside (keys, the parent) spring from the thumb's current position. The value badge rides with the thumb throughout.
- When the slider has 20 steps or fewer, each step crossed during a drag gives a selection haptic.
- Reduced motion jumps the thumb to its value.

## Mobile

The gesture area covers the track and the label row below it (about 60px tall), so the hit area clears 44px. The drag recognizer starts after 8px instead of Flutter's 18px so the thumb does not stick under the finger. Badges stay inside the slider's width at the ends of the range, so they never spill off a phone screen.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `value` / `defaultValue` (number) | `value` (controlled only) |
| `value` (array) | `KumoSlider.range(values: ...)` |
| `onValueChange` | `onValueChange` / `onValuesChange` |
| `onValueCommitted` | `onValueCommitted` / `onValuesCommitted` |
| `min`, `max`, `step`, `largeStep` | same |
| `size` | `size` |
| `label` | `label` |
| `disabled` | `disabled` |
| `format`, `locale` (`Intl.NumberFormat`) | `format` (a function) |
| `getAriaLabel` | `thumbSemanticLabel` |
| `orientation` | not supported (Kumo forces horizontal) |
