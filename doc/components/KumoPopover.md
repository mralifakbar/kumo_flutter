# KumoPopover

Rich, interactive content anchored to a trigger: a notification list, a small settings form, a confirmation with buttons.

Kumo reference: https://kumo-ui.com/components/popover

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoPopover(
  triggerBuilder: (context, popover) => KumoButton(
    icon: KumoIcons.bell,
    shape: KumoButtonShape.square,
    semanticLabel: 'Notifications',
    onPress: popover.toggle,
  ),
  children: const [
    KumoPopoverTitle('Notifications'),
    KumoPopoverDescription('No new alerts for example.com.'),
  ],
)
```

## When to use / when not to

- Use a popover when people interact with the content (links, buttons, inputs).
- For a short label on an icon button, use `KumoTooltip`. For a list of commands, use `KumoDropdownMenu`. For a preview on hover, use `KumoHoverCard`. For a blocking decision, use a dialog.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | Stacked top to bottom (Kumo's `flex flex-col`), stretched to the popup width |
| `triggerBuilder` | `KumoPopoverTriggerBuilder?` | | `(context, popover) => Widget`; call `popover.toggle`, `open` or `close` |
| `trigger` | `Widget?` | | Non-interactive content made pressable. Pass exactly one of `trigger` and `triggerBuilder` |
| `open` | `bool?` | `null` | Controls the open state; null lets the popover manage it |
| `onOpenChange` | `ValueChanged<bool>?` | | |
| `side` | `KumoSide` | `bottom` | Flips when there is no room |
| `align` | `KumoAlign` | `center` | |
| `sideOffset` | `double` | `8` | The arrow sits in this gap |
| `alignOffset` | `double` | `0` | |
| `showArrow` | `bool` | `true` | Kumo's `Popover.Arrow` |
| `width` | `double?` | `null` | Fixed width (Kumo demos use 288); null fits the content |
| `maxWidth` | `double` | `360` | Upper bound when `width` is null |
| `padding` | `EdgeInsetsGeometry` | `symmetric(horizontal: 16, vertical: 12)` | Kumo's `px-4 py-3` |
| `semanticLabel` | `String?` | first `KumoPopoverTitle` | Accessible name of the popup |
| `dismissOnOutsideTap` | `bool` | `true` | |
| `closeOnEscape` | `bool` | `true` | |
| `disabled` | `bool` | `false` | |
| `onClosed` | `VoidCallback?` | | After the close animation |

### Parts

| Widget | Parameters | Notes |
| --- | --- | --- |
| `KumoPopoverTitle` | `text` (positional) | 14px medium, 24px line height, announced as a header |
| `KumoPopoverDescription` | `text` (positional) | 14px subtle, 24px line height |
| `KumoPopoverClose` | `label` (default `KumoStrings.close`), `onPress`, `variant = secondary`, `size = sm`, `icon`, `alignment = centerStart` | A button that runs `onPress`, then closes |

`KumoPopover.closeFrom(context)` closes the popover from any widget inside it and returns false when there is none.

## Examples

### Close button

```dart
KumoPopover(
  triggerBuilder: (context, popover) => KumoButton(label: 'Cache settings', onPress: popover.toggle),
  children: [
    const KumoPopoverTitle('Browser cache TTL'),
    const KumoPopoverDescription('How long browsers keep cached files.'),
    const SizedBox(height: 12),
    KumoPopoverClose(label: 'Save', variant: KumoButtonVariant.primary, onPress: saveTtl),
  ],
)
```

### Placement

```dart
KumoPopover(
  side: KumoSide.right,
  align: KumoAlign.start,
  triggerBuilder: (context, popover) => KumoButton(label: 'Details', onPress: popover.toggle),
  children: const [KumoPopoverDescription('Opens to the right.')],
)
```

### Close from custom content

```dart
KumoPopover(
  width: 288,
  triggerBuilder: (context, popover) => KumoButton(label: 'Rename', onPress: popover.toggle),
  children: [
    Builder(
      builder: (context) => KumoButton(
        label: 'Apply',
        onPress: () {
          applyRename();
          KumoPopover.closeFrom(context);
        },
      ),
    ),
  ],
)
```

## Accessibility

- The popup is a semantics container named by `semanticLabel` or its first title; the title is a header.
- Focus moves into the popover when it opens and Tab cycles inside it. Escape, an outside tap or a close button closes it, and focus returns to what had it before (the trigger, when opened from the keyboard).
- `trigger` slots announce as buttons with an expanded state.

## Motion

Kumo's popup motion: scale from 0.9 with a fade, anchored on the trigger, through `KumoAnchoredOverlay`'s spring; it closes along the same path and turns around if reopened mid-close. Reduced motion keeps only the fade.

## Mobile

The popup stays inside the screen and the safe area, shifting along its edge; tall content scrolls inside the room it has. It does not switch to a sheet: on narrow screens keep popovers short, or use a sheet directly for long forms.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `Popover.Root open / onOpenChange` | `open` / `onOpenChange` |
| `Popover.Trigger render={<Button/>}` | `triggerBuilder` |
| `Popover.Positioner side / align / sideOffset / alignOffset` | `side` / `align` / `sideOffset` / `alignOffset` |
| `Popover.Arrow` | `showArrow` |
| `Popover.Popup className="w-72"` | `width: 288` |
| `Popover.Title` / `Popover.Description` | `KumoPopoverTitle` / `KumoPopoverDescription` |
| `Popover.Close render={<Button/>}` | `KumoPopoverClose` |
| `Popover.Trigger openOnHover delay` | not ported; use `KumoHoverCard` |
| `Popover.Content anchor` (virtual anchor) | not ported |
