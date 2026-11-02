# KumoBadge

Kumo's `Badge`: a small label for status, categories or metadata, such as "Active", "Beta" or "Proxied".

Kumo reference: https://kumo-ui.com/components/badge

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoBadge('New', variant: KumoBadgeVariant.secondary)
```

## When to use / when not to

Use a badge to label a row, a heading or a card with a short status or category. Keep the label to one or two words in sentence case: the label carries the meaning, the color only reinforces it.

Reach for the semantic variants (`primary`, `secondary`, `error`, `warning`, `success`, `info`, `outline`, `beta`) first. The color variants (`red`, `green`, `neutral`, `orange`, `purple`, `teal`, `blue`) are for product categories where a semantic color would say the wrong thing.

Do not use a badge as a button bar or a filter control; use buttons or tabs. A badge with `onPress` is for a single navigation target (a changelog link).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` (positional) | required | Badge text. One line, ellipsized if the parent is too narrow |
| `variant` | `KumoBadgeVariant` | `primary` | Color variant, see the table below |
| `appearance` | `KumoBadgeAppearance` | `filled` | `dot` draws a transparent badge with a hairline ring and a 7px status dot |
| `size` | `KumoBadgeSize` | `base` | `base` is Kumo's 20px badge (12px text). `lg` (13px text, about 23px) is a port addition for page headers |
| `icon` | `IconData?` | | Leading 12px icon. Filled appearance only |
| `iconWidget` | `Widget?` | | Leading widget in place of `icon` |
| `onPress` | `VoidCallback?` | | Makes the badge pressable; hover draws a 1px ring in the text color |
| `isLink` | `bool` | `false` | Announce as a link instead of a button when pressable |
| `semanticLabel` | `String?` | | Replaces the label for screen readers |

### Variants

| Variant | Background | Text |
| --- | --- | --- |
| `primary` (alias `inverted`) | `badgeInverted` | `textBadgeInverted` |
| `secondary` (alias `neutralSubtle`) | `fill` | `textBadgeNeutralSubtle` |
| `error` | `dangerTint` | `textDanger` |
| `warning` | `warningTint` | `textWarning` |
| `success` | `successTint` | `textSuccess` |
| `info` | `infoTint` | `textInfo` |
| `beta` | transparent, 1px dashed `brand` border | `textLink` |
| `outline` | `base`, 1px `fill` border | `textDefault` |
| `red`, `green`, `neutral`, `purple`, `teal`, `blue` | `badge<Color>` | white |
| `orange` | `badgeOrange` | black |
| `tealSubtle` | `badgeTeal` at 12% (24% dark) | `textBadgeTealSubtle` |
| `orangeSubtle` | `badgeOrange` at 16% (20% dark) | `textBadgeOrangeSubtle` |
| `destructive` | deprecated, same as `red` | |

`KumoBadgeColors.resolve(theme, variant)` returns the exact pair a badge draws, for custom chips or tests.

## Examples

### Status with a dot

The dot only appears for `success`, `warning`, `error` and `neutral`, as in Kumo.

```dart
const Wrap(spacing: 8, children: [
  KumoBadge('Healthy', variant: KumoBadgeVariant.success, appearance: KumoBadgeAppearance.dot),
  KumoBadge('Rate limited', variant: KumoBadgeVariant.warning, appearance: KumoBadgeAppearance.dot),
  KumoBadge('Down', variant: KumoBadgeVariant.error, appearance: KumoBadgeAppearance.dot),
])
```

### With an icon

```dart
const KumoBadge('Verified', variant: KumoBadgeVariant.success, icon: KumoIcons.checkCircle)
```

### In a sentence

```dart
const Row(children: [
  KumoText('Workers'),
  SizedBox(width: 8),
  KumoBadge('New', variant: KumoBadgeVariant.secondary),
])
```

### Linked badge

```dart
KumoBadge(
  'View changelog',
  variant: KumoBadgeVariant.outline,
  isLink: true,
  onPress: () => openChangelog(),
)
```

## Accessibility

A static badge is plain text and is read as its label. The dot is decorative; the label names the state. A pressable badge is a button (or a link with `isLink`) with Kumo's focus ring, Enter and Space activation, and a 44x44 touch target on touch platforms.

Contrast, measured with `KumoColorUtils.contrastRatio` over the base, canvas, elevated and control surfaces (translucent tints composited first): every pair meets 4.5:1 in dark mode. In light mode two Kumo pairs fall short at 12px and are kept for parity with Kumo:

| Variant | Light ratio | Note |
| --- | --- | --- |
| `warning` | about 3.8 to 4.0 | `textWarning` on `warningTint` |
| `green` | about 3.65 | white on `badgeGreen` (Tailwind green 600) |

Both pass 3:1. Where the badge is the only place a state appears, prefer `success` over `green`, or pair `warning` with an icon or the dot appearance.

## Motion

A change of label, variant or appearance (Deploying to Active) cross-fades the pill (100ms) and eases its width (200ms), so the row around it slides instead of jumping. The old label leaves the semantics tree at once. The hover ring of a pressable badge switches instantly, like every Kumo hover. Reduced motion swaps at once.

## Mobile

Badges are text-sized and never wrap; a label longer than its parent is ellipsized. At 2x text the badge grows taller instead of clipping.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` | `label` |
| `variant="teal-subtle"` | `variant: KumoBadgeVariant.tealSubtle` |
| `appearance="dot"` | `appearance: KumoBadgeAppearance.dot` |
| `icon={CheckCircleIcon}` | `icon: KumoIcons.checkCircle` |
| `icon={<Custom />}` | `iconWidget:` |
| wrapping in `<Link>` | `onPress:` + `isLink: true` |
| `className` | not ported |

Deviation: Kumo's `teal-subtle` uses `bg-kumo-badge-teal-subtle`, which Kumo's theme never defines, so the web badge renders with no fill. The port fills it with a light tint of the teal badge color.
