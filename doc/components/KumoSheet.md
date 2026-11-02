# KumoSheet

A sheet attached to a screen edge that follows the finger. Open one with `showKumoSheet`.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
Future<void> pickRegion(BuildContext context) async {
  final region = await showKumoSheet<String>(
    context: context,
    semanticLabel: 'Choose a region',
    builder: (context) => Padding(
      padding: const EdgeInsets.all(KumoSpace.s4),
      child: KumoButton(label: 'Use Frankfurt', block: true, onPress: () => KumoSheetScope.closeFrom(context, 'fra')),
    ),
  );
  debugPrint(region);
}
```

## When to use / when not to

Use sheets for short tasks and choices on phones. Menus, selects and pickers already switch to a sheet below 768px. For confirmations on wide screens use a dialog.

## Parameters (`showKumoSheet`)

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `context`, `builder` | | required | |
| `edge` | `KumoSheetEdge` | `bottom` | `bottom`, `top`, `start`, `end` |
| `snapPoints` | `List<double>?` | | Heights as fractions of the screen; null sizes to content |
| `initialSnapPointIndex` | `int?` | | |
| `dismissible` | `bool` | `true` | Drag, flick, scrim tap and Escape close it |
| `showHandle` | `bool` | `true` | `KumoSheetHandle` on bottom sheets |
| `maxExtentFraction` | `double` | `0.85` | |
| `semanticLabel` | `String?` | | Names the sheet for screen readers |
| `useRootNavigator` | `bool` | `true` | |

`KumoSheetScope.closeFrom(context, [result])` closes the sheet from inside it, or pops its route from the builder's context.

## Accessibility

The sheet scopes the route for screen readers, traps focus and returns it on close. The handle is a "Close" button for screen reader users. Escape closes.

## Motion

The sheet springs in from its edge. A drag follows the finger 1:1 and rubberbands past the open position. On release, the velocity is projected to choose a snap point or dismissal; a flick toward the edge dismisses, a push back keeps it open. Scrolling content hands off to the sheet at its top. It leaves along the path it came in on. Reduced motion fades instead.

## Mobile

Respects the safe area and keeps content above the home indicator.
