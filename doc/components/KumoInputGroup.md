# KumoInputGroup

Kumo's `InputGroup`: one field built from an input and the parts around it (icons, text addons, an inline suffix, buttons), drawn inside a single ring with a single focus ring.

Kumo reference: https://kumo-ui.com/components/input-group

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoInputGroup(
  label: 'Subdomain',
  children: [
    KumoInputGroupInput(value: subdomain, onValueChange: (v) => setState(() => subdomain = v)),
    const KumoInputGroupSuffix('.workers.dev'),
  ],
)
```

## When to use / when not to

Use a group when something belongs inside the field: a leading icon, a fixed prefix (`https://`, `/api/`, `$`), a domain that follows the value, a status icon or loader, a show/hide or clear button, or an action button attached to the end (Search, Apply). For a plain field use `KumoInput`; for a secret with reveal and copy use `KumoSensitiveInput`, which already has those buttons.

## Parts

| Part | Role |
| --- | --- |
| `KumoInputGroup` | Root: size, disabled, label, description, error. Owns the ring and focus ring |
| `KumoInputGroupInput` | The text input (exactly one). Takes the value and keyboard settings |
| `KumoInputGroupAddon` | Icon, text or compact button at `start` or `end` |
| `KumoInputGroupSuffix` | Text that follows the typed value and truncates when the value fills the field |
| `KumoInputGroupButton` | Ghost button inside an addon, or a solid button attached to the group's end |

Start addons are always drawn first and end addons last, whatever their order in `children`.

## Parameters

### KumoInputGroup

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | The parts |
| `size` | `KumoFieldSize` | `base` | Applies to every part: `xs` 20, `sm` 26, `base` 36, `lg` 40px |
| `disabled` | `bool` | `false` | Disables the input and every button |
| `label` | `String?` | | Text above; also the input's accessible name |
| `labelTooltip` | `String?` | | Info icon after the label |
| `description` | `String?` | | Helper text below |
| `error` | `String?` | | Error message below; turns the ring red |
| `required` | `bool` | `false` | Announced, not drawn |
| `showOptional` | `bool` | `false` | "(optional)" after the label |

### KumoInputGroupInput

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String?` | | Null leaves the input uncontrolled |
| `onValueChange` | `ValueChanged<String>?` | | |
| `controller`, `focusNode` | | | |
| `placeholder` | `String?` | | |
| `semanticLabel` | `String?` | | Accessible name when the group has no `label` |
| `readOnly`, `obscureText`, `mono` | `bool` | `false` | |
| `keyboardType`, `textInputAction`, `textCapitalization`, `autofillHints`, `inputFormatters`, `maxLength` | | | As in `KumoInput` |
| `passwordManagerIgnore` | `bool` | `false` | |
| `autocorrect`, `enableSuggestions` | `bool` | `true` | |
| `autofocus`, `onSubmitted`, `scrollPadding` | | | |

### KumoInputGroupAddon

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `align` | `KumoInputGroupAlign` | `start` | `start` or `end` |
| `icon` | `IconData?` | | Sized to the group: 10, 13, 18, 20px for `xs` to `lg` |
| `text` | `String?` | | Subtle text such as `/api/` or `@example.com` |
| `child` | `Widget?` | | Anything else: a `KumoInputGroupButton`, a `KumoLoader`, a status icon |

### KumoInputGroupSuffix

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String` | required (positional) | Follows the typed value |

