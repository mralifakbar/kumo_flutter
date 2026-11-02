import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

List<Widget> _tiles(int n, {double? tallIndexHeight}) => [
      for (var i = 0; i < n; i++)
        Container(
          key: ValueKey(i),
          height: i == 1 && tallIndexHeight != null ? tallIndexHeight : 40,
          color: const Color(0xFF888888),
        ),
    ];

Rect _tile(WidgetTester tester, int i) => tester.getRect(find.byKey(ValueKey(i)));

void main() {
  test('variants resolve columns at Tailwind breakpoints', () {
    expect(KumoGridVariant.twoUp.tracksAt(390), [1]);
    expect(KumoGridVariant.twoUp.tracksAt(800), [1, 1]);
    expect(KumoGridVariant.sideBySide.tracksAt(390), [1, 1]);
    expect(KumoGridVariant.twoOne.tracksAt(800), [2, 1]);
    expect(KumoGridVariant.oneTwo.tracksAt(800), [1, 2]);
    expect(KumoGridVariant.oneThreeUp.tracksAt(800), [1]);
    expect(KumoGridVariant.oneThreeUp.tracksAt(1100), [1, 1, 1]);
    expect(KumoGridVariant.threeUp.tracksAt(800).length, 2);
    expect(KumoGridVariant.threeUp.tracksAt(1100).length, 3);
    expect(KumoGridVariant.fourUp.tracksAt(1300).length, 4);
    expect(KumoGridVariant.sixUp.tracksAt(390).length, 2);
    expect(KumoGridVariant.sixUp.tracksAt(1300).length, 6);
    expect(KumoGridVariant.oneTwoFourUp.tracksAt(1100).length, 4);
  });

  test('gaps follow Kumo', () {
    expect(KumoGridGap.none.at(1000), 0);
    expect(KumoGridGap.sm.at(390), 12);
    expect(KumoGridGap.base.at(390), 8);
    expect(KumoGridGap.base.at(800), 24);
    expect(KumoGridGap.base.at(1100), 32);
    expect(KumoGridGap.lg.at(390), 32);
  });

  test('explicit columns cascade upward', () {
    const c = KumoGridColumns(base: 2, md: 3, xl: 5);
    expect(c.at(390), 2);
    expect(c.at(700), 2);
    expect(c.at(800), 3);
    expect(c.at(1100), 3);
    expect(c.at(1300), 5);
  });

  testWidgets('stacks on phones, goes side by side on desktop', (tester) async {
    await pumpKumo(tester, KumoGrid(variant: KumoGridVariant.twoUp, children: _tiles(2)), center: false);
    expect(_tile(tester, 1).top, greaterThan(_tile(tester, 0).bottom));
    expect(_tile(tester, 1).top - _tile(tester, 0).bottom, 8);
    expect(_tile(tester, 0).width, 390);

    await pumpKumo(tester, KumoGrid(variant: KumoGridVariant.twoUp, children: _tiles(2)), size: kumoDesktopSize, center: false);
    expect(_tile(tester, 0).top, _tile(tester, 1).top);
    expect(_tile(tester, 1).left - _tile(tester, 0).right, 32);
    expect(_tile(tester, 0).width, (1280 - 32) / 2);
  });

  testWidgets('2-1 splits two thirds and one third', (tester) async {
    await pumpKumo(
      tester,
      KumoGrid(variant: KumoGridVariant.twoOne, gap: KumoGridGap.none, children: _tiles(2)),
      size: kumoDesktopSize,
      center: false,
    );
    expect(_tile(tester, 0).width, closeTo(1280 * 2 / 3, 0.01));
    expect(_tile(tester, 1).width, closeTo(1280 / 3, 0.01));
  });

  testWidgets('cells in a row stretch to the tallest', (tester) async {
    await pumpKumo(
      tester,
      KumoGrid(variant: KumoGridVariant.sideBySide, gap: KumoGridGap.sm, children: _tiles(3, tallIndexHeight: 120)),
      center: false,
    );
    expect(_tile(tester, 0).height, 120);
    expect(_tile(tester, 1).height, 120);
    expect(_tile(tester, 2).top, 120 + 12);
    expect(_tile(tester, 2).width, (390 - 12) / 2);
  });

  testWidgets('container breakpoints read the grid width, not the window', (tester) async {
    await pumpKumo(
      tester,
      SizedBox(
        width: 400,
        child: KumoGrid(variant: KumoGridVariant.twoUp, breakpoints: KumoGridBreakpoints.container, children: _tiles(2)),
      ),
      size: kumoDesktopSize,
    );
    expect(_tile(tester, 0).width, 400);
  });

  testWidgets('RTL puts the first item on the right', (tester) async {
    await pumpKumo(
      tester,
      KumoGrid(variant: KumoGridVariant.sideBySide, children: _tiles(2)),
      textDirection: TextDirection.rtl,
      center: false,
    );
    expect(_tile(tester, 0).left, greaterThan(_tile(tester, 1).left));
  });

  testWidgets('mobile dividers separate stacked 4up items', (tester) async {
    await pumpKumo(tester, KumoGrid(variant: KumoGridVariant.fourUp, mobileDivider: true, children: _tiles(3)), center: false);
    final hairline = KumoThemeData.light().colors.hairline;
    final dividers = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where((d) {
      final dec = d.decoration;
      return dec is BoxDecoration && dec.border is Border && (dec.border! as Border).bottom.color == hairline;
    });
    expect(dividers, hasLength(2));
  });

  testWidgets('works inside a scroll view, in dark, with 2x text', (tester) async {
    await pumpKumo(
      tester,
      SingleChildScrollView(
        child: KumoGrid(
          columns: const KumoGridColumns(base: 2),
          children: [for (var i = 0; i < 6; i++) const KumoLayerCard(child: Text('Requests today across every Worker'))],
        ),
      ),
      brightness: Brightness.dark,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
