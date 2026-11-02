# KumoButtonGroup

Kumo's `ButtonGroup`: a few tightly coupled buttons joined into one control, most often a split button (an action next to a menu trigger for related actions).

Kumo reference: https://kumo-ui.com/components/button-group

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoButtonGroup(
  semanticLabel: 'Deploy',
  variant: KumoButtonVariant.primary,
  children: [
    KumoButtonGroupButton(label: 'Deploy', onPress: deploy),
    KumoButtonGroupButton(
      icon: KumoIcons.caretDown,
      semanticLabel: 'More deploy options',
      onPress: openDeployMenu,
    ),
  ],
)
```

## When to use / when not to

Use it for a split button or two or three actions that act on the same thing. For a row of independent actions, use a toolbar or spaced `KumoButton`s. For choosing between options, use `KumoToggleGroup` or a segmented `KumoRadioGroup`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<Widget>` | required | `KumoButtonGroupButton`s, possibly wrapped in a tooltip or a menu anchor |
| `size` | `KumoButtonSize` | `base` | Default size of every button; keep them equal |
| `variant` | `KumoButtonVariant` | `secondary` | Default style of every button |
| `semanticLabel` | `String?` | | Names the group for screen readers |

### KumoButtonGroupButton

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String?` | | Button text. Without it the button is square |
| `icon` | `IconData?` | | Leading icon, or the only content |
| `endIcon` | `IconData?` | | Trailing icon |
| `onPress` | `VoidCallback?` | | Null renders the button disabled |
| `variant` | `KumoButtonVariant?` | group's | |
| `size` | `KumoButtonSize?` | group's | |
| `disabled` | `bool` | `false` | |
| `loading` | `bool` | `false` | Spinner in place of the icon; presses ignored |
| `title` | `String?` | | Tooltip; doubles as the accessible name of icon-only buttons |
| `semanticLabel` | `String?` | | Required for icon-only buttons (or `title`) |
| `focusNode` | `FocusNode?` | | |

## Examples

### Split button with a menu

```dart
KumoButtonGroup(
  semanticLabel: 'Save',
  children: [
    KumoButtonGroupButton(label: 'Save', onPress: save),
    KumoAnchoredOverlay(
      open: menuOpen,
      align: KumoAlign.end,
      trapFocus: true,
      onDismiss: () => setState(() => menuOpen = false),
      overlayBuilder: (context, placement) => KumoMenuPanel(
        children: [
          KumoMenuRow(label: 'Save as draft', onPress: saveDraft),
          KumoMenuRow(label: 'Save and publish', onPress: publish),
        ],
      ),
      child: KumoButtonGroupButton(
        icon: KumoIcons.caretDown,
        semanticLabel: 'More save options',
        onPress: () => setState(() => menuOpen = !menuOpen),
      ),
    ),
  ],
)
```

### Joined actions

```dart
KumoButtonGroup(
  semanticLabel: 'Worker version',
  size: KumoButtonSize.sm,
  children: [
    KumoButtonGroupButton(label: 'Roll back', icon: KumoIcons.arrowCounterClockwise, onPress: rollBack),
    KumoButtonGroupButton(label: 'Promote', onPress: promote),
  ],
)
```

## Accessibility

- The group is a labeled container; each button is a separate button with its own Tab stop and Enter/Space activation.
- Icon-only buttons need `semanticLabel` or `title` (asserted).
- Keyboard focus draws the 2px brand ring just inside the button's edge, so the neighbor's seam cannot cover it.

## Motion

Joined buttons do not scale on press: scaling one segment would open gaps at the seams. Press and hover feedback is the instant background change Kumo uses. A loading spinner turns only while `loading` is true.

## Mobile

On touch each button's hit area extends to 44px tall above and below the visual. Square buttons widen to 44px, because joined buttons cannot be padded apart the way single buttons are. A group wider than the screen scrolls sideways instead of overflowing, since Kumo's group keeps its intrinsic width.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `children` (`Button`s) | `children` (`KumoButtonGroupButton`s) |
| child `variant`, `size` | group `variant`, `size`, or per button |
| child `shape="square"` | omit `label` |
| `aria-label` | `semanticLabel` |
| `className` | not ported |

Deviation: Kumo joins any `Button`. Flutter's `KumoButton` draws fixed rounded corners, so the group uses its own `KumoButtonGroupButton`, which matches `KumoButton`'s variants, sizes and loading state but rounds only the outer corners.
