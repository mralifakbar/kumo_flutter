part of 'kumo_charts.dart';

/// How a [KumoTimeseriesChart] draws its series.
enum KumoTimeseriesChartType {
  /// One line per series. Add `gradient: true` for an area fill.
  line,

  /// Bars stacked per timestamp, positive values up and negative down.
  bar,
}

/// Which series a [KumoTimeseriesChart] tooltip lists.
enum KumoTimeseriesTooltipMode {
  /// Every visible series at the hovered time, largest value first.
  all,

  /// Only the series whose value is closest to the pointer.
  single,
}

/// Which axis the tooltip tracks the pointer on.
enum KumoTimeseriesTooltipFollow {
  /// Beside the pointer on both axes.
  both,

  /// Horizontally only, pinned to the top of the plot so it never covers
  /// the data under the pointer. Touch always uses this, so the finger does
  /// not hide the tooltip.
  x,
}

/// Stroke pattern for a line series or a marker. Kumo's guidance: give lines
/// patterns as well as colors so series stay distinct without color vision.
enum KumoTimeseriesLineStyle { solid, dashed, dotted }

/// One series of a [KumoTimeseriesChart]: Kumo's `TimeseriesData`.
///
/// Points are `(time, value)` records ordered by time (unordered input is
/// sorted). A `double.nan` value leaves a gap in the line.
///
/// ```dart
/// KumoTimeseriesData(
///   name: 'Requests',
///   color: KumoChartColors.light.semantic(KumoChartSemanticColor.neutral),
///   data: [(DateTime.utc(2026, 3, 4, 14), 120), (DateTime.utc(2026, 3, 4, 14, 1), 132)],
/// )
/// ```
@immutable
class KumoTimeseriesData {
  const KumoTimeseriesData({
    required this.name,
    required this.data,
    required this.color,
    this.lineStyle = KumoTimeseriesLineStyle.solid,
  });

  /// Shown in the tooltip, legend and screen reader summary. Unique per chart.
  final String name;
  final List<(DateTime, double)> data;

  /// Line, bar and legend dot color, usually from [KumoChartColors].
  final Color color;

  /// Stroke pattern for line charts.
  final KumoTimeseriesLineStyle lineStyle;

  @override
  bool operator ==(Object other) =>
      other is KumoTimeseriesData &&
      other.name == name &&
      other.color == color &&
      other.lineStyle == lineStyle &&
      (identical(other.data, data) || listEquals(other.data, data));

  @override
  int get hashCode => Object.hash(name, color, lineStyle, data.length);
}

/// A vertical reference line at a point in time, such as a deployment or a
/// configuration change. Kumo's `TimeseriesMarker`.
///
/// Markers closer together than about one x-axis tick merge into a single
/// line labelled "N changes"; its tooltip lists each one.
///
/// ```dart
/// KumoTimeseriesMarker(time: DateTime.utc(2026, 3, 4, 14, 15), label: 'Deploy 4f2c1a9', description: 'image-resizer v42')
/// ```
@immutable
class KumoTimeseriesMarker {
  const KumoTimeseriesMarker({
    required this.time,
    this.label,
    this.description,
    this.color,
    this.lineStyle = KumoTimeseriesLineStyle.dashed,
  });

  final DateTime time;

  /// Short label drawn along the line.
  final String? label;

  /// Longer text shown in the marker's tooltip.
  final String? description;

  /// Defaults to the subtle text color.
  final Color? color;
  final KumoTimeseriesLineStyle lineStyle;

  @override
  bool operator ==(Object other) =>
      other is KumoTimeseriesMarker &&
      other.time == time &&
      other.label == label &&
      other.description == description &&
      other.color == color &&
      other.lineStyle == lineStyle;

  @override
  int get hashCode => Object.hash(time, label, description, color, lineStyle);
}

/// A horizontal reference on the value axis: a dashed line at [value], or a
/// shaded band from [value] to [endValue]. Kumo's `TimeseriesThreshold`
/// (bands are a Flutter addition). The value axis always extends to include
/// thresholds.
///
/// ```dart
/// KumoTimeseriesThreshold(value: 128, label: 'Memory limit', color: KumoChartColors.light.semantic(KumoChartSemanticColor.attention))
/// KumoTimeseriesThreshold(value: 200, endValue: 400, label: 'Target latency', color: KumoChartColors.light.semantic(KumoChartSemanticColor.success))
/// ```
@immutable
class KumoTimeseriesThreshold {
  const KumoTimeseriesThreshold({required this.value, required this.color, this.label, this.endValue});

  final double value;

  /// When set, a band between [value] and [endValue] instead of a line.
  final double? endValue;

  /// Drawn at the end of the line, in [color].
  final String? label;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is KumoTimeseriesThreshold &&
      other.value == value &&
      other.endValue == endValue &&
      other.label == label &&
      other.color == color;

  @override
  int get hashCode => Object.hash(value, endValue, label, color);
}

/// Marks periods where data may still be arriving: line segments up to
/// [before] and from [after] are drawn dashed. Kumo's `incomplete` prop.
@immutable
class KumoTimeseriesIncomplete {
  const KumoTimeseriesIncomplete({this.before, this.after});

  final DateTime? before;
  final DateTime? after;

  @override
  bool operator ==(Object other) => other is KumoTimeseriesIncomplete && other.before == before && other.after == after;

  @override
  int get hashCode => Object.hash(before, after);
}

/// Kumo's `TimeseriesChart`: lines, area fills or stacked bars over time,
/// with a value axis that rounds to nice numbers, time labels that adapt to
/// the range, thresholds, reference markers and a crosshair tooltip.
///
/// ```dart
/// KumoTimeseriesChart(
///   xAxisName: 'Time (UTC)',
///   yAxisName: 'Requests',
///   data: [
///     KumoTimeseriesData(
///       name: 'Requests',
///       color: KumoChartColors.of(context).semantic(KumoChartSemanticColor.neutral),
///       data: [(DateTime.utc(2026, 3, 4, 14), 120), (DateTime.utc(2026, 3, 4, 14, 1), 132)],
///     ),
///   ],
///   tooltipValueFormat: (v) => '${v.round()} req/s',
/// )
/// ```
///
/// Interaction: with a mouse the tooltip follows the pointer; on touch it
/// appears under the finger on contact and follows a horizontal drag 1:1
/// (vertical drags still scroll the page), with a selection haptic each time
/// it snaps to a new point, and stays until the next touch or a tap outside.
/// With keyboard focus, Left and Right step through points, Home and End
/// jump to the ends and Escape hides the tooltip. Screen readers get a
/// summary of every series and can step through points with increase and
/// decrease actions.
///
/// States: [loading] shows Kumo's wave skeleton, [error] a message with a
/// retry button, and a chart without points an empty message.
class KumoTimeseriesChart extends StatefulWidget {
  const KumoTimeseriesChart({
    super.key,
    required this.data,
    this.type = KumoTimeseriesChartType.line,
    this.gradient = false,
    this.markers = const [],
    this.thresholds = const [],
    this.incomplete,
    this.xAxisName,
    this.yAxisName,
    this.xAxisTickCount = 5,
    this.yAxisTickCount = 5,
    this.yAxisMinInterval,
    this.xAxisHideLabelOverlap = true,
    this.xAxisTickFormat,
    this.yAxisTickFormat,
    this.tooltipValueFormat,
    this.tooltipTimestampFormat,
    this.tooltipFooter,
    this.tooltipMode = KumoTimeseriesTooltipMode.all,
    this.tooltipMaxItems = 10,
    this.tooltipFollowCursor = KumoTimeseriesTooltipFollow.both,
    this.showLegend = false,
    this.hiddenSeries,
    this.onHiddenSeriesChange,
    this.highlightedSeries,
    this.onTimeRangeChange,
    this.height,
    this.loading = false,
    this.error,
    this.onRetry,
    this.emptyMessage,
    this.emptyDescription = 'Choose a longer time range to see earlier data.',
    this.semanticLabel,
    this.scrubHaptic = KumoHaptic.selection,
  });

