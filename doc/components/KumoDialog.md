# KumoDialog

A modal panel near the top of the screen over a recessed backdrop, for focused tasks and confirmations that block the page behind them.

Kumo reference: https://kumo-ui.com/components/dialog

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<void> renameWorker(BuildContext context) async {
  final name = await showKumoDialog<String>(
    context,
    builder: (context) => const KumoDialog(
      title: 'Rename Worker',
      description: 'Routes keep working; the workers.dev URL changes.',
      actions: [
        KumoDialogClose(label: 'Cancel'),
        KumoDialogClose(label: 'Rename', variant: KumoButtonVariant.primary, result: 'thumbnailer'),
      ],
    ),
  );
  debugPrint('Renamed to $name');
}
```

## When to use / when not to

- Use for a short task or decision that must finish before the user goes on: renaming a resource, editing a record, confirming a change.
- Use `KumoDialogRole.alertDialog` (or `showKumoAlertDialog`) for destructive or irreversible confirmations.
- Use `KumoLayerDialog` when the same content should be a bottom sheet on phones, and `KumoDrawer` for details and filters that sit beside the page.
- Do not use a dialog for messages that need no decision; use `KumoToast` or `KumoBanner`.
- Never conditionally render a dialog. Open it with `showKumoDialog`, or keep it mounted in `KumoDialogRoot` and drive `open` so it can animate out.

## Parameters

### KumoDialog

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String?` | `null` | 20px semibold heading. Names the dialog for screen readers. |
| `description` | `String?` | `null` | Subtle supporting copy under the title. |
| `child` | `Widget?` | `null` | Body. Scrolls inside the panel when it does not fit. |
| `actions` | `List<Widget>` | `const []` | Footer buttons, end-aligned, wrapping when they do not fit. |
| `leading` | `Widget?` | `null` | Shown before the title, such as a 40px warning badge. |
| `size` | `KumoDialogSize` | `base` | Desktop width: `sm` 288, `base` 384, `lg` 512, `xl` 768. `sm` also uses 16px padding and small buttons. |
| `showCloseButton` | `bool?` | `null` | The header X. Null shows it for `KumoDialogRole.dialog` with a title, hides it for alert dialogs. |
| `padding` | `EdgeInsetsGeometry?` | `null` | Overrides the size's padding (24px, 16px for `sm`). |
| `semanticLabel` | `String?` | `null` | Accessible name when there is no title. |

Static helpers: `KumoDialog.closeFrom(context, [result])` closes the dialog, layer dialog or drawer that `context` belongs to; `KumoDialog.roleOf(context)` returns the role it was opened with.

### showKumoDialog

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `context` | `BuildContext` | required, positional | |
| `builder` | `WidgetBuilder` | required | Builds the dialog, usually a `KumoDialog`. |
| `role` | `KumoDialogRole` | `dialog` | `alertDialog` blocks backdrop dismissal and hides the X. |
| `dismissible` | `bool?` | `null` | Backdrop tap closes. Defaults to true for `dialog`, false for `alertDialog`. |
| `semanticLabel` | `String?` | `null` | Route label. |
| `useRootNavigator` | `bool` | `true` | |

Returns `Future<T?>`: the result of the `KumoDialogClose` or `KumoDialog.closeFrom` call that closed it, or null.

### KumoDialogRoot

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `open` | `bool` | required | Shows the dialog while true; turning false animates it out. |
| `onOpenChange` | `ValueChanged<bool>` | required | Called with false for every user dismissal (X, close parts, Escape, backdrop, back gesture, swipe). |
| `dialog` | `Widget` | required | Rebuilt with the root, so live state reaches the open dialog (one frame later). A `KumoLayerDialog` or `KumoDrawer` opens in a sheet route. |
| `child` | `Widget` | required | The page content, usually with the trigger. |
| `role` | `KumoDialogRole` | `dialog` | |
| `dismissible` | `bool?` | `null` | As in `showKumoDialog`. Read when the dialog opens. |
| `semanticLabel` | `String?` | `null` | |
| `useRootNavigator` | `bool` | `true` | |

### Parts

| Part | Description |
| --- | --- |
| `KumoDialogTitle(String)` | The heading, for custom layouts in `child`. |
| `KumoDialogDescription(String)` | Subtle 14px copy. |
| `KumoDialogFooter(children:)` | End-aligned wrapping action row with 8px gaps. |
| `KumoDialogClose({label, variant, size, result, onPress, semanticLabel, autofocus, disabled})` | A button that closes the dialog with `result` after running `onPress`. Without `label` it is the square X, announced with `KumoStrings.close`. Size defaults to the dialog size's button size. |

