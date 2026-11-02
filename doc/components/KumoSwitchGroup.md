# KumoSwitchGroup

Kumo's `Switch.Group`: a legend over related `KumoSwitch`es, each with its own value, with an error and a description below.

Kumo reference: https://kumo-ui.com/components/switch

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoSwitchGroup(
  legend: 'Notifications',
  description: 'Delivered to the account owner.',
  children: [
    KumoSwitch(label: 'Deploy failures', checked: failures, onCheckedChange: (v) => setState(() => failures = v)),
    KumoSwitch(label: 'Weekly usage report', checked: report, onCheckedChange: (v) => setState(() => report = v)),
  ],
)
```

## When to use / when not to

Use it to title a few switches that belong together on a settings page. Each switch stays independently controlled. For a set of choices saved together with a form, use `KumoCheckboxGroup`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | Usually `KumoSwitch`es |
| `legend` | `String?` | | Group title (14px medium) |
| `hideLegend` | `bool` | `false` | Keep the legend for screen readers only |
| `description` | `String?` | | Helper text under the switches |
| `error` | `String?` | | Error under the switches, announced |
| `disabled` | `bool` | `false` | Disables every switch in the group |
| `controlFirst` | `bool` | `true` | Default for switches that do not set their own |

## Examples

### Label first, disabled

```dart
KumoSwitchGroup(
  legend: 'Managed settings',
  controlFirst: false,
  disabled: true,
  children: [
    KumoSwitch(label: 'Enforced by policy', checked: true, onCheckedChange: (_) {}),
  ],
)
```

## Accessibility

Each switch keeps its own Tab stop and announcement. The legend is read before them; the error is a live region.

## Motion

See `KumoSwitch`.

## Mobile

On touch, switch rows are padded to 44px hit areas, which replace Kumo's 8px gap between rows.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `legend` / `Switch.Legend` | `legend` |
| `Switch.Legend className="sr-only"` | `hideLegend: true` |
| `error`, `description`, `disabled` | same |
| `controlFirst` | `controlFirst` |
| `children` (`Switch.Item`) | `children` (`KumoSwitch`) |
