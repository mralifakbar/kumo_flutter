# KumoSwitch

Kumo's `Switch`: an on/off control for a setting that takes effect at once, with a thumb you can tap or drag.

Kumo reference: https://kumo-ui.com/components/switch

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoSwitch(
  label: 'Always use HTTPS',
  checked: httpsOnly,
  onCheckedChange: (value) => setState(() => httpsOnly = value),
)
```

## When to use / when not to

Use a switch when flipping it changes something immediately (a zone setting, a feature flag). When the choice is saved later with a form, use `KumoCheckbox`. For several switches under one title, wrap them in `KumoSwitchGroup`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `checked` | `bool` | required | Controlled value |
| `onCheckedChange` | `ValueChanged<bool>?` | | Called after a tap, key press or a drag that changes sides. Null disables the switch |
| `label` | `String?` | | Label text, 14px medium. Also the accessible name |
| `labelWidget` | `Widget?` | | Custom label in place of `label` |
| `labelTooltip` | `String?` | | Info icon with a tooltip after the label |
| `required` | `bool?` | | `false` shows "(optional)" after the label |
| `controlFirst` | `bool?` | group's, else `true` | Switch before the label, or after it |
| `size` | `KumoSwitchSize` | `base` | `sm` 32x16, `base` 36x18, `lg` 40x20 |
| `variant` | `KumoSwitchVariant` | `base` | `base` blue track when on; `neutral` monochrome |
| `disabled` | `bool` | `false` | |
| `transitioning` | `bool` | `false` | A save is in flight: keeps the look, ignores input, adds a "Loading" hint |
| `semanticLabel` | `String?` | | Accessible name without a label (defaults to "Switch") |
| `focusNode` | `FocusNode?` | | |
| `autofocus` | `bool` | `false` | |

## Examples

### Sizes and neutral

```dart
KumoSwitch(
  label: 'Compact table rows',
  size: KumoSwitchSize.sm,
  variant: KumoSwitchVariant.neutral,
  checked: compact,
  onCheckedChange: (value) => setState(() => compact = value),
)
```

### Saving to an API

```dart
KumoSwitch(
  label: 'Proxy status',
  checked: proxied,
  transitioning: saving,
  onCheckedChange: (value) async {
    setState(() => saving = true);
    await updateProxy(value);
    setState(() {
      proxied = value;
      saving = false;
    });
  },
)
```

### Label first

```dart
KumoSwitch(
  label: 'Development mode',
  controlFirst: false,
  checked: devMode,
  onCheckedChange: (value) => setState(() => devMode = value),
)
```

## Accessibility

- Announced as a switch (toggled state) with its label; not as a button.
- Tab focuses it; Space or Enter toggles. Keyboard focus draws a 2px brand ring around the track.
- Without a visible label pass `semanticLabel`; otherwise it is announced as "Switch", Kumo's fallback.

## Motion

- Tap: the thumb springs to the other side (`KumoSprings.standard`), starting from wherever it is, so rapid taps never jump. Track and thumb colors follow the thumb's position.
- Press: the thumb widens by a quarter while held (a press spring), toward the side it can travel to.
- Drag: the thumb follows the finger 1:1 from the touch point and rubberbands past either end. On release the side is chosen from the position plus the projected flick (`KumoMotion.project`); a flick settles with `KumoSprings.momentum` (a slight overshoot), a slow release with `KumoSprings.standard`.
- A selection haptic marks every change. If the parent does not accept the new value, the thumb springs back.
- Reduced motion moves the thumb without animation and drops the press stretch.

## Mobile

The track keeps Kumo's size; the row (track and label) is padded to a 44px hit area on touch. The drag recognizer uses a 4px slop instead of Flutter's 18px, which is as long as the thumb's whole travel. Labels wrap at 2x text.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `checked` | `checked` |
| `onCheckedChange` | `onCheckedChange` |
| `label` | `label` / `labelWidget` |
| `labelTooltip` | `labelTooltip` |
| `required` | `required` |
| `controlFirst` | `controlFirst` |
| `size` | `size` |
| `variant` (`default`, `neutral`) | `variant` (`base`, `neutral`) |
| `disabled` | `disabled` |
| `transitioning` | `transitioning` (also blocks input) |
| `aria-label` | `semanticLabel` |
| `Switch.Item` | `KumoSwitch` inside `KumoSwitchGroup` |
