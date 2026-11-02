# KumoTagInput

A field that collects short values as removable tags. Reach for it for lists the user types: email recipients, allowed origins, labels.

Kumo reference: https://kumo-ui.com/components/tag-input

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTagInput(
  label: 'Alert recipients',
  placeholder: 'name@example.com',
  value: recipients,
  onValueChange: (v) => setState(() => recipients = v),
)
```

## When to use / when not to

- Use it when values are free-form and there are several of them.
- When the values come from a known list, use `KumoCombobox.multiple` or `KumoSelect.multiple`.
- For one value, use `KumoInput`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `List<String>` | required | The tags, in order |
| `onValueChange` | `ValueChanged<List<String>>?` | | Next list after an add or remove |
| `validateValue` | `KumoTagValidator?` | | `(value, accepted) => String?`: null accepts, a message rejects, `''` rejects with `labels.invalidValue` |
| `maxValues` | `int?` | | Largest number of tags |
| `allowDuplicates` | `bool` | `false` | Off: repeated tags are skipped silently |
| `labels` | `KumoTagInputLabels` | from `KumoStrings` | `input` (`addTag`), `removeValue` (`removeItem`), `invalidValue` (`invalidValue`), `maxValuesReached` (`maxValuesReached`) |
| `label`, `labelTooltip`, `description` | `String?` | | Field parts |
| `error` | `String?` | | Caller's error; replaces the field's own message |
| `showOptional`, `required` | `bool` | `false` | |
| `placeholder` | `String?` | | |
| `disabled` | `bool` | `false` | |
| `readOnly` | `bool` | `false` | Tags shown; no adding or removing; input still focusable |
| `mono` | `bool` | `false` | Monospace input |
| `keyboardType` | `TextInputType?` | `text` | Such as `TextInputType.emailAddress` |
| `focusNode`, `autofocus` | | | |

## Examples

### Validation

```dart
KumoTagInput(
  label: 'Allowed origins',
  value: origins,
  onValueChange: (v) => setState(() => origins = v),
  validateValue: (v, accepted) => v.startsWith('https://') ? null : 'Origins must start with https://',
)
```

### Limit and localized copy

```dart
KumoTagInput(
  label: 'Etiquetas',
  maxValues: 3,
  labels: KumoTagInputLabels(
    input: 'Agregar etiqueta',
    removeValue: (v) => 'Eliminar $v',
    invalidValue: (v) => '$v no es valido.',
    maxValuesReached: (n) => 'Maximo de $n etiquetas.',
  ),
  value: tags,
  onValueChange: (v) => setState(() => tags = v),
)
```

### Read only

```dart
const KumoTagInput(label: 'Assigned teams', readOnly: true, value: ['billing', 'dns', 'workers'])
```

## Behavior

- Enter, a typed comma, the keyboard's done key, Tab and leaving the field add what was typed, trimmed.
- Text pasted with commas or line breaks becomes one tag per part.
- Tags are checked in order. The first rejected one, and everything after it, stays in the input with the message under the field; tags before it are added. Editing clears the message.
- At `maxValues` the rest stays in the input with `KumoStrings.maxValuesReached` ("You can add up to N").

## Accessibility

- Each tag's X is a button named "Remove <tag>" (`labels.removeValue`).
- Backspace in the empty input removes the last tag (hardware keyboards).
- A rejected Tab keeps focus in the field so the value can be fixed.
- The validation message is a live region and is announced.

## Motion

A new tag grows in from zero width and fades in over 150ms; a removed tag (X button or Backspace) shrinks and fades the way it came while the tags after it slide over. Typing never waits for a tag to finish animating. A rejected value does not shake the field: the message under it opens and fades in over 150ms, and closes the same way once the text is edited. Under reduced motion tags and messages appear and leave at once.

## Mobile

Tags wrap onto new lines and the field grows; it never scrolls sideways. Remove buttons get touch targets up to 44px wide inside the field without changing its density.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `value`, `onValueChange` | `value`, `onValueChange` |
| `validateValue` (returns `bool`) | `validateValue` (returns the message or null) |
| `maxValues` | `maxValues` |
| `labels` | `labels` (`KumoTagInputLabels`) |
| `label`, `labelTooltip`, `description`, `error` | same names |
| `disabled`, `readOnly`, `placeholder`, `required` | same names |
| duplicates skipped | `allowDuplicates: false` |
| `name`, `form` | not ported (no HTML forms) |
