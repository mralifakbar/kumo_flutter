# KumoFlowList

A sequence of connected steps inside a [KumoFlowParallel](KumoFlowParallel.md), for a branch with more than one step.

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
    KumoFlowList(children: [
      KumoFlowNode(label: 'Cache lookup'),
      KumoFlowNode(label: 'Serve from cache'),
    ]),
    KumoFlowNode(label: 'Bypass cache'),
  ]),
  KumoFlowNode(label: 'Response'),
])
```

## When to use / when not to

- Use it only as a branch. The diagram's own `children` are already a list.
- Entries outside the list connect to its first node (incoming) and its last node (outgoing) only.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `children` | `List<KumoFlowEntry>` | required | Steps in order. These can include their own parallel groups. |

Steps in a list are 64px apart on the main axis (Kumo's `columnGap`).

## Examples

### A branch that starts with its own branches

```dart
const KumoFlowParallel(children: [
  KumoFlowList(children: [
    KumoFlowNode(label: 'Client users'),
    KumoFlowNode(label: 'Engineering access'),
  ]),
  KumoFlowList(children: [
    KumoFlowParallel(children: [
      KumoFlowNode(label: 'All authenticated users'),
      KumoFlowNode(label: 'Site users'),
    ]),
    KumoFlowNode(label: 'Contractor access'),
  ]),
])
```

## Accessibility

Steps in a list announce their place in it after their branch: "Serve from cache, Step 2 of 3, branch 1 of 2, Step 2 of 2".

## Motion

None of its own.

## Mobile

A list branch makes a horizontal diagram longer. On phones, prefer `orientation: KumoFlowOrientation.auto` on the diagram, or keep list branches to two steps.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Flow.List>` | `KumoFlowList` |
| `children` | `children` |
