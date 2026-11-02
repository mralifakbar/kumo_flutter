# KumoFlowDiagram

A directed step diagram: nodes joined by connectors with rounded elbows, plus parallel branches and custom anchor points. Use it when the order of steps matters, as in a request path, a deploy pipeline or a set of routing rules.

Kumo reference: https://kumo-ui.com/components/flow

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoFlowDiagram(
  semanticLabel: 'Request path',
  children: [
    KumoFlowNode(label: 'Request'),
    KumoFlowNode(label: 'WAF'),
    KumoFlowNode(label: 'image-resizer'),
    KumoFlowNode(label: 'Origin'),
  ],
)
```

The children are entries, not widgets: [KumoFlowNode](KumoFlowNode.md), [KumoFlowParallel](KumoFlowParallel.md) and [KumoFlowList](KumoFlowList.md). Like Material's `Step` in a `Stepper`, they only work inside a diagram. Inside a node, [KumoFlowAnchor](KumoFlowAnchor.md) marks where connectors attach.

## When to use / when not to

- Use it for a small, fixed structure that the reader should understand at a glance: three to fifteen steps with a few branches.
- Do not use it for an editable graph with free node placement, or for hundreds of nodes. It lays nodes out automatically and builds every node.
- For a linear progress indicator ("step 2 of 4" in a form), use a stepper or progress component instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<KumoFlowEntry>` | required | Steps in order. |
| `orientation` | `KumoFlowOrientation` | `horizontal` | `horizontal`, `vertical`, or `auto` (horizontal when it fits the width, otherwise vertical). |
| `align` | `KumoFlowAlign` | `start` | Cross-axis alignment: `start` or `center`. |
| `canvas` | `bool` | `true` | When the content overflows: pan, wheel, edge fade and scrollbars. With `false`, overflow is clipped and the content does not move. |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.symmetric(horizontal: 16, vertical: 64)` | Space between the diagram's edge and the content. Kumo's default. |
| `onOverflowChange` | `ValueChanged<KumoFlowOverflow>?` | `null` | Called after the first layout, then whenever overflow changes. `KumoFlowOverflow` has `x` and `y`. |
| `onGeometryChange` | `ValueChanged<KumoFlowGeometry>?` | `null` | Called after layout when the node rectangles or connector endpoints change. It also reports the orientation that `auto` picked. |
| `semanticLabel` | `String?` | `null` | Screen reader name of the diagram. Falls back to `strings.diagram`. |
| `strings` | `KumoFlowStrings?` | from `KumoLocale` | Screen reader copy: `diagram`, `step(i, n)`, `branch(i, n)`, `steps(n)`. Defaults to `KumoStrings.flowDiagram`, `flowStep`, `flowBranch`, `flowSteps`. |

`KumoFlowGeometry` holds `orientation`, `size` (the content box), `nodes` (one `Rect` per node, depth first), `ids` and `connectors`. Each `KumoFlowConnector` has `from`, `to`, `start`, `end` and `disabled`. Coordinates are relative to the content box, so they exclude the padding and the pan offset, and they are mirrored under RTL.

## Examples

### Vertical, centered

```dart
const KumoFlowDiagram(
  orientation: KumoFlowOrientation.vertical,
  align: KumoFlowAlign.center,
  children: [
    KumoFlowNode(label: 'Start'),
    KumoFlowParallel(children: [
      KumoFlowNode(label: 'Branch A'),
      KumoFlowNode(label: 'Branch B'),
    ]),
    KumoFlowNode(label: 'End'),
  ],
)
```

### Adapting to the screen

```dart
KumoFlowDiagram(
  orientation: KumoFlowOrientation.auto,
  onGeometryChange: (geometry) => debugPrint('Using ${geometry.orientation.name}'),
  children: const [
    KumoFlowNode(label: 'Push to main'),
    KumoFlowNode(label: 'Build'),
    KumoFlowNode(label: 'Deploy preview'),
    KumoFlowNode(label: 'Promote'),
  ],
)
```

### A large diagram in a frame

```dart
SizedBox(
  height: 240,
  child: KumoFlowDiagram(
    semanticLabel: 'Deploy pipeline',
    children: [
      for (final step in ['Install', 'Lint', 'Test', 'Build', 'Upload', 'Deploy', 'Purge cache'])
        KumoFlowNode(label: step),
    ],
  ),
)
```

### Loading, empty and error states

The diagram draws whatever structure it is given. While the data loads, or when there is none, show a loader or a message in its place:

```dart
Widget routes(List<String>? routes, Object? error) {
  if (error != null) {
    return const KumoText('Could not load routes for example.com. Check your API token and reload.',
        variant: KumoTextVariant.error);
  }
  if (routes == null) return const KumoLoader(semanticLabel: 'Loading routes');
  if (routes.isEmpty) {
    return const KumoText('No routes on example.com yet. Add a route to a Worker to see its path.',
        variant: KumoTextVariant.secondary);
  }
  return KumoFlowDiagram(children: [
    KumoFlowParallel(children: [for (final r in routes) KumoFlowNode(label: r)]),
    const KumoFlowNode(label: 'image-resizer'),
  ]);
}
```

To show the status of a single step, put an icon and text inside that node. See [KumoFlowNode](KumoFlowNode.md).

## Accessibility

- The diagram is one semantics container. Its label is `semanticLabel` and its value is the step count ("Request path, 4 steps").
- Screen readers visit nodes in flow order, not screen order, so a branch is read in full before the step after it. Each node reads its label and its place: "image-resizer, Step 3 of 4", "WAF, Step 2 of 3, branch 1 of 2". A step inside a list branch gets another part: "Load session, Step 2 of 3, branch 1 of 2, Step 2 of 2".
- Tab moves through pressable nodes in the same order. Enter and Space activate the focused node.
- When the content overflows, the container exposes scroll left/right/up/down actions that pan by 80% of the viewport. A node that gets keyboard or accessibility focus is panned into view.
- Disabled nodes are announced as disabled. Kumo shows a disabled node only by dimming its connectors, so also say it in the label ("Backup handler, paused").
- Connectors use `textPlaceholder`, as in Kumo. They are decoration; the structure also comes from the layout and the announcements.

## Motion

- Panning follows the finger 1:1 from the first frame. Movement before the drag is recognized counts too.
- On release, the finger's velocity becomes momentum. Past the start or end, the content rubber-bands and springs back with `KumoSprings.standard`. Touching a moving canvas stops it where it is.
- Revealing a focused node uses a spring that starts from the current position. Under reduced motion it jumps.
- Scrollbars appear and disappear instantly (Kumo shows them on hover), while hovered, dragged or moving.

## Mobile

- Kumo's diagrams are built for wide dashboards. On a phone, a horizontal diagram usually does not fit. There are two answers, and both are supported:
  - The default `horizontal` keeps Kumo's layout and pans. Edges where content is hidden fade out over 24px, so it is clear there is more. This is the right choice when left-to-right order carries meaning, or for short diagrams.
  - `auto` switches to vertical only when the horizontal layout does not fit the measured width, so landscape and tablets keep the horizontal look. This is the right choice when the diagram sits in a scrolling page, because vertical diagrams scroll with the page instead of inside it.
- Only the overflowing axis is grabbed. A horizontal diagram inside a vertical page lets vertical drags and mouse wheels scroll the page.
- Nodes are measured with the viewport width as their maximum, so long labels wrap instead of overflowing at 2x text.
- Pressable nodes keep Kumo's geometry in the layout and still answer taps within a 44x44 area on touch.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Flow>` | `KumoFlowDiagram` |
| `orientation="horizontal" \| "vertical"` | `orientation: KumoFlowOrientation.horizontal \| vertical` (plus `auto`) |
| `align="start" \| "center"` | `align: KumoFlowAlign.start \| center` |
| `canvas` | `canvas` |
| `padding={{ x, y }}` | `padding: EdgeInsets.symmetric(horizontal: x, vertical: y)` |
| `onOverflowChange` | `onOverflowChange` |
| `className` | wrap the diagram (for example in a `DecoratedBox`) |
| `children` | `children` |
| n/a | `onGeometryChange`, `semanticLabel`, `strings` |