  /// The series to draw, in legend and stacking order.
  final List<KumoTimeseriesData> data;
  final KumoTimeseriesChartType type;

  /// Fills beneath each line with a fade from 40% of its color to clear.
  /// No effect on bars.
  final bool gradient;
  final List<KumoTimeseriesMarker> markers;
  final List<KumoTimeseriesThreshold> thresholds;

  /// Dashes line segments in periods that may be incomplete.
  final KumoTimeseriesIncomplete? incomplete;

  /// Label under the time axis, such as `'Time (UTC)'`.
  final String? xAxisName;

  /// Label beside the value axis, such as `'Requests'`.
  final String? yAxisName;

  /// About how many time labels to show. Defaults to 5.
  final int xAxisTickCount;

  /// About how many value ticks to show. Defaults to 5.
  final int yAxisTickCount;

  /// Smallest step between value ticks. Pass `1` for counts so the axis
  /// never shows fractions.
  final double? yAxisMinInterval;

  /// Hides time labels that would overlap their neighbour. Defaults to true.
  final bool xAxisHideLabelOverlap;

  /// Formats time labels. By default the precision follows the range:
  /// `14:05:30`, `14:05`, `Mar 4`, `Mar`, `2026`, in the zone of the data
  /// (pass UTC times to label in UTC).
  final String Function(DateTime time)? xAxisTickFormat;

  /// Formats value labels. Defaults to grouped digits (`12,000`).
  final String Function(double value)? yAxisTickFormat;

  /// Formats tooltip values, such as `(v) => '${v.toStringAsFixed(1)} ms'`.
  final String Function(double value)? tooltipValueFormat;

  /// Formats the tooltip timestamp. Defaults to `Mar 4, 14:05:09`.
  final String Function(DateTime time)? tooltipTimestampFormat;

  /// Short note under the tooltip rows, such as how values are aggregated.
  final String? tooltipFooter;
  final KumoTimeseriesTooltipMode tooltipMode;

  /// Rows shown in [KumoTimeseriesTooltipMode.all] before a `+N more` line.
  final int tooltipMaxItems;
  final KumoTimeseriesTooltipFollow tooltipFollowCursor;

  /// Shows a row of [KumoChartLegend] items above the chart with each
  /// series' latest value. Pressing an item hides or shows its series;
  /// hovering it highlights the series.
  final bool showLegend;

  /// Names of series to leave out (controlled). Hidden series are not drawn,
  /// leave the tooltip and no longer stretch the value axis. When null the
  /// chart tracks legend toggles itself.
  final Set<String>? hiddenSeries;

  /// Called with the next hidden set when a legend item is pressed.
  final ValueChanged<Set<String>>? onHiddenSeriesChange;

  /// Name of a series to emphasise; the others fade. Drive it from your own
  /// legend's `onHoverChange`.
  final String? highlightedSeries;

  /// Enables range selection: dragging across the chart with a mouse
  /// selects a time range and reports it here. Touch drags scrub instead.
  final void Function(DateTime from, DateTime to)? onTimeRangeChange;

  /// Height of the plot area. Defaults to Kumo's 350, or 260 below the `md`
  /// breakpoint so a phone shows the chart and its context together.
  final double? height;

  /// Shows the loading skeleton in place of the chart.
  final bool loading;

  /// Shows this message with a warning icon in place of the chart, such as
  /// `'Could not load requests. Check your connection, then retry.'`.
  final String? error;

  /// Adds a Retry button to the [error] state.
  final VoidCallback? onRetry;

  /// Title of the state shown when no series has a point.
  final String? emptyMessage;

  /// Next step shown under [emptyMessage].
  final String? emptyDescription;

  /// Leads the screen reader summary, such as `'Requests for image-resizer'`.
  /// The chart appends series names, the time range and value ranges.
  final String? semanticLabel;

  /// Fired when a touch scrub snaps to a new point.
  final KumoHaptic scrubHaptic;

  @override
  State<KumoTimeseriesChart> createState() => _KumoTimeseriesChartState();
}

class _TsSeries {
  _TsSeries({
    required this.name,
    required this.order,
    required this.color,
    required this.style,
    required this.t,
    required this.v,
    this.alpha = 1,
  });

  final String name;

  /// Index in the widget's data, so stacking and paint order stay stable
  /// while series fade in and out.
  final int order;
  final Color color;
  final KumoTimeseriesLineStyle style;
  final Float64List t;
  final Float64List v;
  final double alpha;

  _TsSeries copyWith({Float64List? v, double? alpha}) =>
      _TsSeries(name: name, order: order, color: color, style: style, t: t, v: v ?? this.v, alpha: alpha ?? this.alpha);
}

class _MarkerCluster {
  _MarkerCluster(this.ms, this.label, this.color, this.style, this.markers);

  final double ms;
  final String? label;
  final Color? color;
  final KumoTimeseriesLineStyle style;
  final List<KumoTimeseriesMarker> markers;
}

/// Everything the painters need for one moment: the series and the axis
/// domains. Targets come from the widget; while morphing, frames are
/// interpolated between the geometry on screen and the target.
class _TsFrame {
  _TsFrame({
    required this.series,
    required this.x0,
    required this.x1,
    required this.y0,
    required this.y1,
    required this.times,
    required this.scale,
    required this.slotMs,
    required this.utc,
    required this.clusters,
  });

  final List<_TsSeries> series;
  final double x0;
  final double x1;
  final double y0;
  final double y1;

  /// Sorted unique timestamps of the visible series: the points the
  /// crosshair snaps to.
  final Float64List times;
  final _NiceScale scale;

  /// Smallest gap between timestamps, for bar widths.
  final double slotMs;
  final bool utc;
  final List<_MarkerCluster> clusters;

  _TsPaths? _paths;
  Rect? _pathsRect;

  bool get isEmpty => series.every((s) => s.t.isEmpty);

  static _TsFrame lerp(_TsFrame a, _TsFrame b, double t, bool bar) {
    final from = {for (final s in a.series) s.name: s};
    final out = <_TsSeries>[];
    final seen = <String>{};
    for (final s in b.series) {
      seen.add(s.name);
      final f = from[s.name];
      if (f == null) {
        out.add(s.copyWith(alpha: s.alpha * t, v: bar ? _scaleValues(s.v, t) : null));
      } else {
        final fv = _resample(f, s.t);
        final v = Float64List(s.v.length);
        for (var i = 0; i < v.length; i++) {
          final target = s.v[i];
          final start = fv[i];
          v[i] = target.isNaN || start.isNaN ? target : start + (target - start) * t;
        }
        out.add(s.copyWith(v: v, alpha: _lerp(f.alpha, s.alpha, t)));
      }
    }
    for (final f in a.series) {
      if (seen.contains(f.name)) continue;
      final alpha = f.alpha * (1 - t);
      if (alpha <= 0.001) continue;
      out.add(f.copyWith(alpha: alpha, v: bar ? _scaleValues(f.v, 1 - t) : null));
    }
    out.sort((x, y) => x.order.compareTo(y.order));
    return _TsFrame(
      series: out,
      x0: _lerp(a.x0, b.x0, t),
      x1: _lerp(a.x1, b.x1, t),
      y0: _lerp(a.y0, b.y0, t),
      y1: _lerp(a.y1, b.y1, t),
      times: b.times,
      scale: b.scale,
      slotMs: _lerp(a.slotMs, b.slotMs, t),
      utc: b.utc,
      clusters: b.clusters,
    );
  }
}

Float64List _scaleValues(Float64List v, double k) {
  final out = Float64List(v.length);
  for (var i = 0; i < v.length; i++) {
    out[i] = v[i] * k;
  }
  return out;
}

