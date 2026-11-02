import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

List<Widget> _items(List<String> log, {bool bold = false}) => [
  KumoToolbarButton(icon: KumoIcons.uploadSimple, label: 'Import', onPress: () => log.add('import')),
  KumoToolbarButton(icon: KumoIcons.downloadSimple, label: 'Export', onPress: () => log.add('export')),
  KumoToolbarGroup(
    semanticLabel: 'Formatting',
    children: [
      KumoToolbarButton(icon: KumoIcons.textB, semanticLabel: 'Bold', toggled: bold, onPress: () => log.add('bold')),
      KumoToolbarButton(icon: KumoIcons.textItalic, semanticLabel: 'Italic', onPress: () => log.add('italic')),
    ],
  ),
  const KumoToolbarButton(icon: KumoIcons.trash, semanticLabel: 'Delete', disabled: true),
  KumoToolbarButton(icon: KumoIcons.gearSix, semanticLabel: 'Settings', onPress: () => log.add('settings')),
];

Widget _toolbar(List<String> log, {double? width, bool bold = false}) => Align(
  alignment: AlignmentDirectional.topStart,
  child: SizedBox(
    width: width,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: KumoToolbar(
        semanticLabel: 'DNS records',
        children: _items(log, bold: bold),
      ),
    ),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders all items when they fit in ${brightness.name}', (tester) async {
      await pumpKumo(tester, _toolbar([]), brightness: brightness, size: kumoDesktopSize, center: false);
      expect(find.text('Import'), findsOneWidget);
      expect(find.byIcon(KumoIcons.dotsThree).hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('presses fire; disabled does not', (tester) async {
    final log = <String>[];
    await pumpKumo(tester, _toolbar(log), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Import'));
    await tester.tap(find.byIcon(KumoIcons.textB));
    await tester.tap(find.byIcon(KumoIcons.trash));
    expect(log, ['import', 'bold']);
  });

  testWidgets('narrow: trailing items move into a More menu instead of overflowing', (tester) async {
    final log = <String>[];
    await pumpKumo(tester, _toolbar(log, width: 260), size: kumoDesktopSize, center: false);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(KumoToolbar)).width, lessThanOrEqualTo(260));
    final more = find.byIcon(KumoIcons.dotsThree).hitTestable();
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(log, ['settings']);
  });

  testWidgets('overflowed toggle becomes a checkbox row; groups move together', (tester) async {
    final handle = tester.ensureSemantics();
    final log = <String>[];
    await pumpKumo(tester, _toolbar(log, width: 200, bold: true), size: kumoDesktopSize, center: false);
    await tester.tap(find.byIcon(KumoIcons.dotsThree).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Bold'), findsOneWidget);
    expect(find.text('Italic'), findsOneWidget);
    final bold = tester.getSemantics(find.text('Bold')).getSemanticsData();
    expect(bold.flagsCollection.isChecked, CheckedState.isTrue);
    await tester.tap(find.text('Bold'));
    await tester.pumpAndSettle();
    expect(log, ['bold']);
    handle.dispose();
  });

  testWidgets('on a phone the More menu is a sheet', (tester) async {
    await pumpKumo(tester, _toolbar([], width: 220), center: false);
    await tester.tap(find.byIcon(KumoIcons.dotsThree).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
  });

  testWidgets('keyboard: one Tab stop, arrows rove and skip disabled, Home/End', (tester) async {
    final log = <String>[];
    await pumpKumo(
      tester,
      Column(
        children: [
          _toolbar(log),
          KumoButton(label: 'After', onPress: () {}),
        ],
      ),
      size: kumoDesktopSize,
      center: false,
    );
    bool focused(Finder f) => Focus.of(tester.element(f)).hasPrimaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focused(find.text('Import')), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focused(find.byIcon(KumoIcons.textB)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(focused(find.byIcon(KumoIcons.gearSix)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(focused(find.byIcon(KumoIcons.textItalic)), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(log, ['italic']);
    // Tab leaves the toolbar from wherever focus is.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focused(find.text('After')), isTrue);
    // Shift+Tab comes back to the last focused button.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(focused(find.byIcon(KumoIcons.textItalic)), isTrue);
  });

  testWidgets('RTL: items run right to left and arrows follow', (tester) async {
    await pumpKumo(tester, _toolbar([]), size: kumoDesktopSize, center: false, textDirection: TextDirection.rtl);
    expect(tester.getCenter(find.text('Import')).dx, greaterThan(tester.getCenter(find.text('Export')).dx));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Export'))).hasPrimaryFocus, isTrue);
  });

  testWidgets('semantics: toolbar label, icon button labels, toggled state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, _toolbar([], bold: true), size: kumoDesktopSize, center: false);
    expect(find.bySemanticsLabel('DNS records'), findsOneWidget);
    final bold = tester.getSemantics(find.bySemanticsLabel('Bold')).getSemanticsData();
    expect(bold.flagsCollection.isToggled, Tristate.isTrue);
    expect(bold.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('slots stay and flex fills free width', (tester) async {
    await pumpKumo(
      tester,
      SizedBox(
        width: 360,
        child: KumoToolbar(
          children: [
            const KumoToolbarSlot(flex: 1, minWidth: 120, child: SizedBox(height: 36, child: Text('Search records'))),
            KumoToolbarButton(icon: KumoIcons.funnelSimple, semanticLabel: 'Filter', onPress: () {}),
          ],
        ),
      ),
      size: kumoDesktopSize,
    );
    expect(tester.getSize(find.byType(KumoToolbar)).width, 360);
    expect(find.text('Search records'), findsOneWidget);
  });

  testWidgets('text scale 2 at 390px: no overflow, More appears', (tester) async {
    await pumpKumo(tester, _toolbar([], width: 358), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(KumoIcons.dotsThree).hitTestable(), findsOneWidget);
  });
}
