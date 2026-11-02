import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _tabs = [
  KumoTab(value: 'overview', label: 'Overview'),
  KumoTab(value: 'metrics', label: 'Metrics', icon: KumoIcons.chartBar),
  KumoTab(value: 'logs', label: 'Logs', disabled: true),
  KumoTab(value: 'settings', label: 'Settings'),
];

class _Host extends StatefulWidget {
  const _Host({
    this.tabs = _tabs,
    this.variant = KumoTabsVariant.segmented,
    this.size = KumoTabsSize.base,
    this.initial = 'overview',
    this.activateOnFocus = false,
    this.onChange,
    this.width,
  });

  final List<KumoTab> tabs;
  final KumoTabsVariant variant;
  final KumoTabsSize size;
  final String initial;
  final bool activateOnFocus;
  final ValueChanged<String>? onChange;
  final double? width;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final tabs = KumoTabs(
      tabs: widget.tabs,
      value: value,
      variant: widget.variant,
      size: widget.size,
      activateOnFocus: widget.activateOnFocus,
      semanticLabel: 'Worker sections',
      onValueChange: (v) {
        widget.onChange?.call(v);
        setState(() => value = v);
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.width == null ? tabs : SizedBox(width: widget.width, child: tabs),
        Text('active: $value'),
      ],
    );
  }
}

Rect _indicator(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('kumo-tabs-indicator')));

double _tabCenter(WidgetTester tester, String label) =>
    tester.getCenter(find.ancestor(of: find.text(label), matching: find.byType(Container)).first).dx;

