# KumoHoverCard

A preview card that opens while the pointer rests on a link or name: a Worker's last deployment, a zone's status.

Kumo reference: none (Kumo has no hover card; the behavior follows shadcn's `HoverCard`). The surface matches https://kumo-ui.com/components/popover

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoHoverCard(
  content: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      KumoText('image-resizer', bold: true),
      KumoText('Last deployed 2 hours ago', variant: KumoTextVariant.secondary),
    ],
  ),
  child: KumoButton(label: 'image-resizer', variant: KumoButtonVariant.ghost, isLink: true, onPress: openWorker),
)
```

## When to use / when not to

- Use it to preview what a link leads to, for people who use a pointer.
- Never make it the only way to reach information: touch and screen reader users can miss it. The trigger must lead to the full page.
- For a short label, use `KumoTooltip`. For content people act on, use `KumoPopover`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The trigger; keep it interactive on its own |
| `content` | `Widget` | required | Card content; scrolls if taller than the room |
| `openDelay` | `Duration` | `700ms` | Hover time before opening |
| `closeDelay` | `Duration` | `300ms` | Time after the pointer leaves the trigger and card |
| `side` | `KumoSide` | `bottom` | |
| `align` | `KumoAlign` | `center` | |
| `sideOffset` | `double` | `8` | |
| `alignOffset` | `double` | `0` | |
| `showArrow` | `bool` | `false` | |
| `width` | `double?` | `256` | shadcn's `w-64`; null fits the content |
| `padding` | `EdgeInsetsGeometry` | `all(16)` | |
| `disabled` | `bool` | `false` | |
| `open` | `bool?` | `null` | Controls the open state; null lets hover and focus drive it |
| `onOpenChange` | `ValueChanged<bool>?` | | |

## Examples

### Controlled

```dart
KumoHoverCard(
  open: previewOpen,
  onOpenChange: (v) => setState(() => previewOpen = v),
  content: const KumoText('Zone example.com is active'),
  child: const KumoText('example.com'),
)
```

## Accessibility

- Opens while the trigger has keyboard focus and closes when focus leaves; Escape closes it.
- It never takes focus from the page. Content is readable by screen readers while open, but treat it as a bonus.

## Motion

Opens from the trigger with `KumoAnchoredOverlay`'s scale-from-anchor spring after `openDelay`, and closes along the same path. Moving the pointer from the trigger onto the card keeps it open. Reduced motion keeps only the fade.

## Mobile

Touch has no hover: a long press opens the card (with a medium haptic) and a tap anywhere else closes it. A plain tap still activates the trigger.

## Kumo React mapping

| shadcn prop | Flutter parameter |
| --- | --- |
| `HoverCard openDelay / closeDelay` | `openDelay` / `closeDelay` |
| `HoverCard open / onOpenChange` | `open` / `onOpenChange` |
| `HoverCardTrigger` | `child` |
| `HoverCardContent side / align / sideOffset` | `side` / `align` / `sideOffset` |
