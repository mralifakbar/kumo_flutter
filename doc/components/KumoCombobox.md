# KumoCombobox

A text field that filters a list of options as you type, for one value or several shown as chips. Reach for it when the list is long enough that searching beats scrolling.

Kumo reference: https://kumo-ui.com/components/combobox

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoCombobox<String>(
  label: 'Database',
  placeholder: 'Search databases',
  value: database,
  onValueChange: (v) => setState(() => database = v),
  options: const [
    KumoSelectOption(value: 'd1', label: 'D1'),
    KumoSelectOption(value: 'hyperdrive', label: 'Hyperdrive'),
    KumoSelectOption(value: 'kv', label: 'Workers KV'),
  ],
)
```

## When to use / when not to

- Use it when the value must come from the list and the list is long or the user knows the name.
- When any typed text is valid, use `KumoAutocomplete`. For a short list, `KumoSelect` is quicker.
- For free-form values collected as chips (emails, labels), use `KumoTagInput`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `options` | `List<KumoSelectItem<T>>` | required | Options, groups and separators. Groups get a hairline between them |
| `value` | `T?` | `null` | Chosen value (single). The field shows its label |
| `onValueChange` | `ValueChanged<T?>?` | | Picked value, or null from the clear button |
| `values` | `List<T>` | required in `.multiple` | Chosen values, shown as chips |
| `onValuesChange` | `ValueChanged<List<T>>?` | | `.multiple` only |
| `inputSide` | `KumoComboboxInputSide` | `right` | `.multiple` only: input after the chips, or `top` above them |
| `size` | `KumoFieldSize` | `base` | `xs` 20, `sm` 26, `base` 36, `lg` 40 px |
| `label`, `description`, `error`, `labelTooltip` | `String?` | | Field parts, as in `KumoField` |
| `showOptional`, `required` | `bool` | `false` | |
| `placeholder` | `String?` | | Input placeholder (hidden behind inline chips) |
| `disabled` | `bool` | `false` | |
| `loading` | `bool` | `false` | A loading row at the top of the list; hides the empty state |
| `filter` | `KumoOptionFilter<T>?` | `kumoContainsFilter` | `(option, query) => bool`. Pass `(o, q) => true` for server-filtered options |
| `emptyMessage` | `String?` | `KumoStrings.noResults` | Shown when nothing matches |
| `loadingMessage` | `String?` | `KumoStrings.loading` | |
| `onInputValueChange` | `ValueChanged<String>?` | | Text as typed, for fetching options |
| `side` | `KumoSide` | `bottom` | Flips above when the keyboard or the screen edge leaves too little room |
| `sideOffset` | `double` | `4` | |
| `maxHeight` | `double` | `384` | Kumo's 24rem cap |
| `semanticLabel` | `String?` | | Accessible name without a visible label |
| `clearLabel` | `String?` | `KumoStrings.clear` | Single: the clear button's name |
| `showOptionsLabel` | `String?` | `KumoStrings.showOptions` | Single: the caret button's name |
| `removeLabel` | `String Function(String)?` | `KumoStrings.removeItem` | Multiple: a chip's remove button name |
| `focusNode`, `autofocus` | | | |

## Examples

### Multiple with chips

```dart
KumoCombobox<String>.multiple(
  label: 'Allowed crawlers',
  placeholder: 'Add a crawler',
  values: bots,
  onValuesChange: (v) => setState(() => bots = v),
  options: KumoSelectOption.fromLabels(['Googlebot', 'Bingbot', 'Applebot', 'DuckDuckBot']),
)
```

### Server search

```dart
KumoCombobox<String>(
  label: 'R2 bucket',
  placeholder: 'Search buckets',
  options: results,
  filter: (option, query) => true,
  loading: searching,
  onInputValueChange: (q) => searchBuckets(q),
  value: bucket,
  onValueChange: (v) => setState(() => bucket = v),
)
```

### Custom filter

```dart
KumoCombobox<String>(
  label: 'Region code',
  options: const [
    KumoSelectOption(value: 'enam', label: 'Eastern North America', keywords: ['us-east']),
    KumoSelectOption(value: 'weur', label: 'Western Europe', keywords: ['eu-west']),
  ],
  filter: (option, query) => option.value.startsWith(query.toLowerCase()),
  value: region,
  onValueChange: (v) => setState(() => region = v),
)
```

## Accessibility

- The input is a labelled text field with an expanded state while the list shows.
- Focus stays in the input. Down and Up open the list and move the highlight (skipping disabled options); Enter picks; Escape closes and restores the chosen label; Tab closes and moves on.
- Typing highlights the first match, so Enter picks it.
- Multiple: each chip's X is a button named "Remove <label>"; Backspace in the empty input removes the last chip.
- "No results" and the loading row are live regions.

## Motion

The list scales in from the field and fades with Kumo's popup spring; reduced motion leaves only the fade. In multiple mode a picked chip grows in from zero width and fades in over 150ms; a removed chip shrinks and fades the way it came while the chips after it slide over, and the gap before it closes with it. A chip removed and picked again mid-exit turns around from where it is. The up-down caret is symmetric and does not rotate. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once. Under reduced motion chips appear and leave at once.

## Mobile

The list stays anchored to the field on phones (a sheet would hide the text being typed) and opens above the field when the on-screen keyboard covers the room below. Chip remove buttons and the clear button get touch targets up to 44px wide without changing the 36px field. Backspace on an empty input is a hardware-keyboard gesture; touch users remove chips with their X.

## Kumo React mapping

| Kumo prop / part | Flutter parameter |
| --- | --- |
| `items` + `Combobox.Item` | `options` |
| `Combobox.Group` + `GroupLabel` | `KumoSelectGroup` |
| `value`, `onValueChange` | `value`, `onValueChange` |
| `multiple` + `TriggerMultipleWithInput` + `Chip` | `KumoCombobox.multiple(values:, onValuesChange:)` |
| `inputSide` | `inputSide` |
| `Combobox.TriggerInput` (clear and caret buttons) | the single-value field |
| `Combobox.Empty` | `emptyMessage` |
| `useFilter` / `filter` | `filter` |
| `onInputValueChange` | `onInputValueChange` |
| `size`, `label`, `description`, `error`, `labelTooltip`, `required` | same names |
| `clearLabel`, `showOptionsLabel`, `removeLabel` | same names |
| `Combobox.TriggerValue` + `Combobox.Input` (search inside the popup) | not ported; use `KumoSelect` or the single field |
