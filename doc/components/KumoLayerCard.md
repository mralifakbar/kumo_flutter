# KumoLayerCard

Kumo's `LayerCard`: the standard container for a block of content, plain or layered with a header strip.

Kumo reference: https://kumo-ui.com/components/layer-card

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoLayerCard(child: KumoText('Requests in the last 24 hours'))
```

## When to use / when not to

Use one card per block of related content. Never nest a layer card inside another; put a heading above a single card instead. Not every group needs a card: lists and plain sections with spacing are often clearer.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required (plain form) | |
| `children` | `List<Widget>` | required (`.layered`) | `KumoLayerCardSecondary` and `KumoLayerCardPrimary` |
| `padding` | `EdgeInsetsGeometry` | `h 20, v 16` | Plain form only |
| `onPress` | `VoidCallback?` | | Makes the card pressable |
| `semanticLabel` | `String?` | | For pressable cards |

`KumoLayerCardSecondary(child:, trailing:)` is the header strip. `KumoLayerCardPrimary(child:, padding:)` is the inset content panel.

## Examples

### Layered

```dart
const KumoLayerCard.layered(children: [
  KumoLayerCardSecondary(child: Text('Web Analytics')),
  KumoLayerCardPrimary(child: Text('Measure site traffic without changing your code.')),
])
```

### Pressable

```dart
KumoLayerCard(
  onPress: () {},
  semanticLabel: 'Open image-resizer',
  child: const KumoText('image-resizer'),
)
```

## Accessibility

A pressable card is one button; give it a `semanticLabel` that names the destination.

## Motion

Pressable cards scale to 0.98 on press; hover tint is instant.

## Mobile

Cards fill the width with 16px page gutters.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `<LayerCard>` | `KumoLayerCard(child:)` |
| `<LayerCard.Secondary>` | `KumoLayerCardSecondary` |
| `<LayerCard.Primary>` | `KumoLayerCardPrimary` inside `KumoLayerCard.layered` |
