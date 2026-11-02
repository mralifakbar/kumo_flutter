# KumoRadio

Kumo's `Radio.Item`: one option of a `KumoRadioGroup`. It is only valid as an item of a group, which supplies its selection, focus and appearance.

Kumo reference: https://kumo-ui.com/components/radio

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoRadio(value: 'standard', label: 'Standard', description: 'Cached at every data center.')
```

## When to use / when not to

Always inside `KumoRadioGroup.items`. A lone radio makes no sense; for a single yes or no choice use `KumoCheckbox` or `KumoSwitch`. Placing a `KumoRadio` outside a group asserts in debug builds.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `T` | required | The value the group reports when this item is chosen |
| `label` | `String` | required | Label text and accessible name |
| `labelWidget` | `Widget?` | | Custom label; `label` stays the accessible name |
| `description` | `String?` | | Helper text under the label (base and card appearances) |
| `disabled` | `bool` | `false` | Skipped by arrow keys, dimmed to 50% |
| `variant` | `KumoRadioVariant?` | group's | `error` red ring for this item only |
| `appearance` | `KumoRadioAppearance?` | group's | Overrides a `base` or `card` group; `segmented` is group-only |

## Examples

### Mixed appearances

```dart
KumoRadioGroup<String>(
  legend: 'Origin',
  value: origin,
  onValueChange: (next) => setState(() => origin = next),
  items: const [
    KumoRadio(value: 'r2', label: 'R2 bucket'),
    KumoRadio(
      value: 'custom',
      label: 'Custom origin',
      description: 'Any HTTPS server you run.',
      appearance: KumoRadioAppearance.card,
    ),
  ],
)
```

## Accessibility

Announced as a radio button in a radio group with its checked state. See `KumoRadioGroup` for keyboard behavior.

## Motion

The 8px inner dot lands with `KumoCurves.bounce` (150ms) when selected, and the circle presses in to 0.9 with a press spring while the row is held. In a segmented group the selected fill slides between segments (see `KumoRadioGroup`). Static under reduced motion.

## Mobile

The circle stays 16px; the whole row is the hit area, padded to 44px tall on touch.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `value` | `value` |
| `label` | `label` / `labelWidget` |
| `description` | `description` |
| `disabled` | `disabled` |
| `variant` | `variant` |
| `appearance` | `appearance` |
