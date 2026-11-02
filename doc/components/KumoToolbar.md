# KumoToolbar

Controls grouped into one compact card, with shared borders between items and only the outer corners rounded. Items that do not fit move into a "More" menu.

Kumo reference: https://kumo-ui.com/components/toolbar

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoToolbar(
  semanticLabel: 'DNS records',
  children: [
    KumoToolbarButton(icon: KumoIcons.uploadSimple, label: 'Import', onPress: importRecords),
    KumoToolbarButton(icon: KumoIcons.downloadSimple, label: 'Export', onPress: exportRecords),
    KumoToolbarButton(icon: KumoIcons.gearSix, semanticLabel: 'Settings', onPress: openSettings),
  ],
)
```

## When to use / when not to

- Use it for a row of related actions or filters over a table, editor or file list.
- For one action, use a `KumoButton`. For many commands in categories, use `KumoMenubar`. For tabs, use tabs.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | `KumoToolbarButton`, `KumoToolbarGroup`, `KumoToolbarSlot` (any other widget is placed as a fixed slot) |
| `overflowMenu` | `bool` | `true` | Move items that do not fit into a "More" menu; false clips |
| `semanticLabel` | `String?` | | Accessible name of the toolbar |
| `moreLabel` | `String?` | `KumoStrings.more` | Accessible name of the overflow button |
| `presentation` | `KumoPresentation` | `auto` | Overflow menu as a sheet below 768px |

### KumoToolbarButton

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String?` | | Text; omit for icon-only buttons |
| `icon` | `IconData?` | | |
| `onPress` | `VoidCallback?` | | Null renders it disabled |
| `disabled` | `bool` | `false` | |
| `loading` | `bool` | `false` | Spinner in place of the icon; presses blocked |
| `toggled` | `bool?` | `null` | Pressed state for toggles (bold); becomes a checkbox row in the overflow menu |
| `isLink` | `bool` | `false` | Announce as a link (Kumo's `Toolbar.Link`) |
| `semanticLabel` | `String?` | | Required for icon-only buttons; also their overflow menu label |
| `tooltip` | `String?` | | Hover tooltip |

### KumoToolbarGroup

`children` (`List<KumoToolbarButton>`) sit with no divider between them and move into the overflow menu together. `semanticLabel` names the group.

### KumoToolbarSlot

`child` (any widget, such as a search field), `flex` (`int`, default `0`; a share of the free width, like `flex-1`), `minWidth` (`double`, default `160`; width kept before other items overflow). Slots never move into the overflow menu.

## Examples

### Formatting toggles

```dart
KumoToolbar(
  semanticLabel: 'Editor',
  children: [
    KumoToolbarGroup(semanticLabel: 'Text formatting', children: [
      KumoToolbarButton(icon: KumoIcons.textB, semanticLabel: 'Bold', toggled: bold, onPress: toggleBold),
      KumoToolbarButton(icon: KumoIcons.textItalic, semanticLabel: 'Italic', toggled: italic, onPress: toggleItalic),
    ]),
    KumoToolbarButton(icon: KumoIcons.linkSimple, semanticLabel: 'Insert link', onPress: insertLink),
  ],
)
```

### Search slot

```dart
KumoToolbar(
  children: [
    const KumoToolbarSlot(flex: 1, child: SearchRecordsField()),
    KumoToolbarButton(icon: KumoIcons.funnelSimple, semanticLabel: 'Filter', onPress: openFilters),
  ],
)
```

## Accessibility

- The toolbar is a named semantics container; buttons announce their label, toggles their toggled state, links as links.
- One Tab stop: Tab enters on the last focused button (the first one at the start), Left and Right move between buttons (mirrored in RTL, skipping disabled ones, wrapping), Home and End jump, and Tab leaves. Arrow keys inside a slot (a text field) are left to the slot.

## Motion

Buttons respond on pointer-down with `KumoPressable`'s press spring; hover colors switch instantly. The overflow menu opens from the More button with the scale-from-anchor spring, or as a sheet that follows the finger. Items move into the More menu in the same layout pass that runs out of room, so a resize never shows a clipped or overlapping button; they do not animate, so the toolbar never lags behind a window or panel resize.

## Mobile

On touch, buttons are 44px tall and icon-only buttons 44px wide. When the row does not fit (390px, 2x text), trailing buttons and groups move into the More menu instead of overflowing; on phones it opens as a bottom sheet.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `Toolbar` children | `children` |
| `Toolbar.Button icon / children / aria-label / disabled / loading` | `KumoToolbarButton icon / label / semanticLabel / disabled / loading` |
| `Toolbar.Link` | `KumoToolbarButton(isLink: true)` |
| `Toolbar.Input`, `Toolbar.InputGroup`, Select or Combobox triggers | `KumoToolbarSlot(child: ...)` |
| `className="flex-1"` on an item | `KumoToolbarSlot(flex: 1)` |
| `size` (deprecated) | not ported |
