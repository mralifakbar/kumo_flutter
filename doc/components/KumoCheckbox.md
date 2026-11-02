# KumoCheckbox

Kumo's `Checkbox`: a 16px box with a label for a single yes or no choice, or the "select all" control above a list (with `indeterminate`).

Kumo reference: https://kumo-ui.com/components/checkbox

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoCheckbox(
  label: 'Purge cache after deploy',
  checked: purge,
  onCheckedChange: (value) => setState(() => purge = value),
)
```

## When to use / when not to

Use a checkbox for a choice that is submitted or saved later, or for selecting items in a list. For a setting that takes effect at once, use `KumoSwitch`. For one choice out of several, use `KumoRadioGroup`. For several related checkboxes under one title, use `KumoCheckboxGroup`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `checked` | `bool` | required | Controlled value |
| `onCheckedChange` | `ValueChanged<bool>?` | | Called with the next value. An indeterminate checkbox reports `true`. Null disables the checkbox |
| `indeterminate` | `bool` | `false` | Shows a dash; announced as mixed. Takes precedence over `checked` |
| `label` | `String?` | | Label text, regular weight (medium in cards). Also the accessible name |
| `labelWidget` | `Widget?` | | Custom label in place of `label` |
| `description` | `String?` | | Helper text under the label (13px, subtle) |
| `error` | `String?` | | Error text under the label, announced as a live region. Also switches to the error ring |
| `labelTooltip` | `String?` | | Info icon with a tooltip after the label |
| `required` | `bool?` | | `false` shows "(optional)" after the label, as in Kumo |
| `controlFirst` | `bool?` | `true`, `false` for cards | Box before the label, or after it |
| `variant` | `KumoCheckboxVariant` | `base` | `error` draws the red ring without a message |
| `appearance` | `KumoCheckboxAppearance` | `base` | `card`: bordered, 12px padding, tinted while checked |
| `disabled` | `bool` | `false` | Dims the box (the whole card for cards) |
| `semanticLabel` | `String?` | | Accessible name without a visible label |
| `focusNode` | `FocusNode?` | | |
| `autofocus` | `bool` | `false` | |

## Examples

### Select all with indeterminate

```dart
KumoCheckbox(
  label: 'All routes',
  checked: selected.length == routes.length,
  indeterminate: selected.isNotEmpty && selected.length < routes.length,
  onCheckedChange: (all) => setState(() => selected = all ? routes.toSet() : <String>{}),
)
```

### Label first

```dart
KumoCheckbox(
  label: 'Remember this device',
  controlFirst: false,
  checked: remember,
  onCheckedChange: (value) => setState(() => remember = value),
)
```

### Error

```dart
KumoCheckbox(
  label: 'I understand this deletes the bucket',
  error: confirmed ? null : 'Confirm to continue.',
  checked: confirmed,
  onCheckedChange: (value) => setState(() => confirmed = value),
)
```

### Card

```dart
KumoCheckbox(
  appearance: KumoCheckboxAppearance.card,
  label: 'Bot Fight Mode',
  description: 'Challenge requests that match known bot patterns.',
  checked: botFight,
  onCheckedChange: (value) => setState(() => botFight = value),
)
```

### Row selection without a visible label

```dart
KumoCheckbox(
  semanticLabel: 'Select image-resizer',
  checked: isSelected,
  onCheckedChange: (value) => toggleRow('image-resizer', value),
)
```

## Accessibility

- Announced as a checkbox (not a button) with its checked, unchecked or mixed state; the label is the accessible name. Without a label, pass `semanticLabel`.
- Tab focuses the checkbox; Space or Enter toggles it. Keyboard focus draws Kumo's 2px brand ring on the box.
- `error` text is a live region, and the red ring is always paired with text.

## Motion

The check mark (or dash) scales in from 0.6 with Kumo's `--ease-bounce` curve (`KumoCurves.bounce`) over 150ms, a small overshoot as it lands. Unchecking removes the mark at once, as Kumo's indicator does. The whole row is the hit area; on pointer-down the box itself presses in to 0.9 with a press spring and springs back on release, from wherever it is. Under reduced motion the mark appears without animation and the box does not scale.

## Mobile

The box stays 16px. The whole row (box and label) is the hit area and is padded to at least 44px tall on touch platforms; a checkbox without a label gets a 44x44 hit area. Labels wrap; there is no fixed height, so 2x text does not clip.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `checked` | `checked` |
| `indeterminate` | `indeterminate` |
| `onCheckedChange` | `onCheckedChange` |
| `label` | `label` / `labelWidget` |
| `labelTooltip` | `labelTooltip` |
| `controlFirst` | `controlFirst` |
| `variant="error"` | `variant: KumoCheckboxVariant.error` (or `error`) |
| `appearance="card"` (items) | `appearance: KumoCheckboxAppearance.card` |
| `disabled` | `disabled` |
| `required={false}` | `required: false` |
| `aria-label` | `semanticLabel` |
| `name` | not ported (no HTML forms) |

`description` and `error` on a single checkbox are port additions; Kumo shows them only on groups and card items.
