---
name: kumo-flutter
description: |
  Build and review Flutter UI with kumo_flutter, the unofficial Flutter port of Cloudflare's Kumo design system.
  Use when creating screens, components or visual changes in a Flutter app that depends on kumo_flutter, when choosing
  Kumo components, tokens, icons or motion, or when auditing Flutter code for Kumo adherence.
  Not for non-visual logic (state management, networking, persistence) or for apps that do not use kumo_flutter.
license: MIT
---

# kumo_flutter

## Companion skill

Load `kumo-flutter-craft` together with this one for every UI task. It holds the design, accessibility, motion and copy standard and the delivery checklist that closes each task.

## Before writing code

1. Confirm the app depends on `kumo_flutter` (check `pubspec.yaml`). If not, ask before adding it.
2. Read `references/guides/for-ai-agents.md` and `references/guides/tokens.md` once per session.
3. For every component you plan to use, read its page in `references/components/<Name>.md`. Parameters, defaults and examples there are exact; do not guess names from Kumo React or Material.
4. Tell the user which Kumo components you will use before building.

## Rules

- `import 'package:kumo_flutter/kumo_flutter.dart';` and `KumoThemeProvider` at the root (with `kumoMaterialTheme(context.kumo)` for MaterialApp and `KumoToaster` in `MaterialApp.builder` if you show toasts). Read the theme with `context.kumo`.
- Colors: `KumoColor` tokens (`context.kumo.colors.base`, `KumoColor.textSubtle`) only; never hex values. Spacing: `KumoSpace` (Tailwind 4px steps). Radius: `KumoRadius`. Borders as rings: `KumoRing.border(colors.line)`. Shadows only on floating surfaces: `KumoShadow.lg`.
- Text through `KumoText` (14px content; `heading` 16px, `size: lg` 20px; `secondary` for metadata; `mono` for IDs and hostnames). Sentence case. Never bold (w700).
- Icons: `KumoIcon(KumoIcons.<name>)` (Phosphor regular; `<name>Fill` for active states). Pick by meaning.
- One `primary` `KumoButton` per view; `secondary` by default; `ghost` in toolbars; `destructive` for delete. Icon-only buttons need `semanticLabel` or `title`.
- Controlled inputs: hold `value`/`checked`/`open` in your state and update it in `onValueChange`/`onCheckedChange`/`onOpenChange`.
- Custom tappable surfaces use `KumoPressable`, never raw `GestureDetector`/`InkWell`. Custom floating panels use `KumoAnchoredOverlay` + `KumoPopupSurface`; custom phone panels use `showKumoSheet`.
- Every data view ships loading, empty (`KumoEmpty`) and error states.
- Copy: specific labels ("Deploy Worker"), no em dash, no buzzwords, no invented numbers presented as real.

## Component picker

| Need | Use |
| --- | --- |
| App frame with sidebar, drawer on phones | `KumoAppShell` + `KumoSidebar`; `KumoBottomNavigation` for phone tabs |
| Page title, breadcrumbs, tabs, actions | `KumoPageHeader`, `KumoBreadcrumbs`, `KumoTabs` |
| List of resources with status | `KumoResourceList` + `KumoResourceListItem` |
| Tabular data, sorting, selection | `KumoTable` (`layout: auto` for cards on phones) |
| Container | `KumoLayerCard` (never nested) |
| Action | `KumoButton`, `KumoRefreshButton`, `KumoButtonGroup`, `KumoToolbar` |
| Text field | `KumoInput`, `KumoInputArea`, `KumoInputGroup`, `KumoSensitiveInput` (secrets), `KumoNumberInput`, `KumoInputOtp`, labels via `KumoField` |
| Choice | `KumoSelect`, `KumoCombobox` (searchable), `KumoAutocomplete`, `KumoTagInput`, `KumoRadioGroup`, `KumoCheckbox(Group)`, `KumoSwitch`, `KumoToggleGroup`, `KumoSlider` |
| Dates and time | `KumoDatePicker` (single, range, multiple), `KumoCalendar`, `KumoDateInput`, `KumoTimePicker`, `KumoTimeInput` |
| Menu | `KumoDropdownMenu`, `KumoContextMenu`, `KumoMenubar` |
| Floating info | `KumoTooltip` (labels), `KumoPopover` (content), `KumoHoverCard` (previews) |
| Modal | `showKumoDialog` + `KumoDialog`, `showKumoAlertDialog`, `KumoLayerDialog`, `showKumoDrawer`, `KumoDeleteResource` (type-to-confirm) |
| Feedback | `showKumoToast`, `KumoBanner`, `KumoLoader`, `KumoSkeletonLine`, `KumoProgress`, `KumoMeter`, `KumoEmpty` |
| Status and metadata | `KumoBadge`, `KumoTracker` (uptime), `KumoTimeline`, `KumoAvatar(Group)`, `KumoKbd`, `KumoSeparator` |
| Code and copy | `KumoCode`, `KumoCodeHighlighted`, `KumoClipboardText`, `KumoInlineCopyText` |
| Disclosure and steps | `KumoCollapsible`, `KumoAccordion`, `KumoSteps`, `KumoStepper`, `KumoTree`, `KumoTableOfContents` |
| Navigation helpers | `KumoLink`, `KumoPagination`, `KumoCommandPalette` (`showKumoCommandPalette`, `KumoCommandPaletteShortcut` for Cmd/Ctrl+K) |
| Charts | `KumoTimeseriesChart`, `KumoSparkline`, `KumoSankeyChart`, `KumoMapChart`, `KumoChartLegend`, `KumoChartColors` |
| Pipelines and diagrams | `KumoFlowDiagram` with `KumoFlowNode`, `KumoFlowParallel`, `KumoFlowList` |
| Layout grid | `KumoGrid` |

## If no component fits

1. Compose primitives (`KumoPressable`, `KumoText`, `KumoIcon`, `KumoLayerCard`, `KumoFieldBox` + `KumoEditable`, `KumoMenuPanel` + `KumoMenuRow`) with tokens.
2. Only then fall back to plain Flutter widgets, styled from `context.kumo`.

## Review mode

When asked to audit code for Kumo adherence, check in this order and report findings with file:line:
hardcoded colors, sizes or spacing; Material widgets where a Kumo component exists; content text not 14px or bold
headings; missing semantics or tap targets; missing loading/empty/error states; motion that ignores reduced motion or
loops forever; more than one primary button; nested layer cards.
