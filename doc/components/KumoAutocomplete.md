# KumoAutocomplete

A free-text field with a list of suggestions. Reach for it when any value is valid but common ones are worth offering: route patterns, hostnames, dates.

Kumo reference: https://kumo-ui.com/components/autocomplete

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoAutocomplete(
  label: 'Route',
  placeholder: 'example.com/*',
  value: route,
  onValueChange: (v) => setState(() => route = v),
  options: KumoSelectOption.fromLabels(['example.com/*', 'api.example.com/*', 'example.com/images/*']),
)
```

## When to use / when not to

- Use it when the text itself is the value and suggestions only speed up typing.
- When the value must be one of the options, use `KumoCombobox` or `KumoSelect`.
- For a plain field with no suggestions, use `KumoInput`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | The field's text |
| `onValueChange` | `ValueChanged<String>?` | required | Every edit, and a picked suggestion's value |
| `options` | `List<KumoSelectItem<String>>` | required | Suggestions; an option's `value` is the inserted text, its `label` what the list shows |
| `size` | `KumoFieldSize` | `base` | |
| `label`, `description`, `error`, `labelTooltip` | `String?` | | Field parts |
| `showOptional`, `required` | `bool` | `false` | |
| `placeholder` | `String?` | | |
| `disabled` | `bool` | `false` | |
| `loading` | `bool` | `false` | A loading row while suggestions are fetched |
| `filter` | `KumoOptionFilter<String>?` | `kumoContainsFilter` | Which suggestions match the text |
| `emptyMessage` | `String?` | `null` | Text when nothing matches; null hides the list instead (Kumo's behavior) |
| `loadingMessage` | `String?` | `KumoStrings.loading` | |
| `onOpenChange` | `ValueChanged<bool>?` | | The suggestion list showed or hid |
| `onSubmitted` | `ValueChanged<String>?` | | Enter with no suggestion highlighted |
| `side`, `sideOffset` | | `bottom`, `4` | Flips above near the keyboard |
| `maxHeight` | `double` | `384` | |
| `semanticLabel` | `String?` | | Accessible name without a label |
| `keyboardType`, `autofillHints` | | | Passed to the text field |
| `mono` | `bool` | `false` | Monospace text for hostnames and paths |
| `focusNode`, `autofocus` | | | |

## Examples

### Grouped suggestions with an empty message

```dart
KumoAutocomplete(
  label: 'Custom hostname',
  emptyMessage: 'No saved hostnames match. Press Enter to use what you typed.',
  value: hostname,
  onValueChange: (v) => setState(() => hostname = v),
  onSubmitted: (v) => addHostname(v),
  options: const [
    KumoSelectGroup(label: 'Saved', options: [
      KumoSelectOption(value: 'shop.example.com', label: 'shop.example.com'),
      KumoSelectOption(value: 'docs.example.com', label: 'docs.example.com'),
    ]),
  ],
)
```

## Accessibility

- A labelled text field with an expanded state while suggestions show.
- Typing or Down opens the suggestions; Up and Down move the highlight while focus stays in the field; Enter puts the highlighted suggestion in the field (with nothing highlighted, Enter submits); Escape closes and keeps the text.
- The suggestion equal to the current text shows a check.

## Motion

Kumo's popup motion: a spring scale from the field plus a fade, fade only under reduced motion. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.

## Mobile

The list stays anchored to the field and opens above it when the on-screen keyboard leaves too little room below.

## Kumo React mapping

| Kumo prop / part | Flutter parameter |
| --- | --- |
| `items` + `Autocomplete.Item` | `options` |
| `Autocomplete.Group`, `GroupLabel`, `Separator` | `KumoSelectGroup`, `KumoSelectSeparator` |
| `value`, `onValueChange` | `value`, `onValueChange` |
| `onOpenChange` | `onOpenChange` (`open` is managed by the field) |
| `Autocomplete.InputGroup size` | `size` |
| `Autocomplete.Empty` | `emptyMessage` |
| `useFilter` / `filter` | `filter` |
| `label`, `description`, `error`, `labelTooltip`, `required` | same names |
