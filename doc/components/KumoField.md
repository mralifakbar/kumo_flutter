# KumoField

Kumo's `Field`: a label above a control, with a description or an error message below it. Use it to give a custom or bare control the same layout as Kumo's form components.

Kumo reference: https://kumo-ui.com/components/input (Field is documented with the form components)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoField(
  label: 'Custom hostname',
  description: 'A hostname under a domain you own.',
  error: hostnameError,
  child: KumoInput(semanticLabel: 'Custom hostname', value: hostname, onValueChange: setHostname),
)
```

## When to use / when not to

Kumo's form components already wrap themselves in a field when you pass `label`, `description` or `error`, so prefer `KumoInput(label: ...)` over `KumoField(child: KumoInput())`. Reach for `KumoField` around a control that has no label of its own: a custom picker, a row of chips, a group of buttons. For checkboxes and switches use the control's own label.

## Layout

A column with 8px gaps (`grid gap-2`): label, control, then the error or the description. The error replaces the description, in 13px danger text with a warning icon. The description is 13px subtle text.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The control |
| `label` | `String?` | | Text above the control, drawn with `KumoLabel` |
| `labelWidget` | `Widget?` | | Custom label in place of `label` |
| `description` | `String?` | | Helper text below; hidden while `error` is set |
| `error` | `String?` | | Error message below, announced as a live region. Also put the control in its error state |
| `showOptional` | `bool` | `false` | "(optional)" after the label |
| `labelTooltip` | `String?` | | Info icon after the label |
| `required` | `bool` | `false` | Announces the label as required |
| `hideLabel` | `bool` | `false` | Keeps the label for screen readers only |

## Examples

### Around a custom control

```dart
KumoField(
  label: 'Allowed methods',
  description: 'Requests with other methods get a 405.',
  child: Wrap(spacing: 8, children: [
    for (final m in ['GET', 'POST', 'PUT'])
      KumoButton(label: m, size: KumoButtonSize.sm, onPress: () => toggle(m)),
  ]),
)
```

### Error

The field draws the message; put the control in its own error state too if it has one.

```dart
KumoField(
  label: 'Allowed methods',
  error: methods.isEmpty ? 'Pick at least one method.' : null,
  child: Wrap(spacing: 8, children: [
    for (final m in ['GET', 'POST', 'PUT'])
      KumoButton(label: m, size: KumoButtonSize.sm, onPress: () => toggle(m)),
  ]),
)
```

### Visually hidden label

```dart
const KumoField(
  label: 'Search zones',
  hideLabel: true,
  child: KumoInput(semanticLabel: 'Search zones', leadingIcon: KumoIcons.magnifyingGlass),
)
```

## Accessibility

- The label is exposed as text; the control needs its own accessible name (`semanticLabel` on Kumo inputs) because a field label is not linked to an arbitrary child. Kumo's own form components do this linking for you when you use their `label`.
- `required` reads the label as "Label, Required".
- The error row is a live region, so a new error is announced.

## Motion

None.

## Mobile

Every row wraps and grows with the text scale; nothing has a fixed height.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` | `child` |
| `label` (string or node) | `label` / `labelWidget` |
| `description` | `description` |
| `error` (`{ message, match }`) | `error` (string; decide when it shows in Dart) |
| `required={false}` | `showOptional: true` |
| `required` | `required` |
| `labelTooltip` | `labelTooltip` |
| `hideLabel` | `hideLabel` (Flutter keeps the label for screen readers) |
| `controlFirst` | not used; checkbox and switch labels come from those controls |
