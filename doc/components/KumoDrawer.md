# KumoDrawer

A panel attached to a screen edge, for details, settings and filters that sit beside the page instead of over its center.

Kumo reference: none. Kumo has no drawer; this follows the sheet pattern from shadcn/ui, built on `KumoSheet` and Kumo tokens.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<void> openSettings(BuildContext context) {
  return showKumoDrawer<void>(
    context,
    builder: (context) => KumoDrawer(
      title: 'image-resizer',
      description: 'Worker settings',
      actions: [
        const KumoDialogClose(label: 'Cancel'),
        KumoButton(
          label: 'Save settings',
          variant: KumoButtonVariant.primary,
          onPress: () => KumoDialog.closeFrom(context),
        ),
      ],
      child: const KumoText('Compatibility date 2026-10-26'),
    ),
  );
}
```

## When to use / when not to

- Use an end drawer for a record's details or settings while the list stays in view, a start drawer for navigation, a bottom drawer for short pickers on phones.
- Use `KumoDialog` when the task needs the user's full attention, and `KumoLayerDialog` for a dialog that becomes a bottom sheet on phones.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `side` | `KumoSheetEdge` | `end` | `start`, `end`, `bottom` or `top`. `start` and `end` follow the text direction. |
| `title` | `String?` | `null` | 16px semibold heading; names the route. |
| `description` | `String?` | `null` | Subtle text under the title. |
| `child` | `Widget` | required | Body. Scrolls when it does not fit. |
| `actions` | `List<Widget>` | `const []` | Footer buttons, end-aligned. `KumoDialogClose` works here. |
| `showCloseButton` | `bool` | `true` | The ghost X in the header. |
| `maxWidth` | `double` | `384` | Largest width of a side drawer; never more than 85% of the screen. |
| `dismissible` | `bool` | `true` | False blocks backdrop taps and drag dismissal. Escape still closes. |
| `semanticLabel` | `String?` | `null` | Accessible name without a title. |

`Future<T?> showKumoDrawer<T>(BuildContext context, {required WidgetBuilder builder, String? semanticLabel, bool useRootNavigator = true})` returns the value passed to `KumoDialog.closeFrom` or `KumoDialogClose(result:)`. `KumoDialogRoot(dialog: KumoDrawer(...))` keeps one mounted.

## Examples

### Bottom picker

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Future<String?> pickFilter(BuildContext context) {
  return showKumoDrawer<String>(
    context,
    builder: (context) => KumoDrawer(
      side: KumoSheetEdge.bottom,
      title: 'Filter zones',
      child: Column(
        children: [
          for (final option in const ['All zones', 'Active zones', 'Paused zones'])
            KumoButton(label: option, block: true, onPress: () => KumoDialog.closeFrom(context, option)),
        ],
      ),
    ),
  );
}
```

## Accessibility

- Focus moves into the drawer, Tab stays inside, and focus returns to the trigger on close. Escape closes it.
- The title is a heading that names the route; the X is announced with `KumoStrings.close`. A bottom drawer's handle is a Close button for screen readers.

## Motion

The drawer springs in from its edge and follows the finger 1:1, rubberbanding past its open position. On release the finger's velocity decides: a flick toward the edge dismisses and carries on at that speed; a short or reversed drag springs back. Escape, the backdrop and the back gesture close it along the same path. The backdrop dims with how far the drawer is open. Reduced motion swaps the slide for a fade.

## Mobile

Side drawers take at most 85% of the width so the page stays visible as a cue; bottom drawers cap at 85% of the height and hand drags at the top of scrolled content to the drawer. The header and footer stay put while the body scrolls, separated by hairlines once content passes under them, and the panel respects the safe area on the edges it touches.

## Kumo React mapping

| shadcn/ui Sheet | Flutter parameter |
| --- | --- |
| `Sheet` / `open` / `onOpenChange` | `showKumoDrawer` or `KumoDialogRoot` |
| `SheetContent side` | `side:` |
| `SheetTitle` / `SheetDescription` | `title:` / `description:` |
| `SheetFooter` | `actions:` |
| `SheetClose` | `KumoDialogClose` |
