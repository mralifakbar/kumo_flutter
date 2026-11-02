# KumoSensitiveInput

Kumo's `SensitiveInput`: a field for secrets (API tokens, signing keys, passwords) that shows a mask until it is tapped, with a hide toggle and a copy button.

Kumo reference: https://kumo-ui.com/components/sensitive-input

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoSensitiveInput(
  label: 'API token',
  value: token,
  onValueChange: (v) => setState(() => token = v),
)
```

## When to use / when not to

Use it to show or edit a secret the user may need to read or copy once: an API token, a webhook secret, an environment variable marked secret. For a login password that the user types and never reads back, a `KumoInput` with `obscureText: true` and `autofillHints: [AutofillHints.password]` works better with password managers.

## Behavior

| State | Shown | Changes to |
| --- | --- | --- |
| Masked | Eight dots, whatever the length; "Click to reveal" (mouse) or "Tap to reveal" (touch) on hover or focus | Revealed on tap, Enter or Space; the field gets focus |
| Revealed | The value in a normal text field, with a hide button | Masked on the hide button, Escape (focus stays on the field), or when focus leaves the field |
| Empty | A normal empty text field | Revealed as soon as something is typed |

A new value from outside (a rolled token) is masked unless the field has focus. Copying never reveals the value.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String?` | | The secret. Null leaves the field uncontrolled |
| `onValueChange` | `ValueChanged<String>?` | | |
| `controller`, `focusNode` | | | |
| `onCopy` | `VoidCallback?` | | Called after the value is on the clipboard |
| `size` | `KumoFieldSize` | `base` | |
| `label` | `String?` | | Text above; also the accessible name |
| `labelTooltip`, `description`, `error` | `String?` | | As in `KumoInput` |
| `required`, `showOptional` | `bool` | `false` | |
| `placeholder` | `String?` | | Shown in the empty state |
| `semanticLabel` | `String?` | `'Sensitive value'` | Accessible name without a `label` |
| `disabled` | `bool` | `false` | Cannot reveal or copy |
| `readOnly` | `bool` | `false` | Reveal and copy, no editing |
| `mono` | `bool` | `false` | Monospace, which keeps similar characters in tokens apart |
| `revealText` | `String?` | `'Click to reveal'` / `'Tap to reveal'` | Shown over the mask and read as the hint |
| `hiddenAnnouncement` | `String?` | `KumoStrings.valueHidden` | Announced when the value is masked again |
| `scrollPadding` | `EdgeInsets` | `(20, 56, 20, 56)` | |

The copy and hide buttons are named from `KumoStrings` (`copy`, `copied`, `hide`), and the copy result is announced with `copied` or `copyFailed`.

## Examples

### Copy feedback

```dart
KumoSensitiveInput(
  label: 'Webhook secret',
  value: secret,
  mono: true,
  onCopy: () => setState(() => copies++),
)
```

### States

```dart
Column(children: const [
  KumoSensitiveInput(label: 'Signing key', value: 'invalid-key', error: 'This key is not valid for the zone.'),
  KumoSensitiveInput(label: 'Disabled', value: 'cannot-edit', disabled: true),
  KumoSensitiveInput(label: 'Read-only', value: 'view-only-secret', readOnly: true),
  KumoSensitiveInput(label: 'Webhook secret', placeholder: 'Paste the secret from your provider'),
])
```

### Sizes

```dart
Column(children: [
  for (final s in KumoFieldSize.values) KumoSensitiveInput(size: s, label: '${s.name} size', value: 'secret-api-key-123'),
])
```

## Accessibility

- Masked, the field is a button named by the label with the reveal text as its hint; the secret is not in the semantics tree.
- Revealed, it is a text field named by the label, with suggestions and autocorrect off and the `visiblePassword` keyboard so the keyboard does not learn the secret.
- Hiding announces `hiddenAnnouncement`; copying announces "Copied".
- Keyboard: Tab to the field, Enter or Space to reveal, Escape to mask, Tab to the hide and copy buttons.

## Motion

Revealing and masking fade the new text in over 100ms instead of flashing it. The mouse Copy tab fades in over 100ms on hover and focus. The error or description under the field opens and fades in over 150ms when it appears, closes the same way when it goes, and cross-fades when one replaces the other, so the content below slides instead of jumping. Gaining or losing the message never rebuilds the field, so it keeps focus and text. Reduced motion shows and hides it at once. Under reduced motion every change is instant.

## Mobile

- With a mouse, the Copy tab sits on the field's top edge as in Kumo. On touch, where there is no hover, a copy button sits inside the field next to the hide button, each with a 44px-wide hit area.
- Tap the mask to reveal and focus; the keyboard opens only when the field is editable.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `value` / `defaultValue` | `value` / `controller` |
| `onValueChange`, `onChange` | `onValueChange` |
| `onCopy` | `onCopy` |
| `size` | `size` |
| `variant="error"` (deprecated) | `error` |
| `label`, `labelTooltip`, `description`, `error` | same names |
| `required={false}` | `showOptional: true` |
| `disabled`, `readOnly` | same names |
| `autoComplete="off"` | always off |
| "Click to reveal" | `revealText` |
