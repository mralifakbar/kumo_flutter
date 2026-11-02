import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

List<KumoTrackerDay> _days(int n, {Map<int, KumoTrackerStatus> overrides = const {}}) => [
  for (var i = 0; i < n; i++)
    KumoTrackerDay(
      date: DateTime(2026, 1, 1).add(Duration(days: i)),
      status: overrides[i] ?? KumoTrackerStatus.operational,
      note: overrides[i] == KumoTrackerStatus.outage ? 'Origin unreachable for 18 min' : null,
    ),
];

Widget _host(KumoTracker tracker) => Padding(padding: const EdgeInsets.all(16), child: tracker);

Finder get _bars => find.descendant(of: find.byType(KumoTracker), matching: find.byType(CustomPaint)).first;

/// Center of bar [i] for [n] bars across the tracker's bar area.
Offset _barCenter(WidgetTester tester, int i, int n, {bool rtl = false}) {
  final r = tester.getRect(_bars);
  final visual = rtl ? n - 1 - i : i;
  return Offset(r.left + r.width * (visual + 0.5) / n, r.center.dy);
}

void main() {
  final mixed = _days(
    30,
    overrides: {3: KumoTrackerStatus.degraded, 10: KumoTrackerStatus.outage, 0: KumoTrackerStatus.noData},
  );

  testWidgets('90 days fit a 390px phone in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        _host(
          KumoTracker(
            days: _days(90),
            label: 'image-resizer',
            valueText: '100% uptime',
            startLabel: '90 days ago',
            endLabel: 'Today',
          ),
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_bars).width, 358);
    }
  });

  testWidgets('legend names only the statuses present', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed)));
    expect(find.text('Operational'), findsOneWidget);
    expect(find.text('Degraded'), findsOneWidget);
    expect(find.text('Outage'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
    await pumpKumo(tester, _host(KumoTracker(days: _days(5))));
    expect(find.text('Operational'), findsOneWidget);
    expect(find.text('Outage'), findsNothing);
    await pumpKumo(tester, _host(KumoTracker(days: mixed, showLegend: false)));
    expect(find.text('Operational'), findsNothing);
  });

  testWidgets('hover shows the date and status of the bar under the pointer', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed)), size: kumoDesktopSize);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(_barCenter(tester, 10, 30));
    await tester.pumpAndSettle();
    expect(find.text('Jan 11, 2026'), findsOneWidget);
    expect(find.text('Origin unreachable for 18 min'), findsOneWidget);
    // The tooltip sits above the hovered bar.
    final popup = tester.getRect(find.byType(KumoPopupSurface));
    expect(popup.bottom, lessThan(tester.getRect(_bars).top));
    expect(popup.center.dx, closeTo(_barCenter(tester, 10, 30).dx, 1));

    await mouse.moveTo(_barCenter(tester, 3, 30));
    await tester.pump();
    expect(find.text('Jan 4, 2026'), findsOneWidget);
    expect(find.text('Degraded'), findsNWidgets(2));

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.byType(KumoPopupSurface), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('long press scrubs across days; the tooltip hides 1.5s after release', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed)));
    final gesture = await tester.startGesture(_barCenter(tester, 5, 30));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('Jan 6, 2026'), findsOneWidget);
    await gesture.moveTo(_barCenter(tester, 10, 30));
    await tester.pump();
    expect(find.text('Jan 11, 2026'), findsOneWidget);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Jan 11, 2026'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(KumoPopupSurface), findsNothing);
  });

  testWidgets('a tap shows the tapped day', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed)));
    await tester.tapAt(_barCenter(tester, 20, 30));
    await tester.pumpAndSettle();
    expect(find.text('Jan 21, 2026'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('RTL draws the oldest day on the right', (tester) async {
    await pumpKumo(
      tester,
      _host(KumoTracker(days: mixed)),
      textDirection: TextDirection.rtl,
      size: kumoDesktopSize,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    final right = tester.getRect(_bars).centerRight - const Offset(2, 0);
    await mouse.moveTo(right);
    await tester.pumpAndSettle();
    expect(find.text('Jan 1, 2026'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('keyboard: one Tab stop, arrows move, Home and End jump, Escape hides', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Jan 30, 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('Jan 29, 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(find.text('Jan 1, 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('Jan 1, 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(find.text('Jan 30, 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KumoPopupSurface), findsNothing);
  });

  testWidgets('screen readers hear a summary and can step through days', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, _host(KumoTracker(days: mixed, label: 'image-resizer', valueText: '96.7% uptime')));
    final node = tester.getSemantics(find.byType(KumoAnchoredOverlay));
    expect(node.label, 'image-resizer, 96.7% uptime. 30 days: 27 operational, 1 degraded, 1 outage, 1 no data');
    expect(node, containsSemantics(hasIncreaseAction: true, hasDecreaseAction: true));
    tester.semantics.performAction(find.semantics.byLabel(RegExp('image-resizer')), SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.byType(KumoAnchoredOverlay)).value, 'Jan 1, 2026, No data');
    handle.dispose();
  });

  test('summary counts each status and omits absent ones', () {
    final t = KumoTracker(days: _days(3, overrides: {1: KumoTrackerStatus.outage}));
    expect(t.summary(), '3 days: 2 operational, 1 outage');
    final custom = KumoTracker(days: _days(1), statusLabels: const {KumoTrackerStatus.operational: 'Disponible'});
    expect(custom.summary(), '1 day: 1 disponible');
  });

  testWidgets('loading, error and empty states', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, _host(const KumoTracker(days: [], loading: true, label: 'image-resizer')));
    expect(find.bySemanticsLabel('image-resizer Loading'), findsOneWidget);
    expect(find.text('Operational'), findsNothing);

    await pumpKumo(tester, _host(KumoTracker(days: mixed, error: 'Could not load health checks for image-resizer')));
    expect(find.text('Could not load health checks for image-resizer'), findsOneWidget);
    expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);

    await pumpKumo(tester, _host(const KumoTracker(days: [])));
    expect(find.text('No status checks ran in this period'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('loading ignores input', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed, loading: true)));
    await tester.tapAt(_barCenter(tester, 4, 30));
    await tester.pumpAndSettle();
    expect(find.byType(KumoPopupSurface), findsNothing);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpKumo(
      tester,
      _host(
        KumoTracker(
          days: mixed,
          label: 'api.example.com health check',
          valueText: '96.7% uptime',
          startLabel: '30 days ago',
          endLabel: 'Today',
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tooltip glides between bars instead of jumping', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed)), size: kumoDesktopSize);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(_barCenter(tester, 3, 30));
    await tester.pumpAndSettle();
    final from = tester.getRect(find.byType(KumoPopupSurface)).center.dx;
    expect(from, closeTo(_barCenter(tester, 3, 30).dx, 1), reason: 'a fresh tooltip opens at its bar');
    await mouse.moveTo(_barCenter(tester, 20, 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = tester.getRect(find.byType(KumoPopupSurface)).center.dx;
    final to = _barCenter(tester, 20, 30).dx;
    expect(mid, inExclusiveRange(from, to));
    expect(find.text('Jan 21, 2026'), findsOneWidget, reason: 'the content switches at once');
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(KumoPopupSurface)).center.dx, closeTo(to, 1));
  });

  testWidgets('reduced motion: the tooltip jumps to the next bar', (tester) async {
    await pumpKumo(tester, _host(KumoTracker(days: mixed)), size: kumoDesktopSize, disableAnimations: true);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(_barCenter(tester, 3, 30));
    await tester.pumpAndSettle();
    await mouse.moveTo(_barCenter(tester, 20, 30));
    await tester.pump();
    await tester.pump();
    expect(tester.getRect(find.byType(KumoPopupSurface)).center.dx, closeTo(_barCenter(tester, 20, 30).dx, 1));
    // An open anchored popup keeps a frame callback registered, so check the
    // tooltip stays put rather than asserting on running animations.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(find.byType(KumoPopupSurface)).center.dx, closeTo(_barCenter(tester, 20, 30).dx, 1));
  });

  testWidgets('placeholder bars cross-fade into the history', (tester) async {
    await pumpKumo(tester, _host(const KumoTracker(days: [], loading: true)));
    await pumpKumo(tester, _host(KumoTracker(days: mixed)), settle: false);
    await tester.pump(const Duration(milliseconds: 60));
    final fades = tester
        .widgetList<FadeTransition>(
          find.descendant(of: find.byType(KumoTracker), matching: find.byType(FadeTransition)),
        )
        .map((f) => f.opacity.value)
        .where((v) => v > 0 && v < 1);
    expect(fades, isNotEmpty);
    await tester.pumpAndSettle();
  });
}