/// Values of [s] at [times], linearly interpolated, clamped to its ends.
Float64List _resample(_TsSeries s, Float64List times) {
  final out = Float64List(times.length);
  final n = s.t.length;
  if (n == 0) return out;
  var j = 0;
  for (var i = 0; i < times.length; i++) {
    final tt = times[i];
    if (tt <= s.t[0]) {
      out[i] = s.v[0];
      continue;
    }
    if (tt >= s.t[n - 1]) {
      out[i] = s.v[n - 1];
      continue;
    }
    while (j < n - 2 && s.t[j + 1] < tt) {
      j++;
    }
    final span = s.t[j + 1] - s.t[j];
    final k = span == 0 ? 0.0 : (tt - s.t[j]) / span;
    out[i] = s.v[j] + (s.v[j + 1] - s.v[j]) * k;
  }
  return out;
}

/// Index of the point in sorted [t] nearest to [ms] (Kumo's `findNearest`).
int _nearestIndex(Float64List t, double ms) {
  if (t.isEmpty) return -1;
  var lo = 0;
  var hi = t.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (t[mid] < ms) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if (lo > 0 && (t[lo - 1] - ms).abs() <= (t[lo] - ms).abs()) lo--;
  return lo;
}

class _TsRun {
  _TsRun(this.points);

  final List<Offset> points;
}

class _TsSeriesPaths {
  _TsSeriesPaths(this.series);

  final _TsSeries series;
  final List<_TsRun> solid = [];
  final List<_TsRun> dashed = [];
  final List<_TsRun> area = [];
  final List<Rect> bars = [];
  double areaTop = double.infinity;
}

class _TsPaths {
  _TsPaths(this.series);

  final List<_TsSeriesPaths> series;
}

class _TsAxes {
  _TsAxes({
    required this.plot,
    required this.yTicks,
    required this.xTicks,
    required this.xName,
    required this.yName,
    required this.xNameTop,
    required this.yNameCenterX,
    required this.thresholdLabels,
    required this.markerLabels,
  });

  final Rect plot;
  final List<(double, TextPainter)> yTicks;
  final List<(double, TextPainter)> xTicks;
  final TextPainter? xName;
  final TextPainter? yName;
  final double xNameTop;
  final double yNameCenterX;
  final List<TextPainter?> thresholdLabels;
  final List<TextPainter?> markerLabels;

  void dispose() {
    for (final (_, p) in yTicks) {
      p.dispose();
    }
    for (final (_, p) in xTicks) {
      p.dispose();
    }
    xName?.dispose();
    yName?.dispose();
    for (final p in thresholdLabels) {
      p?.dispose();
    }
    for (final p in markerLabels) {
      p?.dispose();
    }
  }
}

class _TsHover {
  _TsHover({
    required this.ms,
    required this.index,
    required this.rows,
    required this.hiddenCount,
    required this.anchor,
    this.cluster,
  });

  final double ms;
  final int index;
  final List<(String, Color, double)> rows;
  final int hiddenCount;
  final Offset anchor;
  final _MarkerCluster? cluster;
}

class _ScrubDragRecognizer extends HorizontalDragGestureRecognizer {
  _ScrubDragRecognizer({super.supportedDevices});
}

class _BrushDragRecognizer extends HorizontalDragGestureRecognizer {
  _BrushDragRecognizer({super.supportedDevices});
}

const Set<PointerDeviceKind> _kTouchKinds = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

class _KumoTimeseriesChartState extends State<KumoTimeseriesChart> with SingleTickerProviderStateMixin {
  late final AnimationController _morph;
  late final FocusNode _focusNode;
  late _TsFrame _target;
  _TsFrame? _from;
  _TsFrame? _displayedCache;
  double _displayedAt = -1;

  Set<String> _ownHidden = const {};
  String? _legendHover;

  _TsAxes? _axes;
  Object? _axesKey;

  Offset? _pointer;
  bool _touch = false;
  bool _touchUp = false;
  bool _scrubbing = false;
  int? _keyIndex;
  int? _lastSnap;
  double? _brushStart;
  double? _brushEnd;
  bool _focusHighlight = false;
  String? _summaryCache;

  Set<String> get _hidden => widget.hiddenSeries ?? _ownHidden;

  bool get _bar => widget.type == KumoTimeseriesChartType.bar;

