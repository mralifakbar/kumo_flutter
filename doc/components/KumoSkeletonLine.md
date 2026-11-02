# KumoSkeletonLine

Kumo's `SkeletonLine`: a placeholder bar that stands in for a line of text while it loads.

Kumo reference: https://kumo-ui.com/components/skeleton-line

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoSkeletonLine()
```

## When to use / when not to

Use skeleton lines for content with a known shape (a card, a list row, a settings panel) while it loads. For a wait without a known shape, or inside a button, use `KumoLoader`. For work with a known amount, use `KumoProgress`.

The line needs a bounded width: place it in a `Column`, an `Expanded` or a `SizedBox`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `widthFactor` | `double?` | | Exact width as a fraction (0 to 1) of the available width |
| `minWidth` | `double` | `30` | Lower bound of the random width, in percent |
| `maxWidth` | `double` | `100` | Upper bound of the random width, in percent |
| `height` | `double` | `8` | Bar height (Kumo's 0.5rem) |
| `blockHeight` | `double?` | | Height of a box that centers the bar, to match a known line height |
| `animate` | `bool` | `false` | Runs the shimmer. Pass the loading flag |
| `semanticLabel` | `String?` | | Announces the placeholder. Set it on one line per group |

Without `widthFactor`, each line picks a width between `minWidth` and `maxWidth` once, when it mounts, so a stack of lines looks like ragged text.

## Examples

### Card loading state

```dart
KumoLayerCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KumoSkeletonLine(widthFactor: 0.5, blockHeight: 24, animate: loading, semanticLabel: 'Loading zone settings'),
      KumoSkeletonLine(blockHeight: 21, animate: loading),
      KumoSkeletonLine(blockHeight: 21, minWidth: 50, maxWidth: 70, animate: loading),
    ],
  ),
)
```

### Fixed widths

```dart
const Column(children: [
  KumoSkeletonLine(widthFactor: 0.9),
  SizedBox(height: 12),
  KumoSkeletonLine(widthFactor: 0.6),
])
```

## Accessibility

Lines are hidden from screen readers unless they have a `semanticLabel`. Label one line per group ("Loading DNS records") so the wait is announced once.

## Motion

**Static by default.** Kumo's web shimmer loops forever. Here a line only shimmers while `animate` is true, and callers should tie that to a real loading flag, never a constant: a placeholder that stays on screen (a stalled request, a list that never fills) then stops moving instead of drawing the eye indefinitely, and no ticker runs for a placeholder nobody is waiting on. The shimmer pauses off screen (`TickerMode`) and is replaced by the still line under reduced motion. Its timing follows Kumo: a gradient sweeps across in 1.3 to 1.7s with a random 0 to 0.5s offset per line.

**Skeleton to content.** Swap the placeholder for the content with a brief cross-fade rather than a cut, and give the skeleton the content's height (`blockHeight`) so nothing below moves:

```dart
AnimatedSwitcher(
  duration: KumoMotion.duration(context, KumoDurations.fast),
  child: loading
      ? const KumoSkeletonLine(key: ValueKey('skeleton'), blockHeight: 20, animate: true)
      : const Text('image-resizer', key: ValueKey('content')),
)
```

## Mobile

No changes.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `minWidth`, `maxWidth` | `minWidth`, `maxWidth` (same percent units) |
| `blockHeight` (number) | `blockHeight` |
| `className="h-4"` | `height: 16` |
| `minDuration`, `maxDuration`, `minDelay`, `maxDelay` | not ported; Kumo's defaults apply |
| (always shimmering) | `animate: true` while loading |

The colors are Kumo's hard-coded skeleton colors (`#f3f4f6` in light mode, white at 6% in dark), not theme tokens, matching Kumo's CSS.
