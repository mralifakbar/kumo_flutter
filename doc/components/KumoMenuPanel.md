# KumoMenuPanel

The shared parts of every menu and option list: `KumoMenuPanel` (surface), `KumoMenuRow` (row), `KumoMenuSeparator`, `KumoMenuGroupLabel` and `KumoMenuKeyboard` (arrow-key movement).

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoMenuPanel(children: [
  const KumoMenuGroupLabel('Worker'),
  KumoMenuRow(label: 'Rename', icon: KumoIcons.pencilSimple, onPress: () {}),
  KumoMenuRow(label: 'Duplicate', icon: KumoIcons.copy, shortcut: '⌘D', onPress: () {}),
  const KumoMenuSeparator(),
  KumoMenuRow(label: 'Delete', icon: KumoIcons.trash, destructive: true, onPress: () {}),
])
```

## When to use / when not to

Use `KumoDropdownMenu`, `KumoSelect` and the other finished components first. These parts are for custom lists that must look and behave like Kumo menus.

## Parameters

`KumoMenuPanel`: `children`, `minWidth` (144), `maxHeight`, `padding` (6), `scrollController`, `semanticLabel`. The panel scrolls when its content is taller than the room it has.

`KumoMenuRow`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | |
| `onPress` | `VoidCallback?` | | |
| `icon` / `leading` | `IconData?` / `Widget?` | | |
| `description` | `String?` | | Second line in subtle text |
| `trailing` | `Widget?` | | A check, a caret |
| `shortcut` | `String?` | | Shortcut hint |
| `selected`, `checked`, `inMutuallyExclusiveGroup`, `expanded` | `bool?` | | Semantic state |
| `highlighted` | `bool` | `false` | Force the highlight (combobox lists driven from a text field) |
| `disabled`, `destructive`, `inset` | `bool` | `false` | `inset` aligns labels with checkable rows |
| `focusNode`, `autofocus`, `semanticLabel` | | | |

## Accessibility

Rows are focusable buttons; Up and Down move between them, Home and End jump to the ends. Group labels are headings.

## Motion

Rows highlight instantly on hover or focus. They do not scale on press.

## Mobile

Rows grow to 40px minimum height on touch platforms.
