# KumoSelect

A field-styled trigger that opens a list of options. Reach for it when the user picks one value (or a few) from a known list: a region, a plan, an environment.

Kumo reference: https://kumo-ui.com/components/select

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoSelect<String>(
  label: 'Region',
  placeholder: 'Choose a region',
  value: region,
  onValueChange: (v) => setState(() => region = v),
  options: const [
    KumoSelectOption(value: 'enam', label: 'Eastern North America'),
    KumoSelectOption(value: 'weur', label: 'Western Europe'),
    KumoSelectOption(value: 'apac', label: 'Asia Pacific'),
  ],
)
```

## When to use / when not to

- Use it for a closed list of up to a few thousand options where the user knows what they want.
- When the user should search by typing, use `KumoCombobox`. When any text is acceptable and options are only suggestions, use `KumoAutocomplete`.
- For two to five options that should all be visible, use a radio group or segmented tabs.
- For actions (Rename, Delete), use `KumoDropdownMenu`; a select holds a value.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `options` | `List<KumoSelectItem<T>>` | required | `KumoSelectOption`, `KumoSelectGroup` and `KumoSelectSeparator` entries in display order |
| `value` | `T?` | `null` | Chosen value (single). Null shows `placeholder`. Compared with `==` |
| `onValueChange` | `ValueChanged<T?>?` | | Called with the picked value |
| `values` | `List<T>` | required in `.multiple` | Chosen values, in pick order |
| `onValuesChange` | `ValueChanged<List<T>>?` | | `.multiple` only: next list after a toggle |
| `size` | `KumoFieldSize` | `base` | `xs` 20, `sm` 26, `base` 36, `lg` 40 px tall |
| `label` | `String?` | | Visible label; also the accessible name |
| `description` | `String?` | | Help text under the trigger |
| `error` | `String?` | | Error text under the trigger; red ring; announced |
| `labelTooltip` | `String?` | | Info icon with a tooltip after the label |
| `showOptional` | `bool` | `false` | Shows "(optional)" after the label |
| `required` | `bool` | `false` | Announces the field as required |
| `placeholder` | `String?` | | Shown while nothing is chosen |
| `loading` | `bool` | `false` | Skeleton in the trigger; cannot open |
| `disabled` | `bool` | `false` | Dimmed; cannot open |
| `presentation` | `KumoPresentation` | `auto` | `auto` uses a bottom sheet below 768px; `popover` or `sheet` force one |
| `side` | `KumoSide` | `bottom` | Flips when there is no room |
| `align` | `KumoAlign` | `start` | |
| `sideOffset` | `double` | `4` | Gap between trigger and list |
| `maxHeight` | `double?` | `null` | Caps the list; by default it may use all the room on its side |
| `renderValue` | `KumoSelectValueBuilder<T>?` | | `(context, selected) => Widget` for the trigger; `selected` is never empty |
| `semanticLabel` | `String?` | | Accessible name without a visible label (Kumo's `aria-label`) |
| `sheetTitle` | `String?` | `label` | Heading at the top of the sheet |
| `focusNode` | `FocusNode?` | | |
| `autofocus` | `bool` | `false` | |

### Option types

| Type | Parameters | Notes |
| --- | --- | --- |
| `KumoSelectOption<T>` | `value`, `label`, `description`, `icon`, `disabled`, `keywords` | `KumoSelectOption.fromLabels(['a', 'b'])` builds string options |
| `KumoSelectGroup<T>` | `label`, `options` | Heading plus its options |
| `KumoSelectSeparator<T>` | | Hairline between options |

## Examples

### Groups, separators and disabled options

```dart
KumoSelect<String>(
  label: 'Region',
  value: region,
  onValueChange: (v) => setState(() => region = v),
  options: const [
    KumoSelectGroup(label: 'Americas', options: [
      KumoSelectOption(value: 'enam', label: 'Eastern North America', icon: KumoIcons.globeHemisphereWest),
      KumoSelectOption(value: 'sam', label: 'South America', disabled: true),
    ]),
    KumoSelectSeparator(),
    KumoSelectGroup(label: 'Europe', options: [
      KumoSelectOption(value: 'weur', label: 'Western Europe', description: 'London, Paris, Amsterdam'),
    ]),
  ],
)
```

### Multiple with a summary

```dart
KumoSelect<String>.multiple(
  label: 'Visible columns',
  values: columns,
  onValuesChange: (v) => setState(() => columns = v),
  options: KumoSelectOption.fromLabels(['Name', 'Route', 'Status', 'Last deploy', 'Requests']),
  renderValue: (context, selected) => Text(
    selected.length > 3
        ? '${selected.take(2).map((o) => o.label).join(', ')} and ${selected.length - 2} more'
        : selected.map((o) => o.label).join(', '),
  ),
)
```

### Loading

```dart
KumoSelect<String>(
  label: 'Zone',
  placeholder: 'Choose a zone',
  loading: zones == null,
  options: KumoSelectOption.fromLabels(zones ?? const []),
  value: zone,
  onValueChange: (v) => setState(() => zone = v),
)
```

### Error and sizes

```dart
KumoSelect<String>(
  size: KumoFieldSize.sm,
  label: 'Environment',
  error: environment == null ? 'Choose an environment to deploy to' : null,
  options: KumoSelectOption.fromLabels(['production', 'staging']),
  value: environment,
  onValueChange: (v) => setState(() => environment = v),
)
```

### Thousands of options

Lists longer than 100 rows are built lazily with measured row heights, so they open at once and jump to any row (the current value, End) without building the rows in between. Nothing changes in the API:

```dart
KumoSelect<String>(
  label: 'Worker',
  options: [for (final w in workers) KumoSelectOption(value: w, label: w)],
  value: worker,
  onValueChange: (v) => setState(() => worker = v),
)
```

## Accessibility

- The trigger is a button with the label as its name, the selection as its value and an expanded state.
- Keyboard: Tab focuses the trigger. Enter, Space, Up or Down open the list. In the list, Up and Down move the highlight (skipping disabled options), Home and End (and Page Up/Down) jump to the ends, Enter or Space picks, Escape closes, Tab closes and moves on. Typing letters jumps to the next option that starts with them; typing the same letter again cycles. With the list closed, typing letters picks the match directly, like a native select.
- Focus never leaves the trigger while the list is open, so it is where the user left it after closing.
- Multiple-select rows are announced as checked or unchecked; single-select rows as selected.
- The error message is a live region.

## Motion

The list scales in from the trigger and fades (Kumo's 150ms popup motion, as a spring that reverses mid-flight). Under reduced motion it only fades. The trigger's value cross-fades over 100ms when it changes. The caret is Kumo's up-down caret, which is symmetric, so it does not rotate. The loading placeholder is a static `KumoSkeletonLine`. The sheet follows the finger, snaps by release velocity and dismisses with a downward flick; picking in the sheet fires a selection haptic. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.

## Mobile

Below 768px the list opens in a bottom sheet with the label as its title and the current option checked. Rows are 40px tall and the trigger's hit area is 44px on touch platforms. Force either presentation with `presentation`. The trigger fills its parent's width; inside a `Row` without bounds it takes Kumo's default width for its size (160, 200, 280, 320).

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `items` / `Select.Option` | `options` with `KumoSelectOption` |
| `Select.Group` + `Select.GroupLabel` | `KumoSelectGroup(label:, options:)` |
| `Select.Separator` | `KumoSelectSeparator()` |
| `value`, `onValueChange` | `value`, `onValueChange` |
| `multiple` | `KumoSelect.multiple(values:, onValuesChange:)` |
| `renderValue` | `renderValue` (receives the selected options) |
| `size` | `size` (`KumoFieldSize`) |
| `label`, `description`, `error`, `labelTooltip` | same names |
| `required={false}` | `showOptional: true` |
| `placeholder`, `loading`, `disabled` | same names |
| `side`, `align`, `sideOffset` | same names |
| `aria-label` | `semanticLabel` |
| `isItemEqualToValue` | value `==` |
| `alignItemWithTrigger`, `container` | not ported |
