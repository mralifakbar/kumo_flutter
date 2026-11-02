# KumoChartLegend

A legend item for a chart series: a colored dot, the series name and its value. Kumo's `ChartLegend.SmallItem` and `ChartLegend.LargeItem`.

Kumo reference: https://kumo-ui.com/charts

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoChartLegend.small(name: 'Requests', color: KumoChartColors.of(context).categorical(0), value: '1,234')
```

## When to use / when not to

Use `small` for multi-series legends under or beside a chart, `large` for headline metrics on a dashboard card. For a plain toggle legend on a `KumoTimeseriesChart`, pass `showLegend: true` instead of building one.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `String` | required | Series name |
| `color` | `Color` | required | Dot color, from `KumoChartColors` |
| `value` | `String?` | | Formatted value; required for `large` |
| `unit` | `String?` | | `large` only: unit after the value (`'ms'`) |
| `inactive` | `bool` | `false` | Dot and text at 50% opacity (series hidden or faded) |
| `onPress` | `VoidCallback?` | | Makes the item a focusable toggle button |
| `onHoverChange` | `ValueChanged<bool>?` | | Pointer enter (true) and leave (false) |
| `semanticLabel` | `String?` | name, value, unit | Announced label |
| `size` (`.loading`) | `KumoChartLegendSize` | `small` | Layout of the placeholder |

Constructors: `KumoChartLegend.small`, `KumoChartLegend.large`, `KumoChartLegend.loading`.

## Examples

### Headline metrics

```dart
final palette = KumoChartColors.of(context);
Wrap(spacing: 16, children: [
  KumoChartLegend.large(name: 'P99', color: palette.semantic(KumoChartSemanticColor.attention), value: '124', unit: 'ms'),
  KumoChartLegend.large(name: 'P50', color: palette.semantic(KumoChartSemanticColor.neutral), value: '10', unit: 'ms'),
]);
```

### Toggle and highlight a chart's series

```dart
KumoChartLegend.large(
  name: 'P95',
  color: KumoChartColors.of(context).semantic(KumoChartSemanticColor.warning),
  value: '76',
  unit: 'ms',
  inactive: hidden.contains('P95'),
  onPress: () => setState(() => hidden.contains('P95') ? hidden.remove('P95') : hidden.add('P95')),
  onHoverChange: (hovering) => setState(() => highlighted = hovering ? 'P95' : null),
)
```

Pass the same `hidden` set to `KumoTimeseriesChart.hiddenSeries` and `highlighted` to `highlightedSeries`.

### Loading

```dart
const Wrap(spacing: 16, children: [KumoChartLegend.loading(), KumoChartLegend.loading()])
```

## Accessibility

Without callbacks the item is a single text node ("P99 124 ms"). With `onPress` it is a focusable button that reports `toggled` (on unless `inactive`); Enter and Space activate. Loading placeholders are hidden from screen readers; announce loading on the chart.

## Motion

Pressable items scale to 0.98 on press. Toggling `inactive` eases the item between full and half opacity (150ms), in step with the series fading in the chart; instant under reduced motion. Hover never animates color. Loading placeholders are static `KumoSkeletonLine` bars.

## Mobile

Pressable items grow their hit area to 44px tall on touch. Below the `md` breakpoint large items drop Kumo's 168px minimum width so two or three fit on a phone row.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `ChartLegend.SmallItem` | `KumoChartLegend.small` |
| `ChartLegend.LargeItem` | `KumoChartLegend.large` |
| `loading` | `KumoChartLegend.loading` |
| `name`, `color`, `value`, `unit`, `inactive` | same |
| `onClick` | `onPress` |
| `onPointerEnter` / `onPointerLeave` | `onHoverChange(true / false)` |
