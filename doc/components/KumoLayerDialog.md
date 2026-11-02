# KumoLayerDialog

A strict responsive dialog with a sticky title frame and one primary action: a centered panel from 640px up, a bottom sheet that follows the finger on phones.

Kumo reference: https://kumo-ui.com/components/layer-dialog

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<void> configureHostname(BuildContext context) {
  return showKumoLayerDialog<void>(
    context,
    builder: (context) => KumoLayerDialog(
      title: 'Configure custom hostname',
      description: 'Route requests for this hostname to your Worker.',
      body: const KumoText('api.example.com'),
      action: KumoLayerDialogAction(
        label: 'Save hostname',
        onPress: () => KumoDialog.closeFrom(context),
      ),
    ),
  );
}
```

## When to use / when not to

- Use when a dialog must also work well on phones: forms, pickers and confirmations that become bottom sheets there.
- The composition is fixed. Without `action`: an X in the title frame and no footer, for read-only content. With `action`: no X, an automatic dismiss button at the start of the footer and the action at the end. You cannot add other footer controls; put related actions in `KumoLayerDialogAction.menu`.
- Use `KumoLayerDialog.alert` for destructive or critical confirmations.
- Use `KumoDialog` for free-form layouts.

## Parameters

### KumoLayerDialog / KumoLayerDialog.alert

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String` | required | Heading of the sticky title frame (16px medium); names the dialog. |
| `description` | `String?` | `null` | Under the title. Folds away once the body scrolls past 8px (if enough overflow remains) and unfolds at the top. |
| `body` | `Widget` | required | Scrollable content. Use `KumoLayerDialogSeparator` between sections. |
| `action` | `KumoLayerDialogAction?` | `null` | The single primary action. Required in `.alert`. |
| `dismissLabel` | `String?` | `KumoStrings.close`, or `KumoStrings.cancel` in `.alert` | Footer dismiss button text. |
| `closeLabel` | `String?` | `KumoStrings.close` | Accessible name of the X. |
| `size` | `KumoLayerDialogSize` | `base` | Desktop width: `sm` 448, `base` 576, `lg` 672, `xl` 768. |
| `verticalAlign` | `KumoLayerDialogVerticalAlign` | `center` | Desktop placement: `center` (24px margins) or `top` (64px from the top). |
| `dismissDisabled` | `bool` | `false` | Blocks the X, the dismiss button, Escape, the backdrop, swipes and the back gesture while work is pending. Closing from code still works. |

`.alert` is announced as an alert dialog, shows no X, ignores backdrop taps and swipes, and labels the dismiss button Cancel. Escape still cancels.

`KumoLayerDialog.createRoute<T>({builder, semanticLabel})` returns the route `showKumoLayerDialog` pushes.

### KumoLayerDialogAction

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | |
| `onPress` | `VoidCallback?` | required | Null disables it. The action does not close the dialog by itself; call `KumoDialog.closeFrom`. |
| `variant` | `KumoLayerDialogActionVariant` | `primary` | `destructive` for irreversible confirmations. |
| `loading` | `bool` | `false` | |
| `disabled` | `bool` | `false` | |
| `menu` | `List<KumoLayerDialogMenuItem>` | `const []` | Related actions behind a caret button next to the action. |
| `menuLabel` | `String?` | `KumoStrings.moreActions` | Accessible name of the caret. |

`KumoLayerDialogMenuItem({required label, required onPress, icon, destructive = false})`.

### showKumoLayerDialog

`Future<T?> showKumoLayerDialog<T>(BuildContext context, {required WidgetBuilder builder, String? semanticLabel, bool useRootNavigator = true})`. To keep the dialog mounted instead, pass it to `KumoDialogRoot(dialog:)`.

## Examples

