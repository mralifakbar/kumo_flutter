import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget controlled<T>(T initial, Widget Function(T value, ValueChanged<T> set) build) {
  var value = initial;
  return StatefulBuilder(builder: (context, setState) => build(value, (v) => setState(() => value = v)));
}

Finder thumb(int i) => find.byWidgetPredicate((w) => w is Focus && w.focusNode?.debugLabel == 'KumoSlider thumb $i');

/// A 300px slider: the inner track is 294px, thumb centers run from 11 to
/// 289px from the slider's left edge.
Widget sized(Widget child) => SizedBox(width: 300, child: child);

double centerFor(WidgetTester tester, double fraction) =>
    tester.getTopLeft(find.byType(KumoSlider)).dx + 11 + fraction * 278;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders sizes, range and disabled in $brightness', (tester) async {
      await pumpKumo(
        tester,
        brightness: brightness,
        sized(
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              KumoSlider(label: 'Base', value: 40, onValueChange: (_) {}),
              KumoSlider(label: 'Small', size: KumoSliderSize.sm, value: 30, onValueChange: (_) {}),
              KumoSlider.range(label: 'Range', values: (start: 25, end: 75), onValuesChange: (_) {}),
              const KumoSlider(label: 'Locked', value: 70, disabled: true),
            ],
          ),
        ),
      );
      expect(find.text('40'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the thumb tracks the finger 1:1, keeping the grab offset', (tester) async {
    final changes = <double>[];
    final commits = <double>[];
    await pumpKumo(
      tester,
      sized(
        controlled<double>(
          50,
          (v, set) => KumoSlider(
            label: 'Volume',
            value: v,
            onValueChange: (next) => set((changes..add(next)).last),
            onValueCommitted: commits.add,
          ),
        ),
      ),
    );
    final start = tester.getCenter(thumb(0));
    expect(start.dx, closeTo(centerFor(tester, 0.5), 0.01));
    final gesture = await tester.startGesture(start + const Offset(5, 0));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(13, 0));
    await tester.pump();
    expect(tester.getCenter(thumb(0)).dx, closeTo(start.dx + 53, 0.01));
    expect(changes, isNotEmpty);
    expect(changes.last, (53 / 278 * 100 + 50).roundToDouble());
    expect(commits, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(commits, [changes.last]);
    // Lands on the snapped value.
    expect(tester.getCenter(thumb(0)).dx, closeTo(centerFor(tester, changes.last / 100), 0.01));
  });

  testWidgets('a drag that starts on the track brings the thumb under the finger', (tester) async {
    await pumpKumo(
      tester,
      sized(controlled<double>(0, (v, set) => KumoSlider(label: 'Volume', value: v, onValueChange: set))),
    );
    final target = centerFor(tester, 0.6);
    final y = tester.getCenter(thumb(0)).dy;
    final gesture = await tester.startGesture(Offset(target, y));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(tester.getCenter(thumb(0)).dx, closeTo(target + 20, 0.01));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the track jumps there and commits', (tester) async {
    final commits = <double>[];
    await pumpKumo(
      tester,
      sized(
        controlled<double>(
          0,
          (v, set) => KumoSlider(label: 'Volume', value: v, onValueChange: set, onValueCommitted: commits.add),
        ),
      ),
    );
    await tester.tapAt(Offset(centerFor(tester, 0.25), tester.getCenter(thumb(0)).dy));
    await tester.pumpAndSettle();
    expect(commits, [25]);
    expect(tester.getCenter(thumb(0)).dx, closeTo(centerFor(tester, 0.25), 0.01));
  });

  testWidgets('keyboard: arrows, Page Up/Down, Shift+arrow, Home and End', (tester) async {
    await pumpKumo(
      tester,
      sized(
        controlled<double>(
          50,
          (v, set) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KumoSlider(label: 'Volume', value: v, onValueChange: set),
              KumoText('Value: $v'),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    Future<void> press(LogicalKeyboardKey key, String expected, {bool shift = false}) async {
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(key);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(find.text('Value: $expected'), findsOneWidget, reason: '$key');
    }

    await press(LogicalKeyboardKey.arrowRight, '51.0');
    await press(LogicalKeyboardKey.arrowDown, '50.0');
    await press(LogicalKeyboardKey.pageUp, '60.0');
    await press(LogicalKeyboardKey.pageDown, '50.0');
    await press(LogicalKeyboardKey.arrowRight, '60.0', shift: true);
    await press(LogicalKeyboardKey.home, '0.0');
    await press(LogicalKeyboardKey.arrowLeft, '0.0');
    await press(LogicalKeyboardKey.end, '100.0');
  });

  testWidgets('keyboard: Left and Right are mirrored in RTL', (tester) async {
    final calls = <double>[];
    await pumpKumo(
      tester,
      textDirection: TextDirection.rtl,
      sized(KumoSlider(label: 'Volume', value: 50, onValueChange: calls.add)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(calls, [49]);
    // The minimum sits at the right edge in RTL.
    final thumbAt = tester.getCenter(thumb(0)).dx;
    expect(thumbAt, closeTo(centerFor(tester, 0.5), 0.01));
  });

  testWidgets('semantics: slider with label, value and increase and decrease actions', (tester) async {
    final handle = tester.ensureSemantics();
    final calls = <double>[];
    await pumpKumo(
      tester,
      sized(KumoSlider(label: 'Sampling rate', value: 40, format: (v) => '$v%', onValueChange: calls.add)),
    );
    final node = tester.getSemantics(thumb(0));
    expect(
      node,
      containsSemantics(
        isSlider: true,
        label: 'Sampling rate',
        value: '40.0%',
        increasedValue: '41.0%',
        decreasedValue: '39.0%',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.performAction(find.semantics.byLabel('Sampling rate'), SemanticsAction.increase);
    tester.semantics.performAction(find.semantics.byLabel('Sampling rate'), SemanticsAction.decrease);
    expect(calls, [41, 39]);
    handle.dispose();
  });

  testWidgets('range: thumbs have their own names and never cross', (tester) async {
    final handle = tester.ensureSemantics();
    KumoSliderRange? last;
    await pumpKumo(
      tester,
      sized(
        controlled<KumoSliderRange>(
          (start: 20, end: 40),
          (v, set) => KumoSlider.range(
            values: v,
            thumbSemanticLabel: (i) => i == 0 ? 'Minimum price' : 'Maximum price',
            onValuesChange: (next) => set(last = next),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Minimum price'), findsOneWidget);
    expect(find.bySemanticsLabel('Maximum price'), findsOneWidget);
    final start = tester.getCenter(thumb(0));
    await tester.dragFrom(start, const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(last!.start, 40);
    expect(last!.end, 40);
    handle.dispose();
  });

  testWidgets('step and format: snaps to 0.05 and shows the formatted value', (tester) async {
    double? last;
    await pumpKumo(
      tester,
      sized(
        KumoSlider(
          label: 'Sampling rate',
          value: 0.25,
          min: 0,
          max: 1,
          step: 0.05,
          format: (v) => '${(v * 100).round()}%',
          onValueChange: (v) => last = v,
        ),
      ),
    );
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    await tester.tapAt(Offset(centerFor(tester, 0.62), tester.getCenter(thumb(0)).dy));
    expect(last, 0.6);
  });

  testWidgets('disabled: no callbacks and no focus', (tester) async {
    var calls = 0;
    await pumpKumo(
      tester,
      sized(KumoSlider(label: 'Locked', value: 70, disabled: true, onValueChange: (_) => calls++)),
    );
    await tester.dragFrom(tester.getCenter(thumb(0)), const Offset(-60, 0));
    await tester.tapAt(Offset(centerFor(tester, 0.1), tester.getCenter(thumb(0)).dy));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(calls, 0);
  });

  testWidgets('outside changes spring the thumb, or jump it under reduced motion', (tester) async {
    await pumpKumo(tester, sized(const KumoSlider(label: 'Volume', value: 0)));
    await pumpKumo(tester, sized(const KumoSlider(label: 'Volume', value: 100)), settle: false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    await pumpKumo(tester, disableAnimations: true, sized(const KumoSlider(label: 'Volume', value: 0)));
    await pumpKumo(
      tester,
      disableAnimations: true,
      sized(const KumoSlider(label: 'Volume', value: 100)),
      settle: false,
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.getCenter(thumb(0)).dx, closeTo(centerFor(tester, 1), 0.01));
  });

  testWidgets('text scale 2.0 at 390px does not overflow; badges stay inside', (tester) async {
    await pumpKumo(
      tester,
      textScale: 2,
      Padding(
        padding: const EdgeInsets.all(16),
        child: KumoSlider.range(
          label: 'Response time window (ms)',
          values: (start: 0, end: 1000),
          max: 1000,
          step: 10,
          onValuesChange: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final slider = tester.getRect(find.byType(KumoSlider));
    for (final text in ['0', '1000']) {
      for (final element in find.text(text).evaluate()) {
        final rect = tester.getRect(find.byElementPredicate((e) => e == element));
        expect(rect.left, greaterThanOrEqualTo(slider.left - 0.01));
        expect(rect.right, lessThanOrEqualTo(slider.right + 0.01));
      }
    }
  });

  testWidgets('the grip darkens while the thumb is held, before any drag', (tester) async {
    double grip() => tester
        .widgetList<Container>(find.descendant(of: find.byType(KumoSlider), matching: find.byType(Container)))
        .map((c) => (c.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .where((c) => c.a < 0.6)
        .first
        .a;
    await pumpKumo(tester, sized(KumoSlider(value: 50, onValueChange: (_) {})));
    final rest = grip();
    final gesture = await tester.startGesture(tester.getCenter(thumb(0)));
    await tester.pump();
    expect(grip(), greaterThan(rest));
    await gesture.up();
    await tester.pump();
    expect(grip(), rest);
  });
}
