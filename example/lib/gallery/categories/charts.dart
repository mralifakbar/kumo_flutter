import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Chart palette, legends, timeseries, sparklines, Sankey and map charts.
/// Every series, flow and region value here is generated sample data.
final KumoDemoCategory chartsCategory = KumoDemoCategory(
  title: 'Charts',
  description: 'Timeseries, sparkline, Sankey and map charts drawn with CustomPainter, plus the chart palette and legend.',
  icon: KumoIcons.chartLine,
  demos: [
    KumoDemo(
      title: 'KumoChartColors',
      description: 'Categorical, semantic and sequential chart colors for the current mode.',
      docPath: 'doc/components/KumoChartColors.md',
      builder: (_) => const _ColorsDemo(),
    ),
    KumoDemo(
      title: 'KumoChartLegend',
      description: 'Large and small legend items, inactive and loading, and a legend that toggles series.',
      docPath: 'doc/components/KumoChartLegend.md',
      builder: (_) => const _LegendDemo(),
    ),
    KumoDemo(
      title: 'KumoTimeseriesChart',
      description: 'Lines, areas and stacked bars with markers, thresholds, range selection and every data state.',
      docPath: 'doc/components/KumoTimeseriesChart.md',
      builder: (_) => const _TimeseriesDemo(),
    ),
    KumoDemo(
      title: 'KumoSparkline',
      description: 'Compact trends in a list of Workers, with end and extreme dots.',
      docPath: 'doc/components/KumoSparkline.md',
      builder: (_) => const _SparklineDemo(),
    ),
    KumoDemo(
      title: 'KumoSankeyChart',
      description: 'Traffic flows with adjacency and path highlighting, inline labels and gray links.',
      docPath: 'doc/components/KumoSankeyChart.md',
      builder: (_) => const _SankeyDemo(),
    ),
    KumoDemo(
      title: 'KumoMapChart',
      description: 'A choropleth over caller-provided shapes: a hexagon tile map of location hint regions.',
      docPath: 'doc/components/KumoMapChart.md',
      builder: (_) => const _MapDemo(),
    ),
  ],
);

/// Fixed start time so the sample series look the same on every run.
final DateTime _start = DateTime.utc(2026, 3, 4, 14);

/// A calm, deterministic wave around [base] with some noise from [seed].
List<(DateTime, double)> _sample({
  required int seed,
  int count = 50,
  Duration step = const Duration(minutes: 1),
  double base = 100,
  double spread = 30,
}) {
  final random = math.Random(seed);
  return [
    for (var i = 0; i < count; i++)
      (
        _start.add(step * i),
        (base + spread * math.sin(i / 6 + seed) + spread * 0.4 * (random.nextDouble() - 0.5)).clamp(0, double.infinity).roundToDouble(),
      ),
  ];
}

class _Stack extends StatelessWidget {
  const _Stack({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: KumoSpace.s8,
        children: children,
      );
}

class _SampleNote extends StatelessWidget {
  const _SampleNote();

  @override
  Widget build(BuildContext context) => const KumoText(
        'All values are generated sample data.',
        variant: KumoTextVariant.secondary,
        size: KumoTextSize.xs,
      );
}

// Colors

class _ColorsDemo extends StatelessWidget {
  const _ColorsDemo();

  static const _categoricalNames = ['Blue', 'Yellow', 'Pink', 'Purple', 'Teal', 'Orange'];

  String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Widget _swatch(BuildContext context, String name, Color color) => SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s1,
          children: [
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(KumoRadius.md),
                border: KumoRing.inset(context.kumo.colors.hairline),
              ),
            ),
            KumoText(name, size: KumoTextSize.sm, bold: true),
            KumoText(_hex(color), variant: KumoTextVariant.monoSecondary),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final palette = KumoChartColors.of(context);
    return _Stack(children: [
      DemoSection(
        title: 'Categorical',
        caption: 'For series without inherent meaning. Index 6 wraps back to blue.',
        child: Wrap(spacing: KumoSpace.s3, runSpacing: KumoSpace.s3, children: [
          for (var i = 0; i < 6; i++) _swatch(context, '$i ${_categoricalNames[i]}', palette.categorical(i)),
        ]),
      ),
      DemoSection(
        title: 'Semantic',
        caption: 'For status and severity. Always pair them with a label.',
        child: Wrap(spacing: KumoSpace.s3, runSpacing: KumoSpace.s3, children: [
          for (final s in KumoChartSemanticColor.values) _swatch(context, s.name, palette.semantic(s)),
        ]),
      ),
      DemoSection(
        title: 'Sequential',
        caption: 'Density, low to high. The dark ramp is reversed so higher always reads brighter.',
        child: Row(children: [
          for (final c in palette.sequential())
            Expanded(child: Container(height: 24, color: c)),
        ]),
      ),
    ]);
  }
}

