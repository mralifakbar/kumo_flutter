# KumoTimeline

A vertical list of events, each with a status marker, title, time and description: deployment history, audit logs, rollout steps.

Kumo reference: none. Kumo has no timeline; this one is built from Kumo tokens (status tints, `kumo-line` rail, Kumo text sizes).

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoTimeline(items: [
  KumoTimelineItem(
    title: 'Deployed to production',
    time: '2 min ago',
    status: KumoTimelineStatus.success,
    statusLabel: 'Succeeded',
  ),
  KumoTimelineItem(title: 'Worker created', time: 'Feb 27'),
])
```

## When to use / when not to

Use a timeline when order in time is the point. For a log people filter and sort, use `KumoTable`. For steps someone completes, use a stepper or a numbered list.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoTimelineItem>` | required | Newest first by convention. Empty renders nothing: show your own empty message |
| `semanticLabel` | `String?` | | Names the list ("Deployment history") |

`KumoTimelineItem`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String` | required | Medium weight |
| `time` | `String?` | | Pre-formatted, 12px subtle, tabular figures |
| `description` | `String?` | | 13px subtle |
| `status` | `KumoTimelineStatus` | `neutral` | `neutral` dot, `success` check, `warning` triangle, `danger` cross, `info` "i", `active` hourglass |
| `statusLabel` | `String?` | | The status in words, read with the item |
| `icon` | `IconData?` | | Replaces the status icon |
| `content` | `Widget?` | | Below the description |
| `trailing` | `Widget?` | | End of the title row |
| `onPress` | `VoidCallback?` | | Makes the item pressable |
| `semanticLabel` | `String?` | | Overrides what is read |
| `id` | `Object?` | | Stable identity; an item with an id that appears after the first build slides open and fades in |

## Examples

### Failed build with details

```dart
const KumoTimeline(items: [
  KumoTimelineItem(
    title: 'Build failed',
    time: 'Yesterday',
    description: 'wrangler.toml is missing compatibility_date.',
    status: KumoTimelineStatus.danger,
    statusLabel: 'Failed',
    content: KumoCode.block(code: 'Error: compatibility_date is required'),
  ),
])
```

### Pressable item

```dart
KumoTimeline(items: [
  KumoTimelineItem(
    title: 'Deployed version 7d1e9b3',
    status: KumoTimelineStatus.success,
    statusLabel: 'Succeeded',
    onPress: () {},
    semanticLabel: 'Open deployment 7d1e9b3',
  ),
])
```

## Accessibility

- Each item is one node: status label, title, time and description read together.
- Status is never color alone: every status has its own icon shape, and `statusLabel` says it in words.
- `active` is static (an hourglass). Nothing spins: a running deployment does not loop an animation forever.

## Motion

- Changing an item's `status` (running to succeeded) eases the marker's tint and ring and cross-fades its icon (150ms). The old status is dropped from the semantics tree at once.
- Items with an `id` that appear after the timeline first shows (a new event at the top) slide open and fade in over 200ms, so the events below move down instead of jumping. Items present on the first build never animate.
- Hover tints on pressable items are instant. Reduced motion makes every change instant.

## Mobile

Titles and descriptions wrap; the time stays on the title's first line. The rail and markers mirror in right-to-left layouts.

## Kumo React mapping

Not in Kumo.

| Concept | Flutter parameter |
| --- | --- |
| Event | `KumoTimelineItem` |
| Status color + icon | `status` + `statusLabel` |
