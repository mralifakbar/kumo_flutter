# KumoMenubar

A horizontal bar of menus (File, View, Deploy) in Kumo's `MenuBar` look: a recessed track where the open menu's trigger is raised onto the base surface.

Kumo reference: `MenuBar` in `packages/kumo/src/components/menubar` (deprecated in Kumo, no docs page)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoMenubar(
  semanticLabel: 'Worker editor',
  menus: [
    KumoMenubarMenu(label: 'File', items: [
      KumoDropdownItem(label: 'New Worker', icon: KumoIcons.plus, onPress: createWorker),
      KumoDropdownItem(label: 'Save', shortcut: '⌘S', onPress: save),
    ]),
    KumoMenubarMenu(label: 'View', items: [
      KumoDropdownCheckboxItem(label: 'Live logs', checked: logs, onCheckedChange: (v) => setState(() => logs = v)),
    ]),
  ],
)
```

## When to use / when not to

- Use it for editor-style screens with several groups of commands.
- For one group of commands, use `KumoDropdownMenu`. For switching views, use segmented tabs (Kumo deprecated its icon `MenuBar` in their favor). For a row of direct actions, use `KumoToolbar`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `menus` | `List<KumoMenubarMenu>` | required | Left to right (start to end) |
| `presentation` | `KumoPresentation` | `auto` | Menus open as bottom sheets below 768px |
| `semanticLabel` | `String?` | | Accessible name of the bar |

### KumoMenubarMenu

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | Trigger text; with `icon`, the tooltip and accessible name |
| `items` | `List<Widget>` | required | Dropdown items (`KumoDropdownItem`, `KumoDropdownSubmenu`, ...) |
| `icon` | `IconData?` | | Icon-only trigger, 18px, as in Kumo's `MenuBar` |
| `disabled` | `bool` | `false` | Skipped by arrow keys and hover |

## Examples

### Icon menus

```dart
KumoMenubar(
  menus: [
    KumoMenubarMenu(label: 'Settings', icon: KumoIcons.gearSix, items: [
      KumoDropdownItem(label: 'Variables', onPress: openVariables),
    ]),
  ],
)
```

## Accessibility

- Triggers are buttons with an expanded state; icon triggers are named by `label`.
- One Tab stop for the whole bar. Left and Right move between triggers (mirrored in RTL, skipping disabled menus, wrapping), Home and End jump. Enter, Space or Down open the focused menu on its first item.
- Inside an open menu, Left and Right move to the neighboring menu; on a submenu row, Right opens the submenu instead. Escape or choosing an item closes the menu and, from the keyboard, focus returns to its trigger.

## Motion

Menus open from their trigger with `KumoAnchoredOverlay`'s scale-from-anchor spring and close along the same path. While one menu is open, hovering another trigger, clicking it or pressing Left/Right switches to it: the panels swap in place in one frame, with no shrink-and-grow between them (as in desktop menu bars). Closing the last open menu animates out as usual. The raised trigger switches instantly (Kumo never animates hover colors).

## Mobile

Below 768px menus open as bottom sheets with the same items. The bar scrolls sideways if its triggers do not fit, and triggers are 44px tall on touch.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `MenuBar options` | `menus` |
| option `icon` | `KumoMenubarMenu.icon` |
| option `tooltip` | `KumoMenubarMenu.label` |
| option `onClick` | each menu's `items` |
| `isActive` | the open menu is raised automatically |
| `useMenuNavigation` (horizontal) | built in |
