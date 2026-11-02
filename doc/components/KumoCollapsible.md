# KumoCollapsible

A trigger that shows and hides a panel, for optional detail (advanced settings, an explanation) that most people skip.

Kumo reference: https://kumo-ui.com/components/collapsible

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoCollapsible(
  open: open,
  onOpenChange: (v) => setState(() => open = v),
  label: 'Advanced settings',
  child: const KumoText('Compatibility date, usage model and placement.'),
)
```

## When to use / when not to

Use it for one block of secondary content. For a list of sections where you want one open at a time, use `KumoAccordion`. Do not hide required form fields in it.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `open` | `bool` | required | Changes animate |
| `onOpenChange` | `ValueChanged<bool>?` | required | Next open state |
| `child` | `Widget` | required | Panel content |
| `label` | `String?` | | Text of the default trigger (required unless `triggerBuilder`) |
| `triggerBuilder` | `KumoCollapsibleTriggerBuilder?` | | `(context, open, toggle) => Widget` |
| `panelStyle` | `KumoCollapsiblePanelStyle` | `accent` | `accent`: 2px `fill` rule on the start edge, 16px inset; `plain`: as given |
| `disabled` | `bool` | `false` | |
| `keepMounted` | `bool` | `false` | Keep closed content alive (form fields keep their text) |
| `semanticLabel` | `String?` | | Accessible name of the default trigger |

Building blocks, also public:

- `KumoCollapsibleTrigger(label:, open:, onPress:, disabled:, semanticLabel:)`: Kumo's `DefaultTrigger`, medium 14px text and a 12px caret that turns while open.
- `KumoCollapsiblePanel(open:, child:, keepMounted:, duration:, fade:)`: Kumo's `Panel`, the animated clip. Use it for your own disclosure layouts.
- `KumoDisclosureCaret(open:, size: 16, color:, icon: KumoIcons.caretDown, turns: 0.5, duration: KumoDurations.moderate)`: the caret, on the same clock as the panel. Put it in custom triggers so it turns in step with the height.

```dart
KumoPressable(
  onPress: () => setState(() => open = !open),
  expanded: open,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: KumoSpace.s1,
    children: [const KumoText('Routes'), KumoDisclosureCaret(open: open, size: 12)],
  ),
)
```

## Examples

### Custom trigger

```dart
KumoCollapsible(
  open: open,
  onOpenChange: (v) => setState(() => open = v),
  panelStyle: KumoCollapsiblePanelStyle.plain,
  triggerBuilder: (context, open, toggle) => KumoButton(
    label: open ? 'Hide bindings' : 'Show bindings',
    size: KumoButtonSize.sm,
    onPress: toggle,
  ),
  child: const KumoText('R2 bucket assets, KV namespace sessions'),
)
```

### Panel only

```dart
KumoCollapsiblePanel(open: showLogs, child: const KumoText('No errors in the last hour'))
```

## Accessibility

The default trigger is a button with an expanded state; Enter and Space toggle. While closed (and while closing) the panel's content is out of the focus order and hidden from screen readers, also with `keepMounted`. A custom trigger should set its own expanded semantics, for example with `KumoPressable(expanded: open)`.

## Motion

The height animates over 200ms (`KumoDurations.moderate`, standard curve) with a fade, while the content is laid out at full height and clipped, so text never reflows mid-animation. Toggling mid-animation reverses from the current height. The caret is a `KumoDisclosureCaret`: it runs on the same clock as the panel, so it turns in step with the height, including when reversed mid-flight. Reduced motion opens, closes and turns instantly.

## Mobile

The trigger's hit area is 44px tall on touch. Content keeps its natural height at 2x text.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `Collapsible.Root open / onOpenChange` | `open` / `onOpenChange` |
| `Collapsible.DefaultTrigger` children | `label` |
| `Collapsible.Trigger render` | `triggerBuilder` |
| `Collapsible.DefaultPanel` | `panelStyle: accent` |
| `Collapsible.Panel` | `panelStyle: plain`, or `KumoCollapsiblePanel` |
| `keepMounted` | `keepMounted` |
| `defaultOpen` | not ported (controlled only) |

Kumo's panel transition is 100ms; this port uses the package's 200ms expand duration, which reads better on taller mobile content.
