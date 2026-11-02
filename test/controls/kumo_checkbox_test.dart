import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

/// Holds a value for a controlled widget under test.
Widget controlled<T>(T initial, Widget Function(T value, ValueChanged<T> set) build) {
  var value = initial;
  return StatefulBuilder(builder: (context, setState) => build(value, (v) => setState(() => value = v)));
}

const _items = [
  KumoCheckboxGroupItem(value: 'deploys', label: 'Failed deployments'),
  KumoCheckboxGroupItem(value: 'usage', label: 'Usage limits'),
  KumoCheckboxGroupItem(value: 'tokens', label: 'Expiring API tokens', disabled: true),
];

void main() {
  group('KumoCheckbox', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders every state in $brightness', (tester) async {
        await pumpKumo(
          tester,
          brightness: brightness,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KumoCheckbox(label: 'Off', checked: false, onCheckedChange: (_) {}),
              KumoCheckbox(label: 'On', checked: true, onCheckedChange: (_) {}),
              KumoCheckbox(label: 'Some', checked: false, indeterminate: true, onCheckedChange: (_) {}),
              KumoCheckbox(label: 'Error', checked: false, error: 'Required', onCheckedChange: (_) {}),
              KumoCheckbox(
                label: 'Card',
                description: 'Shown in card appearance',
                appearance: KumoCheckboxAppearance.card,
                checked: true,
                onCheckedChange: (_) {},
              ),
              const KumoCheckbox(semanticLabel: 'Select row', checked: false, disabled: true),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Required'), findsOneWidget);
      });
    }

    testWidgets('tap reports the next value; indeterminate reports true', (tester) async {
      final calls = <bool>[];
      await pumpKumo(tester, KumoCheckbox(label: 'Purge cache', checked: false, onCheckedChange: calls.add));
      await tester.tap(find.text('Purge cache'));
      await pumpKumo(tester, KumoCheckbox(label: 'Purge cache', checked: true, onCheckedChange: calls.add));
      await tester.tap(find.text('Purge cache'));
      await pumpKumo(
        tester,
        KumoCheckbox(label: 'Purge cache', checked: false, indeterminate: true, onCheckedChange: calls.add),
      );
      await tester.tap(find.text('Purge cache'));
      expect(calls, [true, false, true]);
    });

    testWidgets('disabled and callback-less checkboxes do not fire', (tester) async {
      var calls = 0;
      await pumpKumo(
        tester,
        KumoCheckbox(label: 'Locked', checked: false, disabled: true, onCheckedChange: (_) => calls++),
      );
      await tester.tap(find.text('Locked'));
      await pumpKumo(tester, const KumoCheckbox(label: 'Read only', checked: true));
      await tester.tap(find.text('Read only'));
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('controlled: reflects the value it is given', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        controlled<bool>(false, (v, set) => KumoCheckbox(label: 'Always use HTTPS', checked: v, onCheckedChange: set)),
      );
      expect(
        tester.getSemantics(find.byType(KumoCheckbox)),
        containsSemantics(isChecked: false, hasCheckedState: true),
      );
      await tester.tap(find.byType(KumoCheckbox));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byType(KumoCheckbox)), containsSemantics(isChecked: true, hasCheckedState: true));
      handle.dispose();
    });

    testWidgets('semantics: checkbox role, label, mixed state, not a button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        KumoCheckbox(label: 'Select all', checked: false, indeterminate: true, onCheckedChange: (_) {}),
      );
      expect(
        tester.getSemantics(find.byType(KumoCheckbox)),
        containsSemantics(
          label: 'Select all',
          hasCheckedState: true,
          isCheckStateMixed: true,
          isButton: false,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await pumpKumo(
        tester,
        KumoCheckbox(semanticLabel: 'Select image-resizer', checked: true, onCheckedChange: (_) {}),
      );
      expect(find.bySemanticsLabel('Select image-resizer'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('keyboard: Tab focuses, Space toggles', (tester) async {
      final calls = <bool>[];
      await pumpKumo(tester, KumoCheckbox(label: 'Purge cache', checked: false, onCheckedChange: calls.add));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, [true]);
    });

    testWidgets('the check mark animates in with motion and is instant without', (tester) async {
      await pumpKumo(
        tester,
        controlled<bool>(false, (v, set) => KumoCheckbox(label: 'Purge cache', checked: v, onCheckedChange: set)),
      );
      await tester.tap(find.byType(KumoCheckbox));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();

      await pumpKumo(
        tester,
        controlled<bool>(false, (v, set) => KumoCheckbox(label: 'Reduced', checked: v, onCheckedChange: set)),
        disableAnimations: true,
      );
      await tester.tap(find.byType(KumoCheckbox));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('hit area is 44px tall on touch while the box stays 16px', (tester) async {
      await pumpKumo(tester, KumoCheckbox(semanticLabel: 'Select row', checked: false, onCheckedChange: (_) {}));
      final hit = tester.getSize(find.byType(KumoPressable));
      expect(hit.width, greaterThanOrEqualTo(44));
      expect(hit.height, greaterThanOrEqualTo(44));
      final box = find.descendant(of: find.byType(KumoCheckbox), matching: find.byType(DecoratedBox)).first;
      expect(tester.getSize(box), const Size(16, 16));
    });

    testWidgets('label first places the box after the label, in RTL too', (tester) async {
      await pumpKumo(
        tester,
        KumoCheckbox(label: 'Remember me', controlFirst: false, checked: false, onCheckedChange: (_) {}),
      );
      final box = find.descendant(of: find.byType(KumoCheckbox), matching: find.byType(DecoratedBox)).first;
      expect(tester.getCenter(box).dx, greaterThan(tester.getCenter(find.text('Remember me')).dx));
      await pumpKumo(
        tester,
        textDirection: TextDirection.rtl,
        KumoCheckbox(label: 'Remember me', checked: false, onCheckedChange: (_) {}),
      );
      expect(tester.getCenter(box).dx, greaterThan(tester.getCenter(find.text('Remember me')).dx));
    });

    testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
      await pumpKumo(
        tester,
        textScale: 2,
        Padding(
          padding: const EdgeInsets.all(16),
          child: KumoCheckbox(
            label: 'Delete the R2 bucket assets and every object it contains',
            description: 'This cannot be undone.',
            labelTooltip: 'Objects are removed within a minute',
            required: false,
            checked: true,
            onCheckedChange: (_) {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('KumoCheckboxGroup', () {
    testWidgets('renders legend, items, error and description in light and dark', (tester) async {
      for (final brightness in Brightness.values) {
        await pumpKumo(
          tester,
          brightness: brightness,
          KumoCheckboxGroup<String>(
            legend: 'Email alerts',
            description: 'Sent to the account owner.',
            error: 'Pick at least one alert',
            value: const ['deploys'],
            onValueChange: (_) {},
            items: _items,
          ),
        );
        expect(find.text('Email alerts'), findsOneWidget);
        expect(find.text('Pick at least one alert'), findsOneWidget);
        expect(find.text('Sent to the account owner.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('checking appends, unchecking removes, disabled items ignore taps', (tester) async {
      final calls = <List<String>>[];
      await pumpKumo(
        tester,
        KumoCheckboxGroup<String>(value: const ['deploys'], onValueChange: calls.add, items: _items),
      );
      await tester.tap(find.text('Usage limits'));
      await tester.tap(find.text('Failed deployments'));
      await tester.tap(find.text('Expiring API tokens'));
      expect(calls, [
        ['deploys', 'usage'],
        <String>[],
      ]);
    });

    testWidgets('controlled list drives the checked state', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        controlled<List<String>>(
          const [],
          (v, set) => KumoCheckboxGroup<String>(value: v, onValueChange: set, items: _items),
        ),
      );
      await tester.tap(find.text('Usage limits'));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.text('Usage limits')), containsSemantics(isChecked: true));
      expect(tester.getSemantics(find.text('Failed deployments')), containsSemantics(isChecked: false));
      handle.dispose();
    });

    testWidgets('the error is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        KumoCheckboxGroup<String>(
          error: 'Pick at least one alert',
          value: const [],
          onValueChange: (_) {},
          items: _items,
        ),
      );
      expect(tester.getSemantics(find.text('Pick at least one alert')), containsSemantics(isLiveRegion: true));
      handle.dispose();
    });

    testWidgets('hidden legend stays available to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        KumoCheckboxGroup<String>(
          legend: 'Alerts',
          hideLegend: true,
          value: const [],
          onValueChange: (_) {},
          items: _items,
        ),
      );
      expect(find.text('Alerts'), findsNothing);
      expect(find.bySemanticsLabel('Alerts'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('card groups render as a column and a two-column grid at 390px with 2x text', (tester) async {
      for (final orientation in Axis.values) {
        await pumpKumo(
          tester,
          textScale: 2,
          Padding(
            padding: const EdgeInsets.all(16),
            child: KumoCheckboxGroup<String>(
              legend: 'Where should this profile scan?',
              appearance: KumoCheckboxAppearance.card,
              orientation: orientation,
              value: const ['web'],
              onValueChange: (_) {},
              items: const [
                KumoCheckboxGroupItem(value: 'web', label: 'Web traffic', description: 'Gateway HTTP policies.'),
                KumoCheckboxGroupItem(value: 'saas', label: 'SaaS storage', description: 'Connected cloud apps.'),
                KumoCheckboxGroupItem(value: 'mail', label: 'Outbound email', description: 'Mail leaving the org.'),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('each checkbox is its own Tab stop', (tester) async {
      final calls = <List<String>>[];
      await pumpKumo(tester, KumoCheckboxGroup<String>(value: const [], onValueChange: calls.add, items: _items));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls, [
        ['usage'],
      ]);
    });
  });

  testWidgets('the box presses in on pointer-down, and not under reduced motion', (tester) async {
    double scale() => tester
        .widget<ScaleTransition>(find.descendant(of: find.byType(KumoCheckbox), matching: find.byType(ScaleTransition)))
        .scale
        .value;
    await pumpKumo(tester, KumoCheckbox(label: 'Purge cache', checked: false, onCheckedChange: (_) {}));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Purge cache')));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 30));
    expect(scale(), inExclusiveRange(0.9, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);

    await pumpKumo(
      tester,
      KumoCheckbox(label: 'Purge cache', checked: false, onCheckedChange: (_) {}),
      disableAnimations: true,
    );
    final g2 = await tester.startGesture(tester.getCenter(find.text('Purge cache')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(), 1);
    expect(tester.hasRunningAnimations, isFalse);
    await g2.up();
  });
}
