# KumoButton

Kumo's `Button`: the control for actions, in six variants and four sizes, with icon-only shapes, a loading state and an optional tooltip.

Kumo reference: https://kumo-ui.com/components/button

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoButton(label: 'Deploy', variant: KumoButtonVariant.primary, onPress: () {})
```

## When to use / when not to

Use a button for an action on the current page. Use one `primary` button per view for the main action, `secondary` (the default) for everything else, `ghost` in toolbars and dense rows, `destructive` for delete and revoke. For navigation inside text use `KumoLink`; for a toggled state use `KumoToggle` or `KumoSwitch`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String?` | | Button text, sentence case |
| `child` | `Widget?` | | Custom content in place of `label` |
| `onPress` | `VoidCallback?` | | Null renders the button disabled |
| `onLongPress` | `VoidCallback?` | | |
| `variant` | `KumoButtonVariant` | `secondary` | `primary`, `secondary`, `ghost`, `destructive`, `secondaryDestructive`, `outline` |
| `size` | `KumoButtonSize` | `base` | `xs` 20px, `sm` 26px, `base` 36px, `lg` 40px |
| `shape` | `KumoButtonShape` | `base` | `square` and `circle` are icon-only and need `semanticLabel` or `title` |
| `icon` | `IconData?` | | Leading icon |
| `iconWidget` | `Widget?` | | Leading widget in place of `icon` |
| `endIcon` | `IconData?` | | Trailing icon, such as a caret for menus |
| `loading` | `bool` | `false` | Shows a spinner in place of the icon and ignores presses; the label stays so the width does not jump |
| `disabled` | `bool` | `false` | 50% opacity, not focusable |
| `block` | `bool` | `false` | Stretch to the parent's width |
| `title` | `String?` | | Tooltip text; also the accessible name of icon-only buttons |
| `semanticLabel` | `String?` | | Accessible name override |
| `isLink` | `bool` | `false` | Announce as a link (Kumo's `LinkButton`) |
| `haptic` | `KumoHaptic` | `none` | Haptic on press |
| `focusNode`, `autofocus` | | | |

## Examples

### Variants

```dart
Wrap(spacing: 8, runSpacing: 8, children: [
  KumoButton(label: 'Create Worker', variant: KumoButtonVariant.primary, onPress: () {}),
  KumoButton(label: 'Cancel', onPress: () {}),
  KumoButton(label: 'Edit', variant: KumoButtonVariant.ghost, onPress: () {}),
  KumoButton(label: 'Delete zone', variant: KumoButtonVariant.destructive, onPress: () {}),
  KumoButton(label: 'Revoke token', variant: KumoButtonVariant.secondaryDestructive, onPress: () {}),
  KumoButton(label: 'Filter', variant: KumoButtonVariant.outline, onPress: () {}),
])
```

### Icon and icon-only

```dart
Row(spacing: 8, children: [
  KumoButton(label: 'Add record', icon: KumoIcons.plus, onPress: () {}),
  KumoButton(
    icon: KumoIcons.copy,
    shape: KumoButtonShape.square,
    title: 'Copy token',
    onPress: () {},
  ),
])
```

### Loading

```dart
KumoButton(label: 'Deploying', variant: KumoButtonVariant.primary, loading: true, onPress: () {})
```

### Refresh button

`KumoRefreshButton` is a square button whose arrows turn only while `loading` is true.

```dart
KumoRefreshButton(onPress: () {}, loading: false)
```

## Accessibility

Announced as a button (or link with `isLink`) with its label and enabled state. Icon-only shapes assert a `semanticLabel` or `title`. Tab focuses, Enter and Space activate, keyboard focus shows the 2px brand ring. On touch the hit area grows to 44x44.

## Motion

- Pointer-down scales the button to 0.98 with a spring; release springs back from wherever it is. Hover colors change instantly. Emphasis buttons lighten their top-lit gradient on hover.
- `loading` cross-fades the icon and the spinner (100ms) and keeps the label. In a label-only button the spinner fades in while the button eases to its new width.
- A new `label` ("Copy" to "Copied") cross-fades and the button eases to its new width (200ms). A keyed `iconWidget` cross-fades the same way; an unkeyed one updates in place.
- Becoming disabled or enabled eases between full and half opacity (100ms).
- `KumoRefreshButton`'s arrows turn only while `loading`, finish the current turn when it ends, and stay still under reduced motion.
- Reduced motion removes the scale, the cross-fades and the width easing.

## Mobile

Visual heights stay Kumo's; the touch hit area is padded to 44px. `block: true` is the usual choice for the main action at the bottom of a phone screen.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` | `label` / `child` |
| `onClick` | `onPress` |
| `variant="secondary-destructive"` | `variant: KumoButtonVariant.secondaryDestructive` |
| `size`, `shape`, `loading`, `disabled`, `title` | same names |
| `icon={Plus}` | `icon: KumoIcons.plus` |
| `aria-label` | `semanticLabel` |
| `LinkButton` | `KumoButton(isLink: true)` |
| `RefreshButton` | `KumoRefreshButton` |
