# KumoFlowParallel

Parallel branches in a [KumoFlowDiagram](KumoFlowDiagram.md). The step before the group fans out to every branch, and every branch joins the step after it.

Kumo reference: https://kumo-ui.com/components/flow

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoFlowDiagram(children: [
  KumoFlowNode(label: 'Request'),
  KumoFlowParallel(children: [
    KumoFlowNode(label: 'WAF'),
    KumoFlowNode(label: 'Bot score'),
  ]),
  KumoFlowNode(label: 'Origin'),
])
```

## When to use / when not to

- Use it for work that happens side by side or for alternative routes: several triggers starting one Worker, or one Worker writing to several stores.
- Two parallel groups next to each other are not connected, as in Kumo. If every branch of the first group leads into every branch of the second, put a node between them.
- For a branch with more than one step, use a [KumoFlowList](KumoFlowList.md) as the branch.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<KumoFlowEntry>` | required | One entry per branch: a node, a list or another parallel group. |
| `align` | `KumoFlowParallelAlign` | `start` | `start` lines branches up at the leading edge. `end` lines them up at the trailing edge of the widest branch (the right in a horizontal LTR flow, the bottom in a vertical one). |

Branches are 16px apart (Kumo's `rowGap`). The group is as wide as its widest branch in a horizontal flow, and as tall as its tallest in a vertical one.

## Examples

### Fan in, fan out

```dart
const KumoFlowDiagram(children: [
  KumoFlowParallel(children: [
    KumoFlowNode(label: 'HTTP trigger'),
    KumoFlowNode(label: 'Cron trigger'),
  ]),
  KumoFlowNode(label: 'Process request'),
  KumoFlowParallel(children: [
    KumoFlowNode(label: 'Log analytics'),
    KumoFlowNode(label: 'Update cache'),
  ]),
])
```

### Align end

```dart
const KumoFlowParallel(
  align: KumoFlowParallelAlign.end,
  children: [
    KumoFlowNode(label: 'DNS'),
    KumoFlowNode(label: 'Transform Rules'),
  ],
)
```

## Accessibility

Each node in a branch adds its branch to its announcement: "Bot score, Step 2 of 3, branch 2 of 2". Screen readers and Tab finish one branch before moving to the next, then continue to the step after the group.

## Motion

None of its own. Connectors re-route in the same frame when branches are added, removed or resized.

## Mobile

In a vertical flow, branches sit side by side and can be wider than a phone. The diagram then pans sideways with an edge fade. Keep vertical groups to two or three short branches.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Flow.Parallel>` | `KumoFlowParallel` |
| `align` omitted / `"end"` | `align: KumoFlowParallelAlign.start` / `.end` |
| `children` | `children` |