// Legend

class _LegendDemo extends StatefulWidget {
  const _LegendDemo();

  @override
  State<_LegendDemo> createState() => _LegendDemoState();
}

class _LegendDemoState extends State<_LegendDemo> {
  final Set<String> _hidden = {};
  String? _hovered;

  @override
  Widget build(BuildContext context) {
    final palette = KumoChartColors.of(context);
    final latency = [
      ('P99', palette.semantic(KumoChartSemanticColor.attention), '124'),
      ('P95', palette.semantic(KumoChartSemanticColor.warning), '76'),
      ('P75', palette.semantic(KumoChartSemanticColor.neutral), '32'),
    ];
    final series = [
      for (final (i, (name, color, _)) in latency.indexed)
        KumoTimeseriesData(
          name: name,
          color: color,
          lineStyle: KumoTimeseriesLineStyle.values[i % 3],
          data: _sample(seed: i + 3, base: 120 - i * 40.0, spread: 20 - i * 5.0, count: 30),
        ),
    ];
    return _Stack(children: [
      DemoSection(
        title: 'Large',
        caption: 'Stacked name and value, for single-metric cards. The last item is inactive.',
        child: Wrap(spacing: KumoSpace.s4, runSpacing: KumoSpace.s2, children: [
          for (final (i, (name, color, value)) in latency.indexed)
            KumoChartLegend.large(name: name, color: color, value: value, unit: 'ms', inactive: i == 2),
        ]),
      ),
      DemoSection(
        title: 'Small',
        child: Wrap(spacing: KumoSpace.s4, runSpacing: KumoSpace.s2, children: [
          KumoChartLegend.small(name: 'Requests', color: palette.categorical(0), value: '1,234'),
          KumoChartLegend.small(name: 'Cached', color: palette.categorical(4), value: '987'),
          KumoChartLegend.small(name: 'Errors', color: palette.semantic(KumoChartSemanticColor.attention), value: '12', inactive: true),
        ]),
      ),
      const DemoSection(
        title: 'Loading',
        child: Wrap(spacing: KumoSpace.s4, runSpacing: KumoSpace.s2, children: [
          KumoChartLegend.loading(size: KumoChartLegendSize.large),
          KumoChartLegend.loading(),
          KumoChartLegend.loading(),
        ]),
      ),
      DemoSection(
        title: 'Toggle and highlight series',
        caption: 'Press an item to hide its series; hover one to fade the others.',
        child: KumoLayerCard.layered(children: [
          const KumoLayerCardSecondary(child: Text('Read latency, image-resizer')),
          KumoLayerCardPrimary(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Wrap(spacing: KumoSpace.s4, children: [
                for (final (name, color, value) in latency)
                  KumoChartLegend.large(
                    name: name,
                    color: color,
                    value: value,
                    unit: 'ms',
                    inactive: _hidden.contains(name) || (_hovered != null && _hovered != name),
                    onPress: () => setState(() => _hidden.contains(name) ? _hidden.remove(name) : _hidden.add(name)),
                    onHoverChange: (h) => setState(() => _hovered = h ? name : null),
                  ),
              ]),
              KumoTimeseriesChart(
                data: series,
                height: 220,
                hiddenSeries: _hidden,
                highlightedSeries: _hovered,
                tooltipValueFormat: (v) => '${v.round()} ms',
                tooltipFooter: 'Sample data. Percentiles use a five-minute window.',
                semanticLabel: 'Read latency for image-resizer, sample data',
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// Timeseries

enum _DataState { ready, loading, empty, error }

class _TimeseriesDemo extends StatefulWidget {
  const _TimeseriesDemo();

  @override
  State<_TimeseriesDemo> createState() => _TimeseriesDemoState();
}

class _TimeseriesDemoState extends State<_TimeseriesDemo> {
  int _seed = 0;
  _DataState _state = _DataState.ready;
  (DateTime, DateTime)? _range;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    _timer?.cancel();
    setState(() => _state = _DataState.loading);
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _state = _DataState.ready;
          _seed++;
        });
      }
    });
  }

  String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = KumoChartColors.of(context);
    final requests = KumoTimeseriesData(
      name: 'Requests',
      color: palette.semantic(KumoChartSemanticColor.neutral),
      data: _sample(seed: _seed),
    );
    final errors = KumoTimeseriesData(
      name: 'Errors',
      color: palette.semantic(KumoChartSemanticColor.attention),
      lineStyle: KumoTimeseriesLineStyle.dashed,
      data: _sample(seed: _seed + 7, base: 18, spread: 8),
    );
    final hourly = [
      for (final (i, name) in ['Cached', 'Uncached', 'Errors'].indexed)
        KumoTimeseriesData(
          name: name,
          color: i == 2 ? palette.semantic(KumoChartSemanticColor.attention) : palette.categorical(i == 0 ? 0 : 4),
          data: _sample(seed: i + 11, count: 24, step: const Duration(hours: 1), base: 80 - i * 30.0, spread: 25 - i * 8.0),
        ),
    ];
    final memory = KumoTimeseriesData(
      name: 'Memory used',
      color: palette.semantic(KumoChartSemanticColor.neutral),
      data: _sample(seed: 21, base: 96, spread: 22),
    );

    return _Stack(children: [
      DemoSection(
        title: 'Lines',
        caption: 'Hover, or touch and drag, to scrub. Focus the chart and use the arrow keys to step through points.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s2, children: [
          KumoTimeseriesChart(
            data: [requests, errors],
            showLegend: true,
            xAxisName: 'Time (UTC)',
            yAxisName: 'Requests',
            tooltipValueFormat: (v) => '${v.round()} req/s',
            semanticLabel: 'Requests for image-resizer, sample data',
          ),
          const _SampleNote(),
        ]),
      ),
      DemoSection(
        title: 'Reference markers',
        caption: 'Deploys close together merge into one line; hover it for the list.',
        child: KumoTimeseriesChart(
          data: [requests],
          height: 240,
          markers: [
            KumoTimeseriesMarker(time: _start.add(const Duration(minutes: 15)), label: 'Deploy 4f2c1a9', description: 'image-resizer v41'),
            KumoTimeseriesMarker(time: _start.add(const Duration(minutes: 16)), label: 'Deploy 7b3e0d2', description: 'image-resizer v42'),
            KumoTimeseriesMarker(
              time: _start.add(const Duration(minutes: 36)),
              label: 'Route updated',
              description: 'example.com/images/* now routes to image-resizer',
              lineStyle: KumoTimeseriesLineStyle.dotted,
            ),
          ],
          semanticLabel: 'Requests with deploys, sample data',
        ),
      ),
      DemoSection(
        title: 'Thresholds',
        caption: 'A limit line and a target band. The value axis always reaches them.',
        child: KumoTimeseriesChart(
          data: [memory],
          height: 240,
          yAxisName: 'Memory (MB)',
          thresholds: [
            KumoTimeseriesThreshold(value: 128, label: 'Memory limit', color: palette.semantic(KumoChartSemanticColor.attention)),
            KumoTimeseriesThreshold(value: 60, endValue: 90, label: 'Typical', color: palette.semantic(KumoChartSemanticColor.success)),
          ],
          tooltipValueFormat: (v) => '${v.round()} MB',
          semanticLabel: 'Memory for image-resizer, sample data',
        ),
      ),
      DemoSection(
        title: 'Area with incomplete data',
        caption: 'The last ten minutes are still arriving, so they are dashed.',
        child: KumoTimeseriesChart(
          data: [requests, errors],
          gradient: true,
          height: 240,
          incomplete: KumoTimeseriesIncomplete(after: _start.add(const Duration(minutes: 40))),
          semanticLabel: 'Requests and errors, sample data',
        ),
      ),
      DemoSection(
        title: 'Stacked bars',
        caption: 'Hourly cache status over a day. Press a legend item to hide a series and watch the axis rescale.',
        child: KumoTimeseriesChart(
          data: hourly,
          type: KumoTimeseriesChartType.bar,
          showLegend: true,
          height: 240,
          yAxisMinInterval: 1,
          semanticLabel: 'Requests by cache status, sample data',
        ),
      ),
      DemoSection(
        title: 'Range selection',
        caption: 'With a mouse, drag across the chart to pick a range.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s2, children: [
          KumoTimeseriesChart(
            data: [requests],
            height: 200,
            onTimeRangeChange: (from, to) => setState(() => _range = (from, to)),
          ),
          KumoText(
            _range == null ? 'No range selected' : 'Selected ${_time(_range!.$1)} to ${_time(_range!.$2)} UTC',
            variant: KumoTextVariant.secondary,
            size: KumoTextSize.sm,
          ),
        ]),
      ),
      DemoSection(
        title: 'Loading, empty and error',
        caption: 'Reload shows the skeleton, then the new sample data morphs in from the old line.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s3, children: [
          Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: [
            KumoButton(label: 'Reload sample data', icon: KumoIcons.arrowsClockwise, size: KumoButtonSize.sm, onPress: _reload),
            KumoButton(label: 'Show empty', size: KumoButtonSize.sm, onPress: () => setState(() => _state = _DataState.empty)),
            KumoButton(label: 'Show error', size: KumoButtonSize.sm, onPress: () => setState(() => _state = _DataState.error)),
          ]),
          KumoTimeseriesChart(
            data: _state == _DataState.empty ? const [] : [requests, errors],
            showLegend: true,
            height: 220,
            loading: _state == _DataState.loading,
            error: _state == _DataState.error ? 'Could not load requests for image-resizer. Check your connection, then retry.' : null,
            onRetry: _reload,
            semanticLabel: 'Requests for image-resizer, sample data',
          ),
        ]),
      ),
    ]);
  }
}

