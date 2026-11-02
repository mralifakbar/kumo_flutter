# KumoSeparator

A 1px hairline between groups of content, horizontal or vertical, with an optional centered label.

Kumo reference: none as a component. It is the `h-px bg-kumo-hairline` divider Kumo's dropdown menu uses between groups.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoSeparator()
```

## When to use / when not to

Use it between sections of a card, panel or form. Prefer spacing alone when the groups are already clearly apart; a line is for content that would otherwise run together. Inside menus use `KumoMenuSeparator`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `orientation` | `KumoSeparatorOrientation` | `horizontal` | Use `KumoSeparator.vertical()` for vertical |
| `label` | `String?` | | Short text centered in a horizontal line (12px subtle). Wraps when long |
| `length` | `double?` | | Fixed extent along the line. Null fills the parent |
| `color` | `KumoColor` | `hairline` | `line` gives a stronger divider |
| `thickness` | `double` | `1` | |

## Examples

### With a label

```dart
const KumoSeparator(label: 'or sign in with an API token')
```

### Vertical, in a toolbar

```dart
const IntrinsicHeight(
  child: Row(children: [
    KumoText('Workers'),
    SizedBox(width: 12),
    KumoSeparator.vertical(),
    SizedBox(width: 12),
    KumoText('Pages'),
  ]),
)
```

## Accessibility

The line is decorative and hidden from screen readers; a `label` is read as text.

## Motion

None.

## Mobile

A horizontal separator fills the width it is given. A vertical one fills the height its parent gives it: wrap the row in `IntrinsicHeight` or pass `length`.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<div className="h-px bg-kumo-hairline" />` | `KumoSeparator()` |
