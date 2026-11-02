# KumoTracker

An uptime tracker: a row of day bars colored by status, a tooltip per bar with the date and status, a legend, and a spoken summary.

Kumo reference: none. Kumo has no tracker; this one is inspired by shadcn's tracker and colored with Kumo's status tokens.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTracker(
  label: 'image-resizer',
  valueText: '99.9% uptime',
  startLabel: '90 days ago',
  endLabel: 'Today',
  days: days,
)
```

## When to use / when not to

Use it for the health history of a service, a Worker or a health check, one bar per day (or per hour). For a single current status use a `KumoBadge`; for a trend over a continuous value use a chart.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `days` | `List<KumoTrackerDay>` | required | Oldest first; they draw from the start edge |
| `label` | `String?` | | Name of what is tracked, 14px medium |
| `valueText` | `String?` | | Figure opposite the label, such as `'99.95% uptime'` |
| `startLabel`, `endLabel` | `String?` | | Captions under the first and last bars |
| `showLegend` | `bool` | `true` | Swatch and name for each status present |
| `loading` | `bool` | `false` | Placeholder bars, no input |
| `error` | `String?` | | Replaces the bars with this message and an icon |
| `emptyText` | `String` | `'No status checks ran in this period'` | Shown when `days` is empty |
| `statusLabels` | `Map<KumoTrackerStatus, String>?` | | Replaces the English status names |
| `height` | `double` | `32` | Bar height |
| `semanticLabel` | `String?` | | Replaces `label` as the accessible name |

`KumoTrackerDay(date:, status:, note:)` is one bar. `note` adds detail to the tooltip ("Origin unreachable for 41 min").

`KumoTrackerStatus`: `operational` (`success`), `degraded` (`warning`), `outage` (`danger`), `noData` (`fill`).

## Examples

### Building the days

```dart
final today = DateTime(2026, 10, 31);
final days = [
  for (var i = 29; i >= 0; i--)
    KumoTrackerDay(
      date: today.subtract(Duration(days: i)),
      status: i == 6 ? KumoTrackerStatus.outage : KumoTrackerStatus.operational,
      note: i == 6 ? 'DNS resolution failures for 12 min' : null,
    ),
];
```

### Loading and error

```dart
KumoTracker(
  label: 'api.example.com',
  days: days,
  loading: request.isLoading,
  error: request.failed ? 'Could not load health checks for api.example.com' : null,
)
```

## Accessibility

Status is never color alone. Each bar's tooltip names the date, the status and the note; the legend names every color; and the tracker is one screen reader node whose label is a summary ("image-resizer, 99.9% uptime. 90 days: 84 operational, 3 degraded, 1 outage, 2 no data"). Screen reader users step through days with the increase and decrease actions (swipe up and down), and hear each day as the value.

Keyboard: the tracker is one Tab stop. Focus shows the latest day; Left and Right move between days (mirrored in RTL), Home and End jump to the first and last, Escape hides the tooltip.

## Motion

Hovering, scrubbing or arrowing moves the tooltip between bars without reopening it: it springs from where it is to the next bar (`KumoSprings.popup`) while its content switches at once, and a fresh tooltip opens at its bar. The other bars dim instantly, like a hover. The tooltip opens and closes with Kumo's popup motion and keeps its content while it fades out. The placeholder bars, the history, the error and the empty message cross-fade into each other (150ms). Under reduced motion the tooltip jumps and swaps are instant.

## Mobile

Tap a bar to see its day, or long press and slide to scrub across days; the tooltip stays 1.5s after the finger lifts. Bars share the width with 2px gaps, 1px when dense, and none when very dense, so 90 days fit a 390px phone.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| (no Kumo component) | |
| shadcn `TrackerData(level, tooltip)` | `KumoTrackerDay(status, note)` |