  @override
  void initState() {
    super.initState();
    _morph = AnimationController(vsync: this, duration: KumoDurations.slow)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _from != null) {
          setState(() {
            _from = null;
            _displayedCache = null;
          });
        }
      });
    _focusNode = FocusNode(debugLabel: 'KumoTimeseriesChart');
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
    _target = _buildTarget();
  }

  @override
  void didUpdateWidget(KumoTimeseriesChart old) {
    super.didUpdateWidget(old);
    final changed =
        !listEquals(old.data, widget.data) ||
        old.type != widget.type ||
        !listEquals(old.thresholds, widget.thresholds) ||
        !listEquals(old.markers, widget.markers) ||
        old.yAxisTickCount != widget.yAxisTickCount ||
        old.xAxisTickCount != widget.xAxisTickCount ||
        old.yAxisMinInterval != widget.yAxisMinInterval ||
        !setEquals(old.hiddenSeries, widget.hiddenSeries);
    _invalidateAxes();
    _summaryCache = null;
    if (changed) _retarget(animate: old.type == widget.type);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _invalidateAxes();
    _summaryCache = null;
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _morph.dispose();
    _focusNode.dispose();
    _axes?.dispose();
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) => _updateFocusHighlight();

  void _updateFocusHighlight() {
    final v = _focusNode.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (v != _focusHighlight && mounted) setState(() => _focusHighlight = v);
  }

  void _invalidateAxes() {
    _axesKey = null;
  }

  void _retarget({bool animate = true}) {
    final next = _buildTarget();
    final reduce = KumoMotion.reduceMotion(context);
    if (animate && !reduce && !_target.isEmpty && !next.isEmpty) {
      _from = _displayed();
      _target = next;
      _displayedCache = null;
      _morph.forward(from: 0);
    } else {
      _from = null;
      _target = next;
      _displayedCache = null;
      _morph.value = 1;
    }
    _keyIndex = null;
    _summaryCache = null;
    _invalidateAxes();
  }

  _TsFrame _displayed() {
    final from = _from;
    if (from == null) return _target;
    final v = _morph.value;
    if (_displayedCache != null && _displayedAt == v) return _displayedCache!;
    _displayedAt = v;
    return _displayedCache = _TsFrame.lerp(from, _target, KumoCurves.standard.transform(v), _bar);
  }

  _TsFrame _buildTarget() {
    final w = widget;
    final hidden = _hidden;
    final series = <_TsSeries>[];
    var utc = false;
    var anyPoint = false;
    for (var i = 0; i < w.data.length; i++) {
      final s = w.data[i];
      if (s.data.isNotEmpty && !anyPoint) {
        utc = s.data.first.$1.isUtc;
        anyPoint = true;
      }
      if (hidden.contains(s.name)) continue;
      var pts = s.data;
      for (var k = 1; k < pts.length; k++) {
        if (pts[k].$1.isBefore(pts[k - 1].$1)) {
          pts = [...pts]..sort((a, b) => a.$1.compareTo(b.$1));
          break;
        }
      }
      final t = Float64List(pts.length);
      final v = Float64List(pts.length);
      for (var k = 0; k < pts.length; k++) {
        t[k] = pts[k].$1.millisecondsSinceEpoch.toDouble();
        v[k] = pts[k].$2;
      }
      series.add(_TsSeries(name: s.name, order: i, color: s.color, style: s.lineStyle, t: t, v: v));
    }

    final timeSet = <double>{};
    for (final s in series) {
      timeSet.addAll(s.t);
    }
    final times = Float64List.fromList(timeSet.toList()..sort());

    var x0 = double.infinity;
    var x1 = -double.infinity;
    void extendX(Iterable<double> ts) {
      for (final t in ts) {
        if (t < x0) x0 = t;
        if (t > x1) x1 = t;
      }
    }

    extendX(times);
    if (!x0.isFinite) {
      // Every series hidden: keep the time range of the full data.
      for (final s in w.data) {
        extendX(s.data.map((p) => p.$1.millisecondsSinceEpoch.toDouble()));
      }
    }
    if (!x0.isFinite) {
      final now = clock.now().millisecondsSinceEpoch.toDouble();
      x0 = now - 3600000;
      x1 = now;
    }
    if (x0 == x1) {
      x0 -= 60000;
      x1 += 60000;
    }

    var slot = double.infinity;
    for (var i = 1; i < times.length; i++) {
      final gap = times[i] - times[i - 1];
      if (gap > 0 && gap < slot) slot = gap;
    }
    if (!slot.isFinite) slot = (x1 - x0) / 2;
    if (_bar) {
      x0 -= slot / 2;
      x1 += slot / 2;
    }

    var lo = 0.0;
    var hi = 0.0;
    if (_bar) {
      final pos = <double, double>{};
      final neg = <double, double>{};
      for (final s in series) {
        for (var k = 0; k < s.t.length; k++) {
          final v = s.v[k];
          if (v.isNaN) continue;
          if (v >= 0) {
            pos[s.t[k]] = (pos[s.t[k]] ?? 0) + v;
          } else {
            neg[s.t[k]] = (neg[s.t[k]] ?? 0) + v;
          }
        }
      }
      for (final v in pos.values) {
        hi = math.max(hi, v);
      }
      for (final v in neg.values) {
        lo = math.min(lo, v);
      }
    } else {
      for (final s in series) {
        for (final v in s.v) {
          if (v.isNaN) continue;
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
      }
    }
    for (final th in w.thresholds) {
      for (final v in [th.value, ?th.endValue]) {
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
    final scale = _NiceScale.of(lo, hi, count: w.yAxisTickCount, minInterval: w.yAxisMinInterval);

    final clusters = <_MarkerCluster>[];
    if (w.markers.isNotEmpty) {
      var mn = double.infinity;
      var mx = -double.infinity;
      var count = 0;
      for (final s in w.data) {
        for (final p in s.data) {
          final ms = p.$1.millisecondsSinceEpoch.toDouble();
          mn = math.min(mn, ms);
          mx = math.max(mx, ms);
          count++;
        }
      }
      for (final m in w.markers) {
        final ms = m.time.millisecondsSinceEpoch.toDouble();
        mn = math.min(mn, ms);
        mx = math.max(mx, ms);
        count++;
      }
      final interval = count < 2 ? 0.0 : (mx - mn) / math.max(1, w.xAxisTickCount);
      final sorted = [...w.markers]..sort((a, b) => a.time.compareTo(b.time));
      final groups = <List<KumoTimeseriesMarker>>[];
      for (final m in sorted) {
        if (groups.isNotEmpty &&
            m.time.millisecondsSinceEpoch - groups.last.last.time.millisecondsSinceEpoch <= interval) {
          groups.last.add(m);
        } else {
          groups.add([m]);
        }
      }
      for (final g in groups) {
        final first = g.first;
        clusters.add(
          _MarkerCluster(
            first.time.millisecondsSinceEpoch.toDouble(),
            g.length == 1 ? first.label : '${g.length} changes',
            first.color,
            first.lineStyle,
            g,
          ),
        );
      }
    }

    return _TsFrame(
      series: series,
      x0: x0,
      x1: x1,
      y0: scale.min,
      y1: scale.max,
      times: times,
      scale: scale,
      slotMs: slot,
      utc: utc,
      clusters: clusters,
    );
  }

  String _formatY(double v) =>
      widget.yAxisTickFormat?.call(v) ?? _formatChartNumber(v, maxFractionDigits: math.min(_target.scale.decimals, 6));

  String _formatValue(double v) => widget.tooltipValueFormat?.call(v) ?? _formatChartNumber(v);

  DateTime _time(double ms) => DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: _target.utc);

  String _formatTimestamp(DateTime d) =>
      widget.tooltipTimestampFormat?.call(d) ?? _formatChartTimestamp(d, context.kumoStrings);

  _TsAxes _axesFor(Size size, KumoThemeData kumo, TextScaler scaler) {
    final key = (size, scaler, kumo, _target);
    if (_axes != null && _axesKey == key) return _axes!;
    _axes?.dispose();
    final w = widget;
    final style = _axisTextStyle(kumo);
    final majorStyle = _axisTextStyle(kumo, weight: KumoTypography.medium);
    final strings = context.kumoStrings;

    final yTicks = [for (final v in _target.scale.ticks) (v, _layoutText(_formatY(v), style, scaler))];
    var yLabelW = 0.0;
    for (final (_, p) in yTicks) {
      yLabelW = math.max(yLabelW, p.width);
    }
    final yName = w.yAxisName == null ? null : _layoutText(w.yAxisName!, style, scaler);
    final xName = w.xAxisName == null ? null : _layoutText(w.xAxisName!, style, scaler);
    final xLabelH = _layoutText('0', style, scaler).height;

    // Grid padding from Kumo (left 24, or 30 with an axis name; right, top
    // and bottom 24), grown so labels always fit, like ECharts' outer bounds.
    double left;
    var yNameCenterX = 0.0;
    if (yName != null) {
      final gap = math.max(40.0, yLabelW + 15 + 4 + yName.height / 2);
      left = math.max(30.0, gap + yName.height / 2 + 2);
      yNameCenterX = left - gap;
    } else {
      left = math.max(24.0, yLabelW + 15);
    }
    double bottom;
    var xNameTop = 0.0;
    if (xName != null) {
      final top = math.max(30 - xName.height / 2, 8 + xLabelH + 4);
      bottom = math.max(30.0, top + xName.height + 2);
      xNameTop = top;
    } else {
      bottom = math.max(24.0, 8 + xLabelH + 2);
    }
    const top = 24.0;
    const right = 24.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      math.max(left + 1, size.width - right),
      math.max(top + 1, size.height - bottom),
    );

    final frame = _target;
    final rawTicks = _timeTicks(frame.x0, frame.x1, w.xAxisTickCount, frame.utc, strings);
    final xTicks = <(double, TextPainter)>[];
    var lastRight = -double.infinity;
    for (final tick in rawTicks) {
      final label = w.xAxisTickFormat?.call(tick.time) ?? tick.label;
      final painter = _layoutText(label, tick.major && w.xAxisTickFormat == null ? majorStyle : style, scaler);
      final ms = tick.time.millisecondsSinceEpoch.toDouble();
      final cx = plot.left + (ms - frame.x0) / (frame.x1 - frame.x0) * plot.width;
      final l = (cx - painter.width / 2).clamp(0.0, math.max(0.0, size.width - painter.width));
      if (w.xAxisHideLabelOverlap && l < lastRight + 6) {
        painter.dispose();
        continue;
      }
      lastRight = l + painter.width;
      xTicks.add((ms, painter));
    }

    final thresholdLabels = [
      for (final th in w.thresholds)
        th.label == null ? null : _layoutText(th.label!, style.copyWith(color: th.color), scaler, maxWidth: plot.width),
    ];
    final markerColor = kumo.colors.textSubtle;
    final markerLabels = [
      for (final c in frame.clusters)
        c.label == null
            ? null
            : _layoutText(c.label!, style.copyWith(color: c.color ?? markerColor), scaler, maxWidth: plot.height - 8),
    ];

    _axesKey = key;
    return _axes = _TsAxes(
      plot: plot,
      yTicks: yTicks,
      xTicks: xTicks,
      xName: xName,
      yName: yName,
      xNameTop: xNameTop,
      yNameCenterX: yNameCenterX,
      thresholdLabels: thresholdLabels,
      markerLabels: markerLabels,
    );
  }

  double _xToMs(_TsFrame f, Rect plot, double x) => f.x0 + (x - plot.left) / plot.width * (f.x1 - f.x0);

  double _msToX(_TsFrame f, Rect plot, double ms) => plot.left + (ms - f.x0) / (f.x1 - f.x0) * plot.width;

  List<(String, Color, double)> _rowsAt(double ms) {
    final rows = <(String, Color, double)>[];
    for (final s in _target.series) {
      final i = _nearestIndex(s.t, ms);
      if (i < 0 || s.v[i].isNaN) continue;
      rows.add((s.name, s.color, s.v[i]));
    }
    rows.sort((a, b) => b.$3.compareTo(a.$3));
    return rows;
  }

  _TsHover? _hover(_TsAxes axes, _TsFrame frame) {
    final plot = axes.plot;
    final times = _target.times;
    if (times.isEmpty) return null;
    int index;
    Offset anchor;
    if (_pointer != null) {
      final p = _pointer!;
      // Markers win when the pointer is on their line, as in Kumo.
      final tolerance = _touch ? 12.0 : 5.0;
      for (final c in frame.clusters) {
        final x = _msToX(frame, plot, c.ms);
        if ((p.dx - x).abs() <= tolerance && x >= plot.left - 1 && x <= plot.right + 1) {
          final all = _rowsAt(c.ms);
          final max = widget.tooltipMaxItems;
          return _TsHover(
            ms: c.ms,
            index: _nearestIndex(times, c.ms),
            rows: all.take(max).toList(),
            hiddenCount: math.max(0, all.length - max),
            anchor: _touch ? Offset(p.dx, plot.top) : p,
            cluster: c,
          );
        }
      }
      index = _nearestIndex(times, _xToMs(frame, plot, p.dx.clamp(plot.left, plot.right)));
      final followX = _touch || widget.tooltipFollowCursor == KumoTimeseriesTooltipFollow.x;
      anchor = followX ? Offset(p.dx, plot.top) : p;
    } else if (_keyIndex != null) {
      index = _keyIndex!.clamp(0, times.length - 1);
      anchor = Offset(_msToX(frame, plot, times[index]), plot.top);
    } else {
      return null;
    }
    final ms = times[index];
    final all = _rowsAt(ms);
    List<(String, Color, double)> rows;
    var hiddenCount = 0;
    if (widget.tooltipMode == KumoTimeseriesTooltipMode.single && all.isNotEmpty) {
      final y = _pointer?.dy ?? plot.center.dy;
      final cursor = frame.y0 + (plot.bottom - y) / plot.height * (frame.y1 - frame.y0);
      var best = all.first;
      for (final r in all) {
        if ((r.$3 - cursor).abs() < (best.$3 - cursor).abs()) best = r;
      }
      rows = [best];
    } else {
      rows = all.take(widget.tooltipMaxItems).toList();
      hiddenCount = math.max(0, all.length - widget.tooltipMaxItems);
    }
    return _TsHover(ms: ms, index: index, rows: rows, hiddenCount: hiddenCount, anchor: anchor);
  }

  /// The tooltip state for point [index], for the screen reader's
  /// increased and decreased values.
  _TsHover _hoverAt(int index, _TsAxes axes, _TsFrame frame) {
    final times = _target.times;
    final i = index.clamp(0, times.length - 1);
    final all = _rowsAt(times[i]);
    final max = widget.tooltipMaxItems;
    return _TsHover(
      ms: times[i],
      index: i,
      rows: all.take(max).toList(),
      hiddenCount: math.max(0, all.length - max),
      anchor: Offset(_msToX(frame, axes.plot, times[i]), axes.plot.top),
    );
  }

  void _setPointer(Offset? p, {required bool touch}) {
    if (p == _pointer && touch == _touch) return;
    setState(() {
      _pointer = p;
      _touch = touch;
      if (p != null) _keyIndex = null;
    });
  }

  void _clear() {
    if (_pointer == null && _keyIndex == null && _brushStart == null) return;
    setState(() {
      _pointer = null;
      _keyIndex = null;
      _brushStart = null;
      _brushEnd = null;
      _lastSnap = null;
    });
  }

  void _snapFeedback() {
    final axes = _axes;
    if (axes == null || _pointer == null) return;
    final frame = _displayed();
    final i = _nearestIndex(
      _target.times,
      _xToMs(frame, axes.plot, _pointer!.dx.clamp(axes.plot.left, axes.plot.right)),
    );
    if (_lastSnap != null && i != _lastSnap) kumoHaptic(widget.scrubHaptic);
    _lastSnap = i;
  }

  void _step(int delta) {
    final n = _target.times.length;
    if (n == 0) return;
    setState(() {
      _pointer = null;
      final current = _keyIndex;
      _keyIndex = current == null ? (delta > 0 ? 0 : n - 1) : (current + delta).clamp(0, n - 1);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final n = _target.times.length;
    if (n == 0) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      _step(1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
    } else if (key == LogicalKeyboardKey.home) {
      setState(() => _keyIndex = 0);
    } else if (key == LogicalKeyboardKey.end) {
      setState(() => _keyIndex = n - 1);
    } else if (key == LogicalKeyboardKey.escape && (_keyIndex != null || _pointer != null)) {
      _clear();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _toggleSeries(String name) {
    final next = {..._hidden};
    if (!next.remove(name)) next.add(name);
    widget.onHiddenSeriesChange?.call(next);
    if (widget.hiddenSeries == null) {
      setState(() {
        _ownHidden = next;
        _retarget();
      });
    }
  }

  String _summary() {
    if (_summaryCache != null) return _summaryCache!;
    final strings = context.kumoStrings;
    final w = widget;
    final parts = <String>[];
    if (w.semanticLabel != null) parts.add(w.semanticLabel!);
    final visible = _target.series;
    final kind = _bar ? 'Stacked bar chart' : (w.gradient ? 'Area chart' : 'Line chart');
    final times = _target.times;
    final range = times.isEmpty
        ? ''
        : ', ${_formatChartShortTime(_time(times.first), strings)} to ${_formatChartShortTime(_time(times.last), strings)}';
    parts.add('$kind, ${visible.length} series$range');
    for (final s in visible) {
      var mn = double.infinity;
      var mx = -double.infinity;
      double? last;
      for (final v in s.v) {
        if (v.isNaN) continue;
        mn = math.min(mn, v);
        mx = math.max(mx, v);
        last = v;
      }
      if (last == null) {
        parts.add('${s.name}: no data');
      } else {
        parts.add('${s.name}: ${_formatValue(mn)} to ${_formatValue(mx)}, latest ${_formatValue(last)}');
      }
    }
    final hidden = w.data.where((s) => _hidden.contains(s.name)).map((s) => s.name).toList();
    if (hidden.isNotEmpty) parts.add('Hidden: ${hidden.join(', ')}');
    for (final th in w.thresholds) {
      final name = th.label ?? 'Threshold';
      parts.add(
        th.endValue == null
            ? '$name at ${_formatValue(th.value)}'
            : '$name from ${_formatValue(th.value)} to ${_formatValue(th.endValue!)}',
      );
    }
    if (w.markers.isNotEmpty) {
      parts.add(
        [for (final m in w.markers) '${m.label ?? 'Marker'} at ${_formatChartShortTime(m.time, strings)}'].join('; '),
      );
    }
    return _summaryCache = '${parts.join('. ')}.';
  }

  String? _activeValue(_TsHover? h) {
    if (h == null) return null;
    final buffer = StringBuffer(_formatTimestamp(_time(h.ms)));
    if (h.cluster != null) {
      for (final m in h.cluster!.markers) {
        buffer.write('. ${m.label ?? 'Marker'}');
        if (m.description != null) buffer.write(': ${m.description}');
      }
    }
    for (final (name, _, v) in h.rows) {
      buffer.write('. $name ${_formatValue(v)}');
    }
    if (h.hiddenCount > 0) buffer.write('. ${h.hiddenCount} more');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
        final height = widget.height ?? (context.kumoIsNarrow ? 260.0 : 350.0);
        final w = widget;
        Widget body;
        final String kind;
        if (w.loading) {
          kind = 'loading';
          body = _ChartSkeleton(
            shape: _bar ? _SkeletonShape.bar : _SkeletonShape.line,
            semanticLabel: w.semanticLabel == null
                ? context.kumoStrings.loadingChart
                : '${context.kumoStrings.loadingChart}: ${w.semanticLabel}',
          );
        } else if (w.error != null) {
          kind = 'error';
          body = Semantics(
            liveRegion: true,
            child: _ChartMessage(icon: KumoIcons.warningCircle, title: w.error!, onRetry: w.onRetry, danger: true),
          );
        } else if (w.data.every((s) => s.data.isEmpty)) {
          kind = 'empty';
          body = _ChartMessage(
            icon: KumoIcons.chartLine,
            title: w.emptyMessage ?? context.kumoStrings.noDataInRange,
            description: w.emptyDescription,
          );
        } else {
          kind = 'chart';
          body = AnimatedBuilder(animation: _morph, builder: (context, _) => _buildChart(context, Size(width, height)));
        }
        // The skeleton, chart, error and empty message cross-fade.
        body = SizedBox(
          width: width,
          height: height,
          child: KumoSwap(
            duration: KumoDurations.quick,
            child: KeyedSubtree(key: ValueKey(kind), child: body),
          ),
        );
        if (!w.showLegend) return body;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(context),
            const SizedBox(height: KumoSpace.s2),
            body,
          ],
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context) {
    final w = widget;
    final hidden = _hidden;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2),
      child: Wrap(
        spacing: KumoSpace.s4,
        runSpacing: KumoSpace.s1,
        children: [
          if (w.loading)
            for (var i = 0; i < math.max(1, w.data.length); i++) const KumoChartLegend.loading()
          else
            for (final s in w.data)
              KumoChartLegend.small(
                name: s.name,
                color: s.color,
                value: _latestValue(s),
                inactive: hidden.contains(s.name),
                onPress: () => _toggleSeries(s.name),
                onHoverChange: (hovering) => setState(() {
                  if (hovering) {
                    _legendHover = s.name;
                  } else if (_legendHover == s.name) {
                    _legendHover = null;
                  }
                }),
              ),
        ],
      ),
    );
  }

  String? _latestValue(KumoTimeseriesData s) {
    for (var i = s.data.length - 1; i >= 0; i--) {
      final v = s.data[i].$2;
      if (!v.isNaN) return _formatValue(v);
    }
    return null;
  }

  Widget _buildChart(BuildContext context, Size size) {
    final kumo = context.kumo;
    final scaler = MediaQuery.textScalerOf(context);
    final frame = _displayed();
    final axes = _axesFor(size, kumo, scaler);
    final hover = _hover(axes, frame);
    var highlighted = widget.highlightedSeries ?? _legendHover;
    if (highlighted != null && !_target.series.any((s) => s.name == highlighted)) highlighted = null;

    final gridColor = kumo.colors.textSubtle.withValues(alpha: 0.2);
    final base = CustomPaint(
      size: size,
      painter: _TsBasePainter(
        frame: frame,
        axes: axes,
        bar: _bar,
        gradient: widget.gradient,
        thresholds: widget.thresholds,
        incompleteBefore: widget.incomplete?.before?.millisecondsSinceEpoch.toDouble(),
        incompleteAfter: widget.incomplete?.after?.millisecondsSinceEpoch.toDouble(),
        gridColor: gridColor,
        textColor: kumo.colors.textSubtle,
        markerColor: kumo.colors.textSubtle,
        labelBackground: kumo.colors.base.withValues(alpha: 0.5),
        highlighted: highlighted,
        hoveredCluster: hover?.cluster,
      ),
    );

    final overlay = CustomPaint(
      size: size,
      painter: _TsOverlayPainter(
        frame: frame,
        plot: axes.plot,
        bar: _bar,
        ms: hover == null || hover.cluster != null ? null : hover.ms,
        brush: _brushStart == null || _brushEnd == null ? null : (_brushStart!, _brushEnd!),
        lineColor: kumo.colors.textSubtle.withValues(alpha: 0.45),
        shadowColor: kumo.colors.textSubtle.withValues(alpha: 0.12),
        ringColor: kumo.colors.base,
      ),
    );

    Widget chart = Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(child: base),
        overlay,
        if (hover != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomSingleChildLayout(
                delegate: _ChartTooltipLayout(anchor: hover.anchor),
                child: _buildTooltip(context, hover),
              ),
            ),
          ),
      ],
    );

    chart = KumoFocusRing(visible: _focusHighlight, borderRadius: BorderRadius.circular(KumoRadius.lg), child: chart);

    chart = Listener(
      onPointerDown: (e) {
        if (_kTouchKinds.contains(e.kind)) _touchUp = false;
      },
      onPointerUp: (e) {
        if (_kTouchKinds.contains(e.kind)) _touchUp = true;
      },
      onPointerCancel: (e) {
        if (_kTouchKinds.contains(e.kind)) _clear();
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _ScrubDragRecognizer: GestureRecognizerFactoryWithHandlers<_ScrubDragRecognizer>(
            () => _ScrubDragRecognizer(supportedDevices: _kTouchKinds),
            (r) => r
              ..onDown = (d) {
                _scrubbing = false;
                _lastSnap = null;
                _setPointer(d.localPosition, touch: true);
                _snapFeedback();
              }
              ..onStart = (d) {
                _scrubbing = true;
                _setPointer(d.localPosition, touch: true);
              }
              ..onUpdate = (d) {
                _setPointer(d.localPosition, touch: true);
                _snapFeedback();
              }
              ..onEnd = (_) {
                _scrubbing = false;
              }
              ..onCancel = () {
                // Lifted without moving: a tap, keep the tooltip. Otherwise a
                // vertical scroll took the gesture over.
                if (!_touchUp && !_scrubbing) _clear();
              },
          ),
          if (widget.onTimeRangeChange != null)
            _BrushDragRecognizer: GestureRecognizerFactoryWithHandlers<_BrushDragRecognizer>(
              () => _BrushDragRecognizer(supportedDevices: const {PointerDeviceKind.mouse}),
              (r) => r
                ..onStart = (d) {
                  setState(() {
                    _brushStart = d.localPosition.dx.clamp(axes.plot.left, axes.plot.right);
                    _brushEnd = _brushStart;
                  });
                }
                ..onUpdate = (d) {
                  setState(() {
                    _brushEnd = d.localPosition.dx.clamp(axes.plot.left, axes.plot.right);
                    _pointer = d.localPosition;
                  });
                }
                ..onEnd = (_) {
                  _finishBrush();
                }
                ..onCancel = () {
                  setState(() {
                    _brushStart = null;
                    _brushEnd = null;
                  });
                },
            ),
        },
        child: MouseRegion(
          onHover: (e) => _setPointer(e.localPosition, touch: false),
          onExit: (_) {
            if (!_touch && _brushStart == null) _clear();
          },
          child: chart,
        ),
      ),
    );

    chart = TapRegion(
      onTapOutside: (_) {
        if (_touch) _clear();
      },
      child: chart,
    );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      onFocusChange: (focused) {
        if (!focused && _keyIndex != null) setState(() => _keyIndex = null);
        _updateFocusHighlight();
      },
      child: Semantics(
        container: true,
        label: _summary(),
        value: _activeValue(hover),
        increasedValue: hover == null ? null : _activeValue(_hoverAt(hover.index + 1, axes, frame)),
        decreasedValue: hover == null ? null : _activeValue(_hoverAt(hover.index - 1, axes, frame)),
        onIncrease: () => _step(1),
        onDecrease: () => _step(-1),
        child: ExcludeSemantics(child: chart),
      ),
    );
  }

  void _finishBrush() {
    final axes = _axes;
    final a = _brushStart;
    final b = _brushEnd;
    setState(() {
      _brushStart = null;
      _brushEnd = null;
    });
    if (axes == null || a == null || b == null || (a - b).abs() < 4) return;
    final frame = _displayed();
    final from = _xToMs(frame, axes.plot, math.min(a, b));
    final to = _xToMs(frame, axes.plot, math.max(a, b));
    widget.onTimeRangeChange?.call(_time(from), _time(to));
  }

  Widget _buildTooltip(BuildContext context, _TsHover h) {
    final kumo = context.kumo;
    final header = kumo.text(size: KumoTextSize.xs, weight: KumoTypography.semibold);
    final children = <Widget>[];
    final cluster = h.cluster;
    if (cluster != null) {
      final markerColor = cluster.color ?? kumo.colors.textSubtle;
      if (cluster.markers.length == 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: KumoSpace.s1),
            child: Text(_formatTimestamp(cluster.markers.first.time), style: header),
          ),
        );
      }
      for (final (i, m) in cluster.markers.indexed) {
        children.add(
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : KumoSpace.s1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  spacing: KumoSpace.s2,
                  children: [
                    _ChartDot(color: m.color ?? markerColor, size: 12),
                    Flexible(
                      child: Text(
                        m.label ?? 'Reference marker',
                        style: kumo.text(size: KumoTextSize.xs, weight: KumoTypography.medium),
                      ),
                    ),
                    if (cluster.markers.length > 1)
                      Text(
                        _formatTimestamp(m.time),
                        style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle),
                      ),
                  ],
                ),
                if (m.description != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: KumoSpace.s5, top: KumoSpace.s0_5),
                    child: Text(m.description!, style: kumo.text(size: KumoTextSize.xs)),
                  ),
              ],
            ),
          ),
        );
      }
      if (h.rows.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: KumoSpace.s2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: kumo.colors.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: KumoSpace.s2),
                child: Column(mainAxisSize: MainAxisSize.min, children: _rowWidgets(context, h)),
              ),
            ),
          ),
        );
      }
    } else {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: KumoSpace.s1),
          child: Text(_formatTimestamp(_time(h.ms)), style: header),
        ),
      );
      children.addAll(_rowWidgets(context, h));
    }
    if (widget.tooltipFooter != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: KumoSpace.s1),
          child: Text(
            widget.tooltipFooter!,
            style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle),
          ),
        ),
      );
    }
    return _ChartTooltipSurface(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  List<Widget> _rowWidgets(BuildContext context, _TsHover h) => [
    for (final (name, color, v) in h.rows) _ChartTooltipRow(color: color, name: name, value: _formatValue(v)),
    if (h.hiddenCount > 0)
      Padding(
        padding: const EdgeInsets.only(top: KumoSpace.s1),
        child: Text(
          '+${h.hiddenCount} more',
          style: context.kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle),
        ),
      ),
  ];
}

