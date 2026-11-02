@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

final _t0 = DateTime.utc(2026, 3, 4, 14);

List<(DateTime, double)> _points(double base, double k) => [
  for (var i = 0; i < 40; i++) (_t0.add(Duration(minutes: i)), base + k * ((i * 7) % 11) + i * 0.6),
];

Widget _charts() {
  const p = KumoChartColors.light;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      KumoTimeseriesChart(
        height: 220,
        showLegend: true,
        xAxisName: 'Time (UTC)',
        yAxisName: 'Requests',
        data: [
          KumoTimeseriesData(name: 'Requests', color: p.categorical(0), data: _points(80, 4)),
          KumoTimeseriesData(
            name: 'Errors',
            color: p.semantic(KumoChartSemanticColor.attention),
            data: _points(10, 1),
            lineStyle: KumoTimeseriesLineStyle.dashed,
          ),
        ],
        markers: [KumoTimeseriesMarker(time: _t0.add(const Duration(minutes: 12)), label: 'Deploy 4f2c1a9')],
        thresholds: [
          KumoTimeseriesThreshold(value: 120, label: 'Rate limit', color: p.semantic(KumoChartSemanticColor.attention)),
        ],
      ),
      KumoTimeseriesChart(
        height: 160,
        type: KumoTimeseriesChartType.bar,
        data: [
          KumoTimeseriesData(name: 'Cached', color: p.categorical(0), data: _points(40, 3).take(16).toList()),
          KumoTimeseriesData(name: 'Uncached', color: p.categorical(4), data: _points(20, 2).take(16).toList()),
        ],
      ),
      const Row(
        spacing: 12,
        children: [
          Expanded(child: KumoSparkline(values: [12, 18, 15, 22, 30, 27, 34], area: true, showEndDot: true)),
          Expanded(child: KumoSparkline(values: [5, 3, 4, 2, 6, 1, 2], showMinMax: true)),
        ],
      ),
      const KumoSankeyChart(
        height: 200,
        nodes: [
          KumoSankeyNode(name: 'Users', value: 103600),
          KumoSankeyNode(name: 'Devices', value: 50800),
          KumoSankeyNode(name: 'Workers', value: 122600),
          KumoSankeyNode(name: 'Tunnels', value: 31800),
        ],
        links: [
          KumoSankeyLink(source: 0, target: 2, value: 80000),
          KumoSankeyLink(source: 0, target: 3, value: 23600),
          KumoSankeyLink(source: 1, target: 2, value: 42600),
          KumoSankeyLink(source: 1, target: 3, value: 8200),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('charts in light and dark', (tester) async {
    tester.view.physicalSize = const Size(800, 1200) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(goldenPair(_charts(), width: 390));
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('../goldens/charts.png'));
  });
}
