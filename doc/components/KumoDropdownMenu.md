# KumoDropdownMenu

A list of actions anchored to a trigger, with checkbox items, radio groups and submenus. Reach for it for row actions, account menus and "Add" buttons.

Kumo reference: https://kumo-ui.com/components/dropdown

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoDropdownMenu(
  triggerBuilder: (context, menu) => KumoButton(label: 'Add', icon: KumoIcons.plus, onPress: menu.toggle),
  items: [
    KumoDropdownItem(label: 'Worker', onPress: createWorker),
    KumoDropdownItem(label: 'Pages project', onPress: createProject),
    KumoDropdownItem(label: 'KV namespace', onPress: createNamespace),
  ],
)
```

## When to use / when not to

- Use it for a short list of commands or settings that belong to one trigger.
- To pick a value for a form field, use a select. To search a long list, use a combobox.
- For a menu that opens where the user right-clicks, use `KumoContextMenu` (same items). For several menus in a row, use `KumoMenubar`.
- For rich content (forms, text), use `KumoPopover`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<Widget>` | required | Item widgets listed below, top to bottom |
| `triggerBuilder` | `KumoDropdownTriggerBuilder?` | | `(context, menu) => Widget`; call `menu.toggle`, `menu.open` or `menu.close`; `menu.isOpen` is the state |
| `trigger` | `Widget?` | | Non-interactive content made pressable by the menu (an avatar). Pass exactly one of `trigger` and `triggerBuilder`. A `KumoButton` without `onPress` renders disabled, so buttons go in `triggerBuilder` |
| `open` | `bool?` | `null` | Controls the open state; null lets the menu manage it |
| `onOpenChange` | `ValueChanged<bool>?` | | Trigger press, item selection, Escape, outside tap, sheet dismissal |
| `side` | `KumoSide` | `bottom` | Flips when there is no room |
| `align` | `KumoAlign` | `center` | Base UI's default |
| `sideOffset` | `double` | `8` | Gap between trigger and menu |
| `alignOffset` | `double` | `0` | |
| `presentation` | `KumoPresentation` | `auto` | `auto` uses a bottom sheet below 768px |
| `disabled` | `bool` | `false` | Blocks opening |
| `minWidth` | `double` | `144` | Kumo's `min-w-36` |
| `semanticLabel` | `String?` | | Accessible name of the menu and the sheet |
| `sheetTitle` | `String?` | | Heading at the top of the sheet presentation |
| `backLabel` | `String?` | `KumoStrings.back` | Accessible name of the back row in a sheet submenu |
| `tapRegionGroupId` | `Object?` | | Taps in other widgets of this group do not close the menu |
| `restoreFocus` | `bool` | `true` | Return focus to whatever had it before opening |
| `onNavigateSibling` | `ValueChanged<int>?` | | Left/Right on a row without a submenu (-1 previous, +1 next, mirrored in RTL); used by `KumoMenubar` |
| `animate` | `bool` | `true` | Scale and fade the anchored menu in and out. `KumoMenubar` turns it off while switching between open menus |

### Items

| Widget | Key parameters | Behavior |
| --- | --- | --- |
| `KumoDropdownItem` | `label`, `onPress`, `icon`, `description`, `shortcut`, `destructive`, `disabled`, `selected`, `closeOnPress = true`, `semanticLabel` | Runs `onPress`, then closes. `destructive` is Kumo's `variant="danger"`. `selected` shows a check at the end. `shortcut` is a hint only |
| `KumoDropdownLinkItem` | `label`, `onPress` (required, navigates), `icon`, `destructive`, `disabled` | Announced as a link; closes after `onPress` |
| `KumoDropdownCheckboxItem` | `label`, `checked`, `onCheckedChange`, `description`, `shortcut`, `disabled`, `closeOnPress = false` | Check in the leading slot; stays open |
| `KumoDropdownRadioGroup<T>` | `value`, `onValueChange`, `children`, `label` | Owns the value of its `KumoDropdownRadioItem`s |
| `KumoDropdownRadioItem<T>` | `value`, `label`, `icon`, `description`, `disabled`, `closeOnPress = false` | Check at the end when selected; stays open |
| `KumoDropdownGroup` | `children`, `label` | Groups rows under an optional heading |
| `KumoDropdownLabel` | `text` (positional) | `text-base font-semibold` heading |
| `KumoDropdownSeparator` | | Hairline between groups |
| `KumoDropdownSubmenu` | `label`, `children`, `icon`, `disabled`, `minWidth` | Opens to the side; pushes in place in the sheet. Keep `label` unique within its menu |

Rows without an icon are inset automatically when another row in the same menu has one, so labels line up.

## Examples

### Checkbox items

```dart
KumoDropdownMenu(
  triggerBuilder: (context, menu) => KumoButton(label: 'View options', onPress: menu.toggle),
  items: [
    KumoDropdownGroup(
      label: 'Display',
      children: [
        KumoDropdownCheckboxItem(
          label: 'Show line numbers',
          checked: showLineNumbers,
          onCheckedChange: (v) => setState(() => showLineNumbers = v),
        ),
      ],
    ),
  ],
)
```

### Submenu with a radio group

