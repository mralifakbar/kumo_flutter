# KumoIcon

Renders a Phosphor glyph from `KumoIcons` (or any `IconData`) at Kumo's 16px default size.

Kumo reference: https://kumo-ui.com (Kumo uses `@phosphor-icons/react`)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoIcon(KumoIcons.gear)
```

## When to use / when not to

Pick icons for their meaning (a globe for DNS, a lock for SSL). If no icon fits, use none. Use the `Fill` weight for selected or active states.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `icon` | `IconData` | required, positional | A `KumoIcons` constant or any IconData |
| `size` | `double` | `16` | |
| `color` | `KumoColor?` | | Defaults to the surrounding text color |
| `dangerouslySetColor` | `Color?` | | |
| `semanticLabel` | `String?` | | Icons are decorative unless labelled |

## Examples

### Status icon with meaning

```dart
const KumoIcon(KumoIcons.warningCircle, color: KumoColor.textDanger, semanticLabel: 'Error')
```

### Fill weight for an active state

```dart
const KumoIcon(KumoIcons.starFill, color: KumoColor.warning)
```

### Searching the catalog

```dart
// import 'package:kumo_flutter/kumo_icon_catalog.dart';
// final matches = kumoIconCatalog.where((e) => e.matches('cloud')).toList();
```

## Accessibility

Decorative icons are excluded from semantics. Give a label only to icons that carry meaning without text next to them.

## Motion

None.

## Mobile

Icons inside controls inherit the control's hit area; standalone tappable icons belong in a `KumoButton` with `shape: square`.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `<GearIcon />` | `KumoIcon(KumoIcons.gear)` |
| `<Star weight="fill" />` | `KumoIcon(KumoIcons.starFill)` |
| `size={20}` | `size: 20` |
