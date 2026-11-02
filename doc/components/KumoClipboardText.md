# KumoClipboardText

Kumo's `ClipboardText`: a read-only, input-like field holding a value with a copy button at its end.

Kumo reference: https://kumo-ui.com/components/clipboard-text

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoClipboardText(text: '023e105f4ecef8ad9ca31a8372d0c353')
```

## When to use / when not to

Use it for values people copy into another tool: account and zone IDs, API tokens, install commands. For a short ID inside text or a table cell, use `KumoInlineCopyText`. For multi-line code, use `KumoCodeHighlighted` with `showCopyButton`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String` | required | Shown, and copied unless `textToCopy` is set |
| `textToCopy` | `String?` | | Copied in place of `text` |
| `masked` | `bool` | `false` | Shows dots and a reveal button |
| `size` | `KumoClipboardTextSize` | `lg` | `sm` 26px (12px mono), `base` 36px, `lg` 40px (13px mono) |
| `block` | `bool` | `false` | Fill the parent's width |
| `onCopy` | `VoidCallback?` | | After a successful copy |
| `tooltip` | `KumoClipboardTextTooltip?` | | Tooltip mode: `text`, `copiedText`, `side` |
| `copyLabel` | `String?` | `KumoStrings.copy` | Copy button name |
| `revealLabel` | `String?` | `KumoStrings.show` | Reveal button name |
| `hideLabel` | `String?` | `KumoStrings.hide` | Hide button name |

## Examples

### Masked token

```dart
const KumoClipboardText(text: 'cf_sample_7Hq2xK9mZpL4', masked: true, block: true)
```

### Shortened value, full copy

```dart
const KumoClipboardText(text: 'cf_sample_7Hq2...', textToCopy: 'cf_sample_7Hq2xK9mZpL4')
```

### Tooltip mode

```dart
const KumoClipboardText(
  text: 'npx wrangler deploy',
  tooltip: KumoClipboardTextTooltip(text: 'Copy command', copiedText: 'Command copied'),
)
```

## Accessibility

- The copy button is named by `copyLabel`; the reveal button is a toggle (`toggled` state, like `aria-pressed`) named "Show" or "Hide".
- After a copy, the copied text (`tooltip.copiedText` or `KumoStrings.copied`) is announced. If the clipboard write fails, a warning icon replaces the check and `KumoStrings.copyFailed` is announced.

## Motion

On copy the copy icon slides up and out while a check slides in (200ms), then they swap back after 1.5 seconds. Each copy kicks a spring that swells the check (or the tooltip-mode bubble) about 4% and settles, so a repeat press still visibly lands. Revealing or hiding a masked value cross-fades the value and the eye icon and eases the field's width. Reduced motion swaps everything instantly with no bump.

## Mobile

On touch screens the field is at least 44px tall and the buttons at least 44px wide. Long values truncate with an ellipsis; the copy button never moves off screen.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `text` | `text` |
| `textToCopy` | `textToCopy` |
| `masked` | `masked` |
| `size` | `size` |
| `onCopy` | `onCopy` |
| `tooltip` (`text`, `copiedText`, `side`) | `tooltip: KumoClipboardTextTooltip(...)` |
| `labels.copyAction` / `revealAction` / `hideAction` | `copyLabel` / `revealLabel` / `hideLabel` |
| `className="w-full"` | `block: true` |
