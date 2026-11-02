import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

// Expected values below are worked out by hand from Kumo's flow-layout.ts
// (columnGap 64, rowGap 16) and connectors.tsx, for fixed-size nodes.

KumoFlowNode _box(String id, double w, double h, {bool disabled = false}) => KumoFlowNode(
  id: id,
  disabled: disabled,
  render: SizedBox(key: ValueKey('box-$id'), width: w, height: h),
);

class _Capture {
  KumoFlowGeometry? geometry;
  KumoFlowGeometry get g => geometry!;
  Rect rect(String id) => g.rectOf(id)!;
  KumoFlowConnector connector(String from, String to) =>
      g.connectors.singleWhere((c) => g.ids[c.from] == from && g.ids[c.to] == to);
  Set<String> get edges => {for (final c in g.connectors) '${g.ids[c.from]}-${g.ids[c.to]}'};
}

Future<_Capture> _pump(
  WidgetTester tester,
  List<KumoFlowEntry> children, {
  KumoFlowOrientation orientation = KumoFlowOrientation.horizontal,
  KumoFlowAlign align = KumoFlowAlign.start,
  TextDirection textDirection = TextDirection.ltr,
  Size size = kumoDesktopSize,
}) async {
  final capture = _Capture();
  await pumpKumo(
    tester,
    KumoFlowDiagram(
      orientation: orientation,
      align: align,
      onGeometryChange: (g) => capture.geometry = g,
      children: children,
    ),
    textDirection: textDirection,
    size: size,
  );
  return capture;
}