### Alert

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<void> deleteWorker(BuildContext context) {
  return showKumoLayerDialog<void>(
    context,
    builder: (context) => KumoLayerDialog.alert(
      title: 'Delete production-api?',
      body: const KumoText('Requests to its routes fail until another Worker is deployed.'),
      action: KumoLayerDialogAction(
        label: 'Delete Worker',
        variant: KumoLayerDialogActionVariant.destructive,
        onPress: () => KumoDialog.closeFrom(context),
      ),
    ),
  );
}
```

### Split action and separator

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

KumoLayerDialog deployDialog(VoidCallback deploy, VoidCallback saveDraft) => KumoLayerDialog(
      title: 'Deploy changes',
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KumoText('image-resizer, 2 changed files'),
          KumoLayerDialogSeparator(),
          KumoText('Compatibility date 2026-10-26'),
        ],
      ),
      action: KumoLayerDialogAction(
        label: 'Save and deploy',
        onPress: deploy,
        menu: [KumoLayerDialogMenuItem(label: 'Save as draft', onPress: saveDraft)],
      ),
    );
```

### Pending work

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

class DeployButton extends StatefulWidget {
  const DeployButton({super.key});

  @override
  State<DeployButton> createState() => _DeployButtonState();
}

class _DeployButtonState extends State<DeployButton> {
  bool _open = false;
  bool _deploying = false;

  Future<void> _deploy() async {
    setState(() => _deploying = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _deploying = false);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    return KumoDialogRoot(
      open: _open,
      onOpenChange: (open) => setState(() => _open = open),
      dialog: KumoLayerDialog(
        title: 'Deploy staging-api',
        dismissDisabled: _deploying,
        body: const KumoText('Publishes the new version to every route.'),
        action: KumoLayerDialogAction(label: 'Deploy Worker', loading: _deploying, onPress: _deploy),
      ),
      child: KumoButton(label: 'Deploy staging-api', onPress: () => setState(() => _open = true)),
    );
  }
}
```

## Accessibility

- Announced as a dialog (alert dialog for `.alert`); the title is a heading that names the route. A folded description stays in the semantics tree.
- Focus is trapped while open and returns to the trigger afterwards. Escape closes unless `dismissDisabled`.
- The phone handle is decorative and hidden from screen readers; the footer dismiss button or the X is always reachable.

## Motion

- Desktop: the panel fades in and rises 8px (200ms), and leaves the same way; the backdrop fades with it.
- Phone: a `KumoSheet` that springs up, follows the finger, rubberbands past its open position and dismisses with a downward flick at the finger's velocity. Alerts and pending dialogs do not move.
- The action's caret turns over while its menu is open (150ms) and back when it closes.
- The description folds over 200ms by clipping, not reflowing. Reduced motion makes the fold instant and the panel a short cross-fade.

## Mobile

Below 640px it is a full-width bottom sheet capped at 85% of the screen, with a grab handle (not for alerts). The footer stays under the scrolling body behind a hairline and above the safe area and keyboard; the dismiss button switches to the secondary style. The presentation is chosen when the dialog opens.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `LayerDialog.Root` / `open` / `onOpenChange` | `showKumoLayerDialog` or `KumoDialogRoot` |
| `LayerDialog.Alert` | `KumoLayerDialog.alert` |
| `LayerDialog.Root dismissDisabled` | `dismissDisabled:` |
| `LayerDialog.Content size` / `verticalAlign` / `closeLabel` | `size:` / `verticalAlign:` / `closeLabel:` |
| `LayerDialog.Title` / `Description` / `Body` | `title:` / `description:` / `body:` |
| `LayerDialog.Separator` | `KumoLayerDialogSeparator` |
| `LayerDialog.Actions dismissLabel` | `dismissLabel:` |
| `LayerDialog.Action variant` / `loading` / `menu` / `menuLabel` | `KumoLayerDialogAction(variant:, loading:, menu:, menuLabel:)` |
| `KumoLocaleProvider layerDialog.close` / `.cancel` | `KumoLocale(strings: KumoStrings(close:, cancel:))` |
