@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('controls golden', (tester) async {
    tester.view.physicalSize = const Size(800, 1200) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      goldenPair(
        width: 380,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                KumoCheckbox(label: 'Off', checked: false, onCheckedChange: (_) {}),
                KumoCheckbox(label: 'On', checked: true, onCheckedChange: (_) {}),
                KumoCheckbox(label: 'Some', checked: false, indeterminate: true, onCheckedChange: (_) {}),
                KumoCheckbox(label: 'Error', checked: false, variant: KumoCheckboxVariant.error, onCheckedChange: (_) {}),
                const KumoCheckbox(label: 'Disabled', checked: true),
              ],
            ),
            KumoCheckboxGroup<String>(
              legend: 'Scan targets',
              appearance: KumoCheckboxAppearance.card,
              value: const ['web'],
              onValueChange: (_) {},
              items: const [
                KumoCheckboxGroupItem(value: 'web', label: 'Web traffic', description: 'Gateway HTTP policies.'),
                KumoCheckboxGroupItem(value: 'mail', label: 'Outbound email', description: 'Mail leaving the org.'),
              ],
            ),
            KumoRadioGroup<String>(
              legend: 'Duration',
              appearance: KumoRadioAppearance.segmented,
              value: '12',
              onValueChange: (_) {},
              items: const [
                KumoRadio(value: '1', label: '1h'),
                KumoRadio(value: '12', label: '12h'),
                KumoRadio(value: '24', label: '24h'),
              ],
            ),
            KumoRadioGroup<String>(
              legend: 'Plan',
              orientation: Axis.horizontal,
              value: 'b',
              onValueChange: (_) {},
              items: const [
                KumoRadio(value: 'a', label: 'Free'),
                KumoRadio(value: 'b', label: 'Pro'),
                KumoRadio(value: 'c', label: 'Business'),
              ],
            ),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                KumoSwitch(label: 'Off', checked: false, onCheckedChange: (_) {}),
                KumoSwitch(label: 'On', checked: true, onCheckedChange: (_) {}),
                KumoSwitch(label: 'Neutral', variant: KumoSwitchVariant.neutral, checked: true, onCheckedChange: (_) {}),
                KumoSwitch(label: 'Small', size: KumoSwitchSize.sm, checked: true, onCheckedChange: (_) {}),
              ],
            ),
            KumoSlider(label: 'Volume', value: 40, onValueChange: (_) {}),
            KumoSlider.range(label: 'Range', size: KumoSliderSize.sm, values: (start: 25, end: 75), onValuesChange: (_) {}),
            KumoButtonGroup(
              variant: KumoButtonVariant.primary,
              children: [
                KumoButtonGroupButton(label: 'Deploy', onPress: () {}),
                KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More', onPress: () {}),
              ],
            ),
            KumoButtonGroup(
              children: [
                KumoButtonGroupButton(label: 'Save', onPress: () {}),
                KumoButtonGroupButton(label: 'Copy', onPress: () {}),
                KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More', onPress: () {}),
              ],
            ),
            Row(
              spacing: 8,
              children: [
                KumoToggle(icon: KumoIcons.textB, semanticLabel: 'Bold', pressed: true, onPressedChange: (_) {}),
                KumoToggle(icon: KumoIcons.textItalic, semanticLabel: 'Italic', pressed: false, onPressedChange: (_) {}),
                KumoToggle(label: 'Errors', variant: KumoToggleVariant.outline, pressed: false, onPressedChange: (_) {}),
              ],
            ),
            KumoToggleGroup<String>.multiple(
              values: const ['b', 'c'],
              onValuesChange: (_) {},
              items: const [
                KumoToggleGroupItem(value: 'a', label: 'GET'),
                KumoToggleGroupItem(value: 'b', label: 'POST'),
                KumoToggleGroupItem(value: 'c', label: 'PUT'),
                KumoToggleGroupItem(value: 'd', label: 'DELETE'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('../goldens/controls.png'));
  });
}