void main() {
  group('horizontal positions', () {
    testWidgets('a list runs left to right with a 64px column gap', (tester) async {
      final c = await _pump(tester, [_box('A', 40, 40), _box('B', 60, 40), _box('C', 40, 40)]);
      expect(c.g.orientation, KumoFlowOrientation.horizontal);
      expect(c.rect('A'), const Rect.fromLTWH(0, 0, 40, 40));
      expect(c.rect('B'), const Rect.fromLTWH(104, 0, 60, 40));
      expect(c.rect('C'), const Rect.fromLTWH(228, 0, 40, 40));
      expect(c.g.size, const Size(268, 40));
    });

    testWidgets('parallel branches stack with a 16px row gap', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(children: [_box('B1', 60, 40), _box('B2', 60, 40)]),
        _box('C', 40, 40),
      ]);
      expect(c.rect('B1').topLeft, const Offset(104, 0));
      expect(c.rect('B2').topLeft, const Offset(104, 56));
      expect(c.rect('C').topLeft, const Offset(228, 0));
      expect(c.g.size, const Size(268, 96));
    });

    testWidgets('a parallel group is as wide as its widest branch', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(children: [_box('B1', 60, 40), _box('B2', 100, 40)]),
        _box('C', 40, 40),
      ]);
      expect(c.rect('C').topLeft, const Offset(40 + 64 + 100 + 64, 0));
    });

    testWidgets('a list inside a parallel group (spec example 4)', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(
          children: [
            KumoFlowList(children: [_box('B1', 60, 40), _box('B2', 100, 40)]),
            _box('C1', 40, 40),
          ],
        ),
        _box('D', 40, 40),
      ]);
      expect(c.rect('B1').topLeft, const Offset(104, 0));
      expect(c.rect('B2').topLeft, const Offset(228, 0));
      expect(c.rect('C1').topLeft, const Offset(104, 56));
      expect(c.rect('D').topLeft, const Offset(392, 0));
      expect(c.edges, {'A-B1', 'A-C1', 'B1-B2', 'B2-D', 'C1-D'});
    });

    testWidgets('align end right-aligns branches to the widest', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(align: KumoFlowParallelAlign.end, children: [_box('B1', 60, 40), _box('B2', 100, 40)]),
        _box('C', 40, 40),
      ]);
      expect(c.rect('B1').topLeft, const Offset(144, 0));
      expect(c.rect('B2').topLeft, const Offset(104, 56));
    });

    testWidgets('align center centers nodes of mixed heights', (tester) async {
      final c = await _pump(tester, [
        _box('A', 16, 16),
        _box('B', 60, 40),
        _box('C', 60, 88),
      ], align: KumoFlowAlign.center);
      expect(c.rect('A').topLeft, const Offset(0, 36));
      expect(c.rect('B').topLeft, const Offset(80, 24));
      expect(c.rect('C').topLeft, const Offset(204, 0));
    });
  });

  group('vertical positions', () {
    testWidgets('a list runs top to bottom', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        _box('B', 60, 40),
        _box('C', 40, 40),
      ], orientation: KumoFlowOrientation.vertical);
      expect(c.g.orientation, KumoFlowOrientation.vertical);
      expect(c.rect('A').topLeft, Offset.zero);
      expect(c.rect('B').topLeft, const Offset(0, 104));
      expect(c.rect('C').topLeft, const Offset(0, 208));
      expect(c.g.size, const Size(60, 248));
    });

    testWidgets('align center centers the column', (tester) async {
      final c = await _pump(
        tester,
        [_box('A', 40, 40), _box('B', 60, 40), _box('C', 40, 40)],
        orientation: KumoFlowOrientation.vertical,
        align: KumoFlowAlign.center,
      );
      expect(c.rect('A').topLeft, const Offset(10, 0));
      expect(c.rect('B').topLeft, const Offset(0, 104));
      expect(c.rect('C').topLeft, const Offset(10, 208));
    });

    testWidgets('branches sit side by side; align end bottom-aligns them', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(align: KumoFlowParallelAlign.end, children: [_box('B1', 60, 40), _box('B2', 60, 80)]),
        _box('C', 40, 40),
      ], orientation: KumoFlowOrientation.vertical);
      expect(c.rect('B1').topLeft, const Offset(0, 144));
      expect(c.rect('B2').topLeft, const Offset(76, 104));
      expect(c.rect('C').topLeft, const Offset(0, 248));
    });
  });

  group('connectors', () {
    testWidgets('horizontal: right center to left center', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(children: [_box('B1', 60, 40), _box('B2', 60, 40)]),
        _box('C', 40, 40),
      ]);
      expect(c.edges, {'A-B1', 'A-B2', 'B1-C', 'B2-C'});
      final ab2 = c.connector('A', 'B2');
      expect(ab2.start, const Offset(40, 20));
      expect(ab2.end, const Offset(104, 76));
      final b2c = c.connector('B2', 'C');
      expect(b2c.start, const Offset(164, 76));
      expect(b2c.end, const Offset(228, 20));
    });

    testWidgets('vertical: bottom center to top center', (tester) async {
      final c = await _pump(tester, [_box('A', 40, 40), _box('B', 60, 40)], orientation: KumoFlowOrientation.vertical);
      final ab = c.connector('A', 'B');
      expect(ab.start, const Offset(20, 40));
      expect(ab.end, const Offset(30, 104));
    });

    testWidgets('adjacent parallel groups are not connected', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(children: [_box('B1', 40, 40), _box('B2', 40, 40)]),
        KumoFlowParallel(children: [_box('C1', 40, 40), _box('C2', 40, 40)]),
        _box('D', 40, 40),
      ]);
      expect(c.edges, {'A-B1', 'A-B2', 'C1-D', 'C2-D'});
    });

    testWidgets('a group with nothing before it has no incoming connectors', (tester) async {
      final c = await _pump(tester, [
        KumoFlowParallel(children: [_box('A', 40, 40), _box('B', 40, 40)]),
        _box('C', 40, 40),
      ]);
      expect(c.edges, {'A-C', 'B-C'});
    });

    testWidgets('a disabled node greys out every connector touching it', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        KumoFlowParallel(children: [_box('B1', 40, 40), _box('B2', 40, 40, disabled: true)]),
        _box('C', 40, 40),
      ]);
      expect(c.connector('A', 'B2').disabled, isTrue);
      expect(c.connector('B2', 'C').disabled, isTrue);
      expect(c.connector('A', 'B1').disabled, isFalse);
    });

    testWidgets('anchors move connector endpoints off the node center', (tester) async {
      final c = await _pump(tester, [
        const KumoFlowNode(
          id: 'A',
          render: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KumoFlowAnchor(child: SizedBox(width: 80, height: 20)),
              SizedBox(width: 80, height: 80),
            ],
          ),
        ),
        const KumoFlowNode(
          id: 'B',
          render: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 80, height: 60),
              KumoFlowAnchor(type: KumoFlowAnchorType.end, child: SizedBox(width: 80, height: 40)),
              KumoFlowAnchor(type: KumoFlowAnchorType.start, child: SizedBox(width: 80, height: 10)),
            ],
          ),
        ),
        _box('C', 40, 40),
      ]);
      final ab = c.connector('A', 'B');
      expect(ab.start, const Offset(80, 10));
      expect(ab.end, const Offset(144, 80));
      expect(c.connector('B', 'C').start, const Offset(224, 105));
    });

    testWidgets('vertical flows ignore anchors, as Kumo does', (tester) async {
      final c = await _pump(tester, [
        const KumoFlowNode(
          id: 'A',
          render: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KumoFlowAnchor(child: SizedBox(width: 80, height: 20)),
              SizedBox(width: 80, height: 80),
            ],
          ),
        ),
        _box('B', 80, 40),
      ], orientation: KumoFlowOrientation.vertical);
      expect(c.connector('A', 'B').start, const Offset(40, 100));
    });

    testWidgets('connectors follow a node that changes size', (tester) async {
      final capture = _Capture();
      final tall = ValueNotifier(false);
      addTearDown(tall.dispose);
      await pumpKumo(
        tester,
        KumoFlowDiagram(
          onGeometryChange: (g) => capture.geometry = g,
          children: [
            _box('A', 40, 40),
            KumoFlowNode(
              id: 'B',
              render: ValueListenableBuilder<bool>(
                valueListenable: tall,
                builder: (_, t, _) => SizedBox(width: 60, height: t ? 120 : 40),
              ),
            ),
            _box('C', 40, 40),
          ],
        ),
        size: kumoDesktopSize,
      );
      expect(capture.connector('A', 'B').end, const Offset(104, 20));
      tall.value = true;
      await tester.pumpAndSettle();
      expect(capture.connector('A', 'B').end, const Offset(104, 60));
      expect(capture.connector('B', 'C').start, const Offset(164, 60));
    });
  });

  group('RTL', () {
    testWidgets('mirrors node positions and connectors', (tester) async {
      final c = await _pump(tester, [
        _box('A', 40, 40),
        _box('B', 60, 40),
        _box('C', 40, 40),
      ], textDirection: TextDirection.rtl);
      expect(c.rect('A').topLeft, const Offset(228, 0));
      expect(c.rect('B').topLeft, const Offset(104, 0));
      expect(c.rect('C').topLeft, Offset.zero);
      final ab = c.connector('A', 'B');
      expect(ab.start, const Offset(228, 20));
      expect(ab.end, const Offset(164, 20));
    });

    testWidgets('mirrors vertical branches', (tester) async {
      final c = await _pump(
        tester,
        [
          _box('A', 40, 40),
          KumoFlowParallel(children: [_box('B1', 60, 40), _box('B2', 60, 40)]),
        ],
        orientation: KumoFlowOrientation.vertical,
        textDirection: TextDirection.rtl,
      );
      // Content is 136 wide; B1 starts on the right.
      expect(c.g.size.width, 136);
      expect(c.rect('A').topLeft, const Offset(96, 0));
      expect(c.rect('B1').topLeft, const Offset(76, 104));
      expect(c.rect('B2').topLeft, const Offset(0, 104));
    });

    testWidgets('nodes land where the geometry says on screen', (tester) async {
      await _pump(
        tester,
        [_box('A', 40, 40), _box('B', 60, 40), _box('C', 40, 40)],
        textDirection: TextDirection.rtl,
        size: kumoPhoneSize,
      );
      final diagram = tester.getTopLeft(find.byType(KumoFlowDiagram));
      // 390 wide, 16px side padding: 358 available, 268 content, centered.
      final origin = diagram + const Offset(16 + (358 - 268) / 2, 64);
      Offset at(String id) => tester.getTopLeft(find.byKey(ValueKey('box-$id'))) - origin;
      expect(at('A'), const Offset(228, 0));
      expect(at('B'), const Offset(104, 0));
      expect(at('C'), Offset.zero);
    });
  });

  group('auto orientation', () {
    final steps = [
      for (final id in ['A', 'B', 'C', 'D']) _box(id, 80, 40),
    ];

    testWidgets('stays horizontal when it fits', (tester) async {
      final c = await _pump(tester, steps, orientation: KumoFlowOrientation.auto);
      expect(c.g.orientation, KumoFlowOrientation.horizontal);
    });

    testWidgets('turns vertical when the horizontal layout does not fit', (tester) async {
      final c = await _pump(tester, steps, orientation: KumoFlowOrientation.auto, size: kumoPhoneSize);
      expect(c.g.orientation, KumoFlowOrientation.vertical);
      expect(c.rect('D').topLeft, const Offset(0, 3 * (40 + 64)));
    });
  });
}
