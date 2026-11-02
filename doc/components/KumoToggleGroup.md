# KumoToggleGroup

A row of toggles that act together: one pressed at a time (a view mode, a log level) or any number (HTTP methods, text formatting). Not a Kumo component; it follows shadcn's ToggleGroup and draws Kumo's segmented bar by default.

Kumo reference: https://kumo-ui.com/components/radio (segmented appearance, which the `outline` variant matches)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoToggleGroup<String>(
  semanticLabel: 'Log level',
  value: level,
  onValueChange: (next) => setState(() => level = next),
  items: const [
    KumoToggleGroupItem(value: 'info', label: 'Info'),
    KumoToggleGroupItem(value: 'warn', label: 'Warn'),
    KumoToggleGroupItem(value: 'error', label: 'Error'),
  ],
)
```

## When to use / when not to

Use a toggle group for view options and filters that sit with other controls. For a required single choice inside a form, a segmented `KumoRadioGroup` (with a legend, error and description) fits better. When the choice switches content panels, use tabs.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoToggleGroupItem<T>>` | required | |
| `value` | `T?` | required (single) | The pressed value, or null |
| `onValueChange` | `ValueChanged<T?>?` | | Single: next value, null when cleared. Null disables the group |
| `allowDeselect` | `bool` | `true` | Single: pressing the pressed item clears the value |
| `values` | `List<T>` | required (`.multiple`) | The pressed values |
| `onValuesChange` | `ValueChanged<List<T>>?` | | Multiple: next list; a newly pressed value is appended |
| `variant` | `KumoToggleVariant` | `outline` | `outline`: joined segmented bar; `ghost`: separate toggles 4px apart, for toolbars |
| `size` | `KumoToggleSize` | `base` | `sm` 26px, `base` 34px, `lg` 40px |
| `disabled` | `bool` | `false` | |
| `semanticLabel` | `String?` | | Names the group for screen readers |

### KumoToggleGroupItem

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `T` | required | |
| `label` | `String?` | | Text. Without it the item is square |
| `icon` | `IconData?` | | |
| `disabled` | `bool` | `false` | Skipped by arrow keys |
| `title` | `String?` | | Tooltip; doubles as the accessible name of icon-only items |
| `semanticLabel` | `String?` | | Required for icon-only items (or `title`) |

## Examples

### Toolbar formatting (ghost, multiple)

```dart
KumoToggleGroup<String>.multiple(
  semanticLabel: 'Text formatting',
  variant: KumoToggleVariant.ghost,
  values: formats,
  onValuesChange: (next) => setState(() => formats = next),
  items: const [
    KumoToggleGroupItem(value: 'bold', icon: KumoIcons.textB, title: 'Bold'),
    KumoToggleGroupItem(value: 'italic', icon: KumoIcons.textItalic, title: 'Italic'),
  ],
)
```

### Small, required

```dart
KumoToggleGroup<String>(
  semanticLabel: 'Chart interval',
  size: KumoToggleSize.sm,
  allowDeselect: false,
  value: interval,
  onValueChange: (next) => setState(() => interval = next),
  items: const [
    KumoToggleGroupItem(value: 'hour', label: 'Hour'),
    KumoToggleGroupItem(value: 'day', label: 'Day'),
  ],
)
```

## Accessibility

- Single selection is a radio group: each item is announced as a radio with its checked state. Multiple selection items are toggle buttons with their on or off state.
- Tab reaches the group once (the last focused item, else the first pressed, else the first enabled). Arrow keys move focus between enabled items, wrapping and mirrored in RTL; Home and End jump to the ends. Space or Enter toggles the focused item. Arrows do not change the value, as in Radix and shadcn.

## Motion

- Single choice, outline (segmented): the dark fill slides from the previous item to the new one with `KumoSprings.standard`, from where it is, and labels blend to the inverse color as it covers them. Clearing the value fades the fill out in place.
- Multiple choice: each item fills instantly, like Kumo's segmented radio.
- Segments do not scale on press (it would open gaps at the seams); their pressed fill shows on pointer-down. Ghost items use the standard press-scale spring. A selection haptic marks each change.
- Reduced motion: the fill moves at once.

## Mobile

Segments keep the bar's visual height while their hit area extends to 44px; icon-only segments widen to 44px. A bar wider than the screen scrolls sideways instead of overflowing. Inside an unbounded row (a scrolling toolbar) it lays out at its intrinsic width.

## Kumo React mapping

Kumo has no ToggleGroup; the segmented look comes from `Radio.Group appearance="segmented"`.

| shadcn / Radix prop | Flutter parameter |
| --- | --- |
| `type="single"` | `KumoToggleGroup(...)` |
| `type="multiple"` | `KumoToggleGroup.multiple(...)` |
| `value` / `onValueChange` | `value` / `onValueChange`, or `values` / `onValuesChange` |
| `variant` (`default`, `outline`) | `variant` (`ghost`, `outline`) |
| `size` | `size` |
| `disabled` | `disabled` |
| `ToggleGroupItem` | `KumoToggleGroupItem` |
