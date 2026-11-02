# KumoInputArea

Kumo's `InputArea`: a multi-line text field (a textarea) with a built-in label, description and error message. Use it for notes, descriptions, messages and pasted config or scripts.

Kumo reference: https://kumo-ui.com/components/input-area

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoInputArea(
  label: 'Deployment notes',
  placeholder: 'What changed in this version?',
  value: notes,
  onValueChange: (v) => setState(() => notes = v),
)
```

## When to use / when not to

Use it when the answer can run past one line. For one line use `KumoInput`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String?` | | The text. Null leaves the field uncontrolled |
| `onValueChange` | `ValueChanged<String>?` | | Called on every edit, newlines included |
| `controller` | `TextEditingController?` | | Drives the text instead of `value` |
| `focusNode` | `FocusNode?` | | |
| `size` | `KumoFieldSize` | `base` | Text size and horizontal padding (`xs`/`sm` use 12px text) |
| `rows` | `int` | `3` | Visible lines when `autoResize` is off; longer text scrolls |
| `autoResize` | `bool` | `false` | Grow and shrink with the content |
| `minRows` | `int` | `1` | Lines when empty, with `autoResize` |
| `maxRows` | `int?` | | Lines to grow to before scrolling; null grows without limit |
| `label`, `labelWidget`, `labelTooltip`, `description`, `error` | | | As in `KumoInput` |
| `required` | `bool` | `false` | Announced, not drawn |
| `showOptional` | `bool` | `false` | "(optional)" after the label |
| `placeholder`, `semanticLabel` | `String?` | | |
| `disabled`, `readOnly` | `bool` | `false` | |
| `mono` | `bool` | `false` | Monospace, for scripts and config |
| `keyboardType` | `TextInputType?` | `multiline` | |
| `textInputAction` | `TextInputAction?` | `newline` | |
| `textCapitalization` | `TextCapitalization` | `sentences` | |
| `autocorrect`, `enableSuggestions` | `bool` | `true` | |
| `inputFormatters`, `maxLength`, `autofocus`, `onTap` | | | |
| `scrollPadding` | `EdgeInsets` | `(20, 56, 20, 56)` | Room kept around the caret when it scrolls above the keyboard |

## Examples

### Grows with its content

```dart
KumoInputArea(
  label: 'Configuration value',
  description: 'Grows up to 8 rows, then scrolls.',
  autoResize: true,
  minRows: 2,
  maxRows: 8,
  value: config,
  onValueChange: (v) => setState(() => config = v),
)
```

### Fixed rows

```dart
const KumoInputArea(label: 'Summary', rows: 2, placeholder: 'One or two sentences')
```

### Error

```dart
KumoInputArea(
  label: 'Support message',
  error: message.trim().length < 10 ? 'Write at least 10 characters so support can help.' : null,
  value: message,
  onValueChange: (v) => setState(() => message = v),
)
```

### Monospace script

```dart
const KumoInputArea(
  label: 'Worker script',
  labelTooltip: 'An ES module with a default fetch handler',
  mono: true,
  rows: 6,
)
```

## Accessibility

Same as `KumoInput`: one text-field node named by the label, with the description or error as its hint and the invalid state when `error` is set. The error row is a live region. Tapping the label or the padding focuses the field.

## Motion

With `autoResize` the height follows the text line by line, as on the web. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.

## Mobile

- The web resize handle has no touch equivalent; use `autoResize` so the field grows as the user types.
- Enter inserts a newline (`TextInputAction.newline`).
- Heights come from the row count and text scale, so 2x text never clips.
- The caret scrolls into view above the keyboard.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `value` / `defaultValue` | `value` / `controller` |
| `onValueChange`, `onChange` | `onValueChange` |
| `rows` | `rows` |
| `autoResize` | `autoResize` |
| `minRows`, `maxRows` | `minRows`, `maxRows` |
| `size` | `size` |
| `label`, `labelTooltip`, `description`, `error` | same names (`error` is a string) |
| `required={false}` | `showOptional: true` |
| `aria-label` | `semanticLabel` |
| `disabled`, `readOnly`, `placeholder`, `maxLength` | same names |
| `resize` (CSS) | not applicable; use `autoResize` |
