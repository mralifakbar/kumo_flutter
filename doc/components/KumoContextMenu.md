# KumoContextMenu

A menu that opens where the user right-clicks a widget, or long-presses it on touch screens. It takes the same items as `KumoDropdownMenu`.

Kumo reference: none (Kumo has no context menu; the behavior follows shadcn's `ContextMenu`). Items match https://kumo-ui.com/components/dropdown

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoContextMenu(
  items: [
    KumoDropdownItem(label: 'Copy record ID', icon: KumoIcons.copy, onPress: copyId),
    const KumoDropdownSeparator(),
    KumoDropdownItem(label: 'Delete record', icon: KumoIcons.trash, destructive: true, onPress: deleteRecord),
  ],
  child: const KumoText('A  example.com  192.0.2.1'),
)
```

## When to use / when not to

- Use it as a shortcut for actions on a row, file or canvas object.
- Context menus are hard to discover: every action in one must also be reachable from a visible control, such as a row's overflow `KumoDropdownMenu`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The area that responds to right click and long press. Its own taps keep working |
| `items` | `List<Widget>` | required | `KumoDropdownItem`, `KumoDropdownSubmenu` and the other dropdown items |
| `onOpenChange` | `ValueChanged<bool>?` | | |
| `presentation` | `KumoPresentation` | `auto` | Bottom sheet below 768px |
| `disabled` | `bool` | `false` | Ignores right click, long press and keys |
| `semanticLabel` | `String?` | | Accessible name of the menu |
| `sheetTitle` | `String?` | | Heading of the sheet presentation |
| `backLabel` | `String?` | `KumoStrings.back` | Back row of sheet submenus |

## Examples

### Nested actions

```dart
KumoContextMenu(
  sheetTitle: 'example.com',
  items: [
    KumoDropdownSubmenu(
      label: 'Change TTL',
      icon: KumoIcons.clock,
      children: [
        KumoDropdownItem(label: '5 minutes', onPress: () => setTtl(300)),
        KumoDropdownItem(label: '1 hour', onPress: () => setTtl(3600)),
      ],
    ),
  ],
  child: const KumoText('example.com'),
)
```

## Accessibility

- Keyboard: with focus anywhere inside `child`, the Menu key or Shift+F10 opens the menu at the center of `child`. Inside, the keys work as in `KumoDropdownMenu`; Escape closes it.
- Screen readers have no right click: put the same actions on a visible button.

## Motion

Opens with its corner at the pointer and scales from there with `KumoAnchoredOverlay`'s spring; flips above or to the side near screen edges. Right-clicking elsewhere on `child` while it is open moves it to the new point. A long press fires a medium haptic.

## Mobile

On touch, a long press opens it. Below 768px it opens as a bottom sheet with the same items (submenus push in place). On the web, call `BrowserContextMenu.disableContextMenu()` once at startup so the browser's own menu does not cover it.

## Kumo React mapping

| shadcn prop | Flutter parameter |
| --- | --- |
| `ContextMenu onOpenChange` | `onOpenChange` |
| `ContextMenuTrigger` children | `child` |
| `ContextMenuContent` items | `items` (Kumo dropdown items) |
| `ContextMenuTrigger disabled` | `disabled` |
