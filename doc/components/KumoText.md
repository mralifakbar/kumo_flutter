# KumoText

Kumo's `Text`: every string in a Kumo UI, with Kumo's variants and sizes.

Kumo reference: https://kumo-ui.com/components/text

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoText('Deployed 3 minutes ago', variant: KumoTextVariant.secondary, size: KumoTextSize.sm)
```

## When to use / when not to

Use it for all visible text so size, color and weight stay on the Kumo scale. Content text is 14px (`base`); 16px and up is for headings.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `String` | required, positional | |
| `variant` | `KumoTextVariant` | `body` | `heading`, `body`, `secondary`, `success`, `error`, `mono`, `monoSecondary` |
| `size` | `KumoTextSize` | `base` | `xs` 12, `sm` 13, `base` 14, `lg` 16. Headings: `lg` is 20px. Mono: `lg` is 14px, otherwise 13px |
| `bold` | `bool` | `false` | Medium weight (500). Ignored by headings and mono |
| `truncate` | `bool` | `false` | One line with an ellipsis |
| `maxLines` | `int?` | | |
| `textAlign` | `TextAlign?` | | |
| `color` | `KumoColor?` | | Overrides the variant color |
| `dangerouslySetColor` | `Color?` | | Raw color escape hatch |
| `headingLevel` | `int?` | | Marks the text as a heading (1 to 6) for screen readers |
| `tabularNumbers` | `bool` | `false` | Fixed-width digits |
| `semanticsLabel` | `String?` | | |

`KumoText.styleOf(context, variant:, size:, bold:)` returns the resolved `TextStyle`.

## Examples

### Page title and section heading

```dart
const Column(children: [
  KumoText('Workers', variant: KumoTextVariant.heading, size: KumoTextSize.lg, headingLevel: 1),
  KumoText('Recent deployments', variant: KumoTextVariant.heading, headingLevel: 2),
])
```

### Inline code

```dart
const KumoText('wrangler.toml', variant: KumoTextVariant.mono)
```

## Accessibility

Text scales with the platform setting. `headingLevel` adds heading semantics. Use `selectable` regions by wrapping a subtree in Flutter's `SelectionArea`.

## Motion

None.

## Mobile

Use `truncate` or `maxLines` for resource names in narrow rows; never place text in a fixed-height box.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` | `text` |
| `variant="mono-secondary"` | `variant: KumoTextVariant.monoSecondary` |
| `as="h2"` | `headingLevel: 2` |
| `size`, `bold`, `truncate` | same names |
| `DANGEROUS_className` | `color` / `dangerouslySetColor` |
