# KumoTree

A nested list of expandable items with selection, keyboard arrows and lazy children: files in a Worker bundle, objects in an R2 bucket, zones by account.

Kumo reference: none. Kumo has no tree; this follows the ARIA tree pattern with Kumo's row styling (32px rows, `rounded-md`, `bg-kumo-tint` for hover and selection).

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTree(
  nodes: const [
    KumoTreeNode(id: 'src', label: 'src', icon: KumoIcons.folder, children: [
      KumoTreeNode(id: 'src/index.ts', label: 'index.ts', icon: KumoIcons.fileTs),
    ]),
  ],
  expanded: expanded,
  onExpandedChange: (ids) => setState(() => expanded = ids),
  value: selected,
  onValueChange: (id) => setState(() => selected = id),
)
```

## When to use / when not to

Use a tree when hierarchy matters and people browse it: folders, nested resources. For a flat list use a list or `KumoTable`; for two levels of navigation use the sidebar's groups.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `nodes` | `List<KumoTreeNode>` | required | Top-level nodes |
| `expanded` | `Set<Object>` | `{}` | Ids of expanded nodes |
| `onExpandedChange` | `ValueChanged<Set<Object>>?` | | Called with the next set |
| `value` | `Object?` | | Selected node id |
| `onValueChange` | `ValueChanged<Object>?` | | Called when a row is pressed or activated |
| `loadChildren` | `Future<List<KumoTreeNode>> Function(KumoTreeNode)?` | | Loads children of nodes with `hasChildren: true`; results are cached |
| `expandOnPress` | `bool` | `true` | Pressing a branch also toggles it |
| `showGuides` | `bool` | `false` | A hairline down each level |
| `indent` | `double` | `16` | Indent per level |
| `loadErrorText` | `String?` | `KumoStrings.loadFailedRetry` | Shown when `loadChildren` throws |
| `semanticLabel` | `String?` | | Names the tree |

`KumoTreeNode(id:, label:, icon:, expandedIcon:, children:, hasChildren:, trailing:, disabled:)`. Ids must be unique across the tree.

## Examples

### Lazy children

```dart
KumoTree(
  nodes: const [KumoTreeNode(id: 'assets', label: 'assets', icon: KumoIcons.folder, hasChildren: true)],
  expanded: expanded,
  onExpandedChange: (ids) => setState(() => expanded = ids),
  loadChildren: (node) async => const [KumoTreeNode(id: 'assets/logo.svg', label: 'logo.svg')],
)
```

### Guides

```dart
KumoTree(nodes: const [], showGuides: true, expanded: expanded, onExpandedChange: (ids) => setState(() => expanded = ids))
```

## Accessibility

- Rows are buttons named by the node label, with `expanded` state on branches, `selected` state when selection is on, and a hint ("Expand" or "Collapse" from `KumoStrings`).
- Keyboard: Up and Down move; Right expands, or moves to the first child when already open; Left collapses, or moves to the parent; Home and End jump; Enter and Space select. Left and Right swap in right-to-left layouts. The tree is one Tab stop: the last focused row, else the selected one, else the first.
- The loading row announces `KumoStrings.loading`.

## Motion

Children slide open and closed over 200ms while fading, clipped so rows never reflow mid-animation, and the caret turns with the same duration and curve, so all three finish together. Collapsing mid-open reverses from where it is. Lazy children cross-fade in over the loading row while the block eases to its new height. Reduced motion opens and closes instantly. Hover tints are instant.

## Mobile

Rows are 32px tall with a mouse and 44px on touch screens. Labels truncate with an ellipsis rather than wrap, so deep trees stay scannable; keep `indent` at 16 or less on phones.

## Kumo React mapping

Not in Kumo. Closest pieces: Kumo `Collapsible` for the open and close motion, and sidebar menu rows for the styling.

| Pattern | Flutter parameter |
| --- | --- |
| `aria-expanded` | `expanded` + `onExpandedChange` |
| `aria-selected` | `value` + `onValueChange` |
