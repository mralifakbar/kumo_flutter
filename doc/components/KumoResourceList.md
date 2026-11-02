# KumoResourceList

The page for a list of resources (Workers, buckets, namespaces): a title with an icon and description, resource cards with metadata, status and actions, an aside for usage notes, and loading, empty and error states.

Kumo reference: https://kumo-ui.com/blocks/resource-list

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoResourceList(
  title: 'KV namespaces',
  description: 'Store key-value data globally with low-latency reads.',
  icon: KumoIcons.database,
  actions: [KumoButton(label: 'Create namespace', variant: KumoButtonVariant.primary, onPress: () {})],
  children: [
    KumoResourceListItem(
      title: 'production-cache',
      mono: true,
      metadata: const ['Created 2 days ago', 'Bound to 3 Workers'],
      status: const KumoResourceListStatus(label: 'Active', tone: KumoResourceListStatusTone.success),
      actions: [KumoButton(label: 'View keys', size: KumoButtonSize.sm, onPress: () {})],
      onPress: () {},
    ),
  ],
)
```

## When to use / when not to

Use it for a top-level list of things a user owns. For dense, sortable data with many columns, put a table in `children` instead of item cards. It scrolls by itself; pass `scrollable: false` when it sits in a scroll view already.

## Parameters

### KumoResourceList

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String?` | | 30px semibold, the level 1 heading |
| `description` | `String?` | | 16px subtle; shown from 768px up, as in Kumo |
| `icon` / `iconWidget` | `IconData?` / `Widget?` | | 32px subtle icon before the title |
| `actions` | `List<Widget>` | `[]` | After the title; wrap below it under 768px |
| `usage` | `Widget?` | | Aside: a quick start or snippet |
| `additionalContent` | `Widget?` | | Aside: links, limits |
| `children` | `List<Widget>` | `[]` | Usually `KumoResourceListItem`s, 16px apart. Give each a `Key` (the resource ID) and added or removed cards grow in or collapse out |
| `loading` | `bool` | `false` | Placeholder cards in place of `children` |
| `loadingLabel` | `String?` | `'Loading'` | Announced while loading |
| `error` | `String?` | | Error panel in place of the list; say what failed |
| `onRetry` | `VoidCallback?` | | Shows a retry button in the error panel |
| `retryLabel` | `String?` | `KumoStrings.retry` ("Retry") | Label of the error state's retry button |
| `empty` | `Widget?` | `KumoResourceListEmpty()` | Shown when `children` is empty |
| `scrollable` | `bool` | `true` | Wrap in a vertical scroll view |
| `controller` | `ScrollController?` | | |

Precedence: `loading`, then `error`, then `empty`, then `children`.

### KumoResourceListItem

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String` | required | One line, truncates |
| `metadata` | `List<String>` | `[]` | Joined with a middle dot under the title |
| `status` | `KumoResourceListStatus?` | | `label`, `tone` (`neutral`, `success`, `warning`, `danger`, `info`), optional `icon` |
| `actions` | `List<Widget>` | `[]` | Stay separate targets from the card |
| `leading` | `Widget?` | | Before the title |
| `onPress` | `VoidCallback?` | | Makes the card a button |
| `semanticLabel` | `String?` | `title` | |
| `mono` | `bool` | `false` | Monospace title for IDs and hostnames |

### KumoResourceListEmpty

`title` (default `'No resources yet'`), `description`, `icon` (default folder), `action`.

## Examples

### States

```dart
KumoResourceList(
  title: 'R2 buckets',
  loading: loading,
  error: failed ? 'Could not load buckets. Check your connection and try again.' : null,
  onRetry: reload,
  empty: KumoResourceListEmpty(
    title: 'No buckets yet',
    description: 'Create a bucket to store objects without egress fees.',
    action: KumoButton(label: 'Create bucket', variant: KumoButtonVariant.primary, onPress: () {}),
  ),
  children: const [],
)
```

### With an aside

```dart
KumoResourceList(
  title: 'API tokens',
  usage: const KumoLayerCard(child: KumoText('Send the token in the Authorization header.')),
  additionalContent: const KumoLayerCard(child: KumoText('Tokens can be scoped to one zone.')),
  children: const [KumoResourceListItem(title: 'Deploy Workers')],
)
```

## Accessibility

- The title is the level 1 heading; empty-state titles are headings too.
- Status pairs color with an icon and text.
- A pressable card is one button named by its title; its action buttons stay separately reachable.
- Loading and error states are live regions, so screen readers hear the change.

## Motion

- Pressable cards scale to 0.98 on press; hover tint is instant. Placeholders do not shimmer.
- Loading, error, empty and the list cross-fade over 150ms while the space they take eases to its new height over 200ms, so the page never flashes between states.
- With keyed `children`, a removed card fades and collapses over 200ms and the cards below slide up, gap included; an added card grows in the same way. A card that comes back while leaving turns around from where it is.
- Reduced motion: state changes and card removals happen in one frame.

## Mobile

Page padding is 24px below 768px, 32px from 768px and 40px from 1024px. Below 480px of card width, status and actions move under the title. Below 1280px the `usage` aside moves above the list and `additionalContent` below it.

## Kumo React mapping

| Kumo `ResourceListPage` | Flutter |
| --- | --- |
| `title`, `description`, `icon` | `title`, `description`, `icon` / `iconWidget` |
| `usage`, `additionalContent` | `usage`, `additionalContent` |
| `children` | `children` |
| (not in Kumo) | `actions`, `loading`, `error`, `onRetry`, `empty`, `KumoResourceListItem` |
