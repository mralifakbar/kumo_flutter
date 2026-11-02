# KumoAnchoredOverlay

The positioning primitive behind popovers, tooltips, menus, selects and comboboxes. Use it to build custom floating panels.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
class FilterButton extends StatefulWidget {
  const FilterButton({super.key});

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return KumoAnchoredOverlay(
      open: _open,
      onDismiss: () => setState(() => _open = false),
      side: KumoSide.bottom,
      align: KumoAlign.start,
      overlayBuilder: (context, placement) => KumoPopupSurface(
        placement: placement,
        showArrow: true,
        child: const KumoText('Filters'),
      ),
      child: KumoButton(label: 'Filter', icon: KumoIcons.funnel, onPress: () => setState(() => _open = !_open)),
    );
  }
}
```

## When to use / when not to

Reach for the finished components first (`KumoPopover`, `KumoDropdownMenu`, `KumoSelect`, `KumoTooltip`). Use this primitive for a panel those do not cover.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `open` | `bool` | required | Owned by the parent; changes animate |
| `child` | `Widget` | required | The anchor (trigger) |
| `overlayBuilder` | `KumoPopupBuilder` | required | Builds the popup for a `KumoPopupPlacement` |
| `onDismiss` | `VoidCallback?` | | Outside tap or Escape; set `open` to false |
| `side` | `KumoSide` | `bottom` | Flips to the opposite side when there is not enough room |
| `align` | `KumoAlign` | `center` | `start`/`end` follow text direction |
| `sideOffset`, `alignOffset` | `double` | `8`, `0` | |
| `collisionPadding` | `double` | `8` | Distance kept from the screen edges and safe area |
| `preferredExtent` | `double` | `200` | Room wanted before flipping |
| `matchAnchorWidth` | `bool` | `false` | Popup at least as wide as the anchor |
| `dismissOnOutsideTap`, `closeOnEscape` | `bool` | `true` | |
| `trapFocus` | `bool` | `false` | Move focus inside and cycle Tab within the popup |
| `restoreFocus` | `bool` | `true` | |
| `focusPopupWhenUnfocused` | `bool` | `true` | When nothing is focused at open, focus the popup so Escape reaches it |
| `useRootOverlay` | `bool` | `true` | |
| `animate` | `bool` | `true` | |
| `onClosed` | `VoidCallback?` | | After the close animation finishes |
| `tapRegionGroupId` | `Object?` | | Share outside-tap grouping with other widgets |

`KumoPopupPlacement` gives the resolved `side`, `align`, `anchorRect`, `maxWidth`, `maxHeight`, and `popupRect` (a listenable for painters).

## KumoPopupSurface

The floating surface: `bg-kumo-base`, 1px `line` outline, `shadow-lg`, rounded `lg`, 12px padding, and an optional arrow that points at the anchor.

| Name | Type | Default |
| --- | --- | --- |
| `child` | `Widget` | required |
| `placement` | `KumoPopupPlacement?` | needed for the arrow |
| `showArrow` | `bool` | `false` |
| `borderRadius` | `double` | `KumoRadius.lg` |
| `padding` | `EdgeInsetsGeometry` | `all(12)` |
| `shadow` | `KumoShadow` | `lg` |
| `clip` | `bool` | `true` |

## Accessibility

Escape closes from the anchor, from inside the popup, or when nothing is focused. With `trapFocus`, focus moves in and returns to the anchor on close.

## Motion

Opens with a critically damped spring from scale 0.9 plus a 150ms fade, transform origin on the anchor side; closes the same way. Reopening mid-close turns around from the current scale. Reduced motion keeps only the fade.

## Mobile

The popup stays inside the safe area and shifts along its edge to fit. Components built on it switch to `showKumoSheet` on narrow screens.
