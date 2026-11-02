# KumoInput

Kumo's `Input`: a single-line text field with a built-in label, description and error message. Use it for names, hostnames, emails, URLs, search boxes and any other short text.

Kumo reference: https://kumo-ui.com/components/input

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoInput(
  label: 'Worker name',
  description: 'Lowercase letters, numbers and dashes.',
  placeholder: 'image-resizer',
  value: name,
  onValueChange: (v) => setState(() => name = v),
)
```

## When to use / when not to

Use `KumoInput` for one line of free text. Reach for:

- `KumoInputArea` for several lines.
- `KumoInputGroup` when the field needs addons (an icon, `https://`, `.workers.dev`) or buttons attached inside one ring.
- `KumoSensitiveInput` for API tokens and other secrets that should be masked until revealed.
- `KumoNumberInput` for numbers with bounds and steppers, `KumoInputOtp` for one-time codes.
- `KumoSelect` or `KumoCombobox` when the value comes from a list.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String?` | | The text. Null leaves the field uncontrolled (the controller owns it) |
| `onValueChange` | `ValueChanged<String>?` | | Called with the new text on every edit |
| `controller` | `TextEditingController?` | | Drives the text instead of `value`; a new `value` is written into it |
| `focusNode` | `FocusNode?` | | |
| `size` | `KumoFieldSize` | `base` | `xs` 20px, `sm` 26px, `base` 36px, `lg` 40px (minimum heights; they grow with text scale) |
| `label` | `String?` | | Text above the field; also its accessible name. Wraps the field in `KumoField` |
| `labelWidget` | `Widget?` | | Custom label content; pair with `semanticLabel` |
| `labelTooltip` | `String?` | | Info icon after the label with this tooltip; also exposed as the field's tooltip |
| `description` | `String?` | | Helper text below; hidden while `error` is set |
| `error` | `String?` | | Error message below; turns the ring red and marks the field invalid |
| `required` | `bool` | `false` | Announced to screen readers; nothing is drawn (Kumo marks optional fields instead) |
| `showOptional` | `bool` | `false` | Shows "(optional)" after the label |
| `placeholder` | `String?` | | |
| `semanticLabel` | `String?` | | Accessible name when there is no `label` (Kumo's `aria-label`) |
| `disabled` | `bool` | `false` | 60% opacity, recessed fill, not focusable |
| `readOnly` | `bool` | `false` | Selectable, not editable, recessed fill |
| `leadingIcon`, `trailingIcon` | `IconData?` | | Icons inside the field, 16px (12px for `xs`/`sm`) |
| `leading`, `trailing` | `Widget?` | | Any widget in place of the icons (a clear button, a unit) |
| `obscureText` | `bool` | `false` | Masks the text (`type="password"`) |
| `mono` | `bool` | `false` | Monospace text for IDs, tokens and hostnames |
| `keyboardType` | `TextInputType?` | | `emailAddress`, `url`, `phone`, `number` for `type="email"` and friends |
| `textInputAction` | `TextInputAction?` | | The keyboard's action key |
| `textCapitalization` | `TextCapitalization` | `none` | |
| `autofillHints` | `Iterable<String>?` | `null` | Null keeps the field out of autofill |
| `passwordManagerIgnore` | `bool` | `false` | Drops `autofillHints` and suggestions so password managers skip a non-credential field |
| `autocorrect`, `enableSuggestions` | `bool` | `true` | Turned off automatically for `obscureText` |
| `inputFormatters` | `List<TextInputFormatter>?` | | |
| `maxLength` | `int?` | | Hard limit; no counter is drawn |
| `textAlign` | `TextAlign` | `start` | |
| `autofocus` | `bool` | `false` | |
| `onSubmitted`, `onEditingComplete`, `onTap` | | | |
| `scrollPadding` | `EdgeInsets` | `(20, 56, 20, 56)` | Room kept around the field when it scrolls above the keyboard, enough for the label and description |

## Examples

### Sizes

```dart
Column(children: [
  for (final s in KumoFieldSize.values) KumoInput(size: s, label: s.name, placeholder: 'example.com'),
])
```

### Error

The error replaces the description, turns the ring red, marks the field invalid for screen readers and is announced when it appears.

```dart
KumoInput(
  label: 'Billing email',
  keyboardType: TextInputType.emailAddress,
  autofillHints: const [AutofillHints.email],
  value: email,
  error: isValidEmail(email) ? null : 'Enter an email address like you@example.com.',
  onValueChange: (v) => setState(() => email = v),
)
```

### Optional field and label tooltip

```dart
Column(children: const [
  KumoInput(label: 'Phone number', showOptional: true, placeholder: '+1 555 0100'),
  KumoInput(label: 'Account ID', labelTooltip: 'Find it in the dashboard URL after /accounts/', mono: true),
])
```

### Bare input with icons

Without a label, name the field with `semanticLabel`.

```dart
KumoInput(
  semanticLabel: 'Search Workers',
  placeholder: 'Search Workers',
  leadingIcon: KumoIcons.magnifyingGlass,
  value: query,
  onValueChange: (v) => setState(() => query = v),
  trailing: query.isEmpty
      ? null
      : KumoButton(
          icon: KumoIcons.x,
          shape: KumoButtonShape.square,
          size: KumoButtonSize.xs,
          variant: KumoButtonVariant.ghost,
          semanticLabel: 'Clear search',
          onPress: () => setState(() => query = ''),
        ),
)
```

### Password managers

```dart
const KumoInput(label: 'Webhook secret', obscureText: true, passwordManagerIgnore: true)
```

### Controlled value and the caret

The field keeps an internal controller in sync with `value`. While the parent echoes back what was typed, the caret stays where it is. When the parent changes the value (a reset, a transform such as lowercasing), the text is replaced and the selection is kept, clamped to the new length.

```dart
KumoInput(
  label: 'Subdomain',
  value: subdomain,
  onValueChange: (v) => setState(() => subdomain = v.toLowerCase()),
)
```

## Accessibility

- The field is one text-field node named by `label` (or `semanticLabel`), with the description or error as its hint, `isRequired` when `required`, and an invalid validation result when `error` is set. The visible label is hidden from screen readers so the name is not read twice.
- The error row is a live region, so a new error is announced.
- Tapping the label, the padding or an icon focuses the field, like a web `<label>`.
- Tab focuses the field; focus shows Kumo's 1.5px focus ring (`ring-kumo-focus/50`), red in the error state.

## Motion

The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once. The focus and error rings change instantly, as in Kumo.

## Mobile

- Heights are minimums: at 2x text the field grows instead of clipping.
- On focus the field scrolls into view above the keyboard, keeping `scrollPadding` around it so the label and description stay visible (inside any `Scrollable`; give the screen a `Scaffold` with `resizeToAvoidBottomInset`).
- Pick `keyboardType` and `autofillHints` for the right keyboard and autofill.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `value` / `defaultValue` | `value` (controlled) / `controller` |
| `onValueChange` | `onValueChange` |
| `onChange` | `onValueChange` (receives the string) |
| `size` | `size` (`KumoFieldSize`) |
| `variant="error"` (deprecated) | `error` |
| `label` (string or node) | `label` / `labelWidget` |
| `labelTooltip` | `labelTooltip` |
| `description` | `description` |
| `error` (string or `{ message, match }`) | `error` (string; validate in Dart and pass the message) |
| `required={false}` | `showOptional: true` |
| `required` | `required` |
| `aria-label` | `semanticLabel` |
| `type="password"` | `obscureText: true` |
| `type="email"`, `"url"`, `"tel"`, `"number"` | `keyboardType` |
| `autoComplete` | `autofillHints` |
| `passwordManagerIgnore` | `passwordManagerIgnore` |
| `disabled`, `readOnly`, `placeholder`, `maxLength` | same names |
