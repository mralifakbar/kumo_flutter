# KumoGrid

Kumo's `Grid`: a responsive column grid with a gap, whose columns collapse at Kumo's breakpoints.

Kumo reference: https://kumo-ui.com/components/grid

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoGrid(
  variant: KumoGridVariant.twoUp,
  children: [KumoLayerCard(child: Text('Workers')), KumoLayerCard(child: Text('R2'))],
)
```

## When to use / when not to

Use it to lay out cards and stat tiles that should sit side by side on wide screens and stack on phones. For a single row of controls use a `Row` or `Wrap`; for tabular data use `KumoTable`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | Fill rows in reading order |
| `variant` | `KumoGridVariant?` | | Preset layout, see below. Neither `variant` nor `columns`: one column |
| `columns` | `KumoGridColumns?` | | Explicit counts: `base`, `sm` (640), `md` (768), `lg` (1024), `xl` (1280) |
| `gap` | `KumoGridGap` | `base` | `none` 0, `sm` 12, `base` 8 / 24 from md / 32 from lg, `lg` 32 |
| `mobileDivider` | `bool` | `false` | `fourUp` only: hairlines between stacked items |
| `breakpoints` | `KumoGridBreakpoints` | `window` | `container` reads the grid's own width |

Variants: `twoUp` (1, 2 from md), `sideBySide` (2), `twoOne` (2fr 1fr from md), `oneTwo` (1fr 2fr from md), `oneThreeUp` (1, 3 from lg), `threeUp` (1, 2, 3), `fourUp` (1, 2, 3, 4 at xl), `sixUp` (2, 3, 4, 6 at xl), `oneTwoFourUp` (1, 2, 4 from lg).

## Examples

### Explicit columns

```dart
KumoGrid(
  columns: const KumoGridColumns(base: 2, md: 4),
  gap: KumoGridGap.sm,
  children: [for (final name in ['assets', 'backups', 'logs', 'uploads']) KumoLayerCard(child: Text(name))],
)
```

### Inside a side panel

```dart
const KumoGrid(
  variant: KumoGridVariant.twoUp,
  breakpoints: KumoGridBreakpoints.container,
  children: [Text('Requests'), Text('Bandwidth')],
)
```

## Accessibility

The grid adds no semantics; children are read in reading order, which is also visual order in both directions.

## Motion

None. Columns change when the width crosses a breakpoint.

## Mobile

Most variants are one column below 768px. Cells in a row stretch to the tallest cell, like CSS grid, so cards line up. In right-to-left layouts the first column is on the right.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Grid>` + `<GridItem>` | `KumoGrid(children:)` |
| `variant="2up"`, `"side-by-side"`, `"2-1"`, `"1-2"`, `"1-3up"`, `"3up"`, `"4up"`, `"6up"`, `"1-2-4up"` | `KumoGridVariant.twoUp`, `.sideBySide`, `.twoOne`, `.oneTwo`, `.oneThreeUp`, `.threeUp`, `.fourUp`, `.sixUp`, `.oneTwoFourUp` |
| `gap` | `gap` |
| `mobileDivider` | `mobileDivider` |
| custom `grid-cols-*` classes | `columns: KumoGridColumns(...)` |
