# Motion

Motion answers touch. Feedback on press, springs that start from where things are, sheets that follow the finger. Nothing loops forever.

## Press feedback

Every tappable surface is a `KumoPressable`. Its state changes on pointer-down: the surface scales to 0.98 with a spring and hover and pressed colors switch instantly (Kumo never animates a hover color).

## Springs

Anything a finger touches moves on a spring that starts from the current value and carries velocity, so it can be grabbed and reversed mid-flight.

| Spring | Damping | Response | Use |
| --- | --- | --- | --- |
| `KumoSprings.standard` | 1.0 | 0.35s | Things that move on their own |
| `KumoSprings.press` | 1.0 | 0.2s | Press down and release |
| `KumoSprings.popup` | 1.0 | 0.22s | Popovers, menus, tooltips scaling from their trigger |
| `KumoSprings.sheet` | 0.86 | 0.32s | Sheets settling after a drag |
| `KumoSprings.momentum` | 0.8 | 0.35s | Only after a flick that carried momentum |

```dart
var controller = AnimationController.unbounded(vsync: tickerProvider, value: 0);
KumoMotion.springTo(controller, 1, spring: KumoSprings.standard, velocity: controller.velocity);
```

## Gestures

Drags follow the finger 1:1. On release the finger's velocity goes into the spring, `KumoMotion.project(velocity)` predicts where the gesture was heading so the snap target matches the throw, and `KumoMotion.rubberband` resists past the bounds. Sheets dismiss by velocity direction, not only distance.

## Popups

`KumoAnchoredOverlay` opens popovers, menus, selects and tooltips with Kumo's popup motion: scale from 0.9 plus a fade, with the transform origin on the trigger. They close along the same path.

## Fixed durations

Fades and expand/collapse use `KumoDurations` (`fast` 100ms is Kumo's default transition, `quick` 150ms popups, `moderate` 200ms, `slow` 300ms) with `KumoCurves.standard`, `.enter`, `.exit`. Wrap durations in `KumoMotion.duration(context, d)` so reduced motion collapses them.

## Loops

A repeating animation runs only while a real state is true (a spinner while loading) and pauses off screen. Kumo's web skeleton shimmer loops forever; here skeletons are static unless `animate: true` is passed while loading.

## Reduced motion

`KumoMotion.reduceMotion(context)` follows the platform setting. Under it, slides, scales and springs become instant changes or short cross-fades; color and opacity changes that help comprehension stay.