List<double> _linePattern(KumoTimeseriesLineStyle style, double width) => switch (style) {
  KumoTimeseriesLineStyle.solid => const [],
  KumoTimeseriesLineStyle.dashed => [width * 3, width * 2],
  // A near-zero dash with a round cap draws a dot.
  KumoTimeseriesLineStyle.dotted => [0.01, width * 2.5],
};

class _TsBasePainter extends CustomPainter {
  _TsBasePainter({
    required this.frame,
    required this.axes,
    required this.bar,
    required this.gradient,
    required this.thresholds,
    required this.incompleteBefore,
    required this.incompleteAfter,
    required this.gridColor,
    required this.textColor,
    required this.markerColor,
    required this.labelBackground,
    required this.highlighted,
    required this.hoveredCluster,
  });

  final _TsFrame frame;
  final _TsAxes axes;
  final bool bar;
  final bool gradient;
  final List<KumoTimeseriesThreshold> thresholds;
  final double? incompleteBefore;
  final double? incompleteAfter;
  final Color gridColor;
  final Color textColor;
  final Color markerColor;
  final Color labelBackground;
  final String? highlighted;
  final _MarkerCluster? hoveredCluster;

  static const double _lineWidth = 2;

  Rect get plot => axes.plot;

  double _x(double ms) => plot.left + (ms - frame.x0) / (frame.x1 - frame.x0) * plot.width;

