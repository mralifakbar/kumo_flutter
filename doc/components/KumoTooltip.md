# KumoTooltip

Kumo's `Tooltip`: a short label for a control, shown on hover after a delay, at once on keyboard focus, and on long press with touch.

Kumo reference: https://kumo-ui.com/components/tooltip

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTooltip(
  content: 'Copy API token',
  child: KumoButton(icon: KumoIcons.copy, shape: KumoButtonShape.square, semanticLabel: 'Copy', onPress: () {}),
)
```

## When to use / when not to

Use tooltips to name icon-only controls or add a short hint. Never put the only copy of information or anything interactive in a tooltip; touch users may never see it. `KumoButton(title: ...)` adds one for you.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `content` | `String` | required | |
| `child` | `Widget` | required | The trigger |
| `side` | `KumoSide` | `top` | Flips when there is no room |
| `align` | `KumoAlign` | `center` | |
| `delay` | `Duration` | 600ms | Hover delay; after a tooltip closes the next opens without delay for 400ms |
| `closeDelay` | `Duration` | `zero` | |
| `touchDuration` | `Duration` | 1500ms | How long a long-press tooltip stays |
| `disabled` | `bool` | `false` | |
| `showArrow` | `bool` | `true` | |

## Examples

### Below the trigger

```dart
const KumoTooltip(content: 'Cached at the edge', side: KumoSide.bottom, child: KumoIcon(KumoIcons.info))
```

## Accessibility

The content is also exposed as the child's semantic tooltip, so screen readers read it without the popup. Keyboard focus (not taps) opens it; Escape closes it.

## Motion

Scales in from 0.9 toward the trigger and fades, 150ms, and leaves the same way, starting as soon as the pointer leaves (`closeDelay` is zero). Within 400ms of any tooltip closing, the next one opens without delay and without its entrance animation (Base UI's `data-instant`), so scanning a toolbar is quick; hovering the same tooltip again while it is still leaving turns its exit around from where it is instead. Escape and outside taps close it at once. Reduced motion keeps only a short fade.

## Mobile

Opens on long press and closes after `touchDuration`.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `content`, `side`, `align`, `delay`, `closeDelay`, `disabled` | same names |
| `render` / `asChild` | `child` |