// Sparkline

class _SparklineDemo extends StatefulWidget {
  const _SparklineDemo();

  @override
  State<_SparklineDemo> createState() => _SparklineDemoState();
}

class _SparklineDemoState extends State<_SparklineDemo> {
  int _seed = 1;

  List<double> _values(int i) => [for (final p in _sample(seed: _seed * 10 + i, count: 24, base: 40 + i * 20.0, spread: 15)) p.$2];

  @override
  Widget build(BuildContext context) {
    final palette = KumoChartColors.of(context);
    const workers = ['image-resizer', 'auth-gateway', 'r2-uploader'];
    return _Stack(children: [
      DemoSection(
        title: 'In a list',
        caption: 'Requests per hour over the last day. Shuffle to see the lines morph.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s3, children: [
          for (final (i, name) in workers.indexed)
            Row(spacing: KumoSpace.s3, children: [
              Expanded(child: KumoText(name, variant: KumoTextVariant.mono)),
              SizedBox(
                width: 120,
                child: KumoSparkline(
                  values: _values(i),
                  color: palette.categorical(i),
                  area: i == 0,
                  showEndDot: true,
                  showMinMax: i == 1,
                  semanticLabel: 'Requests per hour for $name, sample data',
                ),
              ),
              SizedBox(
                width: 56,
                child: KumoText(
                  '${_values(i).last.round()}',
                  textAlign: TextAlign.end,
                  tabularNumbers: true,
                ),
              ),
            ]),
          Row(children: [
            KumoButton(label: 'Shuffle sample data', size: KumoButtonSize.sm, onPress: () => setState(() => _seed++)),
          ]),
          const _SampleNote(),
        ]),
      ),
      const DemoSection(
        title: 'Loading and empty',
        child: Row(spacing: KumoSpace.s6, children: [
          SizedBox(width: 120, child: KumoSparkline(values: [], loading: true)),
          SizedBox(width: 120, child: KumoSparkline(values: [], semanticLabel: 'Requests for a new Worker')),
        ]),
      ),
    ]);
  }
}