  double _y(double v) => plot.bottom - (v - frame.y0) / (frame.y1 - frame.y0) * plot.height;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (final th in thresholds) {
      if (th.endValue == null) continue;
      final a = _y(th.value);
      final b = _y(th.endValue!);
      canvas.drawRect(
        Rect.fromLTRB(plot.left, math.min(a, b), plot.right, math.max(a, b)),
        Paint()..color = th.color.withValues(alpha: 0.1),
      );
    }

    for (final (v, painter) in axes.yTicks) {
      if (v < frame.y0 - 1e-9 || v > frame.y1 + 1e-9) continue;
      final y = _y(v).roundToDouble() + 0.5;
      _drawDashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), grid);
      painter.paint(canvas, Offset(plot.left - 15 - painter.width, y - painter.height / 2));
    }

    for (final (ms, painter) in axes.xTicks) {
      final cx = _x(ms);
      if (cx < plot.left - 1 || cx > plot.right + 1) continue;
      final l = (cx - painter.width / 2).clamp(0.0, math.max(0.0, size.width - painter.width)).toDouble();
      painter.paint(canvas, Offset(l, plot.bottom + 8));
    }

    if (axes.xName case final name?) {
      name.paint(canvas, Offset(plot.center.dx - name.width / 2, plot.bottom + axes.xNameTop));
    }
    if (axes.yName case final name?) {
      canvas.save();
      canvas.translate(axes.yNameCenterX, plot.center.dy);
      canvas.rotate(-math.pi / 2);
      name.paint(canvas, Offset(-name.width / 2, -name.height / 2));
      canvas.restore();
    }

    final paths = _paths();
    canvas.save();
    canvas.clipRect(plot.inflate(_lineWidth));
    for (final sp in paths.series) {
      final s = sp.series;
      var alpha = s.alpha;
      if (highlighted != null && highlighted != s.name) alpha *= 0.2;
      if (alpha <= 0) continue;
      final color = s.color.withValues(alpha: s.color.a * alpha);
      if (bar) {
        final fill = Paint()..color = color;
        for (final r in sp.bars) {
          canvas.drawRect(r, fill);
        }
        continue;
      }
      if (gradient && sp.area.isNotEmpty) {
        final baseline = _y(frame.y0 <= 0 && frame.y1 >= 0 ? 0 : frame.y0);
        final areaPaint = Paint()
          ..shader = ui.Gradient.linear(Offset(0, sp.areaTop), Offset(0, math.max(baseline, sp.areaTop + 1)), [
            s.color.withValues(alpha: 0.4 * alpha),
            s.color.withValues(alpha: 0),
          ]);
        for (final run in sp.area) {
          final path = Path()..addPolygon(run.points, false);
          path
            ..lineTo(run.points.last.dx, baseline)
            ..lineTo(run.points.first.dx, baseline)
            ..close();
          canvas.drawPath(path, areaPaint);
        }
      }
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _lineWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = s.style == KumoTimeseriesLineStyle.dotted ? StrokeCap.round : StrokeCap.butt
        ..color = color;
      for (final run in sp.solid) {
        final path = Path()..addPolygon(run.points, false);
        final pattern = _linePattern(s.style, _lineWidth);
        pattern.isEmpty ? canvas.drawPath(path, stroke) : _drawDashedPath(canvas, path, stroke, pattern);
      }
      for (final run in sp.dashed) {
        final path = Path()..addPolygon(run.points, false);
        _drawDashedPath(canvas, path, stroke, _linePattern(KumoTimeseriesLineStyle.dashed, _lineWidth));
      }
    }
    canvas.restore();

    for (final (i, th) in thresholds.indexed) {
      final line = Paint()
        ..color = th.color
        ..strokeWidth = 1;
      final values = [th.value, ?th.endValue];
      var topY = double.infinity;
      for (final v in values) {
        final y = _y(v).roundToDouble() + 0.5;
        topY = math.min(topY, y);
        _drawDashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), line, dash: 5, gap: 5);
      }
      final label = i < axes.thresholdLabels.length ? axes.thresholdLabels[i] : null;
      if (label != null) label.paint(canvas, Offset(plot.right - label.width, topY - 3 - label.height));
    }

    for (final (i, c) in frame.clusters.indexed) {
      final x = _x(c.ms);
      if (x < plot.left - 1 || x > plot.right + 1) continue;
      final hovered = identical(c, hoveredCluster);
      final color = c.color ?? markerColor;
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = hovered ? 2 : 1
        ..strokeCap = c.style == KumoTimeseriesLineStyle.dotted ? StrokeCap.round : StrokeCap.butt;
      final path = Path()
        ..moveTo(x, plot.bottom)
        ..lineTo(x, plot.top);
      final pattern = _linePattern(c.style, 1.5);
      pattern.isEmpty ? canvas.drawPath(path, line) : _drawDashedPath(canvas, path, line, pattern);

      final label = i < axes.markerLabels.length ? axes.markerLabels[i] : null;
      if (label == null) continue;
      // ECharts' insideEndTop on a vertical line: the label runs bottom to
      // top along the line's left side and ends near the top of the plot.
      canvas.save();
      canvas.translate(x - 3, plot.top + 4);
      canvas.rotate(-math.pi / 2);
      final rect = Rect.fromLTWH(-label.width - 4, -label.height - 2, label.width + 8, label.height + 4);
      final bg = RRect.fromRectAndRadius(rect, const Radius.circular(KumoRadius.md));
      canvas.drawRRect(bg, Paint()..color = labelBackground);
      label.paint(canvas, Offset(-label.width, -label.height));
      canvas.restore();
    }
  }

  _TsPaths _paths() {
    if (frame._paths != null && frame._pathsRect == plot) return frame._paths!;
    final out = <_TsSeriesPaths>[];
    if (bar) {
      final pos = <double, double>{};
      final neg = <double, double>{};
      final widthPx = (frame.slotMs / (frame.x1 - frame.x0) * plot.width * 0.7).clamp(1.0, 48.0);
      for (final s in frame.series) {
        final sp = _TsSeriesPaths(s);
        for (var k = 0; k < s.t.length; k++) {
          final v = s.v[k];
          if (v.isNaN || v == 0) continue;
          final t = s.t[k];
          final base = v >= 0 ? (pos[t] ?? 0) : (neg[t] ?? 0);
          final top = base + v;
          if (v >= 0) {
            pos[t] = top;
          } else {
            neg[t] = top;
          }
          final cx = _x(t);
          sp.bars.add(
            Rect.fromLTRB(cx - widthPx / 2, math.min(_y(base), _y(top)), cx + widthPx / 2, math.max(_y(base), _y(top))),
          );
        }
        out.add(sp);
      }
    } else {
      for (final s in frame.series) {
        final sp = _TsSeriesPaths(s);
        final n = s.t.length;
        if (n > 0) {
          var start = 0;
          var end = n - 1;
          if (incompleteBefore != null) {
            var b = -1;
            for (var k = 0; k < n && s.t[k] <= incompleteBefore!; k++) {
              b = k;
            }
            if (b > 0) {
              sp.dashed.addAll(_runs(s, 0, b));
              start = b;
            }
          }
          if (incompleteAfter != null) {
            var a = n;
            for (var k = n - 1; k >= 0 && s.t[k] >= incompleteAfter!; k--) {
              a = k;
            }
            if (a < n - 1) {
              sp.dashed.addAll(_runs(s, a, n - 1));
              end = math.max(start, a);
            }
          }
          final solid = _runs(s, start, end);
          sp.solid.addAll(solid);
          sp.area.addAll(solid);
          for (final run in solid) {
            for (final p in run.points) {
              if (p.dy < sp.areaTop) sp.areaTop = p.dy;
            }
          }
        }
        out.add(sp);
      }
    }
    frame._pathsRect = plot;
    return frame._paths = _TsPaths(out);
  }

  /// Screen points for indices [from]..[to], split at NaN gaps. Series with
  /// more points than two per pixel keep each pixel column's first, lowest,
  /// highest and last value, so peaks survive at any density.
  List<_TsRun> _runs(_TsSeries s, int from, int to) {
    final runs = <_TsRun>[];
    var current = <Offset>[];
    final decimate = (to - from + 1) > plot.width * 2;
    var col = -1 << 30;
    double first = 0, mn = 0, mx = 0, last = 0, colX = 0;
    void flushColumn() {
      if (col == -1 << 30) return;
      current
        ..add(Offset(colX, first))
        ..add(Offset(colX, mn))
        ..add(Offset(colX, mx))
        ..add(Offset(colX, last));
      col = -1 << 30;
    }

    for (var k = from; k <= to; k++) {
      final v = s.v[k];
      if (v.isNaN) {
        flushColumn();
        if (current.isNotEmpty) runs.add(_TsRun(current));
        current = <Offset>[];
        continue;
      }
      final x = _x(s.t[k]);
      final y = _y(v);
      if (!decimate) {
        current.add(Offset(x, y));
        continue;
      }
      final c = x.floor();
      if (c != col) {
        flushColumn();
        col = c;
        colX = x;
        first = mn = mx = last = y;
      } else {
        mn = math.min(mn, y);
        mx = math.max(mx, y);
        last = y;
      }
    }
    flushColumn();
    if (current.isNotEmpty) runs.add(_TsRun(current));
    return runs;
  }

  @override
  bool shouldRepaint(_TsBasePainter old) =>
      !identical(old.frame, frame) ||
      !identical(old.axes, axes) ||
      old.bar != bar ||
      old.gradient != gradient ||
      !listEquals(old.thresholds, thresholds) ||
      old.incompleteBefore != incompleteBefore ||
      old.incompleteAfter != incompleteAfter ||
      old.gridColor != gridColor ||
      old.textColor != textColor ||
      old.markerColor != markerColor ||
      old.labelBackground != labelBackground ||
      old.highlighted != highlighted ||
      !identical(old.hoveredCluster, hoveredCluster);
}

