# KumoFlowNode

One step in a [KumoFlowDiagram](KumoFlowDiagram.md). By default it is Kumo's node card. It can show custom content, be pressable and selected, or be disabled.

Kumo reference: https://kumo-ui.com/components/flow

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoFlowDiagram(children: [
  KumoFlowNode(label: 'Request'),
  KumoFlowNode(label: 'image-resizer'),
])
```

## When to use / when not to

- Use `label` for a plain step, `child` for richer content inside the standard card, and `render` for a different shape, such as a dot or a contrast pill.
- Make a node pressable when pressing it shows details somewhere else on the screen, and mark that node `selected`. Do not hide essential information behind a press.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | Stable identity. Keeps the node's widget state when earlier nodes change, and names it in `KumoFlowGeometry`. Must be unique. |
| `label` | `String?` | `null` | Text in the card. Also the screen reader label. |
| `child` | `Widget?` | `null` | Content inside the default card, instead of `label`. |
| `render` | `Widget?` | `null` | Replaces the card entirely. It is still measured, positioned and connected. |
| `disabled` | `bool` | `false` | Connectors touching this node draw at 40% opacity. It also blocks `onPress` and is announced as disabled. |
| `selected` | `bool` | `false` | Tinted background (`tint`) and a 2px `interact` ring. Announced as selected. |
| `onPress` | `VoidCallback?` | `null` | Makes the node pressable, built on `KumoPressable`. |
| `semanticLabel` | `String?` | `null` | Screen reader label when `label` is missing or does not say enough. |

`label` and `child` are mutually exclusive. `render` cannot be combined with either.

The default card is `rounded-md bg-kumo-base px-3 py-2 shadow ring ring-kumo-line`: 6px corners, base surface, 12px by 8px padding, a 1px `line` ring and `KumoShadow.sm`, around 14px body text. Pressable nodes switch to `elevated` instantly on hover, as Kumo's selectable cards do.

## Examples

### Selectable steps

```dart
class RequestPath extends StatefulWidget {
  const RequestPath({super.key});

  @override
  State<RequestPath> createState() => _RequestPathState();
}

class _RequestPathState extends State<RequestPath> {
  String _selected = 'waf';

  KumoFlowNode _step(String id, String label) => KumoFlowNode(
        id: id,
        label: label,
        selected: _selected == id,
        onPress: () => setState(() => _selected = id),
      );

  @override
  Widget build(BuildContext context) => KumoFlowDiagram(children: [
        _step('request', 'Request'),
        _step('waf', 'WAF'),
        _step('worker', 'image-resizer'),
      ]);
}
```

### Status inside a node

Pair the color with an icon and words:

```dart
const KumoFlowNode(
  semanticLabel: 'Deploy, failed',
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: KumoSpace.s1_5,
    children: [
      KumoIcon(KumoIcons.warningCircle, color: KumoColor.textDanger),
      Text('Deploy failed'),
    ],
  ),
)
```

### Custom shape

```dart
KumoFlowNode(
  semanticLabel: 'Entry point',
  render: Container(
    width: 16,
    height: 16,
    decoration: const BoxDecoration(color: Color(0xFFE9E9E9), shape: BoxShape.circle),
  ),
)
```

### Disabled

```dart
const KumoFlowParallel(children: [
  KumoFlowNode(label: 'Primary handler'),
  KumoFlowNode(label: 'Backup handler, paused', disabled: true),
])
```

## Accessibility

- A node reads its label, then its place in the diagram as the value ("WAF, Step 2 of 4"). Pressable nodes are buttons and also announce selected and disabled.
- Nodes with `label` or `child` are merged into one element. A `render` node is a container, so buttons inside it (an expand toggle, a link) stay separately reachable. Give it a `semanticLabel`.
- Keyboard: Tab reaches pressable nodes in flow order, and Enter or Space activates them. A focused node shows Kumo's 2px brand ring and pans into view.

## Motion

Pressable nodes use `KumoPressable`: the press scale starts on pointer-down and springs back, and the hover color changes instantly. Selecting a node eases its tint and 2px ring in (100ms), from wherever they are. Under reduced motion there is no scale and selection is instant. When a node changes size (for example an expanding section), the diagram lays out again and the connectors follow in the same frame.

## Mobile

On touch platforms, pressable nodes answer taps within a 44x44 area. The extra area is added to hit testing only, so the diagram's spacing and connector endpoints stay as in Kumo. Labels wrap at the viewport width and scale with text size.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Flow.Node>` | `KumoFlowNode` |
| `id` | `id` |
| `children` (text) | `label` |
| `children` (elements) | `child` |
| `render` | `render` |
| `disabled` | `disabled` |
| n/a | `selected`, `onPress`, `semanticLabel` |
