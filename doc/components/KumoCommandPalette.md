# KumoCommandPalette

A searchable list of commands, opened with Cmd+K or Ctrl+K. Reach for it to let keyboard users jump to any page or action without the navigation.

Kumo reference: https://kumo-ui.com/components/command-palette

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoCommandPaletteShortcut(
  onTrigger: () => showKumoCommandPalette(
    context: context,
    placeholder: 'Type a command or search',
    groups: [
      KumoCommandGroup(label: 'Workers', items: [
        KumoCommandItem(title: 'Deploy image-resizer', icon: KumoIcons.rocket, onSelect: () => deploy()),
        KumoCommandItem(title: 'Create Worker', icon: KumoIcons.plus, shortcut: 'N', onSelect: () => create()),
      ]),
    ],
  ),
  child: const DashboardPage(),
)
```

## When to use / when not to

- Use it as a global shortcut layer over an app with many pages and actions.
- It is not a replacement for visible navigation or buttons; every command should also be reachable without it.
- For searching one list in a form, use `KumoCombobox`.

## API

### `showKumoCommandPalette`

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `context` | `BuildContext` | required | |
| `groups` | `List<KumoCommandGroup>` | required | Local commands, filtered as you type |
| `onSearch` | `KumoCommandSearch?` | | `(query) async => groups` shown after the local results, with loading and error rows |
| `filter` | `bool Function(KumoCommandItem, String)?` | built in | Replaces the built-in matching; `KumoCommandPalette.noFilter` keeps everything |
| `placeholder` | `String?` | | Search field placeholder; also the dialog's name |
| `emptyMessage` | `String?` | `KumoStrings.noResults` | |
| `footer` | `Widget?` | | Key hints; dialog only |
| `onSelect` | `void Function(KumoCommandItem, {required bool newTab})?` | | After the item's own `onSelect` |
| `presentation` | `KumoPresentation` | `auto` | Dialog on wide screens, full-height sheet below 768px |
| `semanticLabel` | `String?` | `placeholder` | |
| `useRootNavigator` | `bool` | `true` | |

Returns `Future<KumoCommandItem?>`: the command that ran, or null when dismissed. Only one palette opens at a time.

### `KumoCommandPalette` (the panel)

Same content parameters (`groups`, `onSearch`, `filter`, `placeholder`, `emptyMessage`, `footer`, `onSelect`) plus:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `loading` | `bool` | `false` | Shows `KumoCommandPaletteLoading` in place of results |
| `searchErrorMessage` | `String?` | `KumoStrings.searchFailed` | Shown when `onSearch` throws |
| `onClose` | `ValueChanged<KumoCommandItem?>?` | | The panel asks to close: with the command that ran, or null on Escape |
| `onQueryChange` | `ValueChanged<String>?` | | |
| `initialQuery` | `String` | `''` | |
| `inputLeading` / `inputTrailing` | `Widget?` | | Replace the search icon (a back button) / add to the search row |
| `autofocus` | `bool` | `true` | |
| `expand` | `bool` | `false` | Fill the height (full-height sheets) |

### Data

| Type | Parameters |
| --- | --- |
| `KumoCommandGroup` | `label` (optional), `items` |
| `KumoCommandItem` | `title`, `id`, `icon`, `description`, `breadcrumbs`, `shortcut`, `keywords`, `external`, `disabled`, `showArrow = true`, `onSelect`, `value` |

### Parts

| Widget | Kumo part |
| --- | --- |
| `KumoCommandPaletteInput` | `CommandPalette.Input` |
| `KumoCommandPaletteGroupLabel` | `CommandPalette.GroupLabel` |
| `KumoCommandPaletteItem` | `CommandPalette.Item` / `ResultItem` |
| `KumoCommandPaletteHighlightedText` | `CommandPalette.HighlightedText` (`highlights`: inclusive `(start, end)` records) |
| `KumoCommandPaletteEmpty` | `CommandPalette.Empty` |
| `KumoCommandPaletteLoading` | `CommandPalette.Loading` |
| `KumoCommandPaletteFooter` | `CommandPalette.Footer` |
| `KumoCommandPaletteKeyHint`, `KumoCommandPaletteKbd` | the footer's `kbd` hints |
| `KumoCommandPaletteShortcut` | Cmd/Ctrl+K listener; `KumoCommandPaletteShortcut.label()` gives "⌘K" or "Ctrl K" |

## Examples

### Footer hints

```dart
showKumoCommandPalette(
  context: context,
  groups: commands,
  footer: const KumoCommandPaletteFooter(children: [
    KumoCommandPaletteKeyHint(label: 'Navigate', keys: ['Up', 'Down'], icons: [KumoIcons.arrowUp, KumoIcons.arrowDown]),
    KumoCommandPaletteKeyHint(label: 'Run', keys: ['Enter'], icons: [KumoIcons.arrowElbowDownLeft]),
    KumoCommandPaletteKeyHint(label: 'Close', keys: ['Esc']),
  ]),
);
```

### Remote results

```dart
showKumoCommandPalette(
  context: context,
  groups: commands,
  onSearch: (query) async {
    final buckets = await api.searchBuckets(query);
    return [
      KumoCommandGroup(label: 'R2 buckets', items: [
        for (final b in buckets) KumoCommandItem(title: b, breadcrumbs: const ['R2'], icon: KumoIcons.archive),
      ]),
    ];
  },
);
```

### Embedded panel

```dart
SizedBox(
  height: 360,
  child: KumoCommandPalette(autofocus: false, placeholder: 'Filter commands', groups: commands),
)
```

## Matching

Every word typed must appear in the title, breadcrumbs, description or keywords; a word of three letters or more may also match the title's letters in order ("dpl" finds "Deploy"). Within a group, titles that start with the query come first, then word starts, then other matches; matched letters are marked with `bg-kumo-warning/50`. Groups keep their order and empty groups disappear. Remote results are shown as returned.

## Accessibility

- The search field takes focus when the palette opens and keeps it: Up and Down move the highlight (wrapping, skipping disabled commands), Enter runs, Cmd+Enter (Ctrl+Enter elsewhere) runs with `newTab: true`, Escape closes. Focus returns to where it was.
- Rows are buttons named by breadcrumbs and title, with the description as a hint; the highlighted row is announced as selected; `external` rows are links.
- Empty, loading and error states are live regions; the error has an icon as well as color.

## Motion

The dialog fades and scales from 0.9 (Kumo's 150ms dialog motion); reduced motion keeps a short fade. While filtering, rows are reused in place so they never flash, and the panel's height follows the results over 150ms instead of jumping. The keyboard highlight and its arrow fade between rows over 100ms (Kumo's `transition-colors`); the pointer's own hover shows at once. Loading, empty, error and results states fade in when they swap. The sheet follows the finger and dismisses with a downward flick. Under reduced motion the height, highlight and swaps change at once.

## Mobile

Below 768px the palette is a full-height sheet with a Cancel button beside the search field and no footer (key hints mean little on a touch keyboard). The results area sits above the on-screen keyboard. Rows are 44px tall on touch platforms.

## Kumo React mapping

| Kumo prop / part | Flutter |
| --- | --- |
| `CommandPalette.Root open/onOpenChange` | `showKumoCommandPalette` (route) |
| `CommandPalette.Dialog` + `Panel` | `KumoDialogRoute` + `KumoCommandPalette` |
| `items` + `Results` / `Items` render props | `groups: [KumoCommandGroup(...)]` |
| `value`, `onValueChange` | `initialQuery`, `onQueryChange` |
| `filter` (pass-through default) | `filter` (built-in matching by default; `KumoCommandPalette.noFilter` for Kumo's default) |
| `onSelect(item, {newTab})` | `onSelect(item, newTab:)` and `KumoCommandItem.onSelect` |
| `ResultItem` `title`, `breadcrumbs`, `titleHighlights`, `description`, `icon`, `external`, `showArrow` | `KumoCommandItem` fields; highlights are computed |
| `Input leading/trailing` | `inputLeading`, `inputTrailing` |
| `Empty`, `Loading`, `Footer` | `emptyMessage`, `loading`, `footer` |
| `getSelectableItems`, `itemToStringValue`, `onItemHighlighted` | not needed |