## Examples

### Destructive confirmation with a badge

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<bool?> confirmRevoke(BuildContext context) {
  return showKumoDialog<bool>(
    context,
    role: KumoDialogRole.alertDialog,
    builder: (context) => const KumoDialog(
      title: 'Revoke API token?',
      description: 'Scripts using "ci-deploy" stop authenticating right away.',
      leading: KumoIcon(KumoIcons.warningFill, size: 20, color: KumoColor.textDanger),
      actions: [
        KumoDialogClose(label: 'Keep token', result: false, autofocus: true),
        KumoDialogClose(label: 'Revoke token', variant: KumoButtonVariant.destructive, result: true),
      ],
    ),
  );
}
```

### Kept mounted with KumoDialogRoot

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

class EditRecord extends StatefulWidget {
  const EditRecord({super.key});

  @override
  State<EditRecord> createState() => _EditRecordState();
}

class _EditRecordState extends State<EditRecord> {
  bool _open = false;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _saving = false);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    return KumoDialogRoot(
      open: _open,
      onOpenChange: (open) => setState(() => _open = open),
      dialog: KumoDialog(
        title: 'Edit DNS record',
        actions: [
          KumoDialogClose(label: 'Cancel', disabled: _saving),
          KumoButton(label: 'Save record', variant: KumoButtonVariant.primary, loading: _saving, onPress: _save),
        ],
        child: const KumoText('api.example.com, type CNAME'),
      ),
      child: KumoButton(label: 'Edit record', onPress: () => setState(() => _open = true)),
    );
  }
}
```

### Long content

Body content taller than the screen scrolls inside the panel. Hairlines appear under the header once content passes beneath it and above the footer while more content is below, so the sticky parts stay separated without shifting layout.

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<void> reviewRecords(BuildContext context) {
  return showKumoDialog<void>(
    context,
    builder: (context) => KumoDialog(
      size: KumoDialogSize.lg,
      title: 'Review DNS records',
      actions: const [KumoDialogClose(label: 'Done', variant: KumoButtonVariant.primary)],
      child: Column(children: [for (var i = 1; i <= 40; i++) KumoText('app$i.example.com')]),
    ),
  );
}
```

## Accessibility

- The panel is a `SemanticsRole.dialog` (or `alertDialog`) node; the title is a heading that names the route.
- Focus moves into the dialog on open, Tab and Shift+Tab stay inside, and focus returns to the trigger on close.
- Escape closes every dialog, alert dialogs included (the ARIA alert dialog pattern); the backdrop is announced as a Close button when it dismisses.
- The X is announced with `KumoStrings.close`; buttons get 44x44 hit areas on touch.
- `showKumoAlertDialog` focuses Cancel first for destructive confirmations, so Enter never confirms by accident.

## Motion

- Fades in and scales up from 0.9 over 150ms (`KumoDialogRoute`), and leaves the same way. The backdrop fades with it.
- When the content grows or shrinks (a step changes, an error appears), the panel edge glides to the new height on a spring that starts from its current height and speed. The content is laid out at its new size at once and clipped while the edge moves.
- A new `size` animates the width over 200ms; the screen edge still clamps it immediately, so resizing a window never lags.
- Under reduced motion the dialog only cross-fades and size changes land in one frame.

## Mobile

- Below 768px the panel takes the full width minus 16px on each side; from 768px it uses the size width (capped to the screen minus 32px).
- It sits 32px below the safe area (64px from 640px up) and stops 16px above the keyboard or bottom inset; the body scrolls when space runs out.
- Footer buttons wrap onto a second line at large text sizes.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `Dialog.Root open` / `onOpenChange` | `KumoDialogRoot(open:, onOpenChange:)` |
| `Dialog.Root role="alertdialog"` | `role: KumoDialogRole.alertDialog` |
| `Dialog.Root disablePointerDismissal` | `dismissible: false` |
| `Dialog.Trigger` | `KumoDialogRoot(child:)` or a button calling `showKumoDialog` |
| `Dialog size` | `size: KumoDialogSize` |
| `Dialog.Title` | `title:` or `KumoDialogTitle` |
| `Dialog.Description` | `description:` or `KumoDialogDescription` |
| `Dialog.Close render={Button}` | `KumoDialogClose(label:, variant:)` |
| `className="p-8"` | `padding:` |
