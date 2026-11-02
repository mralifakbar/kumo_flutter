import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Bar extends StatefulWidget {
  const _Bar({this.log});

  final List<String>? log;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool logs = true;

  @override
  Widget build(BuildContext context) {
    void act(String a) => widget.log?.add(a);
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: KumoMenubar(
          semanticLabel: 'Worker editor',
          menus: [
            KumoMenubarMenu(
              label: 'File',
              items: [
                KumoDropdownItem(label: 'New Worker', onPress: () => act('new')),
                KumoDropdownSubmenu(
                  label: 'Export',
                  children: [KumoDropdownItem(label: 'As wrangler.toml', onPress: () => act('toml'))],
                ),
              ],
            ),
            KumoMenubarMenu(
              label: 'View',
              items: [
                KumoDropdownCheckboxItem(
                  label: 'Live logs',
                  checked: logs,
                  onCheckedChange: (v) => setState(() => logs = v),
                ),
              ],
            ),
            const KumoMenubarMenu(
              label: 'Billing',
              disabled: true,
              items: [KumoDropdownItem(label: 'Plans')],
            ),
            KumoMenubarMenu(
              label: 'Settings',
              icon: KumoIcons.gearSix,
              items: [KumoDropdownItem(label: 'Variables', onPress: () => act('vars'))],
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('opens a menu under its trigger in ${brightness.name}', (tester) async {
      await pumpKumo(tester, const _Bar(), brightness: brightness, size: kumoDesktopSize, center: false);
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('New Worker'), findsOneWidget);
      expect(tester.getRect(find.byType(KumoMenuPanel)).top, greaterThan(tester.getRect(find.text('File')).bottom));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('hover switches the open menu; disabled menus do not open', (tester) async {
    await pumpKumo(tester, const _Bar(), size: kumoDesktopSize, center: false);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('View')));
    await tester.pump();
    expect(find.text('Live logs'), findsNothing);
    await mouse.moveTo(tester.getCenter(find.text('File')));
    await mouse.down(tester.getCenter(find.text('File')));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.text('New Worker'), findsOneWidget);
    await mouse.moveTo(tester.getCenter(find.text('View')));
    await tester.pumpAndSettle();
    expect(find.text('Live logs'), findsOneWidget);
    expect(find.text('New Worker'), findsNothing);
    await mouse.moveTo(tester.getCenter(find.text('Billing')));
    await tester.pumpAndSettle();
    expect(find.text('Plans'), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('clicking the open trigger closes; items fire and close', (tester) async {
    final log = <String>[];
    await pumpKumo(tester, _Bar(log: log), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    expect(find.text('New Worker'), findsNothing);
    await tester.tap(find.byType(KumoIcon).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Variables'));
    await tester.pumpAndSettle();
    expect(log, ['vars']);
    expect(find.text('Variables'), findsNothing);
  });

  testWidgets('keyboard: one Tab stop, arrows move between triggers and between open menus', (tester) async {
    final log = <String>[];
    await pumpKumo(tester, _Bar(log: log), size: kumoDesktopSize, center: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('File'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('View'))).hasPrimaryFocus, isTrue);
    // Skips the disabled menu and wraps.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('File'))).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('New Worker'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('New Worker'), findsNothing);
    expect(Focus.of(tester.element(find.text('Live logs'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('New Worker'))).hasPrimaryFocus, isTrue);

    // ArrowRight on a submenu row opens the submenu instead of switching.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('As wrangler.toml'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(log, ['toml']);
    expect(find.text('New Worker'), findsNothing);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('File'))).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('New Worker'), findsNothing);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('File'))).hasPrimaryFocus, isTrue);
  });

  testWidgets('semantics: triggers expose expanded state, icon trigger has a label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Bar(), size: kumoDesktopSize, center: false);
    expect(tester.getSemantics(find.text('File')).getSemanticsData().flagsCollection.isExpanded, Tristate.isFalse);
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('File')).getSemanticsData().flagsCollection.isExpanded, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('phone: menus open as sheets that keep checkbox state live', (tester) async {
    await pumpKumo(tester, const _Bar(), center: false);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    await tester.tap(find.text('Live logs'));
    await tester.pumpAndSettle();
    expect(tester.state<_BarState>(find.byType(_Bar)).logs, isFalse);
    expect(find.byType(KumoSheet), findsOneWidget);
  });

  testWidgets('text scale 2 at 390px scrolls instead of overflowing; RTL', (tester) async {
    await pumpKumo(tester, const _Bar(), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
    await pumpKumo(tester, const _Bar(), size: kumoDesktopSize, center: false, textDirection: TextDirection.rtl);
    expect(tester.getRect(find.text('File')).left, greaterThan(tester.getRect(find.text('View')).left));
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    expect(find.text('New Worker'), findsOneWidget);
  });

  testWidgets('switching between open menus swaps the panel in place', (tester) async {
    await pumpKumo(tester, const _Bar(), size: kumoDesktopSize, center: false);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('File')));
    await mouse.down(tester.getCenter(find.text('File')));
    await mouse.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'opening from closed scales in');
    await tester.pumpAndSettle();

    await mouse.moveTo(tester.getCenter(find.text('View')));
    await tester.pump();
    await tester.pump();
    expect(find.text('New Worker'), findsNothing, reason: 'the old panel leaves at once');
    expect(find.text('Live logs'), findsOneWidget);
    final panelOpacity = tester
        .widget<Opacity>(find.ancestor(of: find.byType(KumoMenuPanel), matching: find.byType(Opacity)).first)
        .opacity;
    expect(panelOpacity, 1, reason: 'the new panel is already at rest, no fade-in flash');
    final panelScale = tester
        .widget<Transform>(find.ancestor(of: find.byType(KumoMenuPanel), matching: find.byType(Transform)).first)
        .transform
        .storage[0];
    expect(panelScale, 1);
    // One more frame moves focus into the new panel; then nothing is moving.
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Closing afterwards still animates out.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('Live logs'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Live logs'), findsNothing);
  });
}
