# KumoSteps

A progress indicator for multi-step flows: numbered markers joined by connectors, horizontal on wide layouts and vertical on narrow ones. Shaped after shadcn's steps and drawn with Kumo tokens; Kumo has no steps component.

Kumo reference: none (see `KumoStepper` for the flow with content and buttons)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoSteps(
  current: 1,
  steps: [
    KumoStepsItem(title: 'Choose a plan'),
    KumoStepsItem(title: 'Add DNS records'),
    KumoStepsItem(title: 'Change nameservers'),
  ],
)
```

## When to use / when not to

Use it to show where someone is in a flow of three to six steps. For the flow itself (content plus Back and Continue), use `KumoStepper`. Do not use it for navigation between unrelated pages.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `steps` | `List<KumoStepsItem>` | required | |
| `current` | `int` | required | Step in progress, 0-based; `steps.length` marks all complete |
| `orientation` | `KumoStepsOrientation` | `auto` | `auto`, `horizontal` or `vertical` |
| `onStepPress` | `ValueChanged<int>?` | | Makes steps buttons |
| `stateLabels` | `Map<KumoStepsState, String>` | `kumoStepsStateLabels` | Screen reader names per state |
| `semanticLabel` | `String?` | | |

`KumoStepsItem(title:, description:, state:)`. `state` overrides the derived state (before `current`: complete; at `current`: current; after: upcoming).

States and markers (24px circles), so status never rests on color:

| `KumoStepsState` | Marker | Title |
| --- | --- | --- |
| `upcoming` | outlined circle, number | subtle |
| `current` | filled brand circle with a soft halo, number | medium weight |
| `complete` | filled brand circle, check | default |
| `error` | filled danger circle, cross | danger text |

`auto` is horizontal when the window is at least 768px wide and every step gets 150px; vertical otherwise.

## Examples

### Every state

```dart
const KumoSteps(
  orientation: KumoStepsOrientation.vertical,
  current: 2,
  steps: [
    KumoStepsItem(title: 'Create R2 bucket', description: 'assets'),
    KumoStepsItem(title: 'Upload files', description: '48 files'),
    KumoStepsItem(title: 'Connect domain', description: 'cdn.example.com'),
    KumoStepsItem(title: 'Verify certificate', description: 'DNS record not found', state: KumoStepsState.error),
  ],
)
```

### Going back

```dart
KumoSteps(
  steps: const [KumoStepsItem(title: 'Plan'), KumoStepsItem(title: 'DNS'), KumoStepsItem(title: 'Done')],
  current: step,
  onStepPress: (i) {
    if (i < step) setState(() => step = i);
  },
)
```

## Accessibility

Each step is one node: label "title, state" (for example "Add DNS records, Current step") and value "Step 2 of 3". With `onStepPress` it is a button, reachable with Tab and Enter. Translate the state names with `stateLabels`.

## Motion

Markers change fill over 200ms. When a step completes, the brand fill grows along the connector after it from the start (top in vertical layouts) and the number gives way to a check that lands with Kumo's small bounce (`KumoCurves.bounce`); the error cross lands the same way. Stepping back drains the connector from wherever it is. Reduced motion is instant.

## Mobile

Vertical below 768px, with descriptions under each title. Pressable steps are 44px tall on touch. Titles wrap at 2x text; the marker number stays at its size because the step's accessible label carries it.
