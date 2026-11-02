# KumoTimeseriesChart

Lines, area fills or stacked bars over time, with nice value ticks, time labels that adapt to the range, thresholds, reference markers and a crosshair tooltip. Kumo's `TimeseriesChart`, drawn with `CustomPainter` (no ECharts).

Kumo reference: https://kumo-ui.com/charts/timeseries

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTimeseriesChart(
  xAxisName: 'Time (UTC)',
  yAxisName: 'Requests',
  data: [
    KumoTimeseriesData(
      name: 'Requests',
      color: KumoChartColors.of(context).semantic(KumoChartSemanticColor.neutral),
      data: [(DateTime.utc(2026, 3, 4, 14), 120), (DateTime.utc(2026, 3, 4, 14, 1), 132)],
    ),
  ],
)
```

## When to use / when not to

Use it for metrics over time: requests, latency percentiles, memory, error counts. For a trend inside a table cell or tile, use `KumoSparkline`. For flows between resources, use `KumoSankeyChart`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `data` | `List<KumoTimeseriesData>` | required | Series in legend and stacking order |
| `type` | `KumoTimeseriesChartType` | `line` | `line` or `bar` (stacked per timestamp) |
| `gradient` | `bool` | `false` | Area fill under lines, 40% to clear |
| `markers` | `List<KumoTimeseriesMarker>` | `[]` | Vertical reference lines (deploys, changes) |
| `thresholds` | `List<KumoTimeseriesThreshold>` | `[]` | Horizontal lines, or bands with `endValue` |
| `incomplete` | `KumoTimeseriesIncomplete?` | | Dashes segments before `before` and after `after` |
| `xAxisName` / `yAxisName` | `String?` | | Axis titles |
| `xAxisTickCount` / `yAxisTickCount` | `int` | `5` | Approximate tick counts |
| `yAxisMinInterval` | `double?` | | Minimum tick step; `1` for counts |
| `xAxisHideLabelOverlap` | `bool` | `true` | Skip time labels that would collide |
| `xAxisTickFormat` | `String Function(DateTime)?` | adaptive | `14:05:30`, `14:05`, `Mar 4`, `Mar`, `2026` |
| `yAxisTickFormat` | `String Function(double)?` | grouped digits | Value labels |
| `tooltipValueFormat` | `String Function(double)?` | grouped digits | Tooltip, legend and screen reader values |
| `tooltipTimestampFormat` | `String Function(DateTime)?` | `Mar 4, 14:05:09` | Tooltip header |
| `tooltipFooter` | `String?` | | Note under the tooltip rows |
| `tooltipMode` | `KumoTimeseriesTooltipMode` | `all` | `all` series or the `single` nearest one |
| `tooltipMaxItems` | `int` | `10` | Rows before `+N more` |
| `tooltipFollowCursor` | `KumoTimeseriesTooltipFollow` | `both` | `both` axes, or `x` (pinned to the top) |
| `showLegend` | `bool` | `false` | Toggle legend above the chart with latest values |
| `hiddenSeries` | `Set<String>?` | | Controlled hidden set; null tracks legend toggles internally |
| `onHiddenSeriesChange` | `ValueChanged<Set<String>>?` | | Next hidden set when a legend item is pressed |
| `highlightedSeries` | `String?` | | Emphasise one series, fade the others |
| `onTimeRangeChange` | `void Function(DateTime, DateTime)?` | | Mouse drag selects a range |
| `height` | `double?` | 350, or 260 below `md` | Chart height |
| `loading` | `bool` | `false` | Wave skeleton |
| `error` | `String?` | | Error message shown in place of the chart |
| `onRetry` | `VoidCallback?` | | Adds a Retry button to the error state |
| `emptyMessage` | `String?` | `KumoStrings.noDataInRange` | Shown when no series has points |
| `emptyDescription` | `String?` | `'Choose a longer time range to see earlier data.'` | |
| `semanticLabel` | `String?` | | Leads the screen reader summary |
| `scrubHaptic` | `KumoHaptic` | `selection` | Fired when a touch scrub snaps to a new point |

`KumoTimeseriesData(name, data, color, lineStyle)`: `data` is `List<(DateTime, double)>`; unsorted input is sorted and `double.nan` leaves a gap. Times keep their zone: pass UTC times to label the axis in UTC.

`KumoTimeseriesMarker(time, label, description, color, lineStyle)`: markers closer than about one tick merge into a line labelled "N changes".

`KumoTimeseriesThreshold(value, color, label, endValue)`: the value axis always extends to include thresholds.

## Examples

### Deploy markers and a memory limit

```dart
final palette = KumoChartColors.of(context);
KumoTimeseriesChart(
  yAxisName: 'Memory (MB)',
  data: [KumoTimeseriesData(name: 'Memory used', color: palette.semantic(KumoChartSemanticColor.neutral), data: points)],
  markers: [KumoTimeseriesMarker(time: DateTime.utc(2026, 3, 4, 14, 15), label: 'Deploy 4f2c1a9', description: 'image-resizer v42')],
  thresholds: [KumoTimeseriesThreshold(value: 128, label: 'Memory limit', color: palette.semantic(KumoChartSemanticColor.attention))],
  tooltipValueFormat: (v) => '${v.round()} MB',
);
```

### Stacked bars with a toggle legend

```dart
KumoTimeseriesChart(
  type: KumoTimeseriesChartType.bar,
  showLegend: true,
  yAxisMinInterval: 1,
  data: series,
)
```

### Data states

```dart
KumoTimeseriesChart(
  data: series,
  loading: isLoading,
  error: failed ? 'Could not load requests. Check your connection, then retry.' : null,
  onRetry: reload,
)
```

### Range selection

```dart
KumoTimeseriesChart(
  data: series,
  onTimeRangeChange: (from, to) => setState(() => range = (from, to)),
)
```

## Accessibility

The chart is one semantics node whose label summarises it: kind, series count and time range, then each series' range and latest value, thresholds, markers and hidden series (`semanticLabel` leads). Screen reader increase and decrease actions step through points and the value reads the active point ("Mar 4, 14:05:09. Requests 132. Errors 3"). With keyboard focus (a 2px focus ring) Left and Right step, Home and End jump, Escape hides the tooltip. The error state is a live region with an icon and text; the loading skeleton announces "Loading chart".

## Motion

When data, the hidden set or thresholds change, series morph from the geometry on screen to the new values over 300ms with Kumo's standard curve; the value and time axes slide to their new range, entering line series fade in and bars grow from zero, and series hidden from the legend fade out rather than pop. Under reduced motion changes are instant. The skeleton, chart, error and empty message cross-fade (150ms). The loading sheen sweeps every 1.8s only while `loading` is true and only on screen; under reduced motion it stays still. The crosshair and tooltip follow the pointer 1:1 with no easing. Moving the pointer repaints only the crosshair layer; the series layer is cached and repaints only when its data changes.

## Mobile

Touch: the tooltip appears under the finger on contact, follows a horizontal drag 1:1 with a selection haptic on each new point, and stays after lifting until the next touch or a tap outside. Vertical drags still scroll the page. On touch the tooltip pins to the top of the plot so the finger never covers it. Range selection is mouse only; on touch offer explicit range controls. Default height drops to 260 below the `md` breakpoint, and labels and padding grow with text scale.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `echarts` | (not needed) |
| `type: "line" \| "bar"` | `type` |
| `data: { name, data: [ms, value][], color }` | `data: KumoTimeseriesData(name, data: [(DateTime, double)], color)` |
| `markers`, `thresholds` | same (`time: DateTime` instead of `timestamp`) |
| `xAxisName`, `yAxisName`, `xAxisTickCount`, `yAxisTickCount`, `yAxisMinInterval`, `xAxisHideLabelOverlap` | same |
| `xAxisTickFormat(ms)` | `xAxisTickFormat(DateTime)` |
| `yAxisTickFormat`, `tooltipValueFormat`, `tooltipFooter`, `tooltipMaxItems` | same |
| `yAxisTickLabelFormat` (deprecated) | `tooltipValueFormat` |
| `tooltipTimestampFormat(ms)` | `tooltipTimestampFormat(DateTime)` |
| `tooltipMode: "all" \| "single"` | `tooltipMode` |
| `tooltipFollowCursor: "both" \| "x"` | `tooltipFollowCursor` |
| `tooltipBoundary` | (tooltip always stays inside the chart) |
| `incomplete: { before, after }` | `incomplete: KumoTimeseriesIncomplete(before:, after:)` |
| `enableLegendSelection` + `legendSelect` actions | `hiddenSeries` / `onHiddenSeriesChange`, or `showLegend` |
| `dispatchAction({ type: "highlight" })` | `highlightedSeries` |
| `height` (350) | `height` (350, 260 on phones) |
| `onTimeRangeChange(from, to)` | same, with `DateTime`s |
| `gradient`, `loading` | same |
| `isDarkMode` | follows `KumoTheme` |
| `ariaDescription` | `semanticLabel` (plus a generated summary) |
| `optionUpdateBehavior` | (not applicable) |
