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
  KumoRadio(value: 'basic', label: 'No query string'),
  KumoRadio(value: 'simplified', label: 'Ignore query string', disabled: true),
  KumoRadio(value: 'aggressive', label: 'Standard'),
];

Widget _group({
  String? value,
  ValueChanged<String>? onValueChange,
  KumoRadioAppearance appearance = KumoRadioAppearance.base,
  Axis orientation = Axis.vertical,
  List<KumoRadio<String>> items = _levels,
  String? error,
  bool disabled = false,
}) =>
    KumoRadioGroup<String>(
      legend: 'Cache level',
      description: 'Applies to every route on example.com.',
      error: error,
      value: value,
      onValueChange: onValueChange,
      appearance: appearance,
      orientation: orientation,
      disabled: disabled,
      items: items,
    );

void main() {
  for (final appearance in KumoRadioAppearance.values) {
    testWidgets('renders $appearance in light and dark, both orientations', (tester) async {
      for (final brightness in Brightness.values) {
        for (final orientation in Axis.values) {
          await pumpKumo(
            tester,
            brightness: brightness,
            _group(
              value: 'basic',
              onValueChange: (_) {},
              appearance: appearance,
              orientation: orientation,
              error: 'Pick a level',
            ),
          );
          expect(find.text('Cache level'), findsOneWidget);
          expect(find.text('Pick a level'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  testWidgets('tap selects; disabled items and disabled groups do not fire', (tester) async {
    final calls = <String>[];
    await pumpKumo(tester, _group(value: 'basic', onValueChange: calls.add));
    await tester.tap(find.text('Standard'));
    await tester.tap(find.text('Ignore query string'));
    await tester.tap(find.text('No query string'));
    expect(calls, ['aggressive']);
    await pumpKumo(tester, _group(value: 'basic', onValueChange: calls.add, disabled: true));
    await tester.tap(find.text('Standard'));
    expect(calls, ['aggressive']);
  });

  testWidgets('controlled: the selected item follows the value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, controlled<String?>('basic', (v, set) => _group(value: v, onValueChange: set)));
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('Standard')), containsSemantics(isChecked: true, isInMutuallyExclusiveGroup: true));
    expect(tester.getSemantics(find.text('No query string')), containsSemantics(isChecked: false));
    handle.dispose();
  });

  testWidgets('semantics: radio items in a radio group, with labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, _group(value: 'aggressive', onValueChange: (_) {}));
    expect(
      tester.getSemantics(find.text('Standard')),
      containsSemantics(
        label: 'Standard',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        isButton: false,
        hasTapAction: true,
      ),
    );
    expect(tester.getSemantics(find.text('Ignore query string')), containsSemantics(isEnabled: false));
    handle.dispose();
  });

  testWidgets('keyboard: Tab enters at the selected item, arrows move the selection and skip disabled', (tester) async {
    await pumpKumo(
      tester,
      controlled<String?>(
        'aggressive',
        (v, set) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _group(value: v, onValueChange: set),
            KumoButton(label: 'Save rules', onPress: () {}),
            KumoText('Selected: $v'),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.debugLabel, 'KumoRadio 2');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Selected: basic'), findsOneWidget, reason: 'wraps past the end');
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'KumoRadio 0');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('Selected: aggressive'), findsOneWidget, reason: 'skips the disabled item');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.text('Selected: basic'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(find.text('Selected: aggressive'), findsOneWidget);

    // Tab leaves the group once, straight to the next control.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'KumoPressable');
  });

  testWidgets('keyboard: Left and Right are mirrored in RTL', (tester) async {
    await pumpKumo(
      tester,
      textDirection: TextDirection.rtl,
      controlled<String?>(
        'basic',
        (v, set) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _group(value: v, onValueChange: set, orientation: Axis.horizontal, items: const [
              KumoRadio(value: 'basic', label: 'A'),
              KumoRadio(value: 'aggressive', label: 'B'),
            ]),
            KumoText('Selected: $v'),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Selected: aggressive'), findsOneWidget);
  });

  testWidgets('with no selection, Tab enters at the first enabled item', (tester) async {
    await pumpKumo(tester, _group(value: null, onValueChange: (_) {}));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'KumoRadio 0');
  });

  testWidgets('segmented: tap selects, fits 390px with long labels by scrolling', (tester) async {
    final calls = <String>[];
    await pumpKumo(
      tester,
      _group(value: '1', onValueChange: calls.add, appearance: KumoRadioAppearance.segmented, items: const [
        KumoRadio(value: '1', label: '1h'),
        KumoRadio(value: '12', label: '12h'),
        KumoRadio(value: '24', label: '24h'),
      ]),
    );
    await tester.tap(find.text('24h'));
    expect(calls, ['24']);
    // Segments keep Kumo's 34px bar while their hit area is 44px on touch.
    expect(tester.getSize(find.ancestor(of: find.text('12h'), matching: find.byType(KumoPressable))).height, 44);

    await pumpKumo(
      tester,
      textScale: 2,
      _group(value: 'auto', onValueChange: (_) {}, appearance: KumoRadioAppearance.segmented, items: const [
        KumoRadio(value: 'auto', label: 'Automatic processing'),
        KumoRadio(value: 'manual', label: 'Manual configuration'),
      ]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('card items show descriptions and the selected tint', (tester) async {
    await pumpKumo(
      tester,
      textScale: 2,
      _group(value: 'pro', onValueChange: (_) {}, appearance: KumoRadioAppearance.card, items: const [
        KumoRadio(value: 'free', label: 'Free', description: 'For personal projects and testing.'),
        KumoRadio(value: 'pro', label: 'Pro', description: 'Image optimization and more page rules.'),
      ]),
    );
    expect(find.text('Image optimization and more page rules.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the dot animates in, and is instant under reduced motion', (tester) async {
    await pumpKumo(tester, controlled<String?>('basic', (v, set) => _group(value: v, onValueChange: set)));
    await tester.tap(find.text('Standard'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    await pumpKumo(
      tester,
      disableAnimations: true,
      controlled<String?>('basic', (v, set) => _group(value: v, onValueChange: set)),
    );
    await tester.tap(find.text('Standard'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('KumoRadio outside a group asserts', (tester) async {
    await pumpKumo(tester, const KumoRadio(value: 'x', label: 'Orphan'));
    expect(tester.takeException(), isAssertionError);
  });

  Color? labelColor(WidgetTester tester, String text) =>
      tester.widget<RichText>(find.descendant(of: find.text(text), matching: find.byType(RichText))).text.style?.color;

  const segments = [
    KumoRadio(value: '1', label: '1h'),
    KumoRadio(value: '12', label: '12h'),
    KumoRadio(value: '24', label: '24h'),
  ];

  testWidgets('segmented: the selected fill slides from the previous segment', (tester) async {
    await pumpKumo(
      tester,
      controlled<String?>(
        '1',
        (v, set) => _group(value: v, onValueChange: set, appearance: KumoRadioAppearance.segmented, items: segments),
      ),
    );
    final off = labelColor(tester, '24h')!;
    final on = labelColor(tester, '1h')!;
    await tester.tap(find.text('24h'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // Part of the way over: the target label is between its off and on color.
    final mid = labelColor(tester, '24h')!;
    expect(mid, isNot(off));
    expect(mid, isNot(on));
    await tester.pumpAndSettle();
    expect(labelColor(tester, '24h'), on);
    expect(labelColor(tester, '1h'), off);
  });

  testWidgets('segmented: a tap mid-slide retargets from where the fill is', (tester) async {
    await pumpKumo(
      tester,
      controlled<String?>(
        '1',
        (v, set) => _group(value: v, onValueChange: set, appearance: KumoRadioAppearance.segmented, items: segments),
      ),
    );
    await tester.tap(find.text('24h'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final before = labelColor(tester, '1h');
    await tester.tap(find.text('1h'));
    await tester.pump();
    // No jump back to the start: the first label keeps its in-between color.
    expect(labelColor(tester, '1h'), before);
    await tester.pumpAndSettle();
  });

  testWidgets('segmented: reduced motion moves the fill at once', (tester) async {
    await pumpKumo(
      tester,
      disableAnimations: true,
      controlled<String?>(
        '1',
        (v, set) => _group(value: v, onValueChange: set, appearance: KumoRadioAppearance.segmented, items: segments),
      ),
    );
    final on = labelColor(tester, '1h');
    await tester.tap(find.text('24h'));
    await tester.pump();
    expect(labelColor(tester, '24h'), on);
    // One frame for the bar's scroll view to settle the tap, then nothing.
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the circle presses in on pointer-down, and not under reduced motion', (tester) async {
    Iterable<double> scales() => tester
        .widgetList<ScaleTransition>(find.descendant(of: find.byType(KumoRadioGroup<String>), matching: find.byType(ScaleTransition)))
        .map((s) => s.scale.value);
    await pumpKumo(tester, _group(value: 'basic', onValueChange: (_) {}));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Standard')));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 30));
    expect(scales().any((s) => s > 0.9 && s < 1), isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scales().every((s) => s == 1), isTrue);

    await pumpKumo(tester, _group(value: 'basic', onValueChange: (_) {}), disableAnimations: true);
    final g2 = await tester.startGesture(tester.getCenter(find.text('Standard')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(scales().every((s) => s == 1), isTrue);
    expect(tester.hasRunningAnimations, isFalse);
    await g2.up();
  });
}
