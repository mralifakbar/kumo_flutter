import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

final _t0 = DateTime.utc(2026, 3, 4, 14);

List<(DateTime, double)> _points(int n, double Function(int i) f, {Duration step = const Duration(minutes: 1)}) =>
    [for (var i = 0; i < n; i++) (_t0.add(step * i), f(i))];

List<KumoTimeseriesData> _series() => [
      KumoTimeseriesData(
        name: 'Requests',
        color: KumoChartColors.light.semantic(KumoChartSemanticColor.neutral),
        data: _points(30, (i) => 100 + i * 2.0),
      ),
      KumoTimeseriesData(
        name: 'Errors',
        color: KumoChartColors.light.semantic(KumoChartSemanticColor.attention),
        data: _points(30, (i) => (i % 5).toDouble()),
        lineStyle: KumoTimeseriesLineStyle.dashed,
      ),
    ];

Finder get _chart => find.byType(KumoTimeseriesChart);

/// The chart's own semantics node (its summary and active point).
Finder get _chartNode => find.descendant(
      of: _chart,
      matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.label?.contains(' chart, ') ?? false)),
    );

Future<TestGesture> _hover(WidgetTester tester, Offset at) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(at);
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('renders line, area and bar charts in light and dark', (tester) async {
    for (final b in Brightness.values) {
      for (final type in KumoTimeseriesChartType.values) {
        await pumpKumo(
          tester,
          KumoTimeseriesChart(
            data: _series(),
            type: type,
            gradient: true,
            xAxisName: 'Time (UTC)',
            yAxisName: 'Count',
            thresholds: [
              KumoTimeseriesThreshold(value: 150, label: 'Limit', color: KumoChartColors.light.semantic(KumoChartSemanticColor.attention)),
              KumoTimeseriesThreshold(value: 40, endValue: 60, label: 'Target', color: KumoChartColors.light.semantic(KumoChartSemanticColor.success)),
            ],
            markers: [KumoTimeseriesMarker(time: _t0.add(const Duration(minutes: 10)), label: 'Deploy 4f2c1a9')],
            incomplete: KumoTimeseriesIncomplete(after: _t0.add(const Duration(minutes: 25))),
          ),
          brightness: b,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('defaults to 350px tall on wide screens and 260px on phones', (tester) async {
    await pumpKumo(tester, KumoTimeseriesChart(data: _series()));
    expect(tester.getSize(_chart).height, 260);
    await pumpKumo(tester, KumoTimeseriesChart(data: _series()), size: kumoDesktopSize);
    expect(tester.getSize(_chart).height, 350);
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), height: 200));
    expect(tester.getSize(_chart).height, 200);
  });

  testWidgets('semantics summarise series, ranges, thresholds and markers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      KumoTimeseriesChart(
        data: _series(),
        semanticLabel: 'Requests for image-resizer',
        thresholds: const [KumoTimeseriesThreshold(value: 150, label: 'Limit', color: Color(0xFFFC574A))],
        markers: [KumoTimeseriesMarker(time: _t0.add(const Duration(minutes: 10)), label: 'Deploy 4f2c1a9')],
      ),
    );
    final label = tester.getSemantics(_chartNode).label;
    expect(label, startsWith('Requests for image-resizer. Line chart, 2 series, Mar 4, 14:00 to Mar 4, 14:29'));
    expect(label, contains('Requests: 100 to 158, latest 158'));
    expect(label, contains('Errors: 0 to 4, latest 4'));
    expect(label, contains('Limit at 150'));
    expect(label, contains('Deploy 4f2c1a9 at Mar 4, 14:10'));
    handle.dispose();
  });

  testWidgets('hovering shows a tooltip with every series, largest first, formatted', (tester) async {
    await pumpKumo(
      tester,
      KumoTimeseriesChart(data: _series(), tooltipValueFormat: (v) => '${v.toStringAsFixed(0)} req', tooltipFooter: 'Sample data'),
    );
    expect(find.text('Requests'), findsNothing);
    await _hover(tester, tester.getCenter(_chart));
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Errors'), findsOneWidget);
    expect(find.text('Sample data'), findsOneWidget);
    expect(find.textContaining(' req'), findsNWidgets(2));
    final requests = tester.getTopLeft(find.text('Requests')).dy;
    final errors = tester.getTopLeft(find.text('Errors')).dy;
    expect(requests, lessThan(errors));
  });

  testWidgets('tooltip follows the pointer and hides when it leaves', (tester) async {
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), tooltipTimestampFormat: (d) => 'at ${d.minute}'));
    final rect = tester.getRect(_chart);
    final gesture = await _hover(tester, rect.centerLeft + const Offset(80, 0));
    final first = find.textContaining('at ');
    final firstLabel = (tester.widget<Text>(first)).data;
    final firstX = tester.getTopLeft(first).dx;
    await gesture.moveTo(rect.centerLeft + const Offset(200, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.textContaining('at ')).dx, greaterThan(firstX));
    expect(tester.widget<Text>(find.textContaining('at ')).data, isNot(firstLabel));
    await gesture.moveTo(rect.bottomRight + const Offset(0, 40));
    await tester.pump();
    expect(find.textContaining('at '), findsNothing);
  });

  testWidgets('single tooltip mode lists only the series nearest the pointer', (tester) async {
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), tooltipMode: KumoTimeseriesTooltipMode.single));
    final rect = tester.getRect(_chart);
    // Near the bottom of the plot, the Errors series (0 to 4) is closest.
    await _hover(tester, Offset(rect.center.dx, rect.bottom - 40));
    expect(find.text('Errors'), findsOneWidget);
    expect(find.text('Requests'), findsNothing);
  });

  testWidgets('tooltipMaxItems collapses the rest into a +N more line', (tester) async {
    await pumpKumo(
      tester,
      KumoTimeseriesChart(
        tooltipMaxItems: 2,
        data: [
          for (var s = 0; s < 4; s++)
            KumoTimeseriesData(name: 'zone-$s', color: KumoChartColors.light.categorical(s), data: _points(10, (i) => s * 10.0 + i)),
        ],
      ),
    );
    await _hover(tester, tester.getCenter(_chart));
    expect(find.text('+2 more'), findsOneWidget);
    expect(find.text('zone-3'), findsOneWidget);
    expect(find.text('zone-0'), findsNothing);
  });

  testWidgets('hovering a marker shows its label, description and values', (tester) async {
    final markerTime = _t0.add(const Duration(minutes: 15));
    await pumpKumo(
      tester,
      KumoTimeseriesChart(
        data: _series(),
        markers: [KumoTimeseriesMarker(time: markerTime, label: 'Deploy 4f2c1a9', description: 'image-resizer v42')],
      ),
    );
    final rect = tester.getRect(_chart);
    // Scan across the plot until the marker tooltip appears.
    final gesture = await _hover(tester, rect.center);
    var found = false;
    for (var x = rect.left + 30; x < rect.right - 24 && !found; x += 1) {
      await gesture.moveTo(Offset(x, rect.center.dy));
      await tester.pump();
      found = find.text('image-resizer v42').evaluate().isNotEmpty;
    }
    expect(found, isTrue);
    expect(find.text('Deploy 4f2c1a9'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
  });

  testWidgets('close markers merge into one "N changes" cluster', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      KumoTimeseriesChart(
        data: _series(),
        markers: [
          for (var i = 0; i < 3; i++) KumoTimeseriesMarker(time: _t0.add(Duration(minutes: 10 + i)), label: 'change $i'),
        ],
      ),
    );
    final rect = tester.getRect(_chart);
    final gesture = await _hover(tester, rect.center);
    var found = false;
    for (var x = rect.left + 30; x < rect.right - 24 && !found; x += 1) {
      await gesture.moveTo(Offset(x, rect.center.dy));
      await tester.pump();
      found = find.text('change 1').evaluate().isNotEmpty;
    }
    expect(found, isTrue);
    expect(find.text('change 0'), findsOneWidget);
    expect(find.text('change 2'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('touch: tooltip appears on contact, follows a drag 1:1 and clicks on each new point', (tester) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), tooltipTimestampFormat: (d) => 'minute ${d.minute}'));
    final rect = tester.getRect(_chart);
    final g = await tester.startGesture(rect.centerLeft + const Offset(60, 0));
    await tester.pump();
    expect(find.textContaining('minute '), findsOneWidget);
    expect(haptics, isEmpty);
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(12, 0));
      await tester.pump();
    }
    expect(haptics, isNotEmpty);
    expect(haptics.every((h) => h == 'HapticFeedbackType.selectionClick'), isTrue);
    await g.up();
    await tester.pump();
    // Stays after lifting so it can be read; a tap outside clears it.
    expect(find.textContaining('minute '), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(find.textContaining('minute '), findsNothing);
  });

  testWidgets('touch: a vertical drag scrolls the page and drops the tooltip', (tester) async {
    await pumpKumo(
      tester,
      ListView(children: [
        KumoTimeseriesChart(data: _series(), tooltipTimestampFormat: (d) => 'minute ${d.minute}'),
        const SizedBox(height: 1000),
      ]),
      center: false,
    );
    final rect = tester.getRect(_chart);
    final g = await tester.startGesture(rect.center);
    await tester.pump();
    expect(find.textContaining('minute '), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(0, -15));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(find.textContaining('minute '), findsNothing);
    expect(tester.getRect(_chart).top, lessThan(rect.top));
  });

  testWidgets('keyboard: arrows step through points, Escape hides', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), tooltipTimestampFormat: (d) => 'minute ${d.minute}'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('minute 0'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('minute 1'), findsOneWidget);
    expect(tester.getSemantics(_chartNode).value, contains('Requests 102'));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(find.text('minute 29'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.textContaining('minute '), findsNothing);
    handle.dispose();
  });

  testWidgets('screen reader increase and decrease step through points', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), tooltipTimestampFormat: (d) => 'minute ${d.minute}'));
    final node = tester.getSemantics(_chartNode);
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(tester.getSemantics(_chartNode).value, startsWith('minute 0. Requests 100. Errors 0'));
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(tester.getSemantics(_chartNode).value, startsWith('minute 1'));
    handle.dispose();
  });

  testWidgets('legend toggles series, controlled and uncontrolled', (tester) async {
    final handle = tester.ensureSemantics();
    Set<String>? reported;
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), showLegend: true, onHiddenSeriesChange: (s) => reported = s));
    expect(find.text('Requests'), findsOneWidget);
    await tester.tap(find.text('Errors'));
    await tester.pumpAndSettle();
    expect(reported, {'Errors'});
    expect(tester.getSemantics(_chartNode).label, contains('1 series'));
    expect(tester.getSemantics(_chartNode).label, contains('Hidden: Errors'));

    // Controlled: the widget reflects the set it is given and only reports.
    await pumpKumo(
      tester,
      KumoTimeseriesChart(data: _series(), showLegend: true, hiddenSeries: const {'Requests'}, onHiddenSeriesChange: (s) => reported = s),
    );
    expect(tester.getSemantics(_chartNode).label, contains('Hidden: Requests'));
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(reported, isEmpty);
    expect(tester.getSemantics(_chartNode).label, contains('Hidden: Requests'));
    handle.dispose();
  });

  testWidgets('hidden series leave the tooltip', (tester) async {
    await pumpKumo(tester, KumoTimeseriesChart(data: _series(), hiddenSeries: const {'Errors'}));
    await _hover(tester, tester.getCenter(_chart));
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Errors'), findsNothing);
  });

  testWidgets('data changes morph, and are instant under reduced motion', (tester) async {
    await pumpKumo(tester, KumoTimeseriesChart(data: _series()));
    final next = [
      KumoTimeseriesData(name: 'Requests', color: const Color(0xFF4290F0), data: _points(30, (i) => 300 - i * 1.0)),
    ];
    await tester.pumpWidget(kumoHarness(KumoTimeseriesChart(data: next)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await pumpKumo(tester, KumoTimeseriesChart(data: _series()), disableAnimations: true);
    await tester.pumpWidget(kumoHarness(KumoTimeseriesChart(data: next), disableAnimations: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('loading shows the skeleton; the sheen runs only while loading and never under reduced motion',
      (tester) async {
    final handle = tester.ensureSemantics();
    for (final type in KumoTimeseriesChartType.values) {
      await pumpKumo(tester, KumoTimeseriesChart(data: const [], type: type, loading: true, showLegend: true), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('Loading chart'), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
    }
    await pumpKumo(tester, KumoTimeseriesChart(data: _series()));
    expect(tester.hasRunningAnimations, isFalse);
    await pumpKumo(tester, const KumoTimeseriesChart(data: [], loading: true), disableAnimations: true);
    expect(tester.hasRunningAnimations, isFalse);
    handle.dispose();
  });

  testWidgets('error state names the problem and retries', (tester) async {
    var retries = 0;
    await pumpKumo(
      tester,
      KumoTimeseriesChart(data: _series(), error: 'Could not load requests. Check your connection, then retry.', onRetry: () => retries++),
    );
    expect(find.text('Could not load requests. Check your connection, then retry.'), findsOneWidget);
    expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('empty state when no series has a point', (tester) async {
    await pumpKumo(tester, const KumoTimeseriesChart(data: [KumoTimeseriesData(name: 'Requests', color: Color(0xFF4290F0), data: [])]));
    expect(find.text('No data in this time range'), findsOneWidget);
    expect(find.text('Choose a longer time range to see earlier data.'), findsOneWidget);
  });

  testWidgets('mouse drag selects a time range', (tester) async {
    DateTime? from;
    DateTime? to;
    await pumpKumo(
      tester,
      KumoTimeseriesChart(data: _series(), onTimeRangeChange: (a, b) {
        from = a;
        to = b;
      }),
    );
    final rect = tester.getRect(_chart);
    final g = await tester.startGesture(rect.centerLeft + const Offset(80, 0), kind: PointerDeviceKind.mouse);
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(15, 0));
      await tester.pump();
    }
    await g.up();
    await tester.pump();
    expect(from, isNotNull);
    expect(to!.isAfter(from!), isTrue);
    expect(from!.isAfter(_t0), isTrue);
  });

  testWidgets('NaN values and unsorted input do not throw', (tester) async {
    await pumpKumo(
      tester,
      KumoTimeseriesChart(data: [
        KumoTimeseriesData(
          name: 'Requests',
          color: const Color(0xFF4290F0),
          data: [..._points(10, (i) => i == 4 ? double.nan : i.toDouble()).reversed],
        ),
      ]),
    );
    await _hover(tester, tester.getCenter(_chart));
    expect(tester.takeException(), isNull);
  });

  testWidgets('time labels adapt from seconds to years without errors', (tester) async {
    for (final step in const [Duration(seconds: 1), Duration(minutes: 30), Duration(days: 1), Duration(days: 40), Duration(days: 400)]) {
      await pumpKumo(
        tester,
        KumoTimeseriesChart(data: [KumoTimeseriesData(name: 'Requests', color: const Color(0xFF4290F0), data: _points(40, (i) => i * 1.5, step: step))]),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('text scale 2.0, RTL and 390px width lay out without overflow', (tester) async {
    await pumpKumo(
      tester,
      KumoTimeseriesChart(data: _series(), showLegend: true, xAxisName: 'Time (UTC)', yAxisName: 'Requests per second'),
      textScale: 2,
      textDirection: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await _hover(tester, tester.getCenter(_chart));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the skeleton cross-fades into the chart; instantly under reduced motion', (tester) async {
    await pumpKumo(tester, const KumoTimeseriesChart(data: [], loading: true), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    await pumpKumo(tester, KumoTimeseriesChart(data: _series()), settle: false);
    await tester.pump(const Duration(milliseconds: 60));
    final fades = tester
        .widgetList<FadeTransition>(find.descendant(of: _chart, matching: find.byType(FadeTransition)))
        .map((f) => f.opacity.value)
        .where((v) => v > 0 && v < 1);
    expect(fades, isNotEmpty);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);

    await pumpKumo(tester, const KumoTimeseriesChart(data: [], loading: true), disableAnimations: true);
    await pumpKumo(tester, KumoTimeseriesChart(data: _series()), disableAnimations: true, settle: false);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
