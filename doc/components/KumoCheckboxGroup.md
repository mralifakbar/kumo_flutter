# KumoCheckboxGroup

Kumo's `Checkbox.Group`: a legend over a set of checkboxes, with an error and a description below, controlled with the list of checked values.

Kumo reference: https://kumo-ui.com/components/checkbox

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoCheckboxGroup<String>(
  legend: 'Email alerts',
  description: 'Sent to the account owner.',
  value: alerts,
  onValueChange: (next) => setState(() => alerts = next),
  items: const [
    KumoCheckboxGroupItem(value: 'deploys', label: 'Failed deployments'),
    KumoCheckboxGroupItem(value: 'usage', label: 'Usage limits'),
  ],
)
```

## When to use / when not to

Use a group for several independent yes or no choices that belong together. For one choice out of several, use `KumoRadioGroup`. For a single checkbox, use `KumoCheckbox`. Use `appearance: KumoCheckboxAppearance.card` when each option needs a description.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoCheckboxGroupItem<T>>` | required | The options |
| `value` | `List<T>` | required | The checked values |
| `onValueChange` | `ValueChanged<List<T>>?` | | Next list; a newly checked value is appended. Null disables the group |
| `legend` | `String?` | | Group title (14px medium) |
| `hideLegend` | `bool` | `false` | Keep the legend for screen readers only |
| `description` | `String?` | | Helper text under the items |
| `error` | `String?` | | Error under the items (announced). Items switch to the error ring |
| `disabled` | `bool` | `false` | Disables every item |
| `orientation` | `Axis` | `vertical` | `horizontal` wraps items in rows; card groups become a two-column grid |
| `appearance` | `KumoCheckboxAppearance` | `base` | `card` joins items into one bordered surface |
| `controlFirst` | `bool?` | `true`, `false` for cards | Box before the label |

### KumoCheckboxGroupItem

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `T` | required | |
| `label` | `String` | required | |
| `description` | `String?` | | Helper text under the label |
| `disabled` | `bool` | `false` | |
| `variant` | `KumoCheckboxVariant?` | group's | Overrides the error ring for this item |
| `appearance` | `KumoCheckboxAppearance?` | group's | Overrides the group's appearance |

## Examples

### Validation

```dart
KumoCheckboxGroup<String>(
  legend: 'Email alerts',
  error: alerts.isEmpty ? 'Choose at least one alert.' : null,
  value: alerts,
  onValueChange: (next) => setState(() => alerts = next),
  items: const [
    KumoCheckboxGroupItem(value: 'deploys', label: 'Failed deployments'),
    KumoCheckboxGroupItem(value: 'tokens', label: 'Expiring API tokens'),
  ],
)
```

### Horizontal

```dart
KumoCheckboxGroup<String>(
  legend: 'Cached methods',
  orientation: Axis.horizontal,
  value: methods,
  onValueChange: (next) => setState(() => methods = next),
  items: const [
    KumoCheckboxGroupItem(value: 'GET', label: 'GET'),
    KumoCheckboxGroupItem(value: 'HEAD', label: 'HEAD'),
  ],
)
```

### Card grid

```dart
KumoCheckboxGroup<String>(
  legend: 'Where should this profile scan?',
  appearance: KumoCheckboxAppearance.card,
  orientation: Axis.horizontal,
  value: targets,
  onValueChange: (next) => setState(() => targets = next),
  items: const [
    KumoCheckboxGroupItem(value: 'web', label: 'Web traffic', description: 'Gateway HTTP policies.'),
    KumoCheckboxGroupItem(value: 'mail', label: 'Outbound email', description: 'Email leaving your organization.'),
  ],
)
```

## Accessibility

- Each item is a checkbox with its own Tab stop; Space toggles it.
- The legend is read before the items. With `hideLegend` it is not drawn but stays in the semantics tree.
- The error is a live region and is always text, never color alone.

## Motion

Items use `KumoCheckbox`'s motion: the box presses in on pointer-down, and the check mark scales in over 150ms on `KumoCurves.bounce`. Both are static under reduced motion.

## Mobile

On touch every row is padded to a 44px hit area, so single-line rows drop Kumo's 8px gap (the padding already separates them); rows with descriptions keep it. Horizontal card groups keep two columns at 390px and their text wraps.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `legend` / `Checkbox.Legend` | `legend` |
| `Checkbox.Legend className="sr-only"` | `hideLegend: true` |
| `value` / `defaultValue` | `value` (controlled only) |
| `onValueChange` | `onValueChange` |
| `error`, `description` | `error`, `description` |
| `disabled` | `disabled` |
| `orientation` | `orientation` (`Axis`) |
| `appearance` | `appearance` |
| `controlFirst` | `controlFirst` |
| `Checkbox.Item` | `KumoCheckboxGroupItem` |
| `allValues` (parent checkbox) | not ported; build it with `KumoCheckbox(indeterminate: ...)` |
