# KumoSidebar

App navigation: a header, scrolling groups of rows with icons, badges and nested collapsible sections, and a footer with the collapse button. Collapses to a 57px icon rail.

Kumo reference: https://kumo-ui.com/components/sidebar

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoSidebar(
  header: const KumoSidebarHeader(children: [
    KumoIcon(KumoIcons.cubeFill, color: KumoColor.brand),
    Expanded(child: KumoText('Acme Inc', bold: true, truncate: true)),
  ]),
  footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
  child: KumoSidebarContent(children: [
    KumoSidebarGroup(children: [
      KumoSidebarMenuButton(icon: KumoIcons.house, label: 'Account home', active: true, onPress: () {}),
      KumoSidebarMenuButton(icon: KumoIcons.chartBar, label: 'Analytics and logs', onPress: () {}),
    ]),
    KumoSidebarGroup(label: 'Build', children: [
      KumoSidebarCollapsible(
        icon: KumoIcons.code,
        label: 'Compute',
        initialOpen: true,
        children: [
          KumoSidebarMenuSubButton(label: 'Workers', active: true, onPress: () {}),
          KumoSidebarMenuSubButton(label: 'Containers', badge: 'Beta', onPress: () {}),
        ],
      ),
    ]),
  ]),
)
```

## When to use / when not to

Use it for an app's primary navigation. For a whole app frame that switches between a persistent sidebar, an icon rail and a phone drawer, put it in a `KumoAppShell` instead of laying it out yourself. For a handful of sections inside one page, use tabs.

## Parameters

### KumoSidebar

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | Body between header and footer: `KumoSidebarContent` or `KumoSidebarSlidingViews` |
| `header` | `Widget?` | | Usually `KumoSidebarHeader` |
| `footer` | `Widget?` | | Usually `KumoSidebarFooter` |
| `open` | `bool?` | null | Expanded (true) or collapsed. Null keeps the state inside, starting from `initialOpen` |
| `initialOpen` | `bool` | `true` | Uncontrolled start state |
| `onOpenChange` | `ValueChanged<bool>?` | | Called by the trigger, the resize handle and collapsible rows in the rail |
| `onOpenChangeComplete` | `ValueChanged<bool>?` | | After the width animation settles (immediately under reduced motion) |
| `side` | `KumoSidebarSide` | `start` | `start` or `end`; follows text direction |
| `variant` | `KumoSidebarVariant` | `sidebar` | `sidebar` (end border) or `floating` (8px inset, rounded, ring and shadow) |
| `collapsible` | `KumoSidebarCollapseMode` | `icon` | `icon` (57px rail), `offcanvas` (0px), `none` |
| `width` | `double` | `260` | Expanded width (`KumoSidebar.defaultWidth`) |
| `collapsedWidth` | `double` | `57` | Rail width (`KumoSidebar.iconWidth`) |
| `minWidth` / `maxWidth` | `double` | `200` / `480` | Resize limits; dragging below `minWidth` collapses |
| `onWidthChange` | `ValueChanged<double>?` | | Shows a resize handle on the inner edge. Hold the width in your state and pass it back as `width` |
| `loading` | `bool` | `false` | Shows `KumoSidebarLoading` in place of `child` |
| `loadingLabel` | `String?` | `'Loading'` | Announced while loading |
| `semanticLabel` | `String?` | `KumoStrings.navigation` ("Navigation") | Name of the navigation region |
| `animationDuration` | `Duration` | 250ms | Collapse and expand duration |

`KumoSidebar.of(context)` / `maybeOf(context)` return `KumoSidebarData`: `open`, `collapsed`, `drawer`, `side`, `collapse` (animation, 0 expanded to 1 collapsed), `toggle()`, `setOpen(bool)`, `close` (drawer only).

### Parts

| Part | Key parameters |
| --- | --- |
| `KumoSidebarHeader` | `children` (row, 4px gap), `padding` (12px). 58px min height, bottom border |
| `KumoSidebarContent` | `children` (groups), `controller`. Scrolls; rows fade under the edges while more is hidden |
| `KumoSidebarGroup` | `label` (`String?`), `children`. The label folds into a divider in the rail; the first group has no divider |
| `KumoSidebarMenuButton` | `label`, `icon`, `iconWidget`, `active`, `onPress`, `badge`, `trailing`, `tooltip` (defaults to `label`), `size` (`base` 34px, `sm` 28px), `disabled`, `isLink`, `semanticLabel`, `focusNode` |
| `KumoSidebarCollapsible` | `label`, `children`, `icon`, `badge`, `open` (`bool?`), `initialOpen`, `onOpenChange`, `onOpenChangeComplete`, `autoScrollOnOpen`. Nest one inside another for a second level |
| `KumoSidebarMenuSub` | `children`: an indented list with a guide line (collapsibles wrap their children in one) |
| `KumoSidebarMenuSubButton` | `label`, `active`, `onPress`, `badge`, `trailing`, `disabled`, `isLink` |
| `KumoSidebarMenuBadge` | `text`: dashed pill, also reachable through the `badge` parameters |
| `KumoSidebarSeparator` | Divider between sections |
| `KumoSidebarFooter` | `children` (row, 16px gap). 48px min height, top border |
| `KumoSidebarTrigger` | `onPress`, `collapseLabel`, `expandLabel`. Panel icon whose divider slides with the sidebar |
| `KumoSidebarClose` | `semanticLabel`. X button that closes the drawer; renders nothing outside a drawer |
| `KumoSidebarLoading` | `label`. Still placeholder rows |
| `KumoSidebarSlidingViews` | `activeKey`, `children` (`KumoSidebarSlidingView(value:, child:)`) |
| `KumoSidebarHost` | For custom shells: `open`, `onOpenChange`, `drawer`, `drawerWidth`, `onClose`, `onNavigate` |

## Examples

### Controlled collapse

```dart
KumoSidebar(
  open: expanded,
  onOpenChange: (v) => setState(() => expanded = v),
  onOpenChangeComplete: (open) => debugPrint(open ? 'expanded' : 'collapsed'),
  footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
  child: const KumoSidebarContent(children: []),
)
```

### Loading

```dart
const KumoSidebar(loading: true, loadingLabel: 'Loading navigation', child: SizedBox())
```

### Resizable

```dart
KumoSidebar(
  width: width,
  minWidth: 180,
  maxWidth: 400,
  onWidthChange: (w) => setState(() => width = w),
  child: const KumoSidebarContent(children: []),
)
```

### Sliding views (account and zone)

```dart
KumoSidebarSlidingViews(
  activeKey: surface,
  children: [
    KumoSidebarSlidingView(
      value: 'account',
      child: KumoSidebarContent(children: [
        KumoSidebarGroup(children: [
          KumoSidebarMenuButton(icon: KumoIcons.globe, label: 'Domains', onPress: () => setState(() => surface = 'zone')),
        ]),
      ]),
    ),
    KumoSidebarSlidingView(
      value: 'zone',
      child: KumoSidebarContent(children: [
        KumoSidebarGroup(label: 'example.com', children: [
          KumoSidebarMenuButton(icon: KumoIcons.arrowLeft, label: 'All domains', onPress: () => setState(() => surface = 'account')),
        ]),
      ]),
    ),
  ],
)
```

## Accessibility

- The sidebar is a semantics region named `semanticLabel` (`KumoStrings.navigation`, "Navigation" in English).
- Rows are buttons (or links with `isLink`); the active row is announced as selected. Collapsible triggers announce expanded or collapsed. Collapsed rows keep their full label for screen readers.
- Tab moves through rows, Up and Down arrows move between rows (text fields keep their arrows), Enter and Space activate. Tabbing onto a collapsible opens it; it closes when focus leaves unless it was opened on purpose or holds the active row.
- Hidden sub rows and inactive sliding views are removed from focus, taps and the semantics tree.
- The resize handle is an adjustable slider ("Resize sidebar"): arrows change the width by 10px, Home collapses, End goes to `maxWidth`.
- Badges are text, not color.

## Motion

- Collapse animates the width over 250ms with Kumo's sidebar easing (`cubic-bezier(0.77, 0, 0.175, 1)`). The content keeps its expanded size and is clipped, so labels never re-wrap; rows narrow into 34px icon tiles and group labels fold into dividers alongside.
- Collapsible sections reveal their rows with a clip over 250ms. The chevron turns with the same animation, so it stays in step with the rows and reverses with them when a section is toggled mid-flight.
- When the active row changes inside a `KumoSidebarContent`, the tint travels from the old row to the new one over 200ms (`KumoCurves.standard`) and hands over when it lands; a change mid-flight turns it around from where it is. At rest each active row paints its own tint, so collapsing and scrolling never leave it behind.
- Sliding views slide sideways over 250ms.
- Hover tints are instant. Rows scale to 0.98 on press.
- Reduced motion: every change is instant (the active tint moves at once) and `onOpenChangeComplete` fires right away.

## Mobile

- On touch platforms rows grow to 44px tall; the visual tile stays 34px.
- Inside `KumoAppShell` on narrow screens the sidebar becomes a drawer: always expanded, no resize handle, the trigger and `KumoSidebarClose` close it, and pressing a row closes it.
- The sidebar pads its own top and bottom safe areas.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `Sidebar.Provider` `defaultOpen` / `open` / `onOpenChange` | `KumoSidebar(initialOpen:, open:, onOpenChange:)` |
| `onOpenChangeComplete` | `onOpenChangeComplete` |
| `variant="sidebar" \| "floating"` | `KumoSidebarVariant.sidebar` / `.floating` |
| `variant="inset"` | not ported (only changes the page background) |
| `collapsible="icon" \| "offcanvas" \| "none"` | `KumoSidebarCollapseMode` |
| `side="left" \| "right"` | `KumoSidebarSide.start` / `.end` |
| `resizable`, `defaultWidth`, `minWidth`, `maxWidth`, `onWidthChange` | `onWidthChange` + `width`, `minWidth`, `maxWidth` |
| `mobileBreakpoint`, `fullScreenOnMobile` | `KumoAppShell(narrowBreakpoint:, fullScreenDrawer:)` |
| `peekable` | not ported |
| `useSidebar()` | `KumoSidebar.of(context)` |
| `Sidebar.Header` / `Content` / `Footer` | `KumoSidebarHeader` / `KumoSidebarContent` / `KumoSidebarFooter` |
| `Sidebar.Group` + `GroupLabel` + `Menu` | `KumoSidebarGroup(label:, children:)` |
| `Sidebar.MenuButton` `icon` `active` `size` `tooltip` `href` | `KumoSidebarMenuButton(icon:, active:, size:, tooltip:, isLink:)` |
| `Sidebar.MenuBadge` | `badge:` or `KumoSidebarMenuBadge` |
| `Sidebar.Collapsible` + `CollapsibleTrigger` + `CollapsibleContent` + `MenuChevron` | `KumoSidebarCollapsible` |
| `autoScrollOnOpen` | `autoScrollOnOpen` |
| `Sidebar.MenuSub` / `MenuSubButton` | `KumoSidebarMenuSub` / `KumoSidebarMenuSubButton` |
| `Sidebar.Separator` / `Trigger` / `Close` / `Loading` | `KumoSidebarSeparator` / `KumoSidebarTrigger` / `KumoSidebarClose` / `KumoSidebarLoading` |
| `Sidebar.ResizeHandle` | built in when `onWidthChange` is set |
| `Sidebar.Rail` | not ported (use the trigger) |
| `Sidebar.SlidingViews` / `SlidingView` | `KumoSidebarSlidingViews` / `KumoSidebarSlidingView` |
| `scrollToItem(id)` | give the row a `GlobalKey` and call `Scrollable.ensureVisible(key.currentContext!)` |
