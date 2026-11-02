# KumoSparkline

A compact trend line for table cells, stat tiles and list rows: no axes, no tooltip, just the shape of the data. Kumo has no sparkline; this one follows its chart styling.

Kumo reference: https://kumo-ui.com/charts

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoSparkline(values: [12, 18, 15, 22, 30, 27, 34], semanticLabel: 'Requests, last 7 days')
```

## When to use / when not to

Use it next to a number to show its direction. When people need to read values, times or compare series, use `KumoTimeseriesChart`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `values` | `List<double>` | required | Evenly spaced; `double.nan` leaves a gap |
| `color` | `Color?` | `categorical(0)` | Line color |
| `area` | `bool` | `false` | Fill under the line, 40% to clear |
| `showEndDot` | `bool` | `false` | Dot on the latest value |
| `showMinMax` | `bool` | `false` | Small dots on the lowest and highest values |
| `width` | `double?` | available width, or 120 | |
| `height` | `double` | `32` | |
| `strokeWidth` | `double` | `1.5` | |
| `loading` | `bool` | `false` | Static skeleton line |
| `semanticLabel` | `String?` | `'Trend'` | What the trend measures |
| `valueFormat` | `String Function(double)?` | grouped digits | Values in the summary |

## Examples

### In a list row

```dart
Row(children: [
  const Expanded(child: KumoText('image-resizer', variant: KumoTextVariant.mono)),
  SizedBox(
    width: 120,
    child: KumoSparkline(values: hourly, area: true, showEndDot: true, semanticLabel: 'Requests per hour for image-resizer'),
  ),
])
```

## Accessibility

Announced as an image with a summary: "Requests, last 7 days, 7 points, from 12 to 34, low 12, high 34". Empty data reads "no data" and loading reads "loading". The vertical range is the data's own minimum to maximum, so state the absolute values in nearby text.

## Motion

When values change the line morphs from where it is over 300ms (resampled by position if the length changes); instant under reduced motion. The loading skeleton never animates.

## Mobile

No changes; it fills the width it is given.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| (no Kumo component) | `KumoSparkline` |
