# KumoPressable

The interaction primitive under every tappable Kumo component. Use it for custom rows, tiles and chips.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoPressable(
  onPress: () {},
  semanticLabel: 'Open image-resizer',
  borderRadius: BorderRadius.circular(KumoRadius.lg),
  builder: (context, state) => Container(
    padding: const EdgeInsets.all(KumoSpace.s3),
    decoration: BoxDecoration(
      color: state.active ? context.kumo.colors.tint : context.kumo.colors.base,
      borderRadius: BorderRadius.circular(KumoRadius.lg),
    ),
    child: const KumoText('image-resizer'),
  ),
)
```

## When to use / when not to

Use it for any custom surface a finger or pointer activates. For standard actions use `KumoButton`; for menu rows use `KumoMenuRow`. Do not use `GestureDetector` or `InkWell` for tappable UI.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` / `builder` | `Widget?` / `KumoPressableBuilder?` | | One is required; `builder` receives `KumoPressState` (`hovered`, `pressed`, `focused`, `disabled`, `active`) |
| `onPress`, `onLongPress`, `onPressIn`, `onPressOut` | callbacks | | |
| `disabled` | `bool` | `false` | |
| `loading` | `bool` | `false` | Blocks presses without the disabled look |
| `borderRadius` | `BorderRadius` | `zero` | Shape of the focus ring |
| `focusRingColor` | `KumoColor` | `brand` | |
| `focusRingWidth`, `focusRingOffset` | `double` | `2`, `0` | |
| `showFocusRing` | `bool` | `true` | Off when the component draws its own focus treatment |
| `scaleOnPress`, `pressScale` | `bool`, `double` | `true`, `0.98` | |
| `haptic` | `KumoHaptic` | `none` | |
| `debounce` | `Duration` | `zero` | Ignore repeat presses inside the window |
| `minTapTargetSize` | `double?` | theme | 44 on touch, 0 with a mouse |
| `semanticLabel`, `semanticHint`, `semanticValue` | `String?` | | |
| `selected`, `toggled`, `checked`, `mixed`, `expanded`, `inMutuallyExclusiveGroup` | `bool?` | | Semantic state |
| `isButton`, `isLink` | `bool` | `true`, `false` | |
| `focusNode`, `autofocus`, `canRequestFocus` | | | `canRequestFocus: false` keeps it out of Tab order (roving groups) |
| `excludeChildSemantics`, `mergeChildSemantics` | `bool` | `false`, `true` | |

## Accessibility

Exposes button (or link) semantics with label and state, is focusable, activates with Enter and Space, and shows the focus ring only for keyboard focus.

## Motion

Pointer-down scales to `pressScale` with `KumoSprings.press`; release springs back from the current scale, so rapid taps never jump. Hover state switches instantly. Reduced motion turns the scale off.

## Mobile

On touch platforms the layout grows to at least 44x44 around the visual (centered), so small controls stay reachable.
