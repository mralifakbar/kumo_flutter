import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _items = [
  KumoBottomNavigationItem(value: 'home', label: 'Home', icon: KumoIcons.house, activeIcon: KumoIcons.houseFill),
  KumoBottomNavigationItem(value: 'workers', label: 'Workers', icon: KumoIcons.code, activeIcon: KumoIcons.codeFill),
  KumoBottomNavigationItem(
    value: 'alerts',
    label: 'Alerts',
    icon: KumoIcons.bell,
    activeIcon: KumoIcons.bellFill,
    badgeCount: 3,
  ),
  KumoBottomNavigationItem(value: 'account', label: 'Account', icon: KumoIcons.user, activeIcon: KumoIcons.userFill),
];

class _Host extends StatefulWidget {
  const _Host({this.onChange});

  final ValueChanged<String>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String value = 'home';

  @override
  Widget build(BuildContext context) => KumoBottomNavigation(
    items: _items,
    value: value,
    onValueChange: (v) {
      widget.onChange?.call(v);
      setState(() => value = v);
    },
    body: ListView(children: [for (var i = 0; i < 30; i++) Text('Worker $i')]),
  );
}

Widget _withInset(Widget child, double bottom) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      viewPadding: EdgeInsets.only(bottom: bottom),
      padding: EdgeInsets.only(bottom: bottom),
    ),
    child: child,
  ),
);

Rect _pill(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('kumo-bottom-navigation-pill')));

double _center(WidgetTester tester, String label) => tester.getCenter(find.text(label)).dx;

void main() {
  for (final b in Brightness.values) {
    testWidgets('renders in $b', (tester) async {
      await pumpKumo(tester, const _Host(), brightness: b, center: false);
      expect(find.text('Workers'), findsOneWidget);
    });
  }

  testWidgets('active destination uses the fill icon; tap switches', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, _Host(onChange: changes.add), center: false);
    expect(find.byIcon(KumoIcons.houseFill), findsOneWidget);
    expect(find.byIcon(KumoIcons.code), findsOneWidget);
    await tester.tap(find.text('Workers'));
    await tester.pumpAndSettle();
    expect(changes, ['workers']);
    expect(find.byIcon(KumoIcons.codeFill), findsOneWidget);
    expect(find.byIcon(KumoIcons.house), findsOneWidget);
  });

  testWidgets('targets are at least 44px; badge shows the count', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    for (final item in _items) {
      final size = tester.getSize(find.ancestor(of: find.text(item.label), matching: find.byType(KumoPressable)));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    }
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('safe area: the bar pads for the home indicator and the body sits above it', (tester) async {
    await pumpKumo(tester, _withInset(const _Host(), 34), center: false);
    final bar = tester.getRect(find.byType(Row).last);
    expect(bar.bottom, lessThanOrEqualTo(844 - 34));
    final list = tester.getRect(find.byType(ListView));
    final barTop = tester.getTopLeft(find.ancestor(of: find.text('Home'), matching: find.byType(KumoPressable))).dy;
    expect(list.bottom, lessThanOrEqualTo(barTop));
  });

  testWidgets('semantics: tab bar with selected tab and badge value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(), center: false);
    expect(
      tester.getSemantics(find.text('Home')),
      containsSemantics(label: 'Home', isSelected: true, hasTapAction: true),
    );
    expect(tester.getSemantics(find.text('Alerts')), containsSemantics(label: 'Alerts', value: '3', isSelected: false));
    handle.dispose();
  });

  testWidgets('keyboard: Tab and Enter switch destinations', (tester) async {
    final changes = <String>[];
    await pumpKumo(
      tester,
      KumoBottomNavigation(items: _items, value: 'home', onValueChange: changes.add),
      center: false,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(changes, ['workers']);
  });

  testWidgets('reduced motion, text scale 2 and RTL: no overflow', (tester) async {
    await pumpKumo(
      tester,
      const _Host(),
      center: false,
      disableAnimations: true,
      textScale: 2,
      textDirection: TextDirection.rtl,
    );
    await tester.tap(find.text('Alerts'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
    expect(_pill(tester).center.dx, closeTo(_center(tester, 'Alerts'), 0.5));
    expect(find.byIcon(KumoIcons.bell), findsNothing);
  });

  testWidgets('the active pill slides from the previous destination and turns around mid-flight', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    final home = _center(tester, 'Home');
    final alerts = _center(tester, 'Alerts');
    expect(_pill(tester).center.dx, closeTo(home, 0.5));
    await tester.tap(find.text('Alerts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _pill(tester).center.dx;
    expect(mid, inExclusiveRange(home + 1, alerts - 1));
    await tester.tap(find.text('Workers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect((_pill(tester).center.dx - mid).abs(), lessThan(40), reason: 'continues from where it is');
    await tester.pumpAndSettle();
    expect(_pill(tester).center.dx, closeTo(_center(tester, 'Workers'), 0.5));
  });

  testWidgets('the fill icon cross-fades in', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    await tester.tap(find.text('Workers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    double opacity(IconData icon) => tester
        .widget<FadeTransition>(find.ancestor(of: find.byIcon(icon), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(opacity(KumoIcons.codeFill), inExclusiveRange(0, 1));
    expect(opacity(KumoIcons.code), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.code), findsNothing);
  });
}
