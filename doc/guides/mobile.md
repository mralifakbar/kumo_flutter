# Mobile

Kumo is designed for wide dashboards. kumo_flutter keeps Kumo's dense look and adapts the behavior for phones.

- **Hit areas.** On touch platforms every control's hit area is at least 44x44 (`KumoTapTargetSize.padded`) while the visual keeps Kumo's size.
- **Floating panels become sheets.** Below 768px (`context.kumoIsNarrow`), dropdown menus, selects, date pickers and the command palette open in a bottom sheet that follows the finger, instead of an anchored popover. Components that do this take `presentation: KumoPresentation.auto | popover | sheet`.
- **Dialogs** take the full width minus 16px gutters; long content scrolls between a sticky header and footer.
- **App shell.** `KumoAppShell` shows a persistent sidebar on wide screens, an icon rail on medium screens and a drawer with a labeled menu button on phones, with an optional `KumoBottomNavigation`.
- **Tables** scroll horizontally with an edge affordance, or render rows as cards with `layout: KumoTableLayout.cards`.
- **Text scale.** Components use minimum heights, never fixed heights around text, and are tested at 2x.
- **Keyboard.** Focused fields scroll above the on-screen keyboard.
- **Safe areas.** Sheets, toasts and bottom navigation respect the system insets.
