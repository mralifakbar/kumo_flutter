import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

// Three square tiles side by side, in their own coordinate space.
final _regions = [
  for (final (i, id) in ['wnam', 'enam', 'weur'].indexed)
    KumoMapRegion(id: id, name: id.toUpperCase(), path: Path()..addRect(Rect.fromLTWH(i * 10.0, 0, 9, 9))),
];

const _values = {'wnam': 120.0, 'enam': 480.0};

Finder get _chart => find.byType(KumoMapChart);

Finder get _node => find.descendant(
  of: _chart,
  matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.label?.contains('Map, ') ?? false)),
);

void main() {
  testWidgets('renders in light and dark, with and without a legend', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        KumoMapChart(regions: _regions, values: _values, showLegend: true),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    }
  });

  testWidgets('height follows the shapes\' aspect unless given', (tester) async {
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: _values));
    final size = tester.getSize(_chart);
    expect(size.width / size.height, closeTo(29 / 9, 0.05));
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: _values, height: 200));
    expect(tester.getSize(_chart).height, 200);
  });

  testWidgets('hover shows the region name and value; press reports the region', (tester) async {
    KumoMapRegion? pressed;
    final hovered = <String?>[];
    await pumpKumo(
      tester,
      KumoMapChart(
        regions: _regions,
        values: _values,
        valueFormat: (v) => '${v.round()} req/s',
        onRegionPress: (r) => pressed = r,
        onRegionHover: (r) => hovered.add(r?.id),
      ),
    );
    final rect = tester.getRect(_chart);
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    addTearDown(g.removePointer);
    final enam = Offset(rect.left + rect.width * 14.5 / 29, rect.center.dy);
    await g.moveTo(enam);
    await tester.pump();
    expect(find.text('ENAM'), findsOneWidget);
    expect(find.text('480 req/s'), findsOneWidget);
    // Regions without data show no tooltip.
    await g.moveTo(Offset(rect.left + rect.width * 24.5 / 29, rect.center.dy));
    await tester.pump();
    expect(find.text('WEUR'), findsNothing);
    await g.down(enam);
    await g.up();
    expect(pressed?.id, 'enam');
    expect(hovered, ['enam', null]);
  });

  testWidgets('semantics list regions by value; keyboard steps through them', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: _values, semanticLabel: 'Requests by region'));
    expect(tester.getSemantics(_node).label, 'Requests by region. Map, 3 regions, 2 with data. ENAM: 480. WNAM: 120.');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.getSemantics(_node).value, 'WNAM, 120');
    expect(find.text('WNAM'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.getSemantics(_node).value, 'ENAM, 480');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('ENAM'), findsNothing);
    handle.dispose();
  });

  testWidgets('value changes cross-fade, instantly under reduced motion', (tester) async {
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: _values));
    await tester.pumpWidget(kumoHarness(KumoMapChart(regions: _regions, values: const {'wnam': 10, 'weur': 900})));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: _values), disableAnimations: true);
    await tester.pumpWidget(
      kumoHarness(KumoMapChart(regions: _regions, values: const {'wnam': 10}), disableAnimations: true),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('fromPolygons projects longitude and latitude north up', (tester) async {
    final r = KumoMapRegion.fromPolygons(
      id: 'box',
      rings: const [
        [Offset(-10, 50), Offset(10, 50), Offset(10, 40), Offset(-10, 40)],
      ],
    );
    expect(r.path.getBounds(), const Rect.fromLTRB(-10, -50, 10, -40));
    expect(r.label, 'box');
  });

  testWidgets('loading, error and empty states', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: _values, loading: true));
    expect(find.bySemanticsLabel('Loading map'), findsOneWidget);
    var retries = 0;
    await pumpKumo(
      tester,
      KumoMapChart(regions: _regions, values: _values, error: 'Could not load regions.', onRetry: () => retries++),
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: const {}));
    expect(find.text('No data for these regions'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('text scale 2.0 does not overflow', (tester) async {
    await pumpKumo(tester, KumoMapChart(regions: _regions, values: _values, showLegend: true), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