### KumoInputGroupButton

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String?` | | Button text |
| `icon` | `IconData?` | | Icon; icon-only buttons need `semanticLabel` or `tooltip` |
| `onPress` | `VoidCallback?` | | Null disables the button |
| `variant` | `KumoButtonVariant` | `ghost` | `ghost` inside an addon; any solid variant as a direct child attaches the button to the group's end |
| `semanticLabel` | `String?` | | Defaults to `tooltip` for icon-only buttons |
| `tooltip` | `String?` | | Tooltip below the button |
| `disabled` | `bool` | `false` | |

## Examples

### Icon and text addons

```dart
Column(children: const [
  KumoInputGroup(children: [
    KumoInputGroupAddon(icon: KumoIcons.link),
    KumoInputGroupInput(semanticLabel: 'Link', placeholder: 'Paste a link'),
  ]),
  KumoInputGroup(children: [
    KumoInputGroupAddon(text: '/api/'),
    KumoInputGroupInput(semanticLabel: 'API path', placeholder: 'endpoint'),
    KumoInputGroupAddon(align: KumoInputGroupAlign.end, text: '.json'),
  ]),
])
```

### Inline suffix with a status

Pair the status icon with text (here the description and error) so it is never conveyed by color alone.

```dart
KumoInputGroup(
  label: 'Subdomain',
  description: available ? '$subdomain.workers.dev is available.' : null,
  error: available ? null : '$subdomain.workers.dev is taken.',
  children: [
    KumoInputGroupInput(value: subdomain, onValueChange: check),
    const KumoInputGroupSuffix('.workers.dev'),
    KumoInputGroupAddon(
      align: KumoInputGroupAlign.end,
      child: checking
          ? const KumoLoader(size: KumoLoaderSize.sm, semanticLabel: 'Checking availability')
          : const KumoIcon(KumoIcons.checkCircleFill, color: KumoColor.textSuccess, semanticLabel: 'Available'),
    ),
  ],
)
```

### Buttons

A ghost button inside an addon acts on the value. A solid button as a direct child attaches to the end with its own border and focus treatment.

```dart
KumoInputGroup(children: [
  const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
  KumoInputGroupInput(semanticLabel: 'Search rules', value: query, onValueChange: (v) => setState(() => query = v)),
  KumoInputGroupAddon(
    align: KumoInputGroupAlign.end,
    child: KumoInputGroupButton(icon: KumoIcons.x, semanticLabel: 'Clear search', onPress: () => setState(() => query = '')),
  ),
  KumoInputGroupButton(label: 'Search', variant: KumoButtonVariant.secondary, onPress: search),
])
```

### Button with a tooltip

```dart
KumoInputGroupAddon(
  align: KumoInputGroupAlign.end,
  child: KumoInputGroupButton(icon: KumoIcons.question, tooltip: 'Query language help', onPress: openHelp),
)
```

### Sizes

```dart
Column(children: [
  for (final s in KumoFieldSize.values)
    KumoInputGroup(size: s, label: s.name, children: const [
      KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
      KumoInputGroupInput(placeholder: 'Search zones'),
    ]),
])
```

## Layout details

- Spacing follows Kumo's model: the input has full padding at the group edge (12px at `base`) and a narrower seam (8px) next to an addon; addons have outer padding only (8px, or 4px when they hold a button).
- Buttons inside an addon are one size below the group (26px in a 36px group) with corners concentric with the group's.
- Next to a suffix the input is as wide as its text (or placeholder), so the suffix follows the value; a long value pushes the suffix out rather than overflowing.

## Accessibility

- The group is one semantics container. The input is named by the group's `label` (or the input's `semanticLabel`), with the description or error as its hint and the invalid state on error.
- Icon-only buttons need `semanticLabel` or `tooltip`; status icons in an addon need their own `semanticLabel`.
- Tapping an addon, the suffix or empty space focuses the input; buttons keep their own taps.
- The focus ring stays on the group while focus is on any part inside it, including a button.

## Motion

Buttons inside addons press with the standard 0.98 spring scale. A solid button attached to the end does not scale (it would open a gap at the seam with the field); its press shows through the instant hover fill. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.

## Mobile

- On touch, buttons inside the group get a 44px-wide hit area as tall as the group, so the group keeps Kumo's height instead of growing to 44px.
- At 2x text the group grows; parts stay on one row.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `InputGroup` | `KumoInputGroup` |
| `InputGroup.Input` | `KumoInputGroupInput` |
| `InputGroup.Addon align="start" \| "end"` | `KumoInputGroupAddon(align: KumoInputGroupAlign.start \| end)` |
| `InputGroup.Suffix` | `KumoInputGroupSuffix` |
| `InputGroup.Button` | `KumoInputGroupButton` |
| `InputGroup.Button tooltip` | `tooltip` |
| `size`, `disabled`, `label`, `labelTooltip`, `description`, `error` | same names on `KumoInputGroup` |
| `required={false}` | `showOptional: true` |
| focus modes `container` / `individual` / `hybrid` | chosen the same way: solid direct buttons attach to the end with their own border |
| `InputGroup.Label`, `InputGroup.Description` (deprecated) | `KumoInputGroupAddon`, `KumoInputGroupSuffix` |