// Sankey

const _trafficNodes = [
  KumoSankeyNode(name: 'Users', value: 103600, tooltipData: {'Sessions': 122600, 'Countries': 41}),
  KumoSankeyNode(name: 'Networks', value: 84100),
  KumoSankeyNode(name: 'Devices', value: 50800),
  KumoSankeyNode(name: 'Other', value: 2000),
  KumoSankeyNode(name: 'Apps', value: 122600),
  KumoSankeyNode(name: 'Tunnels', value: 87800),
  KumoSankeyNode(name: 'BYOIP', value: 29500),
  KumoSankeyNode(name: 'Other target', value: 600),
];

const _trafficLinks = [
  KumoSankeyLink(source: 0, target: 4, value: 80000),
  KumoSankeyLink(source: 0, target: 5, value: 20000),
  KumoSankeyLink(source: 0, target: 6, value: 3600),
  KumoSankeyLink(source: 1, target: 4, value: 30000),
  KumoSankeyLink(source: 1, target: 5, value: 50000),
  KumoSankeyLink(source: 1, target: 6, value: 4100),
  KumoSankeyLink(source: 2, target: 4, value: 10000),
  KumoSankeyLink(source: 2, target: 5, value: 15000),
  KumoSankeyLink(source: 2, target: 6, value: 20000),
  KumoSankeyLink(source: 2, target: 7, value: 5800),
  KumoSankeyLink(source: 3, target: 5, value: 1400),
  KumoSankeyLink(source: 3, target: 7, value: 600),
];

