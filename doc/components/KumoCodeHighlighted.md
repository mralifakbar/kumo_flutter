# KumoCodeHighlighted

Kumo's `CodeHighlighted`: a syntax-colored code block with optional line numbers, highlighted lines and a copy button.

Kumo reference: https://kumo-ui.com/components/code-highlighted

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoCodeHighlighted(code: 'npx wrangler deploy', lang: 'sh', showCopyButton: true)
```

## When to use / when not to

Use it for snippets people read or copy: a Worker's handler, a `wrangler.toml`, a shell command. For a short inline value use `KumoInlineCopyText`; for a value in an input-like field use `KumoClipboardText`; for code without colors use `KumoCode`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `code` | `String` | required | Source text |
| `lang` | `String` | required | Language or alias, see below. Unknown languages render plain |
| `variant` | `KumoCodeVariant` | `standard` | `standard`: `bg-kumo-base`, 1px `kumo-fill` border, `rounded-md`, 16px padding. `plain`: no frame |
| `showLineNumbers` | `bool` | `false` | Never shown for single-line code |
| `highlightLines` | `List<int>` | `[]` | 1-based lines to tint |
| `showCopyButton` | `bool` | `false` | |
| `copyLabel` | `String?` | `KumoStrings.copy` | |
| `copiedLabel` | `String?` | `KumoStrings.copied` | Shown and announced after copying |
| `wrap` | `bool` | `false` | Wrap long lines instead of scrolling sideways |
| `maxHeight` | `double?` | | Scroll vertically past this height |
| `colors` | `KumoCodeColors?` | `KumoCodeColors.of(theme)` | Token palette |
| `onCopy` | `VoidCallback?` | | After a successful copy |

Languages (aliases in brackets): `javascript` [js, mjs, cjs], `jsx`, `typescript` [ts, mts, cts], `tsx`, `json`, `jsonc` [json5], `bash` [sh, shell, zsh, console], `toml`, `yaml` [yml], `html` [xml, svg], `css` [scss], `dart`, `python` [py], `sql`, `diff` [patch], `hcl` [tf, terraform].

## Examples

### Line numbers and highlighted lines

```dart
const KumoCodeHighlighted(
  code: 'export default {\n  async fetch(request) {\n    return new Response("Hello");\n  },\n};',
  lang: 'ts',
  showLineNumbers: true,
  highlightLines: [3],
  showCopyButton: true,
)
```

### Wrapping long commands

```dart
const KumoCodeHighlighted(
  code: 'curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/purge_cache" --data \'{"purge_everything":true}\'',
  lang: 'bash',
  wrap: true,
)
```

### Tokens directly

The tokenizer is public, for custom renderers or tests.

```dart
final tokens = KumoCodeHighlighter.tokenize('name = "image-resizer"', 'toml');
final keyColor = KumoCodeColors.of(context.kumo).of(KumoCodeTokenType.property);
```

## Accessibility

- Line numbers are hidden from screen readers (Kumo's `aria-hidden`).
- The copy button is a regular `KumoButton`: Tab reaches it even while it is visually hidden, and focusing it reveals it. After copying, "Copied" is announced; a failed write shows and announces `KumoStrings.copyFailed`.
- Every token color keeps at least 4.5:1 contrast on `bg-kumo-base` in light and dark (tested).
- Wrap a page in Flutter's `SelectionArea` to let readers select code.

## Motion

The copy button fades in on hover (150ms, instant under reduced motion). The label swaps to "Copied" with a small spring bump on every copy, and returns after 2 seconds.

## Mobile

Long lines scroll sideways inside the block, with a fade on the edge that hides content and a thin scrollbar while scrolling; line numbers stay put. On touch screens, which have no hover, the copy button is always visible.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `code` | `code` |
| `lang` | `lang` |
| `showLineNumbers` | `showLineNumbers` |
| `highlightLines` | `highlightLines` |
| `showCopyButton` | `showCopyButton` |
| `labels.copy` / `labels.copied` | `copyLabel` / `copiedLabel` |
| `variant="plain"` | `variant: KumoCodeVariant.plain` |
| `ShikiProvider` | not needed: highlighting is built in, with no dependencies |
| Shiki themes `github-light` / `vesper` | `KumoCodeColors`, derived from Kumo text tokens |
