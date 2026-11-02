# KumoInlineCopyText

Kumo's `InlineCopyText`: a compact, borderless copy control for IDs and other short values in text and dense table cells.

Kumo reference: https://kumo-ui.com/components/inline-copy-text

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoInlineCopyText(
  'f86b3f10-32e9-4db7-ae95-84a1b2c3d4e5',
  copyLabel: 'Copy database ID',
  copiedLabel: 'Database ID copied',
)
```

## When to use / when not to

Use it for short identifiers people copy now and then: database IDs, version hashes, ray IDs. Use `KumoClipboardText` when copying is the main task and the value deserves an always-visible button.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` (positional) | `String` | required | Shown and copied |
| `child` (`.rich`) | `Widget` | required | Any content |
| `value` | `String?` | `text`; required with `.rich` | The value to copy |
| `variant` | `KumoTextVariant` | `monoSecondary` (`.rich`: `body`) | Any variant but `heading` |
| `size` | `KumoTextSize` | `base` | Mono variants only take `lg` (14px) |
| `bold` | `bool` | `false` | Ignored by mono variants |
| `truncate` | `bool` | `true` | One line with an ellipsis |
| `alwaysShowIcon` | `bool` | `false` | Show the copy icon at rest |
| `copyLabel` | `String?` | `KumoStrings.copy` | Accessible name |
| `copiedLabel` | `String?` | `KumoStrings.copied` | Name and announcement after copying |
| `onCopy` | `VoidCallback?` | | After a successful copy |

## Examples

### Rich content

```dart
KumoInlineCopyText.rich(
  value: 'f86b3f10-32e9-4db7-ae95-84a1b2c3d4e5',
  copyLabel: 'Copy database ID',
  child: const Text('Database ID: f86b3f10...'),
)
```

### In a table cell

A hovered `KumoTable` or `KumoTree` row reveals the icon, like Kumo's Tailwind `group`.

```dart
KumoTableColumn<String>(
  id: 'id',
  label: 'ID',
  cell: (context, id) => KumoInlineCopyText(id, copyLabel: 'Copy ID'),
)
```

## Accessibility

A button named `copyLabel`, with the text as its value. After a copy its name becomes `copiedLabel`, which is also announced; a failed write shows a warning icon and announces `KumoStrings.copyFailed`. Enter and Space copy.

## Motion

The copy icon fades in on hover and focus (150ms; instant under reduced motion). After a copy it cross-fades into a check that bumps with a small spring, and cross-fades back after 1.5 seconds. `monoSecondary` text brightens to `text-kumo-default` on hover, instantly.

## Mobile

There is no hover on touch screens, so the icon is always visible there. The hit area grows to 44px.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` (string) | positional `text` |
| `children` (node) + `value` | `KumoInlineCopyText.rich(child:, value:)` |
| `variant`, `size`, `bold`, `truncate` | same names |
| `labels.copyAction` / `labels.copied` | `copyLabel` / `copiedLabel` |
| `onCopy` | `onCopy` |
| parent Tailwind `group` | `KumoTable` and `KumoTree` rows; elsewhere `alwaysShowIcon` |
