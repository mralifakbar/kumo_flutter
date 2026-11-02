# showKumoAlertDialog

Asks the user to confirm one action and returns `true` only when they pick it; Cancel, Escape and the back gesture return `false`.

Kumo reference: https://kumo-ui.com/components/dialog (Alert Dialog)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<void> deleteBucket(BuildContext context) async {
  final confirmed = await showKumoAlertDialog(
    context,
    title: 'Delete R2 bucket "assets"?',
    description: 'Every object in the bucket is removed. This cannot be undone.',
    confirmLabel: 'Delete bucket',
    destructive: true,
  );
  if (confirmed) debugPrint('Deleting assets');
}
```

## When to use / when not to

- Use for a single yes-or-no confirmation before a consequential action.
- Name the action in `confirmLabel` ("Delete bucket", "Purge cache"), never "OK" or "Yes".
- For confirmations that need extra content (a typed resource name, a list of affected routes), build a `KumoDialog` with `role: KumoDialogRole.alertDialog`, or a `KumoLayerDialog.alert`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `context` | `BuildContext` | required, positional | |
| `title` | `String` | required | The question, sentence case. |
| `description` | `String?` | `null` | The consequence. |
| `confirmLabel` | `String` | required | Text of the confirm button. |
| `cancelLabel` | `String?` | `KumoStrings.cancel` | Text of the cancel button. |
| `destructive` | `bool` | `false` | Red confirm button, a warning badge before the title, and initial focus on Cancel. |
| `icon` | `IconData?` | `null` | Badge icon. Defaults to `KumoIcons.warningFill` when `destructive`; without it a non-destructive dialog has no badge. |
| `size` | `KumoDialogSize` | `base` | |
| `useRootNavigator` | `bool` | `true` | |

Returns `Future<bool>`.

## Examples

### Non-destructive confirmation

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<bool> confirmPurge(BuildContext context) => showKumoAlertDialog(
      context,
      title: 'Purge everything for example.com?',
      description: 'Visitors get uncached responses until the cache warms up again.',
      confirmLabel: 'Purge cache',
    );
```

## Accessibility

Announced as an alert dialog; the title names the route. A backdrop tap does not dismiss it, so the user makes an explicit choice; Escape counts as Cancel. With `destructive`, Cancel has focus when the dialog opens.

## Motion

Same as `KumoDialog`: a 150ms fade and scale from 0.9, a cross-fade under reduced motion.

## Mobile

Full width minus 16px gutters below 768px. The two buttons wrap onto separate lines when they do not fit.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `Dialog.Root role="alertdialog"` | built in |
| `Dialog.Title` | `title:` |
| `Dialog.Description` | `description:` |
| `Dialog.Close render={<Button variant="secondary">Cancel</Button>}` | `cancelLabel:` |
| `Dialog.Close render={<Button variant="destructive">Delete</Button>}` | `confirmLabel:` + `destructive: true` |
| Warning badge in the title row | `icon:` / `destructive:` |
