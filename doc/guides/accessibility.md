# Accessibility

- **Semantics.** Every control exposes its role, label and state (button, checked, toggled, selected, expanded, slider value). Icon-only buttons require a `semanticLabel` (an assert enforces it for `KumoButton`).
- **Keyboard.** Tab order follows visual order. Enter and Space activate. Arrow keys move within groups (radio groups, tabs, menus, option lists, calendars, toolbars). Escape closes popovers, menus, sheets and dialogs. Modal overlays trap focus and return it to the trigger on close.
- **Focus ring.** Keyboard focus shows Kumo's 2px brand ring, painted outside the control so layout never shifts. Fields show a 1.5px focus ring.
- **Hit areas** are at least 44x44 on touch platforms.
- **Contrast.** Tokens pass WCAG AA in both modes for text on the surfaces Kumo puts it on; `test/foundation/oklch_test.dart` checks the main pairs. Check custom pairs with `KumoColorUtils.contrastRatio`.
- **Status is never color alone.** Errors carry an icon and text, badges carry text, chart series have names in their semantics summary.
- **Announcements.** Toasts, field errors and "Copied" confirmations are live regions.
- **Text scale** up to 2x, RTL layouts, and reduced motion are supported and tested.
- **Headings.** `KumoText(headingLevel: n)` marks headings for screen reader navigation.
