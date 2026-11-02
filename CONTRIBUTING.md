# Contributing to kumo_flutter

This file is the contract every component follows. Read it fully before adding or changing a component. It applies to human contributors and to coding agents alike.

## What this package is

`kumo_flutter` is an unofficial Flutter port of [Kumo](https://kumo-ui.com), Cloudflare's design system. The reference implementation is the React library in [github.com/cloudflare/kumo](https://github.com/cloudflare/kumo) (`packages/kumo/src/components`), MIT licensed. When in doubt about a value, a prop or a behavior, read the React source and match it. Docs pages and live demos live in `packages/kumo-docs-astro/src/pages/components/*.mdx` and `packages/kumo-docs-astro/src/components/demos/`.

Licensing rules that are not negotiable:

- Never ship the Cloudflare logo, wordmark or any Cloudflare brand mark. `CloudflareLogo` is intentionally not ported. The text token `textBrand` (Cloudflare orange) exists for parity but is not used by any component.
- Kumo is MIT: keep the copyright notice in `NOTICE` and `LICENSE`. Phosphor Icons (MIT), Inter and JetBrains Mono (SIL OFL 1.1) keep their license files in `assets/licenses/`.
- Never describe the package as official or endorsed by Cloudflare.

## Layout

```
lib/
  kumo_flutter.dart             public barrel (maintainers edit this)
  kumo_icon_catalog.dart        separate library: searchable icon list (turns off icon tree shaking)
  src/
    theme/                      tokens (generated colors), typography, motion, provider, Material bridge
    icons/ system/ typography/ buttons/ feedback/ layout/ overlays/    foundation
    <category>/                 one folder per component category
      <category>.dart           category barrel: exports every public file in the folder
      kumo_<component>.dart     one public component (plus its parts) per file
test/
  helpers/harness.dart          pumpKumo(), kumoHarness(), goldenPair(), kumoPhoneSize, kumoDesktopSize
  <category>/kumo_<component>_test.dart
doc/components/<ComponentName>.md   one reference page per component (template below)
example/lib/gallery/categories/<category>.dart   demos for the example app
```

## Foundation you build on

Read these files before writing a component; do not re-implement what they do.

| Need | Use |
| --- | --- |
| Theme | `context.kumo` (`KumoThemeData`): `.colors.<token>`, `.color(KumoColor)`, `.text(size:, weight:, color:)`, `.heading(size:)`, `.code(large:)`, `.minTapTarget`, `.isDark` |
| Tokens | `KumoSpace.s3` (Tailwind 4px steps), `KumoRadius.lg`, `KumoShadow.lg.boxShadows`, `KumoRing.border(color)` (CSS `ring`: outside stroke, no layout), `KumoRing.inset(color)` |
| Responsive | `context.kumoIsNarrow` (below 768px), `context.kumoWindowSize`, `KumoBreakpoints` |
| Motion | `KumoMotion.springTo/project/rubberband/duration/reduceMotion`, `KumoSprings.standard/press/momentum/popup/sheet`, `KumoCurves`, `KumoDurations` |
| Tappable surface | `KumoPressable(builder: (context, state) => ...)`: press scale spring, instant hover, focus ring, Enter/Space, 44px touch target, semantics |
| Focus | `KumoFocusRing` (for widgets not built on KumoPressable), `KumoFocusTrap` |
| Text editing | `KumoEditable`: bare Kumo-styled TextField core. Every field draws its own chrome around it |
| Anchored popups | `KumoAnchoredOverlay` (placement, flip, shift, follow anchor, scale-from-anchor open/close, outside tap, Escape, optional focus trap) + `KumoPopupSurface` (base surface, outline, shadow, optional arrow) |
| Sheets and dialogs | `showKumoSheet`, `KumoSheet`, `KumoSheetScope.closeFrom`, `KumoSheetHandle`, `KumoDialogRoute`, `KumoScrim` |
| Content | `KumoText`, `KumoIcon` + `KumoIcons` (Phosphor regular and `...Fill`), `KumoLoader`, `KumoButton`, `KumoRefreshButton`, `KumoTooltip`, `KumoLayerCard` |
| Color math | `KumoColorUtils.mix` (CSS `color-mix in oklch`), `.contrastRatio` |

## API conventions

1. **Prefix every public widget with `Kumo`** (`KumoButton`, `KumoInput`). It avoids clashes with Material and Cupertino.
2. **Mirror Kumo prop names**, translated to Dart style: `variant`, `size`, `shape`, `disabled`, `loading`, `label`, `description`, `error`, `placeholder`, `value`/`onValueChange` (Base UI) or `checked`/`onCheckedChange`, `open`/`onOpenChange`, `side`, `align`, `title`. Where Kumo takes a click handler, Flutter takes `onPress`. Text content is a `String`; arbitrary content goes in a `Widget` slot.
3. **Enums for closed sets**, named like Kumo's string unions in camelCase (`KumoButtonVariant.secondaryDestructive` for `"secondary-destructive"`). Sizes use Kumo's names: `xs`, `sm`, `base`, `lg`.
4. **Colors are tokens.** Color props take `KumoColor`. A raw `Color` escape hatch is named `dangerouslySet<Prop>` (Kumo uses `DANGEROUS_className`).
5. **Spacing, radius and shadow come from tokens.** Never hardcode a pixel value that exists as a token. Values that only exist in one component (a 26px button height) live in that component's enum, documented with the Tailwind class they come from.
6. **Read the theme through `context.kumo`.** Never use Material `Theme.of` inside a component.
7. **Controlled by default.** Stateful inputs take `value` + `onValueChange` (or `checked` + `onCheckedChange`, `open` + `onOpenChange`) and do not hold their own copy of the value. Internal state is only for transient UI (pressed, focused, open, drag offset). Where Kumo also supports uncontrolled use (`defaultValue`), offer `initialValue` only if it simplifies common use.
8. **`const` constructors** wherever possible. Required params first, positional only for the obvious primary value (`KumoText('Hi')`, `KumoIcon(KumoIcons.gear)`).
9. **Composition like Kumo's compound components.** `Dialog.Title` becomes `KumoDialogTitle`, `LayerCard.Primary` becomes `KumoLayerCardPrimary`. Give every slot a sensible default.
10. **No new dependencies.** The package depends only on Flutter and `clock` (use `clock.now()`, never `DateTime.now()`, in component logic). Charts and diagrams use `CustomPainter`. Material widgets may be used internally only where Flutter offers no widgets-layer equivalent (text editing, via `KumoEditable`).

## Kumo's visual rules (from the Kumo design skill)

- Content text is 14px (`KumoTextSize.base`). 16px and up is for headings only.
- Headings are sentence case and semibold (w600). Emphasis is medium (w500). Never bold (w700). Never change letter spacing.
- Related text sits closer together than the content around it.
- Vertical padding around text is slightly smaller than horizontal (`px-5 py-4`).
- Hover colors change instantly. Never animate a hover color.
- Never combine a border with a drop shadow; use a ring (`KumoRing.border`) with the shadow.
- Never put a shadow under a transparent or translucent fill. CSS paints `box-shadow` only outside the box; Flutter paints it under the whole box, so it shows through as a grey wash.
- Nested rounded shapes are concentric: outer radius = inner radius + padding (`KumoRadius.concentric`).
- Inline icons are optically the size of the text and align with its first line.
- Inline monospace is about 0.9em of the text around it.
- Sticky elements are separated from content with a border.
- Collapsing content keeps its size while it animates (clip it, do not reflow it).
- Never stack a `KumoLayerCard` inside another.
- Never conditionally render a dialog: keep it mounted and drive `open`, so it can animate out.

## Interaction and motion

Motion answers touch. Feedback on press, springs that start from where things are, sheets that follow the finger. Nothing loops forever.

- **Build every tappable surface on `KumoPressable`.** Do not use `GestureDetector`/`InkWell` directly for buttons, rows, chips, tabs or menu items.
- **Feedback starts on pointer-down**, never only on release.
- **Springs, not fixed curves, for anything a finger touches.** Use `AnimationController.unbounded` + `KumoMotion.springTo(controller, target, spring: ..., velocity: ...)`. A spring starts from the controller's current value, so an animation can be grabbed and reversed mid-flight without a jump.
- **Drag follows the finger 1:1**, respecting the grab offset. On release, hand the finger's velocity to the spring, use `KumoMotion.project(velocity)` to choose the snap target, and `KumoMotion.rubberband` past bounds. Decide dismiss vs. return from velocity direction, not only position.
- **Fixed-duration transitions** (fades, expand/collapse, indicator slides that are not dragged) use `KumoDurations` + `KumoCurves`, through `KumoMotion.duration(context, d)` so reduced motion collapses them.
- **Enter and exit on the same path**, anchored to the trigger. Popups use `KumoAnchoredOverlay`, which already does this.
- **Nothing loops forever.** A repeating animation exists only while a real state is true (loading), stops off screen (`TickerMode`), and is replaced by a static state under reduced motion. Kumo's web skeleton shimmer runs forever; here `KumoSkeletonLine` is static unless `animate: true` is passed while loading.
- **Never give `AnimatedSize` a zero duration.** Under reduced motion, skip the `AnimatedSize` wrapper instead of passing `KumoMotion.duration(...)`: a zero-duration `RenderAnimatedSize` asserts when its child changes size.
- **Create AnimationControllers in `initState`**, never as `late final x = AnimationController(...)` field initializers: a lazy controller that is first touched in `dispose()` is created there and asserts.
- **Reduced motion** (`KumoMotion.reduceMotion(context)`): replace slides, scales and springs with an instant change or a short cross-fade.
- **Haptics on the causal event** (commit, snap, selection change) through `kumoHaptic`, and only for touch-first controls (switch, slider, segmented tabs, sheets). Never on every frame.

## Mobile and desktop

Kumo is built for wide dashboards. A Flutter port runs on phones too, so every component has to hold up at 390px wide and with 2x text.

- Keep Kumo's dense visuals; let `KumoPressable` pad hit areas to 44x44 on touch platforms (`KumoTapTargetSize.padded`).
- Below `md` (`context.kumoIsNarrow`), components with floating panels switch to their touch layouts where it helps: menus, selects and pickers open in `showKumoSheet` instead of an anchored popup; dialogs take the full width minus 16px gutters; the sidebar becomes a drawer. Document the switch and allow overriding it (`presentation: KumoPresentation.auto | popover | sheet` where it applies).
- Never put text in a fixed-height box that clips it at 2x text; use minimum heights.
- No horizontal overflow at 390px. Rows that cannot fit wrap or scroll with a visible affordance.

## Accessibility

- Every interactive element exposes `Semantics`: role (`button`, `toggled`, `checked`, `selected`, `slider`, `textField`, `link`, `header`), a label and state. Icon-only controls require a `semanticLabel`.
- Keyboard: Tab order follows visual order, Enter/Space activate, Escape closes overlays, arrow keys move within groups (radio group, tabs, menus, listboxes, calendars), focus is trapped in modal overlays and restored on close.
- Text scales with the platform setting.
- Contrast comes from tokens. Check new pairings with `KumoColorUtils.contrastRatio` (4.5 for text, 3 for UI boundaries).
- Status is never color alone: pair color with an icon or text.
- Toasts and inline errors announce (`liveRegion` / `SemanticsService.sendAnnouncement`).
- RTL: use `EdgeInsetsDirectional`, `AlignmentDirectional`, start/end.

## States

Any component that shows data supports empty, loading and error states, or documents how the caller provides them. Empty and error copy names the cause and the next action.

## Writing: docs, comments, demo copy

- Dartdoc on every public class and every constructor parameter that is not self-explanatory, with one short usage example. Comments explain why, never restate the code. No banner comments, no step narration, no emoji.
- No em dash character in any text. No buzzwords (seamless, powerful, effortless, next-generation). Specific CTAs ("Deploy Worker", "Purge cache"), never "Get started" or "Learn more".
- Demo data is sample data and is labeled as such in the example app. Never present invented numbers, names or customers as real. Use Cloudflare-flavored but generic sample resources (a Worker named `image-resizer`, a zone `example.com`, an R2 bucket `assets`).

## Tests

Every component ships widget tests in `test/<category>/kumo_<component>_test.dart` using `pumpKumo` from `test/helpers/harness.dart`. Cover, as applicable:

1. Renders in light and dark without exceptions.
2. Callbacks fire on tap, and do not fire when disabled or loading.
3. Controlled value: interaction calls the change callback with the next value; the widget reflects the value it is given.
4. Semantics: role, label and state flags (`tester.getSemantics(...)` + `matchesSemantics`, or `find.bySemanticsLabel`).
5. Keyboard: Tab focus, Enter/Space activation, arrow keys in groups, Escape closes overlays.
6. Gestures: drags and flings, verifying snap targets and velocity-driven dismissal.
7. Reduced motion: `pumpKumo(..., disableAnimations: true)`, no running animations after settling where relevant.
8. Text scale 2.0 and 390px width: no overflow exceptions.
9. Narrow vs. wide: components that switch presentation are tested at `kumoPhoneSize` and `kumoDesktopSize`.
10. One golden per category is welcome: tag it `@Tags(['golden'])`, render with `goldenPair`, store under `test/goldens/`.

Run before finishing: `flutter analyze` (zero issues) and `flutter test test/<category>`.

## Component doc template (`doc/components/<ComponentName>.md`)

```markdown
# KumoComponentName

One sentence: what it is and when to reach for it.

Kumo reference: https://kumo-ui.com/components/<name>

## Import

(fenced dart block) import 'package:kumo_flutter/kumo_flutter.dart';

## Usage

(fenced dart block) smallest useful example

## When to use / when not to

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |

## Examples
### <Variant or scenario>

## Accessibility
## Motion
## Mobile
## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
```

Code goes in fenced blocks tagged `dart`, compilable and minimal (`tool/check_doc_snippets.py` compiles them). Agents read these pages to build apps, so be exact about types and defaults.