void main() {
  testWidgets('a read-only tab bar (no onValueChange) passes semantics checks', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoTabs(tabs: _tabs, value: 'overview', onValueChange: null));
    expect(tester.takeException(), isNull);
    final overview = tester.getSemantics(find.text('Overview')).getSemanticsData();
    expect(overview.flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });

  for (final brightness in Brightness.values) {
    for (final variant in KumoTabsVariant.values) {
      for (final size in KumoTabsSize.values) {
        testWidgets('renders $variant $size in $brightness', (tester) async {
          await pumpKumo(
            tester,
            _Host(variant: variant, size: size),
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Overview'), findsOneWidget);
        });
      }
    }
  }

  testWidgets('tap selects and moves the indicator with a spring', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(changes, ['settings']);
    expect(find.text('active: settings'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('reflects the value it is given', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(initial: 'settings'));
    expect(find.text('active: settings'), findsOneWidget);
    expect(tester.getSemantics(find.text('Settings')), containsSemantics(isSelected: true));
    handle.dispose();
  });

  testWidgets('disabled tab does not fire', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  moreTabTests();
}

const _many = [
  KumoTab(value: 'overview', label: 'Overview'),
  KumoTab(value: 'metrics', label: 'Metrics'),
  KumoTab(value: 'deployments', label: 'Deployments'),
  KumoTab(value: 'observability', label: 'Observability'),
  KumoTab(value: 'domains', label: 'Domains'),
  KumoTab(value: 'access', label: 'Access'),
  KumoTab(value: 'settings', label: 'Settings'),
];

void moreTabTests() {
  testWidgets('semantics: tab bar with selected tab', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host());
    expect(
      tester.getSemantics(find.text('Overview')),
      matchesSemantics(
        label: 'Overview',
        isSelected: true,
        hasSelectedState: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    expect(tester.getSemantics(find.text('Metrics')).flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('keyboard: roving focus, arrows move focus, Enter selects, Home and End', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, _Host(onChange: changes.add), size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    String? focusedLabel() => FocusManager.instance.primaryFocus!.debugLabel;
    expect(focusedLabel(), 'KumoTab 0');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedLabel(), 'KumoTab 1');
    expect(changes, isEmpty, reason: 'arrows only move focus by default');
    // Logs (index 2) is disabled and skipped.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedLabel(), 'KumoTab 3');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, ['settings']);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(focusedLabel(), 'KumoTab 0');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(focusedLabel(), 'KumoTab 3');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusedLabel(), 'KumoTab 0', reason: 'wraps around');
  });

  testWidgets('activateOnFocus selects while arrowing', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, _Host(onChange: changes.add, activateOnFocus: true), size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changes, ['metrics']);
  });

  testWidgets('RTL: arrow left moves forward', (tester) async {
    await pumpKumo(tester, const _Host(), textDirection: TextDirection.rtl, size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'KumoTab 1');
  });

  testWidgets('dragging the segmented pill on touch selects where it lands', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, _Host(onChange: changes.add));
    final start = tester.getCenter(find.text('Overview'));
    final end = tester.getCenter(find.text('Metrics'));
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.touch);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(start, end, i / 10)!);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, ['metrics']);
  });

  testWidgets('a fast flick of the pill carries past the nearest tab', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, _Host(onChange: changes.add));
    await tester.fling(find.text('Overview'), const Offset(60, 0), 1500);
    await tester.pumpAndSettle();
    // Logs is disabled, so the projection lands on Settings.
    expect(changes, ['settings']);
  });

  testWidgets('overflowing tabs scroll with an end control and fades', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(tabs: _many, width: 300));
    expect(find.byType(ShaderMask), findsOneWidget);
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    final controller = scroll.controller!;
    expect(controller.offset, 0);
    await tester.tap(find.bySemanticsLabel('Scroll tabs right'));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    // Selecting an offscreen tab scrolls it into view.
    await tester.tap(find.bySemanticsLabel('Scroll tabs left'));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    handle.dispose();
  });

  testWidgets('reduced motion: selection lands without animating', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_indicator(tester).center.dx, closeTo(_tabCenter(tester, 'Settings'), 0.5));
  });

  testWidgets('indicator springs from where it is; a tap mid-flight turns it around', (tester) async {
    await pumpKumo(tester, const _Host());
    final overview = _tabCenter(tester, 'Overview');
    final settings = _tabCenter(tester, 'Settings');
    expect(_indicator(tester).center.dx, closeTo(overview, 0.5));
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _indicator(tester).center.dx;
    expect(mid, inExclusiveRange(overview + 1, settings - 1));
    await tester.tap(find.text('Metrics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final turned = _indicator(tester).center.dx;
    // It carries its velocity a little further before turning: no jump.
    expect((turned - mid).abs(), lessThan(30));
    await tester.pumpAndSettle();
    expect(_indicator(tester).center.dx, closeTo(_tabCenter(tester, 'Metrics'), 0.5));
  });

  testWidgets('text scale 2 at 390px: no overflow, row scrolls', (tester) async {
    for (final variant in KumoTabsVariant.values) {
      await pumpKumo(tester, _Host(tabs: _many, variant: variant), textScale: 2);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('empty tab list renders nothing', (tester) async {
    await pumpKumo(tester, KumoTabs(tabs: const [], value: null, onValueChange: (_) {}));
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('KumoTabPanels: swipe changes the tab, tab tap moves the page', (tester) async {
    await pumpKumo(tester, const _PanelsHost(), center: false);
    expect(find.text('Overview panel'), findsOneWidget);
    await tester.fling(find.text('Overview panel'), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Metrics panel'), findsOneWidget);
    expect(find.text('value: metrics'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings panel'), findsOneWidget);
    expect(find.text('value: settings'), findsOneWidget);
  });

  testWidgets('KumoTabPanels: the indicator follows a panel drag 1:1', (tester) async {
    await pumpKumo(tester, const _PanelsHost(), center: false);
    final overview = _tabCenter(tester, 'Overview');
    final metrics = _tabCenter(tester, 'Metrics');
    final gesture = await tester.startGesture(tester.getCenter(find.text('Overview panel')));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-97.5, 0));
    await tester.pump();
    // 97.5px of a 390px page is a quarter of the way (the first 20px pay
    // for the drag slop).
    final x = _indicator(tester).center.dx;
    expect(x, inExclusiveRange(overview, metrics));
    expect((x - overview) / (metrics - overview), closeTo(0.25, 0.08));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('value: overview'), findsOneWidget);
    expect(_indicator(tester).center.dx, closeTo(overview, 0.5));
  });

  testWidgets('KumoTabPanels: a short drag springs back', (tester) async {
    await pumpKumo(tester, const _PanelsHost(), center: false);
    await tester.drag(find.text('Overview panel'), const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(find.text('value: overview'), findsOneWidget);
  });
}

class _PanelsHost extends StatefulWidget {
  const _PanelsHost();

  @override
  State<_PanelsHost> createState() => _PanelsHostState();
}

class _PanelsHostState extends State<_PanelsHost> {
  final PageController pages = PageController();
  String value = 'overview';

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      KumoTab(value: 'overview', label: 'Overview'),
      KumoTab(value: 'metrics', label: 'Metrics'),
      KumoTab(value: 'settings', label: 'Settings'),
    ];
    return Column(
      children: [
        KumoTabs(tabs: tabs, value: value, pageController: pages, onValueChange: (v) => setState(() => value = v)),
        Text('value: $value'),
        Expanded(
          child: KumoTabPanels(
            controller: pages,
            value: value,
            onValueChange: (v) => setState(() => value = v),
            panels: [
              for (final t in tabs)
                KumoTabPanel(
                  value: t.value,
                  child: Center(child: Text('${t.label} panel')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
