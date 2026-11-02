# KumoChartColors

Kumo's chart palette (`ChartPalette`): categorical colors for series, semantic colors for status data, a sequential scale for density and map fills, each tuned for light and dark mode.

Kumo reference: https://kumo-ui.com/charts/colors

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
final palette = KumoChartColors.of(context);
final errors = palette.semantic(KumoChartSemanticColor.attention);
final third = palette.categorical(2);
```

## When to use / when not to

- Use **semantic** colors when the data has polarity: errors, warnings, health. `neutral` is the baseline series (total requests).
- Use **categorical** colors for nominal series with no meaning of their own. Past six series they cycle (`categorical(6)` is blue again); most charts should show the top five and group the rest.
- Use the **sequential** scale for magnitude across a set (heatmaps, choropleths), not to tell series apart.
- Do not use chart colors for UI chrome; use theme tokens (`context.kumo.colors`).
- Color alone never carries meaning: label semantic series and give lines a `KumoTimeseriesLineStyle` when they need telling apart.

## Parameters

| Member | Type | Description |
| --- | --- | --- |
| `KumoChartColors.light` / `.dark` | `KumoChartColors` | The two palettes |
| `KumoChartColors.of(context)` | `KumoChartColors` | Palette for the nearest `KumoTheme`'s mode |
| `KumoChartColors.forBrightness(b)` | `KumoChartColors` | Palette for a `Brightness` |
| `categorical(int index)` | `Color` | Blue, yellow, pink, purple, teal, orange; wraps with modulo |
| `categoricalColors` | `List<Color>` | The six categorical colors |
| `semantic(KumoChartSemanticColor)` | `Color` | `attention`, `warning`, `success`, `neutral`, `disabled`, `skeleton` |
| `sequential([KumoChartSequentialPalette])` | `List<Color>` | Five steps, low to high (`blues`); reversed in dark mode so high reads brighter |
| `textPrimary` / `textSecondary` | `Color` | Kumo's ECharts label colors, for custom painters |
| `map` | `KumoChartMapColors` | `area` (no-data fill), `bubble`, `scale` (choropleth ramp) |

| Name | Light | Dark |
| --- | --- | --- |
| attention | `#FC574A` | `#FC574A` |
| warning | `#F8A054` | `#F8A054` |
| success | `#00A63E` | `#00A63E` |
| neutral | `#B9D6FF` | `#8EC5FF` |
| disabled | `#CBCBCB` | `#878787` |
| skeleton | `#DDDDDD` | `#5C5C5C` |

## Examples

### Status series

```dart
final palette = KumoChartColors.of(context);
final series = [
  KumoTimeseriesData(name: 'Requests', color: palette.semantic(KumoChartSemanticColor.neutral), data: const []),
  KumoTimeseriesData(name: 'Errors', color: palette.semantic(KumoChartSemanticColor.attention), data: const []),
];
```

### Matching chart colors outside a chart

```dart
final palette = KumoChartColors.of(context);
final swatch = Container(width: 8, height: 8, color: palette.categorical(0));
```

## Accessibility

The categorical order maximises the perceptual distance between neighbours and was checked by Kumo with a color vision deficiency simulator. Kumo avoids pairing dashed or dotted lines with the lightest colors, since patterns make lines read lighter.

## Motion

None.

## Mobile

No changes.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `ChartPalette.categorical(i, isDarkMode)` | `KumoChartColors.of(context).categorical(i)` |
| `ChartPalette.semantic("Attention", isDarkMode)` | `.semantic(KumoChartSemanticColor.attention)` |
| `ChartPalette.sequential("blues", isDarkMode)` | `.sequential(KumoChartSequentialPalette.blues)` |
| `ChartPalette.text("primary", isDarkMode)` | `.textPrimary` |
| `ChartPalette.mapColors(isDarkMode)` | `.map` |
| `CHART_LIGHT_COLORS` / `CHART_DARK_COLORS` | `KumoChartColors.light.categoricalColors` / `.dark` |
