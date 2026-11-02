# KumoAppShell

The responsive frame a Kumo app is built on: a `KumoSidebar`, a sticky top bar and the page, switching between a persistent sidebar, an icon rail and a phone drawer.

Kumo reference: https://kumo-ui.com/components/sidebar (Kumo has no shell component; this is the Flutter frame around Kumo's sidebar and its mobile drawer)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoAppShell(
  sidebar: KumoSidebar(
    header: const KumoSidebarHeader(children: [Expanded(child: KumoText('Acme Inc', bold: true)), KumoSidebarClose()]),
    footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
    child: KumoSidebarContent(children: [
      KumoSidebarGroup(children: [
        KumoSidebarMenuButton(icon: KumoIcons.house, label: 'Account home', active: true, onPress: () {}),
        KumoSidebarMenuButton(icon: KumoIcons.code, label: 'Workers', onPress: () {}),
      ]),
    ]),
  ),
  topBar: const KumoText('Workers', variant: KumoTextVariant.heading),
  body: const Center(child: KumoText('Page content')),
)
```

## When to use / when not to

Use it once, at the root of an app's signed-in area. Pages go in `body`. Do not nest shells; for a sidebar inside a panel, use `KumoSidebar` directly.

## Layouts

| Width of the shell | Layout | Sidebar |
| --- | --- | --- |
| 1024px and up | `KumoAppShellLayout.wide` | Persistent; the trigger collapses it to the rail. State: `sidebarOpen` |
| 768px to 1023px | `KumoAppShellLayout.medium` | Starts as the 57px rail; the trigger expands it until the layout changes |
| below 768px | `KumoAppShellLayout.narrow` | Drawer from the sidebar's edge, opened by the "Menu" button in the top bar or an edge swipe |

The width is the shell's own constraint width, so a shell inside a smaller box picks its layout from the box.

The shell is a page-level widget: it sets Kumo's text style and icon theme for everything inside it, paints the canvas color, and puts a transparent `Material` around the body (text fields need one), so it works as a route's root without a `Scaffold`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `body` | `Widget` | required | The page |
| `sidebar` | `KumoSidebar?` | | Its `open`/`onOpenChange` are ignored; the shell owns them |
| `topBar` | `Widget?` | | Content of the sticky bar (48px min, bottom border). Narrow layouts always show the bar for the menu button |
| `bottomNavigation` | `Widget?` | | Bar pinned to the bottom on narrow layouts, usually a `KumoBottomNavigation` (which draws its own border and home-indicator padding); any other widget gets a top border and the bottom safe area from the shell |
| `sidebarOpen` | `bool?` | null | Wide layout expanded state. Null keeps it inside, starting from `initialSidebarOpen` |
| `initialSidebarOpen` | `bool` | `true` | |
| `onSidebarOpenChange` | `ValueChanged<bool>?` | | Wide layout only |
| `onDrawerOpenChange` | `ValueChanged<bool>?` | | Drawer opened or closed, by any means |
| `layout` | `KumoAppShellLayout?` | | Force a layout |
| `narrowBreakpoint` | `double` | `768` | |
| `wideBreakpoint` | `double` | `1024` | |
| `bodyPadding` | `EdgeInsetsGeometry` | `EdgeInsets.zero` | Inside the safe area |
| `safeAreaBody` | `bool` | `true` | Pad the body for safe-area edges no bar covers |
| `drawerWidth` | `double?` | sidebar width | Capped so 56px of the page stays visible |
| `fullScreenDrawer` | `bool` | `false` | Drawer covers the screen without a scrim; put `KumoSidebarClose` in the header |
| `closeDrawerOnNavigate` | `bool` | `true` | Pressing a menu row closes the drawer |
| `menuLabel` | `String?` | `KumoStrings.menu` | Visible label of the menu button |
| `edgeSwipeWidth` | `double` | `20` | Strip along the edge that starts an edge swipe (plus the safe-area inset) |

`KumoAppShell.of(context)` returns `KumoAppShellData`: `layout`, `drawerOpen`, `openDrawer()`, `closeDrawer()`, `toggleSidebar()`.

## Examples

### Phone app with a bottom bar

```dart
KumoAppShell(
  sidebar: mySidebar,
  topBar: const KumoText('Workers', variant: KumoTextVariant.heading),
  bottomNavigation: myTabBar, // a KumoBottomNavigation
  body: ListView(children: const []),
)
```

### Open the drawer from page content

```dart
KumoButton(label: 'Browse products', onPress: () => KumoAppShell.of(context).openDrawer())
```

### Controlled sidebar on wide screens

```dart
KumoAppShell(
  sidebarOpen: expanded,
  onSidebarOpenChange: (v) => setState(() => expanded = v),
  sidebar: mySidebar,
  body: const SizedBox(),
)
```

## Accessibility

- The menu button has a visible "Menu" label. Opening the drawer moves focus to its first row; Tab and Shift+Tab stay inside the drawer; Escape, the scrim (announced as "Close sidebar"), `KumoSidebarClose` and the system back gesture close it, and focus returns to what had it before.
- While the drawer is open the page behind is out of the focus order and hidden from screen readers.
- The top bar is separated from the page by a border (Kumo's rule for sticky elements).

## Motion

- The drawer follows the finger 1:1, keeping the grab offset. On release a clear flick (over 400px/s) decides by direction; otherwise the projected resting point decides, so a small drag springs back. The settle is a spring (`KumoSprings.sheet`) that keeps the finger's velocity and can be caught mid-flight.
- Past fully open the drawer resists (rubberband) and stretches from its edge rather than pulling away.
- The scrim dims in proportion to how far the drawer is open.
- A light haptic marks a gesture that changes the open state.
- Reduced motion: the drawer appears and disappears in place.
- Sidebar collapse on wide screens follows `KumoSidebar`'s motion.
- A `KumoBottomNavigation` in `bottomNavigation` slides its active pill between destinations.

## Mobile

- The top bar takes the top safe area, the bottom bar takes the bottom one, and the body gets the rest (`MediaQuery.padding` inside the body is what is left).
- Edge swipes start only in the edge strip, so horizontal scrolling in the page keeps working. A closed drawer never listens for drags across the page.
- The drawer is 260px or the sidebar's width, never closer than 56px to the far edge.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `Sidebar.Provider` + `<Sidebar>` + `<main>` | `KumoAppShell(sidebar:, body:)` |
| `mobileBreakpoint` | `narrowBreakpoint` |
| `fullScreenOnMobile` | `fullScreenDrawer` |
| mobile `Sidebar.Trigger` in a page header | the built-in "Menu" button, or `KumoAppShell.of(context).openDrawer()` |
| `openMobile` / `setOpenMobile` | `KumoAppShell.of(context).drawerOpen` / `openDrawer` / `closeDrawer` |
| `open` / `onOpenChange` (desktop) | `sidebarOpen` / `onSidebarOpenChange` |
