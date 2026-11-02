# KumoRadioGroup

Kumo's `Radio.Group`: a legend over mutually exclusive `KumoRadio` items, as circles, choice cards or a compact segmented bar.

Kumo reference: https://kumo-ui.com/components/radio

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoRadioGroup<String>(
  legend: 'Caching level',
  value: level,
  onValueChange: (next) => setState(() => level = next),
  items: const [
    KumoRadio(value: 'basic', label: 'No query string'),
    KumoRadio(value: 'simplified', label: 'Ignore query string'),
    KumoRadio(value: 'aggressive', label: 'Standard'),
  ],
)
```

## When to use / when not to

Use a radio group for exactly one choice out of a few visible options. Use `segmented` only for a small group of short labels that fits on one line (`1h`, `12h`, `24h`); use the default appearance for long labels, descriptions, many options or narrow layouts. When the choice switches which content panel is shown, use tabs. For many options, use a select.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoRadio<T>>` | required | The options |
| `value` | `T?` | required | Selected value; null for none |
| `onValueChange` | `ValueChanged<T>?` | | Called with the newly selected value. Null disables the group |
| `legend` | `String?` | | Group title (14px medium) |
| `hideLegend` | `bool` | `false` | Keep the legend for screen readers only |
| `description` | `String?` | | Helper text under the items |
| `error` | `String?` | | Error under the items (announced). Items switch to the error ring |
| `orientation` | `Axis` | `vertical` | `horizontal` wraps items in rows; cards become a two-column grid. Segmented is always one row |
| `appearance` | `KumoRadioAppearance` | `base` | `base`, `card`, `segmented` |
| `controlPosition` | `KumoRadioControlPosition?` | `start`, `end` for cards | Circle before or after the label |
| `disabled` | `bool` | `false` | Disables every item |

See `KumoRadio` for the item parameters.

## Examples

### Segmented

```dart
KumoRadioGroup<String>(
  legend: 'Time range',
  appearance: KumoRadioAppearance.segmented,
  value: range,
  onValueChange: (next) => setState(() => range = next),
  items: const [
    KumoRadio(value: '1h', label: '1h'),
    KumoRadio(value: '12h', label: '12h'),
    KumoRadio(value: '24h', label: '24h'),
  ],
)
```

### Cards

```dart
KumoRadioGroup<String>(
  legend: 'Plan',
  appearance: KumoRadioAppearance.card,
  value: plan,
  onValueChange: (next) => setState(() => plan = next),
  items: const [
    KumoRadio(value: 'free', label: 'Free', description: 'For personal projects and testing.'),
    KumoRadio(value: 'pro', label: 'Pro', description: 'Image optimization and more page rules.'),
  ],
)
```

### Error

```dart
KumoRadioGroup<String>(
  legend: 'Data localization region',
  error: region == null ? 'Choose where logs are stored.' : null,
  value: region,
  onValueChange: (next) => setState(() => region = next),
  items: const [
    KumoRadio(value: 'us', label: 'United States'),
    KumoRadio(value: 'eu', label: 'European Union'),
  ],
)
```

## Accessibility

- The items sit in a radio group; each is announced as a radio button with its checked state and label.
- Tab reaches the group once: at the selected item, or the first enabled item when nothing is selected. Tab again leaves the group.
- Arrow keys move the selection to the previous or next enabled item, wrapping at the ends (Left and Right are mirrored in RTL). Home and End select the first and last enabled items. Disabled items are skipped.
- Keyboard focus draws a 2px brand ring on the circle (inside the segment for segmented groups).

## Motion

- Base and card items: the inner dot lands with `KumoCurves.bounce` over 150ms when an item becomes selected and disappears at once from the old item. The circle presses in to 0.9 on pointer-down.
- Segmented: the dark fill slides from the previous segment to the new one with `KumoSprings.standard`, starting from where it is, so a tap mid-slide retargets it without a jump. Labels blend from the default to the inverse color as the fill covers them, and the seams hide while the fill passes. Clearing or setting the value from none fades the fill in place. A selection haptic marks each change.
- Reduced motion: the dot appears at once, the circle does not scale, and the segmented fill moves at once.

## Mobile

Rows are padded to 44px hit areas on touch (single-line rows drop the 8px gap; rows with descriptions keep it). Segmented bars keep Kumo's 34px visual height while each segment's hit area extends to 44px above and below. A segmented bar never wraps; when it is wider than the screen it scrolls sideways instead of overflowing.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `legend` / `Radio.Legend` | `legend` |
| `Radio.Legend className="sr-only"` | `hideLegend: true` |
| `value` / `defaultValue` | `value` (controlled only) |
| `onValueChange(value, details)` | `onValueChange(value)` |
| `orientation` | `orientation` (`Axis`) |
| `appearance` | `appearance` |
| `controlPosition` | `controlPosition` |
| `error`, `description`, `disabled` | same |
| `name` | not ported (no HTML forms) |
| `Radio.Item` | `KumoRadio` |
