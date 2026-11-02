# KumoEmpty

Kumo's `Empty`: what a list, table or page shows when it has nothing to show, with an optional copyable command and actions.

Kumo reference: https://kumo-ui.com/components/empty

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoEmpty(
  icon: KumoIcons.database,
  title: 'No D1 databases yet',
  description: 'Databases you create in this account appear here.',
)
```

## When to use / when not to

Use it in place of an empty list, table or page, and for a data view that failed to load. Every data view needs an empty, a loading and an error state; this covers empty and error, `KumoSkeletonLine` covers loading.

Write the copy for the person looking at it:

- The `title` names what is missing or why: "No results for \"api\"", "No connection to the API".
- The `description` says the next step: "Clear the filter to see all 24 records."
- The action in `contents` has a specific label: "Create database", "Retry". Never "Get started".

Do not use it for a single empty field; show a placeholder or a dash instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String` | required | With a `description`: a 20px semibold heading. Alone: 14px subtle text. Both are level-2 headings for screen readers |
| `description` | `String?` | | Secondary text, centered, at most 560px wide |
| `icon` | `IconData?` | | Decorative icon, 32, 48 or 64px by size |
| `iconWidget` | `Widget?` | | Custom content in place of `icon` |
| `iconColor` | `KumoColor` | `textInactive` | Color of `icon`, as in Kumo's demos |
| `commandLine` | `String?` | | Shell command with a `$` prompt and a copy button |
| `copyLabel` | `String?` | `KumoStrings.copyToClipboard` | Accessible name of the command's copy button |
| `contents` | `Widget?` | | Actions under the description |
| `size` | `KumoEmptySize` | `base` | `sm` (px-6 py-8 gap-4), `base` (px-10 py-16 gap-6), `lg` (px-12 py-20 gap-8) |

## Examples

### With actions

```dart
KumoEmpty(
  icon: KumoIcons.cloudSlash,
  title: 'Could not load buckets',
  description: 'The request to the R2 API timed out. Check your connection, then retry.',
  contents: Wrap(spacing: 8, runSpacing: 8, children: [
    KumoButton(label: 'Retry', variant: KumoButtonVariant.primary, onPress: () => reload()),
    KumoButton(label: 'View status page', onPress: () => openStatus()),
  ]),
)
```

### With a command line

```dart
const KumoEmpty(
  icon: KumoIcons.folderOpen,
  title: 'No Workers in this account',
  description: 'Create a Worker from the command line, then deploy it with wrangler.',
  commandLine: 'npm create cloudflare@latest',
)
```

### Minimal

```dart
const KumoEmpty(title: 'No API tokens match "deploy"', size: KumoEmptySize.sm)
```

## Accessibility

The title is a level-2 heading. The icon and the `$` prompt are hidden from screen readers. The copy button is labelled `copyLabel` (default `KumoStrings.copyToClipboard`, "Copy to clipboard"); after a copy it announces `KumoStrings.copied` (or `copyFailed`).

## Motion

After a copy the copy icon cross-fades into a green check that bounces in (Kumo's `animate-bounce-in`: scale 0.6 to 1.2 to 1 over 400ms); after one second the copy icon fades back. Under reduced motion the icons swap at once and the check appears without the bounce.

## Mobile

The container fills the width. A long command scrolls horizontally inside its box, which is at most 80% of the content width, and the edge with hidden text fades out so the scroll is visible; the box grows taller at 2x text. Put two actions in a `Wrap` so they stack on a phone.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `icon={<PackageIcon size={48} />}` | `icon: KumoIcons.package` (sized by `size`) or `iconWidget:` |
| `title`, `description` | `title`, `description` |
| `commandLine` | `commandLine` |
| `contents` | `contents` |
| `size` | `size` |
| `className` | not ported |

Deviation: Kumo draws a white 1px inner border inside the command box's ring in both modes. In dark mode the port keeps only the ring, since a white edge on the dark overlay reads as a bright outline.
