import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget controlled<T>(T initial, Widget Function(T value, ValueChanged<T> set) build) {
  var value = initial;
  return StatefulBuilder(builder: (context, setState) => build(value, (v) => setState(() => value = v)));
}

const _levels = [
  KumoToggleGroupItem(value: 'info', label: 'Info'),
  KumoToggleGroupItem(value: 'warn', label: 'Warn', disabled: true),
  KumoToggleGroupItem(value: 'error', label: 'Error'),
];

void main() {
  group('KumoToggle', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders variants, sizes and states in $brightness', (tester) async {
        await pumpKumo(
          tester,
          brightness: brightness,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final variant in KumoToggleVariant.values)
                for (final size in KumoToggleSize.values)
                  for (final pressed in [false, true])
                    KumoToggle(
                      label: 'Errors',
                      icon: KumoIcons.funnel,
                      variant: variant,
                      size: size,
                      pressed: pressed,
                      onPressedChange: (_) {},
                    ),
              const KumoToggle(icon: KumoIcons.textB, semanticLabel: 'Bold', pressed: true, disabled: true),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tap flips pressed; disabled does not fire', (tester) async {
      final calls = <bool>[];
      await pumpKumo(tester, KumoToggle(label: 'Errors only', pressed: false, onPressedChange: calls.add));
      await tester.tap(find.text('Errors only'));
      await pumpKumo(tester, KumoToggle(label: 'Errors only', pressed: true, onPressedChange: calls.add));
      await tester.tap(find.text('Errors only'));
      await pumpKumo(tester, KumoToggle(label: 'Errors only', pressed: true, disabled: true, onPressedChange: calls.add));
      await tester.tap(find.text('Errors only'));
      expect(calls, [true, false]);
    });

    testWidgets('semantics: a toggle button with its state', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        controlled<bool>(false, (v, set) => KumoToggle(icon: KumoIcons.textB, semanticLabel: 'Bold', pressed: v, onPressedChange: set)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bold')),
        containsSemantics(isButton: true, hasToggledState: true, isToggled: false, hasTapAction: true),
      );
      await tester.tap(find.byType(KumoToggle));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.bySemanticsLabel('Bold')), containsSemantics(isToggled: true));
      handle.dispose();
    });

    testWidgets('keyboard: Space toggles the focused toggle', (tester) async {
      final calls = <bool>[];
      await pumpKumo(tester, KumoToggle(label: 'Wrap lines', pressed: false, onPressedChange: calls.add));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(calls, [true]);
    });

    testWidgets('icon-only toggles have a 44px hit area on touch', (tester) async {
      await pumpKumo(tester, KumoToggle(icon: KumoIcons.textB, semanticLabel: 'Bold', pressed: false, onPressedChange: (_) {}));
      final size = tester.getSize(find.byType(KumoPressable));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('KumoToggleGroup', () {
    for (final variant in KumoToggleVariant.values) {
      testWidgets('renders $variant in light and dark', (tester) async {
        for (final brightness in Brightness.values) {
          await pumpKumo(
            tester,
            brightness: brightness,
            KumoToggleGroup<String>.multiple(variant: variant, values: const ['info', 'error'], onValuesChange: (_) {}, items: _levels),
          );
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('single: selects, deselects, and can require a value', (tester) async {
      final calls = <String?>[];
      await pumpKumo(tester, KumoToggleGroup<String>(value: 'info', onValueChange: calls.add, items: _levels));
      await tester.tap(find.text('Error'));
      await tester.tap(find.text('Info'));
      await tester.tap(find.text('Warn'));
      expect(calls, ['error', null]);
      await pumpKumo(
        tester,
        KumoToggleGroup<String>(value: 'info', allowDeselect: false, onValueChange: calls.add, items: _levels),
      );
      await tester.tap(find.text('Info'));
      expect(calls, ['error', null]);
    });

    testWidgets('multiple: appends and removes values', (tester) async {
      final calls = <List<String>>[];
      await pumpKumo(tester, KumoToggleGroup<String>.multiple(values: const ['info'], onValuesChange: calls.add, items: _levels));
      await tester.tap(find.text('Error'));
      await tester.tap(find.text('Info'));
      expect(calls, [
        ['info', 'error'],
        <String>[],
      ]);
    });

    testWidgets('semantics: single is a radio group, multiple are toggle buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(tester, KumoToggleGroup<String>(semanticLabel: 'Log level', value: 'info', onValueChange: (_) {}, items: _levels));
      expect(
        tester.getSemantics(find.text('Info')),
        containsSemantics(isInMutuallyExclusiveGroup: true, isChecked: true, hasCheckedState: true),
      );
      expect(find.bySemanticsLabel('Log level'), findsOneWidget);
      await pumpKumo(tester, KumoToggleGroup<String>.multiple(values: const ['info'], onValuesChange: (_) {}, items: _levels));
      expect(tester.getSemantics(find.text('Info')), containsSemantics(isButton: true, hasToggledState: true, isToggled: true));
      handle.dispose();
    });

    testWidgets('keyboard: one Tab stop, arrows move focus skipping disabled, Space toggles', (tester) async {
      await pumpKumo(
        tester,
        controlled<List<String>>(
          const [],
          (v, set) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KumoToggleGroup<String>.multiple(values: v, onValuesChange: set, items: _levels),
              KumoButton(label: 'Apply', onPress: () {}),
              KumoText('Values: ${v.join(',')}'),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'KumoToggleGroup 0');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'KumoToggleGroup 2');
      expect(find.text('Values: '), findsOneWidget, reason: 'arrows move focus, not the value');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.text('Values: error'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'KumoToggleGroup 0');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'KumoPressable');
    });

    testWidgets('segmented items keep the 34px bar with a 44px hit area on touch', (tester) async {
      await pumpKumo(tester, KumoToggleGroup<String>(value: 'info', onValueChange: (_) {}, items: _levels));
      expect(tester.getSize(find.ancestor(of: find.text('Info'), matching: find.byType(KumoPressable))).height, 44);
    });

    testWidgets('a wide group scrolls instead of overflowing at 390px with 2x text', (tester) async {
      await pumpKumo(
        tester,
        textScale: 2,
        KumoToggleGroup<String>.multiple(
          values: const ['GET'],
          onValuesChange: (_) {},
          items: [
            for (final m in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']) KumoToggleGroupItem(value: m, label: m),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('works inside an unbounded row such as a toolbar', (tester) async {
      await pumpKumo(
        tester,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              KumoToggleGroup<String>(value: 'info', onValueChange: (_) {}, items: _levels),
              KumoToggleGroup<String>(variant: KumoToggleVariant.ghost, value: 'info', onValueChange: (_) {}, items: _levels),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  Color? labelColor(WidgetTester tester, String text) =>
      tester.widget<RichText>(find.descendant(of: find.text(text), matching: find.byType(RichText))).text.style?.color;

  testWidgets('single segmented group: the fill slides between items; instant under reduced motion', (tester) async {
    Widget group() => controlled<String?>(
      'info',
      (v, set) => KumoToggleGroup<String>(value: v, onValueChange: set, items: _levels),
    );
    await pumpKumo(tester, group());
    final off = labelColor(tester, 'Error')!;
    final on = labelColor(tester, 'Info')!;
    await tester.tap(find.text('Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final mid = labelColor(tester, 'Error')!;
    expect(mid, isNot(off));
    expect(mid, isNot(on));
    await tester.pumpAndSettle();
    expect(labelColor(tester, 'Error'), on);

    await pumpKumo(tester, group(), disableAnimations: true);
    await tester.tap(find.text('Error'));
    await tester.pump();
    expect(labelColor(tester, 'Error'), on);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
