# KumoFlowAnchor

Marks where connectors attach inside a [KumoFlowNode](KumoFlowNode.md), so they meet a header or leave from a footer instead of the node's center.

Kumo reference: https://kumo-ui.com/components/flow

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoFlowDiagram(children: [
  KumoFlowNode(label: 'Load balancer'),
  KumoFlowNode(
    semanticLabel: 'my-worker, 2 bindings',
    render: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KumoFlowAnchor(type: KumoFlowAnchorType.end, child: Text('my-worker')),
        Text('Routes: example.com/*'),
        KumoFlowAnchor(type: KumoFlowAnchorType.start, child: Text('Bindings 2')),
      ],
    ),
  ),
  KumoFlowParallel(children: [
    KumoFlowNode(label: 'DATABASE'),
    KumoFlowNode(label: 'OTHER_SERVICE'),
  ]),
])
```

## When to use / when not to

- Use it for tall nodes whose incoming and outgoing connections belong to different parts of the node.
- Anchors apply to horizontal flows only. In vertical flows, connectors always meet a node at the center of its top and bottom edges, as in Kumo.
- It must be inside a `KumoFlowNode`'s `child` or `render`. Anywhere else it throws a `FlutterError`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `type` | `KumoFlowAnchorType` | `both` | `start`: outgoing connectors leave here. `end`: incoming connectors arrive here. `both`: both. |
| `child` | `Widget` | required | The content the connectors line up with. They meet its vertical center. |

If a node has two anchors of the same type, the last one wins.

## Examples

### One anchor for both directions

```dart
const KumoFlowNode(
  render: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      KumoFlowAnchor(child: Text('Header')),
      Text('Body content that makes the node taller'),
    ],
  ),
)
```

## Accessibility

Anchors add no semantics. Name the node with `semanticLabel` so that its parts read as one step.

## Motion

Connectors follow the anchor whenever the node lays out again, for example when a section above the anchor expands.

## Mobile

No special behavior.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Flow.Anchor>` | `KumoFlowAnchor` |
| `type="start" \| "end"`, omitted | `type: KumoFlowAnchorType.start \| end \| both` |
| `render` / `children` | `child` |
