# KumoToggle

A two-state button that stays pressed: a filter, a view option, a formatting style. Not a Kumo component; it follows shadcn's Toggle with Kumo's segmented styling, where the pressed state fills with `contrast` and inverse text.

Kumo reference: https://kumo-ui.com/components/radio (segmented appearance, which this styling follows)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoToggle(
  icon: KumoIcons.funnel,
  label: 'Errors only',
  pressed: errorsOnly,
  onPressedChange: (value) => setState(() => errorsOnly = value),
)
```

## When to use / when not to

Use a toggle for an on/off option that lives with other buttons (a log viewer's "Errors only", a text editor's bold). For a setting on a form or a settings page, use `KumoSwitch` or `KumoCheckbox`. For several related toggles, use `KumoToggleGroup`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `pressed` | `bool` | required | Controlled state |
| `onPressedChange` | `ValueChanged<bool>?` | | Called with the next state. Null disables the toggle |
| `label` | `String?` | | Text. Without it the toggle is square |
| `icon` | `IconData?` | | Leading icon, or the only content |
| `variant` | `KumoToggleVariant` | `ghost` | `ghost`: no surface until hovered; `outline`: control surface with a ring |
| `size` | `KumoToggleSize` | `base` | `sm` 26px (12px text), `base` 34px (13px), `lg` 40px (14px) |
| `disabled` | `bool` | `false` | |
| `title` | `String?` | | Tooltip; doubles as the accessible name of icon-only toggles |
| `semanticLabel` | `String?` | | Required for icon-only toggles (or `title`) |
| `focusNode` | `FocusNode?` | | |
| `autofocus` | `bool` | `false` | |

## Examples

### Icon-only

```dart
KumoToggle(
  icon: KumoIcons.textB,
  semanticLabel: 'Bold',
  pressed: bold,
  onPressedChange: (value) => setState(() => bold = value),
)
```

### Outline

```dart
KumoToggle(
  label: 'Wrap lines',
  variant: KumoToggleVariant.outline,
  pressed: wrap,
  onPressedChange: (value) => setState(() => wrap = value),
)
```

## Accessibility

Announced as a toggle button with its on or off state. Tab focuses it, Space or Enter flips it, and keyboard focus draws Kumo's 2px brand ring.

## Motion

Like a button: a 0.98 press-scale spring from pointer down, instant hover and pressed colors, no scale under reduced motion.

## Mobile

The visual keeps its size; the hit area is padded to 44x44 on touch.

## Kumo React mapping

Kumo has no Toggle. The closest Base UI API is `Toggle`:

| Base UI prop | Flutter parameter |
| --- | --- |
| `pressed` / `defaultPressed` | `pressed` (controlled only) |
| `onPressedChange` | `onPressedChange` |
| `disabled` | `disabled` |
| `aria-label` | `semanticLabel` |

## KumoToggleGroup

A row of toggles that act together: one at a time (a view mode) or any number (HTTP methods, formatting). By default it draws Kumo's joined segmented bar.

```dart
KumoToggleGroup<String>(
  semanticLabel: 'Layout',
  value: view,
  allowDeselect: false,
  onValueChange: (next) => setState(() => view = next),
  items: const [
    KumoToggleGroupItem(value: 'list', icon: KumoIcons.rows, semanticLabel: 'List view'),
    KumoToggleGroupItem(value: 'grid', icon: KumoIcons.squaresFour, semanticLabel: 'Grid view'),
  ],
)
```

```dart
KumoToggleGroup<String>.multiple(
  semanticLabel: 'HTTP methods',
  values: methods,
  onValuesChange: (next) => setState(() => methods = next),
  items: const [
    KumoToggleGroupItem(value: 'GET', label: 'GET'),
    KumoToggleGroupItem(value: 'POST', label: 'POST'),
  ],
)
```

See `KumoToggleGroup.md` for its parameters.
