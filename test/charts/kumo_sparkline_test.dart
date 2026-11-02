import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every option in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        const Column(mainAxisSize: MainAxisSize.min, children: [
          KumoSparkline(values: [1, 4, 2, 8, 5]),
          KumoSparkline(values: [1, 4, double.nan, 8, 5], area: true, showEndDot: true, showMinMax: true),
          KumoSparkline(values: [3, 3, 3], showMinMax: true),
          KumoSparkline(values: [7]),
          KumoSparkline(values: []),
          KumoSparkline(values: [], loading: true),
        ]),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('sizes to the given box, or the available width', (tester) async {
    await pumpKumo(tester, const KumoSparkline(values: [1, 2], width: 80, height: 24));
    expect(tester.getSize(find.byType(KumoSparkline)), const Size(80, 24));
    await pumpKumo(tester, const SizedBox(width: 200, child: KumoSparkline(values: [1, 2])));
    expect(tester.getSize(find.byType(KumoSparkline)), const Size(200, 32));
  });

  testWidgets('semantics describe the trend', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, KumoSparkline(values: const [12, 8, 41, 30], semanticLabel: 'Requests, last 4 days', valueFormat: (v) => '${v.round()}k'));
    expect(find.bySemanticsLabel('Requests, last 4 days, 4 points, from 12k to 30k, low 8k, high 41k'), findsOneWidget);
    await pumpKumo(tester, const KumoSparkline(values: []));
    expect(find.bySemanticsLabel('Trend, no data'), findsOneWidget);
    await pumpKumo(tester, const KumoSparkline(values: [], loading: true));
    expect(find.bySemanticsLabel('Trend, loading'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('value changes morph, instantly under reduced motion', (tester) async {
    await pumpKumo(tester, const KumoSparkline(values: [1, 2, 3]));
    await tester.pumpWidget(kumoHarness(const KumoSparkline(values: [3, 1, 2, 5])));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await pumpKumo(tester, const KumoSparkline(values: [1, 2, 3]), disableAnimations: true);
    await tester.pumpWidget(kumoHarness(const KumoSparkline(values: [3, 1, 2]), disableAnimations: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('loading never animates', (tester) async {
    await pumpKumo(tester, const KumoSparkline(values: [], loading: true), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
