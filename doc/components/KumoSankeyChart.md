# KumoSankeyChart

A Sankey diagram: flows between nodes, each link as wide as its value. Kumo's `SankeyChart`, laid out with the d3/ECharts Sankey algorithm and drawn with `CustomPainter`.

Kumo reference: https://kumo-ui.com/charts/sankey

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoSankeyChart(
  height: 300,
  nodes: [
    KumoSankeyNode(name: 'Users'),
    KumoSankeyNode(name: 'Devices'),
    KumoSankeyNode(name: 'Workers'),
    KumoSankeyNode(name: 'Tunnels'),
  ],
  links: [
    KumoSankeyLink(source: 0, target: 2, value: 80000),
    KumoSankeyLink(source: 0, target: 3, value: 23600),
    KumoSankeyLink(source: 1, target: 2, value: 42600),
    KumoSankeyLink(source: 1, target: 3, value: 8200),
  ],
)
```

## When to use / when not to

Use it to show how a total splits and recombines across stages: traffic by source and destination, requests by method and status. For values over time use `KumoTimeseriesChart`; for a single split, a bar or meter reads faster.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `nodes` | `List<KumoSankeyNode>` | required | `name`, optional `id`, `color`, `value`, `tooltipData` |
| `links` | `List<KumoSankeyLink>` | required | `source`, `target` (indexes into `nodes`), `value`, optional `id` |
| `height` | `double` | `400` | |
| `nodeWidth` | `double` | `8` | Node bar thickness |
| `nodePadding` | `double` | `10` | Gap between nodes in a column |
| `showTooltip` | `bool` | `true` | |
| `showNodeValues` | `bool?` | true when any node has a value | Value with each label |
| `nodeLabelLayout` | `KumoSankeyLabelLayout` | `stacked` | `stacked` (value over name) or `inline` |
| `formatValue` | `String Function(double)?` | grouped digits | Node and link values |
| `tooltipBuilder` | `Widget? Function(BuildContext, KumoSankeyTooltipDetails)?` | | Custom tooltip content; return null to hide |
| `defaultNodeColor` | `Color?` | | Before the categorical palette |
| `left` / `right` | `double` | `0` | Horizontal padding in px |
| `linkColor` | `KumoSankeyLinkColor` | `gradient` | `gradient` (source to target) or `gray` |
| `linkOpacity` | `double` | `0.5` | Gradient link opacity |
| `nodeAlign` | `KumoSankeyNodeAlign` | `justify` | `justify`, `left`, `right` |
| `focus` | `KumoSankeyFocus` | `adjacency` | Highlight neighbours, or the whole `path` through a node |
| `onNodePress` | `void Function(KumoSankeyNode, int)?` | | |
| `onLinkPress` | `void Function(KumoSankeyLink)?` | | |
| `loading` | `bool` | `false` | Skeleton of nodes and flows |
| `error` / `onRetry` | `String?` / `VoidCallback?` | | Error state with a Retry button |
| `emptyMessage` | `String` | `'No flows to show'` | When no link is valid |
| `emptyDescription` | `String?` | | |
| `semanticLabel` | `String?` | | Leads the screen reader summary |

A node is as tall as the larger of its inflows and outflows (or its `value`, if larger). Links with an out-of-range index, a self link or a value of zero or less are skipped. Nodes without links are not drawn.

## Examples

### Path highlighting and gray links

```dart
KumoSankeyChart(
  nodes: nodes,
  links: links,
  focus: KumoSankeyFocus.path,
  linkColor: KumoSankeyLinkColor.gray,
  nodeLabelLayout: KumoSankeyLabelLayout.inline,
)
```

### Drill down on press

```dart
KumoSankeyChart(
  nodes: nodes,
  links: links,
  onNodePress: (node, index) => setState(() => selected = node.name),
  tooltipBuilder: (context, details) => details.isNode ? KumoText(details.node!.name) : null,
)
```

## Accessibility

One semantics node summarises the diagram ("Sankey chart, 8 nodes, 12 flows. Users to Apps: 80,000. ...") so every flow is readable without the picture. With keyboard focus, arrow keys move between nodes in column order, the value reads the node with its inflows and outflows, Enter or Space calls `onNodePress` and Escape clears.

## Motion

Changing nodes or links morphs node positions and link widths from the current layout over 300ms (new nodes fade in). Hovering or pressing a node or link eases the other flows down and the highlighted ones up (150ms), from wherever they are, so moving across the diagram never flickers. The skeleton, diagram, error and empty message cross-fade (150ms). All of it is instant under reduced motion.

## Mobile

Tap a node or flow to highlight it and show its tooltip above the finger; tap outside to clear. Labels of nodes in the right half sit to the left of the node so nothing runs off a phone screen. Labels grow with text scale and truncate to the column gap.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `echarts` | (not needed) |
| `nodes`, `links`, `height`, `nodeWidth`, `nodePadding` | same |
| `showTooltip`, `showNodeValues`, `nodeLabelLayout`, `formatValue` | same |
| `tooltipFormatter` (HTML string) | `tooltipBuilder` (widget) |
| `defaultNodeColor`, `left`, `right`, `linkColor`, `linkOpacity` | same (`left`/`right` in px) |
| `onNodeClick(node)` | `onNodePress(node, index)` |
| `onLinkClick(link)` | `onLinkPress(link)` |
| `isDarkMode`, `className` | follows `KumoTheme` |
| (ECharts `nodeAlign`, `emphasis.focus`) | `nodeAlign`, `focus` |
