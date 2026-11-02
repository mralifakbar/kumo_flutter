import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget _card({VoidCallback? onPress, bool disabled = false}) => KumoHoverCard(
  disabled: disabled,
  content: const Text('Deployed 2 hours ago'),
  child: KumoButton(label: 'image-resizer', onPress: onPress ?? () {}),
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('opens after the hover delay and closes after leaving in ${brightness.name}', (tester) async {
      await pumpKumo(tester, _card(), brightness: brightness, size: kumoDesktopSize);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(tester.getCenter(find.text('image-resizer')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Deployed 2 hours ago'), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Deployed 2 hours ago'), findsOneWidget);

      // Moving onto the card keeps it open.
      await mouse.moveTo(tester.getCenter(find.text('Deployed 2 hours ago')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Deployed 2 hours ago'), findsOneWidget);

      await mouse.moveTo(const Offset(1, 1));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Deployed 2 hours ago'), findsNothing);
      await mouse.removePointer();
    });
  }

  testWidgets('a quick pass does not open it', (tester) async {
    await pumpKumo(tester, _card(), size: kumoDesktopSize);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(tester.getCenter(find.text('image-resizer')));
    await tester.pump(const Duration(milliseconds: 200));
    await mouse.moveTo(const Offset(1, 1));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Deployed 2 hours ago'), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('touch: long press opens, tap outside closes, tap still activates the trigger', (tester) async {
    var taps = 0;
    await pumpKumo(tester, _card(onPress: () => taps++));
    await tester.tap(find.text('image-resizer'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.text('Deployed 2 hours ago'), findsNothing);
    await tester.longPress(find.text('image-resizer'));
    await tester.pumpAndSettle();
    expect(find.text('Deployed 2 hours ago'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Deployed 2 hours ago'), findsNothing);
  });

  testWidgets('keyboard focus opens it and Escape closes it', (tester) async {
    await pumpKumo(tester, _card(), size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Deployed 2 hours ago'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Deployed 2 hours ago'), findsNothing);
  });

  testWidgets('disabled never opens', (tester) async {
    await pumpKumo(tester, _card(disabled: true));
    await tester.longPress(find.text('image-resizer'));
    await tester.pumpAndSettle();
    expect(find.text('Deployed 2 hours ago'), findsNothing);
  });

  testWidgets('controlled, reduced motion, text scale 2', (tester) async {
    await pumpKumo(
      tester,
      const KumoHoverCard(open: true, content: Text('Zone example.com is active'), child: Text('example.com')),
      disableAnimations: true,
      textScale: 2,
    );
    expect(find.text('Zone example.com is active'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