class _SankeyDemo extends StatefulWidget {
  const _SankeyDemo();

  @override
  State<_SankeyDemo> createState() => _SankeyDemoState();
}

class _SankeyDemoState extends State<_SankeyDemo> {
  String? _pressed;
  bool _weekend = false;

  @override
  Widget build(BuildContext context) {
    final links = _weekend
        ? [for (final l in _trafficLinks) KumoSankeyLink(source: l.source, target: l.target, value: (l.value * (l.source.isEven ? 0.6 : 1.3)).roundToDouble())]
        : _trafficLinks;
    return _Stack(children: [
      DemoSection(
        title: 'Traffic by source',
        caption: 'Hover or tap a node or flow. Switching days morphs the layout.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s2, children: [
          Row(children: [
            KumoButton(
              label: _weekend ? 'Show weekday sample' : 'Show weekend sample',
              size: KumoButtonSize.sm,
              onPress: () => setState(() => _weekend = !_weekend),
            ),
          ]),
          KumoSankeyChart(
            nodes: _trafficNodes,
            links: links,
            height: 340,
            showNodeValues: !_weekend,
            onNodePress: (node, _) => setState(() => _pressed = node.name),
            onLinkPress: (link) => setState(() => _pressed = '${_trafficNodes[link.source].name} to ${_trafficNodes[link.target].name}'),
            semanticLabel: 'Zero Trust traffic by source, sample data',
          ),
          KumoText(
            _pressed == null ? 'Nothing pressed yet' : 'Pressed: $_pressed',
            variant: KumoTextVariant.secondary,
            size: KumoTextSize.sm,
          ),
          const _SampleNote(),
        ]),
      ),
      const DemoSection(
        title: 'Path highlighting',
        caption: 'focus: path highlights every flow upstream and downstream of the hovered node.',
        child: KumoSankeyChart(
          height: 260,
          nodeWidth: 20,
          nodePadding: 15,
          focus: KumoSankeyFocus.path,
          nodes: [
            KumoSankeyNode(name: 'example.com'),
            KumoSankeyNode(name: 'api.example.com'),
            KumoSankeyNode(name: 'Cache'),
            KumoSankeyNode(name: 'Workers'),
            KumoSankeyNode(name: 'Origin'),
            KumoSankeyNode(name: 'R2'),
          ],
          links: [
            KumoSankeyLink(source: 0, target: 2, value: 40),
            KumoSankeyLink(source: 0, target: 3, value: 20),
            KumoSankeyLink(source: 1, target: 2, value: 30),
            KumoSankeyLink(source: 1, target: 3, value: 35),
            KumoSankeyLink(source: 2, target: 4, value: 50),
            KumoSankeyLink(source: 2, target: 5, value: 20),
            KumoSankeyLink(source: 3, target: 4, value: 25),
            KumoSankeyLink(source: 3, target: 5, value: 30),
          ],
          semanticLabel: 'Requests by zone and service, sample data',
        ),
      ),
      const DemoSection(
        title: 'Inline labels and gray links',
        child: KumoSankeyChart(
          height: 220,
          nodeLabelLayout: KumoSankeyLabelLayout.inline,
          linkColor: KumoSankeyLinkColor.gray,
          nodes: [
            KumoSankeyNode(name: 'GET', value: 820),
            KumoSankeyNode(name: 'POST', value: 160),
            KumoSankeyNode(name: 'PUT', value: 20),
            KumoSankeyNode(name: '2xx', value: 930),
            KumoSankeyNode(name: '4xx', value: 55),
            KumoSankeyNode(name: '5xx', value: 15),
          ],
          links: [
            KumoSankeyLink(source: 0, target: 3, value: 780),
            KumoSankeyLink(source: 0, target: 4, value: 35),
            KumoSankeyLink(source: 0, target: 5, value: 5),
            KumoSankeyLink(source: 1, target: 3, value: 135),
            KumoSankeyLink(source: 1, target: 4, value: 15),
            KumoSankeyLink(source: 1, target: 5, value: 10),
            KumoSankeyLink(source: 2, target: 3, value: 15),
            KumoSankeyLink(source: 2, target: 4, value: 5),
          ],
          semanticLabel: 'Requests by method and status, sample data',
        ),
      ),
      const DemoSection(
        title: 'Loading',
        child: KumoSankeyChart(nodes: [], links: [], height: 160, loading: true),
      ),
    ]);
  }
}

