# KumoMeter

Kumo's `Meter`: a labeled bar for a measured value within a known range, such as storage used or request quota.

Kumo reference: https://kumo-ui.com/components/meter

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoMeter(label: 'Storage used', value: 65)
```

## When to use / when not to

Use a meter for a level that can go up and down: quota, storage, memory. For work that finishes (an upload, a deployment) use `KumoProgress`. For a single figure without a range, use text.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | 12px subtle text above the track |
| `value` | `double` | required | Clamped to `min`..`max` |
| `min` | `double` | `0` | |
| `max` | `double` | `100` | |
| `customValue` | `String?` | | Replaces the percentage, for example `'750 / 1,000'` |
| `showValue` | `bool` | `true` | Shows the percentage next to the label (13px medium, tabular digits) |
| `tone` | `KumoMeterTone` | `brand` | Indicator color when no threshold applies: `brand`, `success`, `warning`, `danger` |
| `thresholds` | `List<KumoMeterThreshold>` | `[]` | Levels that switch the tone and add a status line |
| `indicatorColor` | `KumoColor?` | | Overrides the indicator color |

`KumoMeterThreshold(value:, tone:, label:)` applies once `value` is at or above its `value`; the highest matching threshold wins. Its `label` appears under the track with the tone's icon and text color, and is read by screen readers.

`KumoMeterTrack(fraction:, color:, height:)` is the bare 8px track and indicator, for table cells and compact cards.

## Examples

### Custom value

```dart
const KumoMeter(label: 'API requests', value: 750, max: 1000, customValue: '750 / 1,000')
```

### Thresholds

```dart
KumoMeter(
  label: 'R2 storage in assets',
  value: usedGb,
  max: 10,
  customValue: '${usedGb.toStringAsFixed(1)} / 10 GB',
  thresholds: const [
    KumoMeterThreshold(value: 8, tone: KumoMeterTone.warning, label: 'Approaching the 10 GB limit'),
    KumoMeterThreshold(value: 10, tone: KumoMeterTone.danger, label: 'Limit reached. Uploads are paused'),
  ],
)
```

### In a table cell

```dart
const SizedBox(width: 120, child: KumoMeterTrack(fraction: 0.42))
```

## Accessibility

The meter is one node: its label, with the value text (and the threshold label, if any) as the value, for example "R2 storage, 9 / 10 GB, Approaching the 10 GB limit". A state is never shown by color alone: every threshold writes its label under the track with an icon.

## Motion

When the value changes the indicator eases from its current width to the new one (300ms ease-out, Kumo's `transition-[width] duration-300 ease-out`). A change mid-animation continues from where the bar is. Crossing a threshold eases the indicator to its new tone at the same time. Under reduced motion the bar and tone jump.

## Mobile

The label and the value share one row; the label wraps at 2x text, the value stays whole. The status line wraps under the track.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `label` | `label` |
| `value`, `min`, `max` | `value`, `min`, `max` |
| `customValue` | `customValue` |
| `showValue` | `showValue` |
| `indicatorClassName="from-kumo-success ..."` | `tone: KumoMeterTone.success` or `indicatorColor:` |
| `trackClassName` | not ported; use `KumoMeterTrack` for custom layouts |

Addition: `thresholds` and `tone` are not in Kumo, whose meter is always brand blue.
