# KumoLabel

Kumo's `Label`: the medium-weight 14px text above a form control, with an optional "(optional)" marker and an info tooltip.

Kumo reference: https://kumo-ui.com/components/label

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoLabel('Zone name')
```

## When to use / when not to

Most of the time you do not use `KumoLabel` directly: `KumoInput`, `KumoInputArea`, `KumoInputGroup`, `KumoSensitiveInput`, `KumoNumberInput`, `KumoInputOtp` and `KumoField` draw it from their `label`, `showOptional` and `labelTooltip` parameters, and wire the name to the control for screen readers. Use it on its own for a custom layout, or as the `labelWidget` of a `KumoField`.

Kumo marks optional fields rather than required ones. Show "(optional)" when most fields in a form are required; use a tooltip for context that does not fit in the label, never for information the user must read.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String` | required (positional) | Label text, sentence case |
| `showOptional` | `bool` | `false` | Shows "(optional)" after the text in subtle, regular-weight text |
| `optionalLabel` | `String?` | `KumoStrings.optional` | Replaces "(optional)" |
| `tooltip` | `String?` | | Shows an info icon after the text with this tooltip |
| `tooltipSemanticLabel` | `String?` | `KumoStrings.moreInformation` | Accessible name of the info icon |
| `required` | `bool` | `false` | Announces "Required" after the text; nothing is drawn |

## Examples

### Optional and tooltip

```dart
Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
  KumoLabel('Phone number', showOptional: true),
  KumoLabel('API token', tooltip: 'Create one under My Profile, API Tokens'),
])
```

### Translated

`KumoLocale` replaces the built-in copy for a subtree.

```dart
const KumoLocale(
  strings: KumoStrings(optional: '(opcional)', moreInformation: 'Mais informações'),
  child: KumoLabel('Telefone', showOptional: true),
)
```

## Accessibility

- With `required`, the label reads as "Zone name, Required".
- The info icon is named "More information" and exposes the tooltip text to screen readers.
- Form components hide their visible label from screen readers and put the name on the control itself, so it is read once, with the control.

## Motion

The tooltip opens on hover after a short delay, at once on keyboard focus, and on long press with touch (see `KumoTooltip`).

## Mobile

The label wraps onto more lines when it does not fit, and scales with the platform text size.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` | `text` |
| `showOptional` | `showOptional` |
| `optionalLabel` | `optionalLabel` |
| `tooltip` | `tooltip` |
| `tooltipAriaLabel` | `tooltipSemanticLabel` |
| `htmlFor`, `asContent` | not needed: form components wire the label themselves |
