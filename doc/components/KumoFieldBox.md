# KumoFieldBox

The chrome of every Kumo text field, and `KumoEditable`, the bare text-editing core that goes inside it. Use them to build custom fields that match `KumoInput`.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
class HostField extends StatefulWidget {
  const HostField({super.key});

  @override
  State<HostField> createState() => _HostFieldState();
}

class _HostFieldState extends State<HostField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KumoFieldBox(
      focused: _focus.hasFocus,
      leading: const KumoIcon(KumoIcons.globe),
      child: KumoEditable(focusNode: _focus, placeholder: 'example.com'),
    );
  }
}
```

## When to use / when not to

Use `KumoInput` and the other finished fields first. Use these for a field they do not cover.

## Parameters (`KumoFieldBox`)

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | Usually a `KumoEditable` |
| `size` | `KumoFieldSize` | `base` | `xs` 20, `sm` 26, `base` 36, `lg` 40, matching button sizes |
| `focused` | `bool` | `false` | 1.5px focus ring |
| `error` | `bool` | `false` | Danger ring |
| `disabled`, `readOnly` | `bool` | `false` | Recessed fill |
| `leading`, `trailing` | `Widget?` | | Inside the box |
| `multiline` | `bool` | `false` | Top-aligned content |
| `minHeight`, `padding`, `borderRadius` | | | |

## Parameters (`KumoEditable`)

`controller`, `focusNode`, `placeholder`, `size` (`KumoTextSize`), `mono`, `enabled`, `readOnly`, `obscureText`, `autofocus`, `autocorrect`, `enableSuggestions`, `keyboardType`, `textInputAction`, `textCapitalization`, `inputFormatters`, `maxLength`, `minLines`, `maxLines` (1), `textAlign`, `autofillHints`, `onChanged`, `onSubmitted`, `onTap`, `onTapOutside`, `onEditingComplete`, `semanticLabel`, `color`, `scrollPadding`.

## Accessibility

Wrap the field in `KumoField` for a label, description and error, so screen readers announce them together.

## Motion

None; the focus ring appears instantly.

## Mobile

`KumoEditable` scrolls itself above the on-screen keyboard (`scrollPadding`).
