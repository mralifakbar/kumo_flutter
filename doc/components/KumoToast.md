# KumoToast

Brief, non-blocking notifications that stack in a corner of the screen, pause while the user looks at them and swipe away.

Kumo reference: https://kumo-ui.com/components/toast

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

Place one `KumoToaster` near the root, above the navigator, then raise toasts from anywhere below it.

```dart
import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

void main() {
  runApp(
    KumoThemeProvider(
      child: MaterialApp(
        builder: (context, child) => KumoToaster(child: child!),
        home: Builder(
          builder: (context) => KumoButton(
            label: 'Purge cache',
            onPress: () => showKumoToast(context, title: 'Cache purged', description: 'example.com serves fresh content.'),
          ),
        ),
      ),
    ),
  );
}
```

## When to use / when not to

- Use for the outcome of an action the user just took ("Worker deployed", "DNS record deleted"), optionally with one or two actions such as Undo.
- Do not put information the user must act on only in a toast: it disappears. Use `KumoBanner` for persistent page-level messages and `KumoDialog` for decisions.
- Give repeated notifications a stable `id` so they bump one toast instead of stacking copies.

## Parameters

### KumoToaster

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The app. It sizes the toaster. |
| `manager` | `KumoToastManager?` | `null` | A manager created outside the tree, for toasts raised from code without a `BuildContext`. Null creates one. |
| `limit` | `int` | `3` | Toasts shown at once; older ones wait hidden until a slot frees up. |
| `timeout` | `Duration` | `KumoToaster.defaultTimeout` (5s) | Auto-dismiss time for toasts that do not set their own. |

### KumoToast.of / showKumoToast

`KumoToast.of(context)` returns the nearest toaster's `KumoToastManager` and throws a `FlutterError` that explains the fix when there is none; `KumoToast.maybeOf(context)` returns null instead. `showKumoToast(context, ...)` is `KumoToast.of(context).add(...)` and returns the toast id.

### KumoToastManager.add

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `id` | `String?` | generated | Reusing the id of a toast on screen bumps it and restarts its timer instead of adding a copy. |
| `title` | `String?` | `null` | Medium weight, colored by the variant. |
| `description` | `String?` | `null` | 70% default text. |
| `variant` | `KumoToastVariant` | `neutral` | `neutral`, `success`, `error`, `warning`, `info`. Non-neutral variants add an icon. |
| `content` | `Widget?` | `null` | Custom content in place of icon, title, description and actions. The close button stays. |
| `actions` | `List<KumoToastAction>` | `const []` | Buttons under the text; they scroll sideways if they do not fit. |
| `timeout` | `Duration?` | toaster timeout | `Duration.zero` keeps the toast until closed. |
| `bump` | `bool?` | `null` | `false` skips the bump on a repeated id. |
| `onClose` | `VoidCallback?` | `null` | Called once when the toast starts closing, for any reason. |
| `semanticLabel` | `String?` | title and description | What screen readers announce. |

Other members: `addToast(KumoToastData, {id, bump})`, `update(id, (toast) => toast.copyWith(...), {bump = false})` (a changed timeout restarts the timer), `promise<T>(future, loading:, success:, error:)` (one toast from loading to result; the loading toast stays until the future completes), `close(id)`, `closeAll()`, `ids`, `toastFor(id)`.

### KumoToastAction

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | |
| `onPress` | `VoidCallback` | required | |
| `variant` | `KumoButtonVariant` | `secondary` | |
| `icon` | `IconData?` | `null` | |
| `closesToast` | `bool` | `false` | Close the toast after `onPress`, for one-shot actions such as Undo. |

### KumoToast widget

`KumoToast({title, description, variant, content, actions, onClose})` renders one toast surface on its own, for previews and custom hosts.

## Examples

### Undo action

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

void recordDeleted(BuildContext context, VoidCallback restore) {
  showKumoToast(
    context,
    title: 'DNS record deleted',
    description: 'api.example.com, type CNAME',
    variant: KumoToastVariant.success,
    actions: [KumoToastAction(label: 'Undo', onPress: restore, closesToast: true)],
  );
}
```

### Promise

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<String> deployWorker() async => 'image-resizer';

Future<void> deploy(BuildContext context) async {
  await KumoToast.of(context).promise<String>(
    deployWorker(),
    loading: const KumoToastData(title: 'Deploying image-resizer', variant: KumoToastVariant.info),
    success: (name) => KumoToastData(title: '$name deployed', variant: KumoToastVariant.success),
    error: (e) => KumoToastData(title: 'Deployment failed', description: '$e', variant: KumoToastVariant.error),
  );
}
```

### Raising toasts outside the widget tree

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

final appToasts = KumoToastManager();

void onSyncFailed() => appToasts.add(title: 'Sync failed', variant: KumoToastVariant.error);

Widget withToasts(Widget app) => KumoToaster(manager: appToasts, child: app);
```

## Accessibility

- New toasts are announced: each toast is a live region (Android, web) and the toaster sends an announcement elsewhere, using `semanticLabel` or the title and description.
- Status is not color alone: variants add an icon, and the title says what happened.
- The close button is announced with `KumoStrings.close` and gets a 44x44 hit area on touch; actions are regular buttons in the Tab order.
- Hovering or focusing the stack pauses every timer, so reading or tabbing to an action never races the timeout. Timers also pause while the app is in the background.

## Motion

- A toast enters from the bottom edge with a spring and leaves the way it came (sliding down and fading).
- Older toasts peek 12px above the newest, each scaled down 10%, with their content hidden. Hovering or focusing the stack, or touching it on a phone, fans them out with 12px gaps; positions move on springs that start from where each toast is.
- When a toast leaves, the ones behind slide and grow into their new places from where they are.
- Updating a toast in place (`update`, a settled `promise`) cross-fades the old message into the new one over 150ms while the height springs to the new content.
- A repeated id bumps the toast: a quick rise to about 1.02 scale and back.
- Swipe down or toward the end edge to dismiss. The toast follows the finger; past 40px or with a flick it keeps the finger's velocity on the way out, otherwise it springs back. Swiping up or toward the start resists.
- Reduced motion replaces slides, scales and the bump with a short fade, and swaps updated content at once.

## Mobile

From 640px up, toasts are 340px wide in the bottom end corner, 32px from the edges. Below 640px they span the bottom with 16px gutters. They always sit above the safe area and the keyboard, and mirror to the bottom left in right-to-left layouts.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Toasty>` | `KumoToaster` |
| `Toasty toastManager` / `createKumoToastManager()` | `KumoToaster(manager:)` / `KumoToastManager()` |
| `useKumoToastManager()` | `KumoToast.of(context)` |
| `toastManager.add({ title, description, variant, content, actions, timeout, id, bump })` | `add(title:, description:, variant:, content:, actions:, timeout:, id:, bump:)` |
| `variant: "default"` | `KumoToastVariant.neutral` |
| `actions: ButtonProps[]` | `actions: List<KumoToastAction>` |
| `toastManager.update(id, fn)` | `update(id, fn)` |
| `toastManager.promise(p, { loading, success, error })` | `promise(p, loading:, success:, error:)` |
| `toastManager.close(id)` | `close(id)` |
