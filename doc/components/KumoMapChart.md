# KumoMapChart

A choropleth map: Kumo's `ChoroplethMap`, drawn over region shapes you provide. Each region is filled from a continuous color scale by its value; regions without a value keep the neutral no-data fill.

Kumo reference: https://kumo-ui.com/charts/maps

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoMapChart(
  regions: [
    KumoMapRegion(id: 'weur', name: 'Western Europe', path: Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10))),
    KumoMapRegion(id: 'eeur', name: 'Eastern Europe', path: Path()..addRect(const Rect.fromLTWH(11, 0, 10, 10))),
  ],
  values: const {'weur': 1200, 'eeur': 860},
  showLegend: true,
)
```

## When to use / when not to

Use it when the geography matters: traffic by region, requests by country. When the exact ranking matters more than the place, a sorted bar list reads faster.

## Supplying geometry

The package ships no map geometry (it would add megabytes and a data license to every app). Bring your own shapes in any coordinate space shared by all regions; the chart fits them to its box.

- **GeoJSON** (for example Natural Earth, which is public domain): parse the file you bundle with your app and pass each feature's coordinate rings to `KumoMapRegion.fromPolygons`. It applies an equirectangular projection with north up and cuts holes with the even-odd rule. Simplify the geometry first (mapshaper or similar) so paths stay small.
- **SVG paths**: convert each path to a `Path` and pass it to `KumoMapRegion(id:, path:)`.
- **Tile maps**: hexagons or squares per region work well on phones and need no projection.

```dart
final france = KumoMapRegion.fromPolygons(
  id: 'FR',
  name: 'France',
  rings: const [
    [Offset(-4.8, 48.4), Offset(2.5, 51.1), Offset(8.2, 49.0), Offset(7.6, 43.8), Offset(3.1, 42.4), Offset(-1.8, 43.4)],
  ],
);
```

(The ring above is a rough six-point outline for illustration only.)

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `regions` | `List<KumoMapRegion>` | required | `id`, `path`, optional `name` |
| `values` | `Map<String, double>` | required | Value per region id |
| `colorRange` | `List<Color>?` | `KumoChartColors.map.scale` | Low to high stops, interpolated in OKLCH |
| `min` / `max` | `double?` | data min / max | Scale bounds |
| `noDataColor` | `Color?` | `KumoChartColors.map.area` | Fill for regions without a value |
| `showLegend` | `bool` | `false` | `Low` to `High` gradient under the map |
| `showTooltip` | `bool` | `true` | Name and value on hover or tap |
| `valueFormat` | `String Function(double)?` | grouped digits | |
| `tooltipBuilder` | `Widget Function(BuildContext, KumoMapRegion, double)?` | | Custom tooltip content |
| `onRegionHover` | `ValueChanged<KumoMapRegion?>?` | | Region with data under the pointer, or null |
| `onRegionPress` | `ValueChanged<KumoMapRegion>?` | | |
| `height` | `double?` | from aspect | Fixed height |
| `aspectRatio` | `double?` | shapes' bounds | Width over height when `height` is null |
| `bounds` | `Rect?` | all regions | Part of the coordinate space to show |
| `loading` | `bool` | `false` | Shapes in the skeleton color |
| `error` / `onRetry` | `String?` / `VoidCallback?` | | Error state with a Retry button |
| `emptyMessage` | `String` | `'No data for these regions'` | When `values` is empty |
| `emptyDescription` | `String?` | | |
| `semanticLabel` | `String?` | | Leads the screen reader summary |

## Examples

### Custom scale and press handling

```dart
KumoMapChart(
  regions: regions,
  values: requestsByRegion,
  colorRange: KumoChartColors.of(context).sequential(),
  valueFormat: (v) => '${v.round()} req/s',
  onRegionPress: (region) => setState(() => selected = region.id),
)
```

## Accessibility

The summary lists every region with data, highest first ("Map, 9 regions, 8 with data. Asia Pacific: 2,400. ..."). With keyboard focus, arrow keys move between regions with data, the value reads the active region, Enter or Space calls `onRegionPress` and Escape clears. The legend reads its range ("Color scale from 100 to 2,400").

## Motion

Value changes cross-fade region fills over 300ms; instant under reduced motion. Hover changes instantly, fading other regions to 45% like Kumo.

## Mobile

Tap a region to highlight it and show its tooltip above the finger; tap outside to clear. The height follows the width, so the whole map stays visible on a phone.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `echarts`, `mapName` | (not needed) |
| `geoJson` | `regions` (`KumoMapRegion.fromPolygons` for GeoJSON rings) |
| `data` + `name` / `value` accessors | `values: {regionId: value}` |
| `nameProperty` | `KumoMapRegion.id` |
| `colorRange`, `min`, `max`, `noDataColor`, `showLegend`, `showTooltip`, `valueFormat` | same |
| `tooltipFormatter(row)` | `tooltipBuilder(context, region, value)` |
| `onRegionHover`, `onRegionClick` | `onRegionHover`, `onRegionPress` |
| `center`, `zoom`, `roam`, `projection` | `bounds` (pan and zoom are not supported) |
| `aspectRatio`, `height` | same |
| `BubbleMap`, `GlobeMap` | not ported |
