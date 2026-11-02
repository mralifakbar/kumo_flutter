# KumoLoader

Kumo's `Loader`: a spinner for work of unknown length.

Kumo reference: https://kumo-ui.com/components/loader

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoLoader()
```

## When to use / when not to

Use it inline (in buttons, next to a status) or for a panel that is loading. For content with a known shape, prefer skeleton placeholders (`KumoSkeletonLine`). Pair a long wait with text that says what is loading.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `size` | `KumoLoaderSize` | `base` | `sm` 16, `base` 24, `lg` 32 |
| `dimension` | `double?` | | Exact size; overrides `size` |
| `color` | `KumoColor?` | | Defaults to the surrounding text color |
| `dangerouslySetColor` | `Color?` | | |
| `semanticLabel` | `String?` | `KumoStrings.loading` | Accessible name; pass `''` when nearby text already says what is loading |

## Examples

### Panel loading state

```dart
const Column(mainAxisSize: MainAxisSize.min, children: [
  KumoLoader(size: KumoLoaderSize.lg, semanticLabel: 'Loading deployments'),
  SizedBox(height: 8),
  KumoText('Loading deployments', variant: KumoTextVariant.secondary),
])
```

## Accessibility

Announced as a live region with its label.

## Motion

The arc grows, travels and shrinks around a faint track (Kumo's SVG timing: 2s rotation, 1.5s dash). It runs only while mounted and on screen; under reduced motion it shows a still arc. Inside `KumoButton` the spinner cross-fades with the icon it replaces.

## Mobile

No changes.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `size="sm"` / `size={20}` | `size: KumoLoaderSize.sm` / `dimension: 20` |
| `aria-label` | `semanticLabel` |
