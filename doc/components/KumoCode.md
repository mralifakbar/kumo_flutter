# KumoCode

Kumo's `Code` and `Code.Block`: monospace code without syntax colors, in `text-kumo-subtle` at 13px on 20px lines.

Kumo reference: https://kumo-ui.com/components/code-highlighted

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoCode(code: 'npx wrangler deploy')
```

## When to use / when not to

Use `KumoCode` for short commands and output where color adds nothing, and `KumoCode.block` to set them off in a bordered block. Kumo deprecates `Code` in favor of `CodeHighlighted`; prefer `KumoCodeHighlighted` for source code.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `code` | `String` | required | |
| `lang` | `String?` | | Hint only; `KumoCode` never colors |
| `values` | `Map<String, KumoCodeValue>?` | | Fills `{{key}}` placeholders; the copy button copies the filled text |
| `variant` | `KumoCodeVariant` | `plain` (`KumoCode`), `standard` (`KumoCode.block`) | Block: `bg-kumo-base`, `kumo-fill` border, `rounded-md`, 10px padding |
| `showLineNumbers` | `bool` | `false` | Never shown for single-line code |
| `highlightLines` | `List<int>` | `[]` | 1-based lines to tint |
| `showCopyButton` | `bool` | `false` | |
| `wrap` | `bool` | `false` | Wrap long lines instead of scrolling sideways |
| `maxHeight` | `double?` | | Scroll vertically past this height |
| `onCopy` | `VoidCallback?` | | After a successful copy |

`KumoCodeValue(value, highlight: false)`: a highlighted value is set in medium weight `text-kumo-strong` so the part to replace stands out.

## Examples

### Block with a copy button

```dart
const KumoCode.block(code: 'npm create cloudflare@latest -- image-resizer', showCopyButton: true)
```

### Template values

```dart
const KumoCode.block(
  code: 'export CLOUDFLARE_API_TOKEN={{token}}',
  values: {'token': KumoCodeValue('your-api-token', highlight: true)},
  showCopyButton: true,
)
```

## Accessibility

Same as `KumoCodeHighlighted`: line numbers are hidden from screen readers, the copy button is reachable with Tab and announces "Copied" or the failure copy.

## Motion

The copy button fades in on hover and bumps on each copy; its label cross-fades from "Copy" to "Copied" and back while the button eases to its new width. Reduced motion turns all of it off.

## Mobile

Long lines scroll sideways with an edge fade, or wrap with `wrap: true`. The copy button is always visible on touch screens.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Code code lang>` | `KumoCode(code:, lang:)` |
| `<Code.Block>` / `<CodeBlock>` | `KumoCode.block(...)` |
| `values` (`{ value, highlight }`) | `values` (`KumoCodeValue`) |
