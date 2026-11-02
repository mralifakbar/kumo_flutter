import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget _box(KumoPressState s) => SizedBox(
      width: 80,
      height: 30,
      child: Text(s.pressed ? 'pressed' : (s.hovered ? 'hovered' : (s.focused ? 'focused' : 'idle'))),
    );

double _scaleOf(WidgetTester tester) {
  final t = tester.widget<Transform>(
    find.descendant(of: find.byType(KumoPressable), matching: find.byType(Transform)).first,
  );
  return t.transform.storage[0];
}

void main() {
  testWidgets('fires onPress and exposes button semantics', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpKumo(tester, KumoPressable(onPress: () => taps++, semanticLabel: 'Save', builder: (_, s) => _box(s)));
    await tester.tap(find.byType(KumoPressable));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(KumoPressable)),
      matchesSemantics(
        label: 'Save\nidle',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('press feedback starts on pointer-down and springs back', (tester) async {
    await pumpKumo(tester, KumoPressable(onPress: () {}, builder: (_, s) => _box(s)));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoPressable)));
    await tester.pump();
    expect(find.text('pressed'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), closeTo(KumoMotion.pressScale, 0.001));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), 1);
    expect(find.text('idle'), findsOneWidget);
  });

  testWidgets('reduced motion keeps color feedback but no scale', (tester) async {
    await pumpKumo(tester, KumoPressable(onPress: () {}, builder: (_, s) => _box(s)), disableAnimations: true);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoPressable)));
    await tester.pump();
    expect(find.text('pressed'), findsOneWidget);
    expect(_scaleOf(tester), 1);
    await gesture.up();
  });

  testWidgets('disabled and loading do not fire', (tester) async {
    var taps = 0;
    await pumpKumo(tester, KumoPressable(onPress: () => taps++, disabled: true, builder: (_, s) => _box(s)));
    await tester.tap(find.byType(KumoPressable));
    await pumpKumo(tester, KumoPressable(onPress: () => taps++, loading: true, builder: (_, s) => _box(s)));
    await tester.tap(find.byType(KumoPressable));
    expect(taps, 0);
  });

  testWidgets('hover state switches instantly', (tester) async {
    await pumpKumo(tester, KumoPressable(onPress: () {}, builder: (_, s) => _box(s)));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(KumoPressable)));
    await tester.pump();
    expect(find.text('hovered'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('Tab focuses, shows the ring, Enter and Space activate', (tester) async {
    var taps = 0;
    await pumpKumo(tester, KumoPressable(onPress: () => taps++, builder: (_, s) => _box(s)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.text('focused'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(KumoPressable), matching: find.byWidgetPredicate((w) => w is CustomPaint && w.foregroundPainter is KumoFocusRingPainter)),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('padded tap target grows the hit area to 44', (tester) async {
    await pumpKumo(
      tester,
      KumoPressable(onPress: () {}, child: const SizedBox(width: 20, height: 20)),
    );
    expect(tester.getSize(find.byType(KumoPressable)), const Size(44, 44));
    await pumpKumo(
      tester,
      KumoPressable(onPress: () {}, child: const SizedBox(width: 20, height: 20)),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    expect(tester.getSize(find.byType(KumoPressable)), const Size(20, 20));
  });

  testWidgets('debounce ignores repeat presses inside the window', (tester) async {
    var taps = 0;
    await pumpKumo(
      tester,
      KumoPressable(onPress: () => taps++, debounce: const Duration(milliseconds: 500), child: const SizedBox(width: 50, height: 50)),
    );
    await tester.tap(find.byType(KumoPressable));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(KumoPressable));
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byType(KumoPressable));
    expect(taps, 2);
  });

  testWidgets('canRequestFocus false keeps it out of the Tab order', (tester) async {
    await pumpKumo(
      tester,
      Column(mainAxisSize: MainAxisSize.min, children: [
        KumoPressable(onPress: () {}, canRequestFocus: false, builder: (_, s) => _box(s)),
      ]),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.text('focused'), findsNothing);
  });
}
