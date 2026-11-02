# KumoDialogRoute

The route behind Kumo dialogs: Kumo's backdrop (recessed surface at 80%), a scale-from-0.9 entry, focus trap, Escape and backdrop dismissal. `showKumoDialog` uses it; push it directly for a custom modal.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
Navigator.of(context).push(KumoDialogRoute<void>(
  semanticLabel: 'Purge cache',
  builder: (context) => const Center(child: KumoLayerCard(child: KumoText('Purge everything?'))),
));
```

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `builder` | `WidgetBuilder` | required | |
| `transition` | `KumoDialogTransition` | `scale` | `scale` (0.9 to 1 plus fade, 150ms) or `slideUp` (40px rise, for full-screen pages) |
| `dismissible` | `bool` | `true` | Backdrop tap closes |
| `closeOnEscape` | `bool` | `true` | |
| `restoreFocusOnUnmount` | `bool` | `true` | |
| `showScrim` | `bool` | `true` | |
| `semanticLabel` | `String?` | | Names the route |

`KumoScrim(onPress:, opacity:)` is the backdrop on its own.

## Motion

Enters and leaves on the same path. Reduced motion keeps only a short fade.
