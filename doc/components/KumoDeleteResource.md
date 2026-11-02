# KumoDeleteResource

A confirmation dialog for deleting a resource: the destructive button stays disabled until the user types the resource's name.

Kumo reference: https://kumo-ui.com/blocks/delete-resource

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoDeleteResource(
  open: open,
  onOpenChange: (v) => setState(() => open = v),
  resourceType: 'Zone',
  resourceName: 'example.com',
  isDeleting: deleting,
  onDelete: () async {
    setState(() => deleting = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      deleting = false;
      open = false;
    });
  },
  child: KumoButton(
    label: 'Delete zone',
    variant: KumoButtonVariant.destructive,
    onPress: () => setState(() => open = true),
  ),
)
```

## When to use / when not to

Use it for deletions that cannot be undone and take a resource's data with them (zones, Workers, buckets, namespaces). For reversible or low-stakes removals, use a plain confirm dialog or an undo toast instead; typing a name for every small delete teaches people to ignore it.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `open` | `bool` | required | Keep the widget mounted and drive this; the dialog animates in and out |
| `onOpenChange` | `ValueChanged<bool>` | required | Cancel, close, Escape and backdrop tap call it with false (not while deleting) |
| `resourceType` | `String` | required | "Zone", "Worker". Used in the copy and the default button |
| `resourceName` | `String` | required | The exact name to type |
| `onDelete` | `FutureOr<void> Function()` | required | Runs when confirmed |
| `isDeleting` | `bool` | `false` | Spinner on the button; field, Cancel, close and dismissal disabled |
| `caseSensitive` | `bool` | `true` | |
| `deleteButtonText` | `String?` | `'Delete {resourceType}'` | |
| `errorMessage` | `String?` | | Error banner above the copy |
| `size` | `KumoDeleteResourceSize` | `base` | Width from 768px, as `KumoDialogSize`: `sm` 288, `base` 384 |
| `child` | `Widget?` | | Rendered in place, usually the trigger button |

## Examples

### Failed delete

```dart
KumoDeleteResource(
  open: open,
  onOpenChange: (v) => setState(() => open = v),
  resourceType: 'Worker',
  resourceName: 'image-resizer',
  errorMessage: 'Could not delete image-resizer. Remove its routes first.',
  onDelete: () {},
)
```

## Accessibility

- The dialog is a modal route named "Delete {name}"; focus is trapped inside and returns to the trigger on close. The field is focused on open and named "Type {name} to confirm deletion".
- The name chip is a button, "Copy {name} to clipboard"; copying shows a check and announces "Copied".
- The error banner is a live region. Enter in the field confirms once the name matches.

## Motion

- Built on `KumoDialogRoot` and `KumoDialog`, so it has Kumo's dialog motion: fade with a scale from 0.9 over 150ms, on the same path in and out.
- The delete button eases from its disabled look as the typed name matches.
- The error banner (a `KumoBanner`) grows in over 200ms and cross-fades, so the copy below slides instead of jumping.
- Reduced motion keeps only a short fade for the dialog; the button and banner change in one frame.

## Mobile

Below 768px the dialog takes the full width minus 16px gutters, 32px from the top, and scrolls when the keyboard or 2x text needs the room.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `open`, `onOpenChange` | `open`, `onOpenChange` |
| `resourceType`, `resourceName` | `resourceType`, `resourceName` |
| `onDelete`, `isDeleting` | `onDelete`, `isDeleting` |
| `caseSensitive`, `deleteButtonText`, `errorMessage` | same names |
| `size="sm" \| "base"` | `KumoDeleteResourceSize.sm` / `.base` |
| trigger outside the component | `child` |
