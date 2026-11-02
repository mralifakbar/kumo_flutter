# KumoStepper

A multi-step flow: `KumoSteps`, the current step's content and Back / Continue buttons, with a named final action. For onboarding flows such as adding a zone or creating a Worker.

Kumo reference: none (shadcn-inspired, Kumo-styled)

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoStepper(
  value: step,
  onValueChange: (v) => setState(() => step = v),
  completeLabel: 'Activate zone',
  onComplete: () {},
  steps: const [
    KumoStepperStep(title: 'Add site', child: KumoText('Enter example.com')),
    KumoStepperStep(title: 'Review DNS', child: KumoText('12 records found')),
    KumoStepperStep(title: 'Change nameservers', child: KumoText('Update them at your registrar')),
  ],
)
```

## When to use / when not to

Use it when a task has ordered steps that each need input or review. For a long single form, use sections; for showing progress only, use `KumoSteps`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `steps` | `List<KumoStepperStep>` | required | |
| `value` | `int` | required | Current step, 0-based |
| `onValueChange` | `ValueChanged<int>?` | required | Back, Continue and step presses |
| `onComplete` | `VoidCallback?` | | The primary button on the last step |
| `completeLabel` | `String?` | `KumoStrings.finish` | Name the outcome: "Create Worker", "Activate zone" |
| `nextLabel` | `String?` | `KumoStrings.next` | |
| `backLabel` | `String?` | `KumoStrings.previous` | |
| `orientation` | `KumoStepsOrientation` | `auto` | |
| `linear` | `bool` | `true` | Only earlier steps can be pressed; later ones need Continue |
| `completing` | `bool` | `false` | Shows the final button as loading |
| `stateLabels` | `Map<KumoStepsState, String>` | `kumoStepsStateLabels` | |
| `semanticLabel` | `String?` | | |

`KumoStepperStep(title:, child:, description:, state:, canContinue:)`. Set `canContinue: false` until the step is valid, and `state: KumoStepsState.error` to flag a failed check.

## Examples

### Validation

```dart
KumoStepper(
  value: step,
  onValueChange: (v) => setState(() => step = v),
  completeLabel: 'Create Worker',
  completing: creating,
  onComplete: () {},
  steps: [
    KumoStepperStep(
      title: 'Name',
      canContinue: name.isNotEmpty,
      child: const KumoText('Lowercase letters, numbers and dashes'),
    ),
    const KumoStepperStep(title: 'Deploy', child: KumoText('Deploys to image-resizer.example.workers.dev')),
  ],
)
```

## Accessibility

Steps are announced as in `KumoSteps`; earlier steps are buttons in linear mode. Back and Continue are `KumoButton`s in Tab order after the content. When the step changes, the new content replaces the old; move focus into it yourself if the step starts with a field.

## Motion

The steps animate as in `KumoSteps`: the connector fills from the start, the check lands with a small bounce. Horizontal layouts cross-fade the content in 200ms while the content area eases to the new step's height, so the buttons below slide instead of jumping; the outgoing content is excluded from focus and screen readers. Vertical layouts open the current step's content under its title with `KumoCollapsiblePanel` and close the previous one. Reduced motion switches instantly.

## Mobile

Vertical below 768px, with the content and buttons under the current step, so the flow reads top to bottom at 390px. Buttons wrap to a second line at 2x text.
