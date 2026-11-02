# KumoAvatarGroup

Overlapping `KumoAvatar`s with a "+3" chip for the ones that do not fit.

Kumo reference: none. Inspired by shadcn's avatar group; see `KumoAvatar`.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoAvatarGroup(
  max: 3,
  avatars: [
    KumoAvatar(name: 'Ada Lovelace'),
    KumoAvatar(name: 'Grace Hopper'),
    KumoAvatar(name: 'Alan Turing'),
    KumoAvatar(name: 'Katherine Johnson'),
  ],
)
```

## When to use / when not to

Use it to show who has access to a resource or who is in a team, when the exact list lives elsewhere. When the names matter, list them as text instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `avatars` | `List<KumoAvatar>` | required | In order. Each one's `size` is replaced by the group's |
| `max` | `int?` | | Avatars shown before the overflow chip. Null shows all |
| `size` | `KumoAvatarSize` | `base` | |
| `ringColor` | `KumoColor` | `base` | 2px ring around each avatar; set it to the surface behind the group |
| `onOverflowPress` | `VoidCallback?` | | Makes the "+N" chip a button (open the member list) |
| `semanticLabel` | `String?` | | Replaces the generated label |

## Examples

### Expand on press

```dart
KumoAvatarGroup(
  avatars: members,
  max: showAll ? null : 3,
  onOverflowPress: () => setState(() => showAll = true),
)
```

## Accessibility

Without `onOverflowPress` the group is one node: "Ada Lovelace, Grace Hopper, Alan Turing and 1 more". With it, each avatar reads its own name and the chip is a button labelled "Show 1 more".

## Motion

None.

## Mobile

Each avatar after the first overlaps the previous one by a quarter of its width, toward the start edge (mirrored in RTL). A pressable chip gets a 44x44 hit area on touch platforms without changing its look.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| (no Kumo component) | |
