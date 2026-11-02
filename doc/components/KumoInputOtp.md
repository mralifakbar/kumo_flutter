# KumoInputOtp

A one-time code field drawn as a row of cells, for verification codes sent by SMS, email or an authenticator app.

Kumo has no such component; this follows shadcn's `InputOTP`, drawn with Kumo's field chrome (each cell is a `KumoFieldBox`). Kumo reference for the styling: https://kumo-ui.com/components/input

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoInputOtp(
  label: 'Verification code',
  value: code,
  onValueChange: (v) => setState(() => code = v),
  onComplete: verify,
)
```

## When to use / when not to

Use it for short fixed-length codes: two-factor codes, email confirmation codes, device PINs, recovery codes. For a long token the user pastes once (an API token) use `KumoSensitiveInput` or `KumoInput`.

## Behavior

One hidden text field drives every cell:

- Typing fills the next cell; backspace clears the previous one. The caret always stays after the last character, so cells fill in order.
- Pasting fills every cell. Separators and spaces are dropped ("123 456" becomes 123456) and extra characters are cut off.
- The platform's one-time-code autofill (`AutofillHints.oneTimeCode`) fills the code from an SMS.
- `onComplete` fires each time the code reaches `length`.
- Digits only by default, with the number keyboard. `alphanumeric` accepts letters too and uppercases them.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `length` | `int` | `6` | Number of cells |
| `value` | `String?` | | The code typed so far; null leaves the field uncontrolled |
| `onValueChange` | `ValueChanged<String>?` | | Whole code after every edit |
| `onComplete` | `ValueChanged<String>?` | | When the code reaches `length` |
| `controller`, `focusNode` | | | |
| `groups` | `List<int>?` | | Splits cells with a dash, such as `[3, 3]`; must add up to `length` (otherwise ignored) |
| `size` | `KumoFieldSize` | `lg` | Square cells: 40px at `lg`, 36px at `base` |
| `label`, `labelTooltip`, `description`, `error` | `String?` | | As in `KumoInput`; `error` turns every cell red |
| `required`, `showOptional` | `bool` | `false` | |
| `semanticLabel` | `String?` | | Accessible name without a `label` |
| `disabled` | `bool` | `false` | |
| `obscureText` | `bool` | `false` | A dot in place of each character (PINs) |
| `alphanumeric` | `bool` | `false` | Letters and digits, uppercased |
| `autofocus` | `bool` | `false` | |
| `scrollPadding` | `EdgeInsets` | `(20, 56, 20, 56)` | |

## Examples

### Grouped code with verification

```dart
KumoInputOtp(
  label: 'Verification code',
  description: 'Enter the 6-digit code from your authenticator app.',
  error: rejected ? 'That code is not valid. Request a new one.' : null,
  groups: const [3, 3],
  value: code,
  onValueChange: (v) => setState(() => code = v),
  onComplete: verify,
)
```

### Masked PIN

```dart
KumoInputOtp(
  label: 'Device PIN',
  length: 4,
  obscureText: true,
  value: pin,
  onValueChange: (v) => setState(() => pin = v),
)
```

### Recovery code with letters

```dart
KumoInputOtp(
  label: 'Recovery code',
  length: 8,
  groups: const [4, 4],
  alphanumeric: true,
  value: recovery,
  onValueChange: (v) => setState(() => recovery = v),
)
```

## Accessibility

- Screen readers see one text field named by the label, with the code as its value and the description or error as its hint. The cells are hidden from the semantics tree.
- The error row is a live region.
- Tap any cell, or the label, to focus.

## Motion

The real field is invisible, so the next empty cell draws its own 1.5px caret while the code has focus. It blinks like a text caret (500ms on, 500ms off) only while focused, pauses off screen, and holds still under reduced motion. The active cell's focus ring moves instantly as cells fill. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once.

## Mobile

- Number keyboard and SMS code autofill by default; long-press the cells for Paste.
- Cells stay square and grow with text scale. When the row is wider than the screen (8 cells at 2x text on a phone), the row scales down to fit instead of overflowing.

## Kumo React mapping

Kumo has no one-time code input. Compared with shadcn's `InputOTP`:

| shadcn | Flutter parameter |
| --- | --- |
| `maxLength` | `length` |
| `value`, `onChange` | `value`, `onValueChange` |
| `onComplete` | `onComplete` |
| `InputOTPGroup` + `InputOTPSeparator` | `groups` |
| `pattern` | `alphanumeric` (or digits by default) |