// Map

/// Pointy-top hexagon tiles laid out roughly by geography. These are
/// abstract tiles, not country outlines; real apps pass their own shapes.
const _tiles = [
  ('wnam', 'Western North America', 0, 0),
  ('enam', 'Eastern North America', 1, 0),
  ('weur', 'Western Europe', 3, 0),
  ('eeur', 'Eastern Europe', 4, 0),
  ('apac', 'Asia Pacific', 6, 0),
  ('sam', 'South America', 1, 1),
  ('afr', 'Africa', 3, 1),
  ('me', 'Middle East', 4, 1),
  ('oc', 'Oceania', 6, 1),
];

List<KumoMapRegion> _hexRegions() {
  const r = 10.0;
  final w = math.sqrt(3) * r;
  return [
    for (final (id, name, col, row) in _tiles)
      () {
        final cx = col * w + (row.isOdd ? w / 2 : 0);
        final cy = row * 1.5 * r;
        final path = Path();
        for (var k = 0; k < 6; k++) {
          final a = math.pi / 180 * (60 * k - 90);
          // Shrink a little so tiles keep a hairline gap.
          final p = Offset(cx + r * 0.94 * math.cos(a), cy + r * 0.94 * math.sin(a));
          k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
        return KumoMapRegion(id: id, name: name, path: path);
      }(),
  ];
}

class _MapDemo extends StatefulWidget {
  const _MapDemo();

  @override
  State<_MapDemo> createState() => _MapDemoState();
}

class _MapDemoState extends State<_MapDemo> {
  final List<KumoMapRegion> _regions = _hexRegions();
  int _seed = 2;
  String? _pressed;

  Map<String, double> get _values {
    final random = math.Random(_seed);
    return {
      for (final (id, _, _, _) in _tiles)
        if (id != 'afr' || _seed.isEven) id: (random.nextDouble() * 2400 + 100).roundToDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _Stack(children: [
      DemoSection(
        title: 'Requests by region',
        caption: 'Hover or tap a tile. Regions without data keep the neutral fill.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s3, children: [
          KumoMapChart(
            regions: _regions,
            values: _values,
            showLegend: true,
            valueFormat: (v) => '${v.round()} req/s',
            onRegionPress: (r) => setState(() => _pressed = r.label),
            semanticLabel: 'Requests by location hint region, sample data',
          ),
          Wrap(spacing: KumoSpace.s3, runSpacing: KumoSpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
            KumoButton(label: 'Shuffle sample data', size: KumoButtonSize.sm, onPress: () => setState(() => _seed++)),
            KumoText(
              _pressed == null ? 'Nothing pressed yet' : 'Pressed: $_pressed',
              variant: KumoTextVariant.secondary,
              size: KumoTextSize.sm,
            ),
          ]),
          const _SampleNote(),
        ]),
      ),
      DemoSection(
        title: 'Loading and empty',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s4, children: [
          KumoMapChart(regions: _regions, values: const {}, loading: true, height: 120),
          KumoMapChart(regions: _regions, values: const {}, height: 160),
        ]),
      ),
    ]);
  }
}
