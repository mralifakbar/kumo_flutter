import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget controlled<T>(T initial, Widget Function(T value, ValueChanged<T> set) build) {
  var value = initial;
  return StatefulBuilder(builder: (context, setState) => build(value, (v) => setState(() => value = v)));
}

/// Records haptic calls on the platform channel.
List<String> recordHaptics(WidgetTester tester) {
  final log = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') log.add(call.arguments as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return log;
}

/// Left edge of the thumb relative to the track.
double thumbOffset(WidgetTester tester) {
  final positioned = tester.widget<Positioned>(
    find.descendant(of: find.byType(KumoSwitch), matching: find.byType(Positioned)),
  );
  return positioned.left!;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders every size and variant in $brightness', (tester) async {
      await pumpKumo(
        tester,
        brightness: brightness,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final size in KumoSwitchSize.values)
              for (final variant in KumoSwitchVariant.values)
                for (final checked in [false, true])
                  KumoSwitch(label: '$size $variant', size: size, variant: variant, checked: checked, onCheckedChange: (_) {}),
            const KumoSwitch(label: 'Disabled', checked: true, disabled: true),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('track and thumb sizes match Kumo', (tester) async {
    await pumpKumo(tester, KumoSwitch(semanticLabel: 'Proxy', checked: true, onCheckedChange: (_) {}));
    final track = find.descendant(of: find.byType(KumoSwitch), matching: find.byType(DecoratedBox)).first;
    expect(tester.getSize(track), const Size(36, 18));
    expect(thumbOffset(tester), 18);
  });

  testWidgets('tap toggles with a selection haptic; disabled does not fire', (tester) async {
    final haptics = recordHaptics(tester);
    final calls = <bool>[];
    await pumpKumo(tester, KumoSwitch(label: 'Always use HTTPS', checked: false, onCheckedChange: calls.add));
    await tester.tap(find.text('Always use HTTPS'));
    expect(calls, [true]);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    await pumpKumo(tester, KumoSwitch(label: 'Locked', checked: false, disabled: true, onCheckedChange: calls.add));
    await tester.tap(find.text('Locked'));
    await pumpKumo(tester, KumoSwitch(label: 'Saving', checked: false, transitioning: true, onCheckedChange: calls.add));
    await tester.tap(find.text('Saving'));
    expect(calls, [true]);
  });

  testWidgets('controlled: thumb springs to the new value', (tester) async {
    await pumpKumo(tester, controlled<bool>(false, (v, set) => KumoSwitch(label: 'Proxy', checked: v, onCheckedChange: set)));
    expect(thumbOffset(tester), 0);
    await tester.tap(find.byType(KumoSwitch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final mid = thumbOffset(tester);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(18));
    await tester.pumpAndSettle();
    expect(thumbOffset(tester), 18);
  });

  testWidgets('a refused change springs back', (tester) async {
    await pumpKumo(tester, KumoSwitch(label: 'Proxy', checked: false, onCheckedChange: (_) {}));
    await tester.drag(find.byType(KumoSwitch), const Offset(30, 0));
    await tester.pumpAndSettle();
    expect(thumbOffset(tester), 0);
  });

  testWidgets('semantics: switch with label and toggled state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, KumoSwitch(label: 'Always use HTTPS', checked: true, onCheckedChange: (_) {}));
    expect(
      tester.getSemantics(find.text('Always use HTTPS')),
      containsSemantics(label: 'Always use HTTPS', hasToggledState: true, isToggled: true, isButton: false, hasTapAction: true),
    );
    await pumpKumo(tester, KumoSwitch(checked: false, onCheckedChange: (_) {}));
    expect(find.bySemanticsLabel('Switch'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('keyboard: Tab focuses, Space and Enter toggle', (tester) async {
    final calls = <bool>[];
    await pumpKumo(tester, KumoSwitch(label: 'Proxy', checked: false, onCheckedChange: calls.add));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, [true, true]);
  });

  group('drag', () {
    testWidgets('the thumb follows the finger and a slow drag past halfway turns it on', (tester) async {
      final haptics = recordHaptics(tester);
      await pumpKumo(tester, controlled<bool>(false, (v, set) => KumoSwitch(label: 'Proxy', checked: v, onCheckedChange: set)));
      final start = tester.getTopLeft(find.byType(KumoSwitch)) + const Offset(4, 22);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(6, 0));
      await tester.pump();
      expect(thumbOffset(tester), closeTo(6, 0.01), reason: 'moves 1:1 from the touch point');
      await gesture.moveBy(const Offset(6, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveBy(const Offset(0.1, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(thumbOffset(tester), 18);
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
    });

    testWidgets('a slow short drag returns to off', (tester) async {
      final calls = <bool>[];
      await pumpKumo(tester, KumoSwitch(label: 'Proxy', checked: false, onCheckedChange: calls.add));
      await tester.timedDrag(find.byType(KumoSwitch), const Offset(7, 0), const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(thumbOffset(tester), 0);
    });

    testWidgets('a short flick decides by velocity', (tester) async {
      final calls = <bool>[];
      await pumpKumo(
        tester,
        controlled<bool>(
          false,
          (v, set) => KumoSwitch(label: 'Proxy', checked: v, onCheckedChange: (next) => set((calls..add(next)).last)),
        ),
      );
      // 8px is less than half the 18px travel; only the velocity carries it over.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoSwitch)));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        await gesture.moveBy(const Offset(2, 0), timeStamp: Duration(milliseconds: 8 * (i + 1)));
      }
      await gesture.up(timeStamp: const Duration(milliseconds: 36));
      // The momentum spring carries the flick a little past the end.
      var furthest = 0.0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        furthest = furthest > thumbOffset(tester) ? furthest : thumbOffset(tester);
      }
      await tester.pumpAndSettle();
      expect(calls, [true]);
      expect(furthest, greaterThan(18));
      expect(thumbOffset(tester), 18);
    });

    testWidgets('dragging past the end rubberbands instead of stopping dead', (tester) async {
      await pumpKumo(tester, KumoSwitch(label: 'Proxy', checked: true, onCheckedChange: (_) {}));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoSwitch)));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      final x = thumbOffset(tester);
      expect(x, greaterThan(18));
      expect(x, lessThan(18 + 40));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('RTL drags toward the left to turn on', (tester) async {
      final calls = <bool>[];
      await pumpKumo(
        tester,
        textDirection: TextDirection.rtl,
        KumoSwitch(label: 'Proxy', checked: false, onCheckedChange: calls.add),
      );
      final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoSwitch)));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        await gesture.moveBy(const Offset(-2, 0), timeStamp: Duration(milliseconds: 8 * (i + 1)));
      }
      await gesture.up(timeStamp: const Duration(milliseconds: 36));
      await tester.pumpAndSettle();
      expect(calls, [true]);
    });
  });

  testWidgets('reduced motion moves the thumb without animation', (tester) async {
    await pumpKumo(
      tester,
      disableAnimations: true,
      controlled<bool>(false, (v, set) => KumoSwitch(label: 'Proxy', checked: v, onCheckedChange: set)),
    );
    await tester.tap(find.byType(KumoSwitch));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(thumbOffset(tester), 18);
  });

  testWidgets('group passes controlFirst and disabled to its switches', (tester) async {
    var calls = 0;
    await pumpKumo(
      tester,
      KumoSwitchGroup(
        legend: 'Notifications',
        description: 'Sent to the account owner.',
        controlFirst: false,
        disabled: true,
        children: [KumoSwitch(label: 'Deploy failures', checked: true, onCheckedChange: (_) => calls++)],
      ),
    );
    expect(find.text('Notifications'), findsOneWidget);
    final track = find.descendant(of: find.byType(KumoSwitch), matching: find.byType(DecoratedBox)).first;
    expect(tester.getCenter(track).dx, greaterThan(tester.getCenter(find.text('Deploy failures')).dx));
    await tester.tap(find.text('Deploy failures'));
    expect(calls, 0);
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await pumpKumo(
      tester,
      textScale: 2,
      Padding(
        padding: const EdgeInsets.all(16),
        child: KumoSwitchGroup(
          legend: 'Security settings for example.com',
          error: 'Could not save. Try again.',
          children: [
            KumoSwitch(
              label: 'Automatic HTTPS rewrites for every subdomain',
              labelTooltip: 'Rewrites http links to https',
              required: false,
              checked: true,
              onCheckedChange: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
