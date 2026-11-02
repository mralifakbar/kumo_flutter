# KumoFocusTrap

Keeps keyboard focus inside a subtree while it is on screen and hands it back when it goes away. Dialogs, sheets and focus-trapping popovers already use it.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoFocusTrap(
  onEscPress: () {},
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    KumoButton(label: 'Save', onPress: () {}),
    KumoButton(label: 'Cancel', onPress: () {}),
  ]),
)
```

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | |
| `onEscPress` | `VoidCallback?` | | Called on Escape |
| `disableFocusTrap` | `bool` | `false` | Let Tab leave at the ends |
| `restoreFocusOnUnmount` | `bool` | `true` | |
| `disableAutoFocus` | `bool` | `false` | |
| `disableArrowKeyNavigation` | `bool` | `true` | When false, Up and Down also move focus |

## Accessibility

Tab and Shift+Tab cycle inside and wrap; focus returns to the previously focused widget on unmount.