```dart
KumoDropdownMenu(
  triggerBuilder: (context, menu) => KumoButton(label: 'Account', icon: KumoIcons.user, onPress: menu.toggle),
  items: [
    KumoDropdownItem(label: 'Profile', icon: KumoIcons.user, onPress: openProfile),
    KumoDropdownSubmenu(
      label: 'Region',
      icon: KumoIcons.globe,
      children: [
        KumoDropdownRadioGroup<String>(
          value: region,
          onValueChange: (v) => setState(() => region = v),
          children: const [
            KumoDropdownRadioItem(value: 'wnam', label: 'Western North America'),
            KumoDropdownRadioItem(value: 'weur', label: 'Western Europe'),
          ],
        ),
      ],
    ),
    const KumoDropdownSeparator(),
    KumoDropdownItem(label: 'Log out', icon: KumoIcons.signOut, destructive: true, onPress: logOut),
  ],
)
```

### Custom trigger

```dart
KumoDropdownMenu(
  semanticLabel: 'Signed in as MR',
  trigger: const CircleAvatarWidget(initials: 'MR'),
  items: [KumoDropdownItem(label: 'Settings', icon: KumoIcons.gear, onPress: openSettings)],
)
```

### Controlled

```dart
KumoDropdownMenu(
  open: menuOpen,
  onOpenChange: (v) => setState(() => menuOpen = v),
  triggerBuilder: (context, menu) => KumoButton(label: 'Actions', onPress: menu.toggle),
  items: [KumoDropdownItem(label: 'Purge cache', onPress: purgeCache)],
)
```

## Accessibility

- Rows are buttons; checkbox rows expose `checked`, radio rows `checked` + `inMutuallyExclusiveGroup`, link rows `link`, submenu rows `expanded`, the selected item `selected`. Disabled rows are announced as disabled.
- Keyboard: Enter, Space or ArrowDown on the trigger open the menu (ArrowDown and keyboard opens focus the first item). Up and Down move, Home and End jump. ArrowRight opens a submenu and focuses its first item; ArrowLeft or Escape closes it and returns focus to its row. Escape closes the menu and focus returns to the trigger. Tab stays inside the open menu.
- Opened by pointer, the menu panel takes focus so the first ArrowDown reaches the first item.

## Motion

- Opens from the trigger with `KumoAnchoredOverlay`'s scale-from-anchor spring (0.9 to 1, plus a 150ms fade) and closes along the same path; reopening mid-close turns around from where it is.
- Submenus open the same way from their row after a 100ms hover delay, and close 200ms after the pointer settles on another row, so a diagonal move toward a submenu does not close it.
- A checkbox or radio check lands with Kumo's small bounce (200ms, scale 0.5 to 1) and fades out over 100ms when cleared. Picking another radio option moves the check: the old one leaves while the new one lands. A value flipped back mid-flight reverses from where it is. Checks that are on when the menu opens show at rest.
- The sheet follows the finger and dismisses on a downward flick. Submenus slide and fade in place (200ms) while the sheet grows or shrinks to the new level's height with the same timing.
- `KumoDropdownCaret(open: menu.isOpen)` is a trigger caret that turns over while the menu is open (150ms, the popup's timing) and turns back from wherever it is.
- Reduced motion leaves fades only; checks, the caret and sheet levels change at once.

### KumoDropdownCaret

```dart
KumoDropdownMenu(
  triggerBuilder: (context, menu) => KumoButton(
    onPress: menu.toggle,
    child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
      const Text('image-resizer'),
      KumoDropdownCaret(open: menu.isOpen),
    ]),
  ),
  items: const [KumoDropdownItem(label: 'Rename')],
)
```

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `open` | `bool` | required | The menu is showing; the caret points the other way |
| `size` | `double` | `16` | Icon size |
| `icon` | `IconData` | `KumoIcons.caretDown` | Glyph at rest |

## Mobile

Below 768px (`presentation: KumoPresentation.auto`) the same items open in `showKumoSheet`: rows are at least 44px tall, `sheetTitle` heads the sheet, and a submenu replaces the list with a back row at the top. Checkbox and radio rows keep the sheet open and update live. Force a presentation with `KumoPresentation.popover` or `KumoPresentation.sheet`.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `DropdownMenu` `open` / `onOpenChange` | `open` / `onOpenChange` |
| `DropdownMenu.Trigger render={<Button/>}` | `triggerBuilder` |
| `DropdownMenu.Trigger` children | `trigger` |
| `DropdownMenu.Content side / align / sideOffset / alignOffset` | `side` / `align` / `sideOffset` / `alignOffset` |
| `DropdownMenu.Item` `icon`, `variant="danger"`, `selected`, `disabled`, `onClick` | `KumoDropdownItem` `icon`, `destructive`, `selected`, `disabled`, `onPress` |
| `DropdownMenu.Shortcut` | `KumoDropdownItem.shortcut` |
| `DropdownMenu.LinkItem href` | `KumoDropdownLinkItem.onPress` |
| `DropdownMenu.CheckboxItem checked / onCheckedChange` | `KumoDropdownCheckboxItem checked / onCheckedChange` |
| `DropdownMenu.RadioGroup value / onValueChange` + `RadioItem` + `RadioItemIndicator` | `KumoDropdownRadioGroup` + `KumoDropdownRadioItem` (indicator built in) |
| `DropdownMenu.Sub` + `SubTrigger` + `SubContent` | `KumoDropdownSubmenu` |
| `DropdownMenu.Group` / `Label` / `Separator` | `KumoDropdownGroup` / `KumoDropdownLabel` / `KumoDropdownSeparator` |
| `inset` | automatic |
| `closeOnClick` (Base UI) | `closeOnPress` |
