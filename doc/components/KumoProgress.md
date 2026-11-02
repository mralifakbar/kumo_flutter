# KumoProgress

Linear and circular progress for work that finishes: an upload, a deployment, a migration.

Kumo reference: none. Kumo has no progress component; this one is inspired by shadcn's progress and built from `KumoMeter`'s track and indicator tokens.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoProgress(value: uploaded, max: total, label: 'Uploading assets', showValue: true)
```

## When to use / when not to

Use it when work is running and you know (or will soon know) how much is done. Pass a `value` whenever the amount is known. A null `value` is indeterminate: show it only while the work runs (preparing, waiting for the first byte) and replace or remove it when the work ends.

For a level that goes up and down (quota, storage) use `KumoMeter`. For a short wait inside a button use `KumoButton(loading: true)`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `double?` | | Work done, 0 to `max`. Null is indeterminate |
| `max` | `double` | `100` | |
| `variant` | `KumoProgressVariant` | `linear` | `linear` or `circular` |
| `size` | `KumoProgressSize` | `base` | `sm` (4px track, 16px ring), `base` (8px, 24px), `lg` (12px, 40px) |
| `label` | `String?` | | What is in progress, 12px subtle text |
| `showValue` | `bool` | `false` | Shows the percentage. Ignored while indeterminate |
| `tone` | `KumoMeterTone` | `brand` | Indicator color: `brand`, `success`, `warning`, `danger` |
| `semanticLabel` | `String?` | | Accessible name without a visible label. Defaults to `KumoStrings.loading` |

## Examples

### Preparing, then uploading

```dart
KumoProgress(
  value: preparing ? null : percent,
  label: preparing ? 'Preparing 1,204 objects' : 'Uploading to assets',
  showValue: true,
)
```

### Circular

```dart
const KumoProgress(value: 35, variant: KumoProgressVariant.circular, label: 'Migrating tables', showValue: true)
```

### Finished

```dart
const KumoProgress(value: 100, label: 'Uploaded to assets', showValue: true, tone: KumoMeterTone.success)
```

## Accessibility

One node with the label (or `semanticLabel`) and the percentage as its value. Indeterminate progress has no value. Write the finished state in the label ("Uploaded to assets") rather than relying on the green tone.

## Motion

Determinate changes ease from the current value (300ms ease-out). Switching between indeterminate and measured cross-fades the indicator (150ms). Linear indeterminate progress slides a 40% segment across the track every 1.5s; circular indeterminate progress is `KumoLoader`. Both loops run only while the widget is mounted and on screen (`TickerMode`), and only while `value` is null. Under reduced motion the linear track shows a still, half-strength bar, the ring a still arc, and swaps are instant.

## Mobile

The label wraps at 2x text; the percentage stays whole. The indeterminate segment travels toward the end edge in RTL.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| (no Kumo component) | |
| shadcn `value` | `value` |
| shadcn indeterminate | `value: null` |
