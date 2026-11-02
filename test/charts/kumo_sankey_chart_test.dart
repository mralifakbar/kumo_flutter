import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _nodes = [
  KumoSankeyNode(name: 'Users', value: 103600),
  KumoSankeyNode(name: 'Devices', value: 50800),
  KumoSankeyNode(name: 'Workers', value: 122600, tooltipData: {'Scripts': 42}),
  KumoSankeyNode(name: 'Tunnels', value: 31800),
];

const _links = [
  KumoSankeyLink(source: 0, target: 2, value: 80000),
  KumoSankeyLink(source: 0, target: 3, value: 23600),
  KumoSankeyLink(source: 1, target: 2, value: 42600),
  KumoSankeyLink(source: 1, target: 3, value: 8200),
];

Finder get _chart => find.byType(KumoSankeyChart);

Finder get _node => find.descendant(
      of: _chart,
      matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.label?.contains('Sankey chart, ') ?? false)),
    );

Future<TestGesture> _mouse(WidgetTester tester) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  return g;
}

void main() {
  testWidgets('renders every option in light and dark', (tester) async {
    for (final b in Brightness.values) {
      for (final align in KumoSankeyNodeAlign.values) {
        for (final layout in KumoSankeyLabelLayout.values) {
          await pumpKumo(
            tester,
            KumoSankeyChart(
              nodes: _nodes,
              links: _links,
              height: 300,
              nodeAlign: align,
              nodeLabelLayout: layout,
              linkColor: layout == KumoSankeyLabelLayout.inline ? KumoSankeyLinkColor.gray : KumoSankeyLinkColor.gradient,
            ),
            brightness: b,
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('multi-level flows and invalid links lay out without errors', (tester) async {
    await pumpKumo(
      tester,
      const KumoSankeyChart(
        nodes: [
          KumoSankeyNode(name: 'Input 1'),
          KumoSankeyNode(name: 'Input 2'),
          KumoSankeyNode(name: 'Process A'),
          KumoSankeyNode(name: 'Output X'),
          KumoSankeyNode(name: 'Unused'),
        ],
        links: [
          KumoSankeyLink(source: 0, target: 2, value: 40),
          KumoSankeyLink(source: 1, target: 2, value: 30),
          KumoSankeyLink(source: 2, target: 3, value: 70),
          KumoSankeyLink(source: 3, target: 3, value: 5),
          KumoSankeyLink(source: 0, target: 9, value: 5),
          KumoSankeyLink(source: 1, target: 3, value: 0),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics list every flow', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links, semanticLabel: 'Traffic by source'));
    final label = tester.getSemantics(_node).label;
    expect(label, startsWith('Traffic by source. Sankey chart, 4 nodes, 4 flows'));
    expect(label, contains('Users to Workers: 80,000'));
    expect(label, contains('Devices to Tunnels: 8,200'));
    handle.dispose();
  });

  testWidgets('hovering a node shows its tooltip with tooltipData', (tester) async {
    await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links, height: 300));
    final rect = tester.getRect(_chart);
    final g = await _mouse(tester);
    // Workers is the top node of the right column (justify alignment).
    await g.moveTo(Offset(rect.right - 4, rect.top + 60));
    await tester.pump();
    expect(find.text('Scripts'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    await g.moveTo(rect.bottomRight + const Offset(0, 50));
    await tester.pump();
    expect(find.text('Scripts'), findsNothing);
  });

  testWidgets('hovering a link shows source, target and value; pressing it reports the link', (tester) async {
    KumoSankeyLink? pressed;
    await pumpKumo(
      tester,
      KumoSankeyChart(nodes: _nodes, links: _links, height: 300, onLinkPress: (l) => pressed = l, formatValue: (v) => '${v ~/ 1000}k'),
    );
    final rect = tester.getRect(_chart);
    final g = await _mouse(tester);
    // The widest band, Users to Workers, runs straight across the top.
    final p = Offset(rect.center.dx, rect.top + 50);
    await g.moveTo(p);
    await tester.pump();
    expect(find.text('80k'), findsOneWidget);
    await g.down(p);
    await g.up();
    await tester.pump();
    expect(pressed, _links.first);
  });

  testWidgets('touch: tap highlights and shows the tooltip, tap outside clears', (tester) async {
    int? pressedIndex;
    await pumpKumo(
      tester,
      Column(children: [
        KumoSankeyChart(nodes: _nodes, links: _links, height: 300, onNodePress: (n, i) => pressedIndex = i),
        const SizedBox(height: 200, width: 300),
      ]),
    );
    final rect = tester.getRect(_chart);
    await tester.tapAt(Offset(rect.right - 4, rect.top + 60));
    await tester.pump();
    expect(pressedIndex, 2);
    expect(find.text('Scripts'), findsOneWidget);
    await tester.tapAt(rect.bottomCenter + const Offset(0, 100));
    await tester.pump();
    expect(find.text('Scripts'), findsNothing);
  });

  testWidgets('keyboard: arrows move between nodes, Enter presses, Escape clears', (tester) async {
    final handle = tester.ensureSemantics();
    int? pressed;
    await pumpKumo(tester, KumoSankeyChart(nodes: _nodes, links: _links, onNodePress: (n, i) => pressed = i));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(tester.getSemantics(_node).value, startsWith('Users, 103,600'));
    expect(tester.getSemantics(_node).value, contains('to Workers 80,000'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(pressed, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(tester.getSemantics(_node).value, startsWith('Tunnels'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.getSemantics(_node).value, isEmpty);
    handle.dispose();
  });

  testWidgets('custom tooltipBuilder replaces the content', (tester) async {
    await pumpKumo(
      tester,
      KumoSankeyChart(
        nodes: _nodes,
        links: _links,
        height: 300,
        tooltipBuilder: (context, d) => d.isNode ? Text('Node ${d.node!.name}') : null,
      ),
    );
    final rect = tester.getRect(_chart);
    final g = await _mouse(tester);
    await g.moveTo(Offset(rect.right - 4, rect.top + 60));
    await tester.pump();
    expect(find.text('Node Workers'), findsOneWidget);
  });

  testWidgets('data changes morph, instantly under reduced motion', (tester) async {
    const next = [
      KumoSankeyLink(source: 0, target: 2, value: 20000),
      KumoSankeyLink(source: 0, target: 3, value: 60000),
      KumoSankeyLink(source: 1, target: 2, value: 42600),
    ];
    await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links));
    await tester.pumpWidget(kumoHarness(const KumoSankeyChart(nodes: _nodes, links: next)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links), disableAnimations: true);
    await tester.pumpWidget(kumoHarness(const KumoSankeyChart(nodes: _nodes, links: next), disableAnimations: true));
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('loading, error and empty states', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoSankeyChart(nodes: [], links: [], loading: true), settle: false);
    expect(find.bySemanticsLabel('Loading chart'), findsOneWidget);
    var retries = 0;
    await pumpKumo(tester, KumoSankeyChart(nodes: _nodes, links: _links, error: 'Could not load traffic flows.', onRetry: () => retries++));
    expect(find.text('Could not load traffic flows.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: []));
    expect(find.text('No flows to show'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links, height: 300), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  group('highlight motion', () {
    CustomPainter painter(WidgetTester tester) => tester
        .widget<CustomPaint>(find.descendant(
          of: _chart,
          matching: find.byWidgetPredicate((w) => w is CustomPaint && '${w.painter.runtimeType}' == '_SankeyPainter'),
        ))
        .painter!;

    testWidgets('hovering eases the other flows down instead of popping', (tester) async {
      await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links, height: 300));
      final rect = tester.getRect(_chart);
      final g = await _mouse(tester);
      await g.moveTo(Offset(rect.right - 4, rect.top + 60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final early = painter(tester);
      await tester.pump(const Duration(milliseconds: 40));
      final later = painter(tester);
      expect(tester.hasRunningAnimations, isTrue);
      expect(later.shouldRepaint(early), isTrue, reason: 'the emphasis is still moving');
      await tester.pumpAndSettle();
      final settled = painter(tester);
      expect(settled.shouldRepaint(later), isTrue);
      await tester.pump(const Duration(milliseconds: 40));
      expect(painter(tester).shouldRepaint(settled), isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion: the highlight lands in one frame', (tester) async {
      await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links, height: 300), disableAnimations: true);
      final rect = tester.getRect(_chart);
      final g = await _mouse(tester);
      await g.moveTo(Offset(rect.right - 4, rect.top + 60));
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Scripts'), findsOneWidget);
    });

    testWidgets('the skeleton cross-fades into the diagram', (tester) async {
      await pumpKumo(tester, const KumoSankeyChart(nodes: [], links: [], loading: true), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      await pumpKumo(tester, const KumoSankeyChart(nodes: _nodes, links: _links), settle: false);
      await tester.pump(const Duration(milliseconds: 60));
      final fades = tester
          .widgetList<FadeTransition>(find.descendant(of: _chart, matching: find.byType(FadeTransition)))
          .map((f) => f.opacity.value)
          .where((v) => v > 0 && v < 1);
      expect(fades, isNotEmpty);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse, reason: 'the skeleton sheen stops with the skeleton');
    });
  });
}
