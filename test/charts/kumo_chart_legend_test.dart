import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _red = Color(0xFFFC574A);

void main() {
  testWidgets('renders small, large and loading items in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        const Wrap(spacing: 16, children: [
          KumoChartLegend.small(name: 'Requests', color: _red, value: '1,234'),
          KumoChartLegend.small(name: 'Errors', color: _red),
          KumoChartLegend.large(name: 'P99', color: _red, value: '124', unit: 'ms'),
          KumoChartLegend.large(name: 'P50', color: _red, value: '10', inactive: true),
          KumoChartLegend.loading(),
          KumoChartLegend.loading(size: KumoChartLegendSize.large),
        ]),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
    expect(find.text('1,234'), findsOneWidget);
    expect(find.text('ms'), findsOneWidget);
  });

  testWidgets('large items are at least Kumo\'s 168px wide on wide screens; small items 16px tall', (tester) async {
    await pumpKumo(tester, const KumoChartLegend.large(name: 'P99', color: _red, value: '1', unit: 'ms'), size: kumoDesktopSize);
    expect(tester.getSize(find.byType(KumoChartLegend)).width, greaterThanOrEqualTo(168));
    await pumpKumo(tester, const KumoChartLegend.large(name: 'P99', color: _red, value: '1', unit: 'ms'));
    expect(tester.getSize(find.byType(KumoChartLegend)).width, lessThan(168));
    await pumpKumo(tester, const KumoChartLegend.small(name: 'P99', color: _red, value: '1'),
        tapTargetSize: KumoTapTargetSize.shrinkWrap);
    expect(tester.getSize(find.byType(KumoChartLegend)).height, 16);
  });

  testWidgets('inactive items render at half opacity', (tester) async {
    await pumpKumo(tester, const KumoChartLegend.small(name: 'Requests', color: _red, value: '1', inactive: true));
    final opacities = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).map((o) => o.opacity).toSet();
    expect(opacities, {0.5});
  });

  testWidgets('onPress fires on tap and with Enter; announces as a toggle button', (tester) async {
    final handle = tester.ensureSemantics();
    var presses = 0;
    await pumpKumo(tester, KumoChartLegend.small(name: 'Errors', color: _red, value: '3', onPress: () => presses++));
    await tester.tap(find.text('Errors'));
    expect(presses, 1);
    expect(
      tester.getSemantics(find.byType(KumoChartLegend)),
      matchesSemantics(
        label: 'Errors 3',
        isButton: true,
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(presses, 2);
    handle.dispose();
  });

  testWidgets('without callbacks it is plain labelled text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoChartLegend.large(name: 'P99', color: _red, value: '124', unit: 'ms'));
    expect(find.bySemanticsLabel('P99 124 ms'), findsOneWidget);
    expect(find.byType(KumoPressable), findsNothing);
    handle.dispose();
  });

  testWidgets('loading placeholders are hidden from screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoChartLegend.loading());
    expect(find.byType(ExcludeSemantics), findsWidgets);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('onHoverChange reports pointer enter and leave', (tester) async {
    final events = <bool>[];
    await pumpKumo(tester, KumoChartLegend.small(name: 'Errors', color: _red, onHoverChange: events.add));
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.addPointer(location: Offset.zero);
    addTearDown(g.removePointer);
    await g.moveTo(tester.getCenter(find.text('Errors')));
    await tester.pump();
    await g.moveTo(Offset.zero);
    await tester.pump();
    expect(events, [true, false]);
  });

  testWidgets('touch targets are 44px tall', (tester) async {
    await pumpKumo(tester, KumoChartLegend.small(name: 'Errors', color: _red, onPress: () {}));
    expect(tester.getSize(find.byType(KumoPressable)).height, greaterThanOrEqualTo(44));
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await pumpKumo(
      tester,
      Wrap(spacing: 16, children: [
        for (var i = 0; i < 4; i++) KumoChartLegend.large(name: 'Worker image-resizer $i', color: _red, value: '12,400', unit: 'req/s', onPress: () {}),
      ]),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggling a series eases the item to half opacity; reduced motion swaps at once', (tester) async {
    double opacity() => tester
        .widgetList<FadeTransition>(find.ancestor(of: find.text('Requests'), matching: find.byType(FadeTransition)))
        .map((f) => f.opacity.value)
        .reduce((a, b) => a < b ? a : b);
    Widget legend(bool inactive) =>
        KumoChartLegend.small(name: 'Requests', color: _red, value: '1', inactive: inactive, onPress: () {});
    await pumpKumo(tester, legend(false));
    await pumpKumo(tester, legend(true), settle: false);
    await tester.pump(const Duration(milliseconds: 70));
    expect(opacity(), inExclusiveRange(0.5, 1));
    await tester.pumpAndSettle();
    expect(opacity(), 0.5);

    await pumpKumo(tester, legend(false), disableAnimations: true, settle: false);
    await tester.pump();
    expect(opacity(), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