/// Crosshair, hovered points and the range brush: drawn above the cached
/// series layer so moving the pointer never repaints the series.
class _TsOverlayPainter extends CustomPainter {
  _TsOverlayPainter({
    required this.frame,
    required this.plot,
    required this.bar,
    required this.ms,
    required this.brush,
    required this.lineColor,
    required this.shadowColor,
    required this.ringColor,
  });

  final _TsFrame frame;
  final Rect plot;
  final bool bar;
  final double? ms;
  final (double, double)? brush;
  final Color lineColor;
  final Color shadowColor;
  final Color ringColor;

  double _x(double t) => plot.left + (t - frame.x0) / (frame.x1 - frame.x0) * plot.width;

  double _y(double v) => plot.bottom - (v - frame.y0) / (frame.y1 - frame.y0) * plot.height;

  @override
  void paint(Canvas canvas, Size size) {
    final t = ms;
    if (t != null) {
      final x = _x(t);
      if (bar) {
        final w = (frame.slotMs / (frame.x1 - frame.x0) * plot.width).clamp(2.0, 64.0);
        canvas.drawRect(Rect.fromLTRB(x - w / 2, plot.top, x + w / 2, plot.bottom), Paint()..color = shadowColor);
      } else {
        canvas.drawLine(
          Offset(x.roundToDouble() + 0.5, plot.top),
          Offset(x.roundToDouble() + 0.5, plot.bottom),
          Paint()
            ..color = lineColor
            ..strokeWidth = 1,
        );
        for (final s in frame.series) {
          if (s.alpha < 0.5) continue;
          final i = _nearestIndex(s.t, t);
          if (i < 0 || s.v[i].isNaN) continue;
          final c = Offset(_x(s.t[i]), _y(s.v[i]));
          if (!plot.inflate(4).contains(c)) continue;
          canvas.drawCircle(c, 5, Paint()..color = ringColor);
          canvas.drawCircle(c, 3.5, Paint()..color = s.color);
        }
      }
    }
    if (brush case (final a, final b)) {
      final rect = Rect.fromLTRB(math.min(a, b), plot.top, math.max(a, b), plot.bottom);
      // Kumo's brush: rgba(120,140,180) at 30% fill and 80% border.
      canvas.drawRect(rect, Paint()..color = const Color(0x4D788CB4));
      canvas.drawRect(
        rect.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xCC788CB4),
      );
    }
  }

  @override
  bool shouldRepaint(_TsOverlayPainter old) =>
      !identical(old.frame, frame) ||
      old.plot != plot ||
      old.bar != bar ||
      old.ms != ms ||
      old.brush != brush ||
      old.lineColor != lineColor ||
      old.shadowColor != shadowColor ||
      old.ringColor != ringColor;
}
