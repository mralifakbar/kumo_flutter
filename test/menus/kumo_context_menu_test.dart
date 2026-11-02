import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget _menu({List<String>? log, bool disabled = false, ValueChanged<bool>? onOpenChange}) => Align(
  alignment: Alignment.topLeft,
  child: KumoContextMenu(
    disabled: disabled,
    onOpenChange: onOpenChange,
    items: [
      KumoDropdownItem(label: 'Copy record ID', icon: KumoIcons.copy, onPress: () => log?.add('copy')),
      KumoDropdownSubmenu(
        label: 'Change TTL',
        children: [KumoDropdownItem(label: '5 minutes', onPress: () => log?.add('ttl'))],
      ),
      const KumoDropdownSeparator(),
      KumoDropdownItem(label: 'Delete record', destructive: true, onPress: () => log?.add('delete')),
    ],
    child: const SizedBox(width: 600, height: 300, child: Text('A example.com 192.0.2.1')),
  ),
);

Future<void> _rightClick(WidgetTester tester, Offset at) async {
  final mouse = await tester.startGesture(at, kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
  await mouse.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('right click opens at the pointer in ${brightness.name}', (tester) async {
      await pumpKumo(tester, _menu(), brightness: brightness, size: kumoDesktopSize, center: false);
      await _rightClick(tester, const Offset(200, 120));
      expect(find.text('Copy record ID'), findsOneWidget);
      final panel = tester.getRect(find.byType(KumoMenuPanel));
      expect(panel.left, closeTo(200, 1));
      expect(panel.top, closeTo(122, 1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('right click elsewhere moves the open menu', (tester) async {
    await pumpKumo(tester, _menu(), size: kumoDesktopSize, center: false);
    await _rightClick(tester, const Offset(200, 120));
    await _rightClick(tester, const Offset(400, 200));
    expect(find.text('Copy record ID'), findsOneWidget);
    expect(tester.getRect(find.byType(KumoMenuPanel)).left, closeTo(400, 1));
  });

  testWidgets('item press fires and closes; left click outside closes', (tester) async {
    final log = <String>[];
    final changes = <bool>[];
    await pumpKumo(
      tester,
      _menu(log: log, onOpenChange: changes.add),
      size: kumoDesktopSize,
      center: false,
    );
    await _rightClick(tester, const Offset(200, 120));
    await tester.tap(find.text('Copy record ID'));
    await tester.pumpAndSettle();
    expect(log, ['copy']);
    expect(find.text('Copy record ID'), findsNothing);
    await _rightClick(tester, const Offset(200, 120));
    await tester.tapAt(const Offset(900, 700));
    await tester.pumpAndSettle();
    expect(find.text('Copy record ID'), findsNothing);
    expect(changes, [true, false, true, false]);
  });

  testWidgets('flips up near the bottom edge', (tester) async {
    await pumpKumo(
      tester,
      const Align(
        alignment: Alignment.bottomLeft,
        child: SizedBox(height: 300, child: _Holder()),
      ),
      size: kumoDesktopSize,
      center: false,
    );
    await _rightClick(tester, const Offset(100, 790));
    expect(tester.getRect(find.byType(KumoMenuPanel)).bottom, lessThanOrEqualTo(790));
  });

  testWidgets('long press on touch opens a sheet on phones', (tester) async {
    final log = <String>[];
    await pumpKumo(tester, _menu(log: log), center: false);
    await tester.longPressAt(const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    await tester.tap(find.text('Change TTL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 minutes'));
    await tester.pumpAndSettle();
    expect(log, ['ttl']);
    expect(find.byType(KumoSheet), findsNothing);
  });

  testWidgets('long press on a wide screen opens at the finger', (tester) async {
    await pumpKumo(tester, _menu(), size: kumoDesktopSize, center: false);
    await tester.longPressAt(const Offset(150, 100));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(KumoMenuPanel)).left, closeTo(150, 1));
  });

  testWidgets('keyboard: Shift+F10 opens it from a focused child, Escape closes', (tester) async {
    await pumpKumo(
      tester,
      KumoContextMenu(
        items: const [KumoDropdownItem(label: 'Copy record ID')],
        child: KumoButton(label: 'Record', onPress: () {}),
      ),
      size: kumoDesktopSize,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.text('Copy record ID'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Copy record ID'), findsNothing);
  });

  testWidgets('disabled ignores right click and long press', (tester) async {
    await pumpKumo(tester, _menu(disabled: true), size: kumoDesktopSize, center: false);
    await _rightClick(tester, const Offset(200, 120));
    await tester.longPressAt(const Offset(200, 120));
    await tester.pumpAndSettle();
    expect(find.text('Copy record ID'), findsNothing);
  });

  testWidgets('child taps still work and text scale 2 has no overflow', (tester) async {
    var taps = 0;
    await pumpKumo(
      tester,
      KumoContextMenu(
        items: const [KumoDropdownItem(label: 'Copy record ID')],
        child: KumoButton(label: 'Record', onPress: () => taps++),
      ),
      textScale: 2,
      size: kumoDesktopSize,
    );
    await tester.tap(find.text('Record'));
    expect(taps, 1);
    await _rightClick(tester, tester.getCenter(find.text('Record')));
    expect(find.text('Copy record ID'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Holder extends StatelessWidget {
  const _Holder();

  @override
  Widget build(BuildContext context) => KumoContextMenu(
    items: const [
      KumoDropdownItem(label: 'One'),
      KumoDropdownItem(label: 'Two'),
      KumoDropdownItem(label: 'Three'),
    ],
    child: Container(width: 400, color: const Color(0x00000000)),
  );
}
