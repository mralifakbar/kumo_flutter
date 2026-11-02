# Tokens

## Colors

Kumo defines 54 semantic tokens in OKLCH. `tool/generate_theme.dart` converts them to sRGB with CSS Color 4 gamut mapping (the same result a browser shows on an sRGB screen) into `KumoColorSchemes.light`, `.dark`, `.fedrampLight` and `.fedrampDark`.

| Group | Tokens |
| --- | --- |
| Text | `textDefault`, `textStrong`, `textSubtle`, `textInactive`, `textPlaceholder`, `textInverse`, `textLink`, `textInfo`, `textSuccess`, `textDanger`, `textWarning`, `textBrand` |
| Surfaces | `canvas` (app background), `elevated`, `recessed`, `base` (cards, inputs, popovers), `tint` (hover), `contrast`, `overlay`, `control` (field fill), `fill`, `fillHover` |
| Lines | `line` (rings), `hairline` (dividers), `interact` (control borders), `focus` |
| Accent | `brand` (primary blue), `brandHover` |
| Status | `info`, `success`, `warning`, `danger` and their `...Tint` backgrounds, `bannerInfo`, `bannerWarning` |
| Badges | `badgeRed`, `badgeGreen`, `badgeOrange`, `badgePurple`, `badgeTeal`, `badgeBlue`, `badgeNeutral`, `badgeInverted` and the `textBadge...` tokens |
| Shadows | `shadowEdge`, `shadowDrop`, `arrowEdge`, `arrowStroke` |

Surface hierarchy: `canvas` < `elevated` < `recessed`; components sit on `base`.

```dart
Container(color: context.kumo.colors.base, child: const KumoText('Deleted', color: KumoColor.textDanger))
```

`textBrand` is Cloudflare orange and exists for parity only; no component uses it.

## Spacing

Tailwind's 4px grid, named by Tailwind step: `KumoSpace.s1` 4, `s1_5` 6, `s2` 8, `s3` 12, `s4` 16, `s5` 20, `s6` 24, `s8` 32. Any step: `KumoSpace.step(7)` is 28.

Kumo's spacing rule: related text sits closer together than the content around it, and vertical padding around text is slightly smaller than horizontal (`px-5 py-4`).

## Radius

`KumoRadius.sm` 4, `md` 6, `lg` 8 (buttons, inputs, cards), `xl` 12 (dialogs), `full`. Nested shapes are concentric:

```dart
final inner = KumoRadius.concentric(KumoRadius.xl, 4); // 8
```

## Shadows and rings

Most surfaces are flat with a 1px ring. `KumoRing.border(color)` draws a CSS-style ring outside the box without taking layout space. Floating surfaces add a shadow: `KumoShadow.xs` (resting controls), `.lg` (menus, popovers, toasts), `.xl` (dialogs). Never combine a border with a shadow; use a ring.

```dart
DecoratedBox(
  decoration: BoxDecoration(
    color: context.kumo.colors.base,
    borderRadius: BorderRadius.circular(KumoRadius.lg),
    border: KumoRing.border(context.kumo.colors.line),
    boxShadow: KumoShadow.lg.boxShadows,
  ),
)
```

## Typography

| Use | API | Size |
| --- | --- | --- |
| All content text | `kumo.text()` / `KumoText('...')` | 14px, line height 1.5 |
| Secondary rows | `KumoTextSize.sm` | 13px |
| Captions | `KumoTextSize.xs` | 12px |
| Headings | `KumoTextVariant.heading` | 16px semibold, 20px with `size: lg` |
| Page titles | `kumo.heading(size: KumoHeadingSize.h2)` | 24px |
| Code | `KumoTextVariant.mono` | 13px JetBrains Mono (14px with `size: lg`) |

Weights: 400, 500 (`bold: true`, buttons, labels), 600 (headings). Never 700. Never change letter spacing. Headings are sentence case.

## Breakpoints

`KumoBreakpoints.sm` 640, `md` 768, `lg` 1024, `xl` 1280. `context.kumoIsNarrow` is true below `md`, where floating panels become sheets. `context.kumoWindowSize` gives `compact`, `medium` or `expanded`.

## Icons

`KumoIcons` holds all 1,530 Phosphor icons in regular and fill weights (`KumoIcons.star`, `KumoIcons.starFill`). They are const `IconData`, so release builds tree-shake unused glyphs. `package:kumo_flutter/kumo_icon_catalog.dart` adds a searchable list with tags and categories for icon pickers (importing it turns tree shaking off).
