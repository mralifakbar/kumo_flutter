import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _pipeline = [
  KumoFlowNode(label: 'Request'),
  KumoFlowNode(label: 'WAF'),
  KumoFlowNode(label: 'image-resizer'),
  KumoFlowNode(label: 'Origin'),
];

const _branches = [
  KumoFlowNode(label: 'Request'),
  KumoFlowParallel(
    children: [
      KumoFlowList(
        children: [
          KumoFlowNode(label: 'Validate token'),
          KumoFlowNode(label: 'Load session'),
        ],
      ),
      KumoFlowNode(label: 'Rate limit'),
    ],
  ),
  KumoFlowNode(label: 'Origin'),
];

const _long = [
  'Start', 'Authenticate', 'Validate', 'Transform', 'Process', //
  'Store', 'Notify', 'Log', 'Complete', 'End',
];

List<KumoFlowEntry> _longFlow({VoidCallback? onPress}) => [
  for (final l in _long) KumoFlowNode(id: l, label: l, onPress: onPress),
];

double _x(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dx;

void main() {
  group('rendering', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders nodes and connectors in ${brightness.name} mode', (tester) async {
        await pumpKumo(tester, const KumoFlowDiagram(children: _branches), brightness: brightness);
        expect(tester.takeException(), isNull);
        for (final label in ['Request', 'Validate token', 'Load session', 'Rate limit', 'Origin']) {
          expect(find.text(label), findsOneWidget);
        }
      });
    }

    testWidgets('default node uses Kumo spacing: 12px by 8px around 14px text', (tester) async {
      KumoFlowGeometry? g;
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          onGeometryChange: (v) => g = v,
          children: const [KumoFlowNode(label: 'WAF')],
        ),
      );
      final text = tester.getSize(find.text('WAF'));
      expect(text.height, 21);
      expect(g!.nodes.single.size, Size(text.width + 24, 21 + 16));
    });

    testWidgets('sizes itself to the content plus Kumo padding (16 by 64)', (tester) async {
      KumoFlowGeometry? g;
      await pumpKumo(
        tester,
        KumoFlowDiagram(onGeometryChange: (v) => g = v, children: _pipeline),
        size: kumoDesktopSize,
      );
      final size = tester.getSize(find.byType(KumoFlowDiagram));
      expect(size.width, kumoDesktopSize.width);
      expect(size.height, g!.size.height + 128);
    });

    testWidgets('a custom render replaces the node card', (tester) async {
      await pumpKumo(
        tester,
        const KumoFlowDiagram(
          children: [
            KumoFlowNode(render: SizedBox(key: Key('dot'), width: 16, height: 16)),
            KumoFlowNode(label: 'my-worker'),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(const Key('dot'))), const Size(16, 16));
      expect(find.descendant(of: find.byKey(const Key('dot')), matching: find.byType(DecoratedBox)), findsNothing);
    });

    testWidgets('KumoFlowAnchor outside a node throws', (tester) async {
      await pumpKumo(tester, const KumoFlowAnchor(child: Text('Bindings')));
      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('KumoFlowAnchor must be used within a KumoFlowNode'));
    });

    testWidgets('an empty diagram lays out without errors', (tester) async {
      await pumpKumo(tester, const KumoFlowDiagram(children: []));
      expect(tester.takeException(), isNull);
    });

    testWidgets('nodes keep their state by id when a node is added before them', (tester) async {
      final showFirst = ValueNotifier(false);
      addTearDown(showFirst.dispose);
      await pumpKumo(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: showFirst,
          builder: (_, show, _) => KumoFlowDiagram(
            children: [
              if (show) const KumoFlowNode(id: 'cache', label: 'Cache'),
              const KumoFlowNode(id: 'counter', render: _Counter()),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Taps 0'));
      await tester.pump();
      expect(find.text('Taps 1'), findsOneWidget);
      showFirst.value = true;
      await tester.pumpAndSettle();
      expect(find.text('Cache'), findsOneWidget);
      expect(find.text('Taps 1'), findsOneWidget);
    });
  });

  group('pressable nodes', () {
    testWidgets('tap calls onPress; disabled nodes do not', (tester) async {
      final pressed = <String>[];
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          children: [
            KumoFlowNode(label: 'Primary', onPress: () => pressed.add('primary')),
            KumoFlowNode(label: 'Backup', disabled: true, onPress: () => pressed.add('backup')),
          ],
        ),
      );
      await tester.tap(find.text('Primary'));
      await tester.tap(find.text('Backup'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pressed, ['primary']);
    });

    testWidgets('the hit area reaches 44px on touch without moving the node', (tester) async {
      var taps = 0;
      KumoFlowGeometry? g;
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          onGeometryChange: (v) => g = v,
          children: [KumoFlowNode(label: 'WAF', onPress: () => taps++)],
        ),
      );
      // The node keeps Kumo's 37px height in the layout...
      expect(g!.nodes.single.height, 37);
      // ...but a tap 3px above its top edge still lands.
      final top = tester.getTopLeft(find.text('WAF')) - const Offset(0, 8);
      await tester.tapAt(top + const Offset(4, -3));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('selected state is shown and announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          children: [
            KumoFlowNode(label: 'Request', onPress: () {}),
            KumoFlowNode(label: 'WAF', selected: true, onPress: () {}),
          ],
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('WAF')),
        containsSemantics(label: 'WAF', value: 'Step 2 of 2', isButton: true, isSelected: true, hasTapAction: true),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Request')), containsSemantics(isSelected: false));
      handle.dispose();
    });

    group('node motion', () {
      Widget diagram({required bool selected}) => KumoFlowDiagram(
        children: [KumoFlowNode(label: 'WAF', selected: selected, onPress: () {})],
      );
      double ringWidth(WidgetTester tester) {
        final box = tester.widget<DecoratedBox>(
          find.ancestor(of: find.text('WAF'), matching: find.byType(DecoratedBox)).first,
        );
        return ((box.decoration as BoxDecoration).border! as Border).top.width;
      }

      testWidgets('selection eases the ring and tint in', (tester) async {
        await pumpKumo(tester, diagram(selected: false));
        expect(ringWidth(tester), 1);
        await pumpKumo(tester, diagram(selected: true), settle: false);
        await tester.pump(const Duration(milliseconds: 50));
        expect(ringWidth(tester), inExclusiveRange(1, 2));
        await tester.pumpAndSettle();
        expect(ringWidth(tester), 2);
      });

      testWidgets('a held node scales down', (tester) async {
        await pumpKumo(tester, diagram(selected: false));
        final gesture = await tester.startGesture(tester.getCenter(find.text('WAF')));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 100));
        final scale = tester
            .widgetList<Transform>(find.ancestor(of: find.text('WAF'), matching: find.byType(Transform)))
            .map((t) => t.transform.storage[0])
            .reduce((a, b) => a < b ? a : b);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(scale, lessThan(1));
      });

      testWidgets('reduced motion: selection lands in one frame', (tester) async {
        await pumpKumo(tester, diagram(selected: false), disableAnimations: true);
        await pumpKumo(tester, diagram(selected: true), disableAnimations: true, settle: false);
        await tester.pump();
        expect(ringWidth(tester), 2);
        expect(tester.hasRunningAnimations, isFalse);
      });
    });

    testWidgets('Enter activates a focused node', (tester) async {
      var taps = 0;
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          children: [KumoFlowNode(label: 'Deploy', onPress: () => taps++)],
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 2);
    });

    testWidgets('Tab follows step order across branches', (tester) async {
      final pressed = <String>[];
      KumoFlowNode node(String l) => KumoFlowNode(label: l, onPress: () => pressed.add(l));
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          children: [
            node('Request'),
            KumoFlowParallel(children: [node('WAF'), node('Rate limit')]),
            node('Origin'),
          ],
        ),
        size: kumoDesktopSize,
      );
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
      }
      expect(pressed, ['Request', 'WAF', 'Rate limit', 'Origin']);
    });
  });

  group('semantics', () {
    testWidgets('each node announces its label and step', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(tester, const KumoFlowDiagram(semanticLabel: 'Request path', children: _pipeline));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Request path')),
        containsSemantics(label: 'Request path', value: '4 steps'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('image-resizer')),
        containsSemantics(label: 'image-resizer', value: 'Step 3 of 4'),
      );
      handle.dispose();
    });

    testWidgets('branches are announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(tester, const KumoFlowDiagram(children: _branches), size: kumoDesktopSize);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Load session')),
        containsSemantics(value: 'Step 2 of 3, branch 1 of 2, Step 2 of 2'),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Rate limit')),
        containsSemantics(value: 'Step 2 of 3, branch 2 of 2'),
      );
      handle.dispose();
    });

    testWidgets('screen readers visit steps in flow order, not screen order', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(tester, const KumoFlowDiagram(children: _branches), size: kumoDesktopSize);
      final labels = [
        for (final node in tester.semantics.simulatedAccessibilityTraversal())
          if (node.label.isNotEmpty && node.value.startsWith('Step')) node.label,
      ];
      expect(labels, ['Request', 'Validate token', 'Load session', 'Rate limit', 'Origin']);
      handle.dispose();
    });

    testWidgets('disabled nodes are announced as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        const KumoFlowDiagram(
          children: [
            KumoFlowNode(label: 'Request'),
            KumoFlowNode(label: 'Backup', disabled: true),
          ],
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Backup')),
        containsSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('custom strings localize the announcements', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          strings: KumoFlowStrings(
            diagram: 'Diagrama',
            step: (i, n) => 'Paso $i de $n',
            branch: (i, n) => 'rama $i de $n',
            steps: (n) => '$n pasos',
          ),
          children: const [
            KumoFlowNode(label: 'Inicio'),
            KumoFlowNode(label: 'Fin'),
          ],
        ),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Diagrama')), containsSemantics(value: '2 pasos'));
      expect(tester.getSemantics(find.bySemanticsLabel('Fin')), containsSemantics(value: 'Paso 2 de 2'));
      handle.dispose();
    });
  });

  group('panning', () {
    testWidgets('reports overflow on narrow screens only', (tester) async {
      final reports = <KumoFlowOverflow>[];
      await pumpKumo(tester, KumoFlowDiagram(onOverflowChange: reports.add, children: _longFlow()));
      expect(reports, [const KumoFlowOverflow(x: true)]);

      final wide = <KumoFlowOverflow>[];
      await pumpKumo(
        tester,
        KumoFlowDiagram(onOverflowChange: wide.add, children: _pipeline),
        size: kumoDesktopSize,
      );
      expect(wide, [const KumoFlowOverflow()]);
    });

    testWidgets('the content follows the finger 1:1', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow()));
      final before = _x(tester, 'Start');
      final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoFlowDiagram)));
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.moveBy(const Offset(-110, 0));
      await tester.pump();
      expect(_x(tester, 'Start'), closeTo(before - 150, 0.01));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a fling carries on with momentum and stops at the end', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow()));
      final before = _x(tester, 'Start');
      await tester.fling(find.byType(KumoFlowDiagram), const Offset(-200, 0), 3000);
      await tester.pump(const Duration(milliseconds: 100));
      final midway = _x(tester, 'Start');
      await tester.pumpAndSettle();
      final after = _x(tester, 'Start');
      expect(after, lessThan(midway));
      expect(before - after, greaterThan(400));
      // Never past the end: the last node stays inside the 16px padding.
      expect(tester.getTopRight(find.text('End')).dx, lessThanOrEqualTo(390 - 16 + 0.5));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('dragging past the start resists, then springs back', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow()));
      final before = _x(tester, 'Start');
      final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoFlowDiagram)));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      final pulled = _x(tester, 'Start') - before;
      expect(pulled, greaterThan(0));
      expect(pulled, lessThan(100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_x(tester, 'Start'), closeTo(before, 0.01));
    });

    testWidgets('RTL starts at the right and pans the other way', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow()), textDirection: TextDirection.rtl);
      expect(tester.getTopRight(find.text('Start')).dx, closeTo(390 - 16 - 12, 0.5));
      final before = _x(tester, 'Start');
      final gesture = await tester.startGesture(tester.getCenter(find.byType(KumoFlowDiagram)));
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();
      expect(_x(tester, 'Start'), closeTo(before + 120, 0.01));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping a node in a pannable diagram still presses it', (tester) async {
      var taps = 0;
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow(onPress: () => taps++)));
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('a horizontal mouse wheel pans; a vertical one is left to the page', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow()));
      final before = _x(tester, 'Start');
      final center = tester.getCenter(find.byType(KumoFlowDiagram));
      tester.binding.handlePointerEvent(PointerScrollEvent(position: center, scrollDelta: const Offset(0, 120)));
      await tester.pump();
      expect(_x(tester, 'Start'), before);
      tester.binding.handlePointerEvent(PointerScrollEvent(position: center, scrollDelta: const Offset(120, 0)));
      await tester.pump();
      expect(_x(tester, 'Start'), closeTo(before - 120, 0.01));
    });

    testWidgets('focusing an off-screen node pans it into view', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow(onPress: () {})));
      expect(tester.getTopLeft(find.text('Notify')).dx, greaterThan(390));
      for (var i = 0; i < 7; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.text('Notify'));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
    });

    testWidgets('reduced motion reveals instantly', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow(onPress: () {})), disableAnimations: true);
      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(tester.getRect(find.text('End')).right, lessThanOrEqualTo(390));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('scrollbars show while hovered, as in Kumo', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(children: _longFlow()));
      final theme = KumoThemeData.light(tapTargetSize: KumoTapTargetSize.padded);
      final track = theme.colors.hairline.withValues(alpha: theme.colors.hairline.a * 0.5);
      final diagram = find.byType(KumoFlowDiagram);
      var tracks = 0;
      bool countTracks(Symbol method, List<dynamic> args) {
        if (method == #drawRRect && (args[1] as Paint).color.toARGB32() == track.toARGB32()) tracks++;
        return true;
      }

      expect(diagram, paints..everything(countTracks));
      expect(tracks, 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(diagram));
      await tester.pump();
      expect(diagram, paints..everything(countTracks));
      expect(tracks, 1);
    });

    testWidgets('a vertical drag on a horizontal diagram scrolls the page', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpKumo(
        tester,
        SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              KumoFlowDiagram(children: _longFlow()),
              const SizedBox(height: 1200),
            ],
          ),
        ),
        center: false,
      );
      final before = _x(tester, 'Start');
      await tester.drag(find.byType(KumoFlowDiagram), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(100));
      expect(_x(tester, 'Start'), before);
    });

    testWidgets('canvas false keeps overflowing content in place', (tester) async {
      await pumpKumo(tester, KumoFlowDiagram(canvas: false, children: _longFlow()));
      final before = _x(tester, 'Start');
      await tester.drag(find.byType(KumoFlowDiagram), const Offset(-150, 0));
      await tester.pumpAndSettle();
      expect(_x(tester, 'Start'), before);
    });

    testWidgets('a screen reader scroll action pans by most of a page', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(tester, KumoFlowDiagram(semanticLabel: 'Pipeline', children: _longFlow()));
      final before = _x(tester, 'Start');
      final node = tester.getSemantics(find.bySemanticsLabel('Pipeline'));
      expect(node, containsSemantics(hasScrollLeftAction: true));
      node.owner!.performAction(node.id, SemanticsAction.scrollLeft);
      await tester.pumpAndSettle();
      expect(before - _x(tester, 'Start'), closeTo(358 * 0.8, 0.5));
      handle.dispose();
    });
  });

  group('mobile', () {
    testWidgets('text scale 2.0 at 390px: no overflow, taller nodes', (tester) async {
      KumoFlowGeometry? small;
      KumoFlowGeometry? large;
      await pumpKumo(tester, KumoFlowDiagram(onGeometryChange: (g) => small = g, children: _branches));
      await pumpKumo(tester, KumoFlowDiagram(onGeometryChange: (g) => large = g, children: _branches), textScale: 2);
      expect(tester.takeException(), isNull);
      // 21px of text becomes 42px; the 16px of vertical padding stays.
      expect(large!.nodes.first.height, closeTo(small!.nodes.first.height + 21, 0.5));
      // Connectors still meet the node centers.
      final c = large!.connectors.first;
      expect(c.start.dy, closeTo(large!.nodes[c.from].center.dy, 0.01));
    });

    testWidgets('a long label wraps inside the viewport instead of overflowing', (tester) async {
      KumoFlowGeometry? g;
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          orientation: KumoFlowOrientation.vertical,
          onGeometryChange: (v) => g = v,
          children: const [
            KumoFlowNode(label: 'Route every request for assets.example.com through the image-resizer Worker'),
            KumoFlowNode(label: 'Origin'),
          ],
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(g!.nodes.first.width, lessThanOrEqualTo(390 - 32));
    });

    testWidgets('auto orientation: vertical on a phone, horizontal on a desktop', (tester) async {
      KumoFlowGeometry? g;
      Widget diagram() =>
          KumoFlowDiagram(orientation: KumoFlowOrientation.auto, onGeometryChange: (v) => g = v, children: _pipeline);
      await pumpKumo(tester, diagram());
      expect(g!.orientation, KumoFlowOrientation.vertical);
      await pumpKumo(tester, diagram(), size: kumoDesktopSize);
      expect(g!.orientation, KumoFlowOrientation.horizontal);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: () => setState(() => _taps++), child: Text('Taps $_taps'));
}
