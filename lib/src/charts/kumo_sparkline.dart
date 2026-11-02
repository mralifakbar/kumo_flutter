part of 'kumo_charts.dart';

/// A compact trend line for table cells, stat tiles and list rows: no axes,
/// no tooltip, just the shape of the data.
///
/// Kumo has no sparkline component; this follows its chart styling (chart
/// palette, 40% to clear area fill, `base` ring around dots).
///
/// ```dart
/// KumoSparkline(values: const [12, 18, 15, 22, 30, 27, 34], semanticLabel: 'Requests, last 7 days')
/// KumoSparkline(values: const [3, 2, 4, 1, 0, 2], area: true, showEndDot: true, showMinMax: true)
/// ```
///
/// Values are spaced evenly; `double.nan` leaves a gap. The vertical range
/// is the data's own minimum to maximum, so small changes stay visible.
/// When the values change, the line morphs from where it is (instantly
/// under reduced motion).
class KumoSparkline extends StatefulWidget {
  const KumoSparkline({
    super.key,
    required this.values,
    this.color,
    this.area = false,
    this.showEndDot = false,
    this.showMinMax = false,
    this.width,
    this.height = 32,
    this.strokeWidth = 1.5,
    this.loading = false,
    this.semanticLabel,
    this.valueFormat,
  });

  final List<double> values;

  /// Defaults to the first categorical chart color.
  final Color? color;

  /// Fills under the line with a fade to clear.
  final bool area;

  /// Marks the latest value with a dot.
  final bool showEndDot;

  /// Marks the lowest and highest values with small dots.
  final bool showMinMax;

  /// Defaults to the available width, or 120 when unbounded.
  final double? width;
  final double height;
  final double strokeWidth;

  /// Shows a static skeleton line. A sparkline is too small for a moving
  /// shimmer, so it never animates.
  final bool loading;

  /// What the trend measures, read before the generated summary.
  final String? semanticLabel;

  /// Formats values in the summary. Defaults to grouped digits.
  final String Function(double value)? valueFormat;

  @override
  State<KumoSparkline> createState() => _KumoSparklineState();
}

class _KumoSparklineState extends State<KumoSparkline> with SingleTickerProviderStateMixin {
  late final AnimationController _morph;
  late Float64List _target;
  Float64List? _from;

  @override
  void initState() {
    super.initState();
    _morph = AnimationController(vsync: this, duration: KumoDurations.slow, value: 1)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && _from != null) setState(() => _from = null);
      });
    _target = Float64List.fromList(widget.values);
  }

  @override
  void didUpdateWidget(KumoSparkline old) {
    super.didUpdateWidget(old);
    if (listEquals(old.values, widget.values)) return;
    final next = Float64List.fromList(widget.values);
    if (KumoMotion.reduceMotion(context) || _target.isEmpty || next.isEmpty) {
      _from = null;
      _target = next;
      _morph.value = 1;
      return;
    }
    _from = _current();
    _target = next;
    _morph.forward(from: 0);
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  /// The values on screen, resampled to the target's length by relative
  /// position so a series that gains points still morphs smoothly.
  Float64List _current() {
    final from = _from;
    if (from == null) return _target;
    final t = KumoCurves.standard.transform(_morph.value);
    final n = _target.length;
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      final pos = n == 1 ? 0.0 : i / (n - 1) * (from.length - 1);
      final lo = pos.floor().clamp(0, from.length - 1);
      final hi = pos.ceil().clamp(0, from.length - 1);
      final start = _lerp(from[lo], from[hi], pos - lo);
      final end = _target[i];
      out[i] = end.isNaN || start.isNaN ? end : _lerp(start, end, t);
    }
    return out;
  }

  String _summary() {
    final format = widget.valueFormat ?? (double v) => _formatChartNumber(v);
    final values = widget.values.where((v) => !v.isNaN).toList();
    final lead = widget.semanticLabel == null ? 'Trend' : widget.semanticLabel!;
    if (widget.loading) return '$lead, loading';
    if (values.isEmpty) return '$lead, no data';
    final mn = values.reduce(math.min);
    final mx = values.reduce(math.max);
    return '$lead, ${values.length} points, from ${format(values.first)} to ${format(values.last)}, '
        'low ${format(mn)}, high ${format(mx)}';
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final palette = KumoChartColors.forBrightness(kumo.brightness);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0);
        final Widget paint;
        if (widget.loading) {
          paint = CustomPaint(
            size: Size(width, widget.height),
            painter: _SparklineSkeletonPainter(
              color: palette.semantic(KumoChartSemanticColor.skeleton),
              dark: kumo.isDark,
            ),
          );
        } else {
          paint = AnimatedBuilder(
            animation: _morph,
            builder: (context, _) => CustomPaint(
              size: Size(width, widget.height),
              painter: _SparklinePainter(
                values: _current(),
                color: widget.color ?? palette.categorical(0),
                area: widget.area,
                endDot: widget.showEndDot,
                minMax: widget.showMinMax,
                strokeWidth: widget.strokeWidth,
                ringColor: kumo.colors.base,
                emptyColor: kumo.colors.textSubtle.withValues(alpha: 0.35),
              ),
            ),
          );
        }
        return Semantics(
          container: true,
          image: true,
          label: _summary(),
          child: SizedBox(width: width, height: widget.height, child: paint),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.area,
    required this.endDot,
    required this.minMax,
    required this.strokeWidth,
    required this.ringColor,
    required this.emptyColor,
  });

  final Float64List values;
  final Color color;
  final bool area;
  final bool endDot;
  final bool minMax;
  final double strokeWidth;
  final Color ringColor;
  final Color emptyColor;

  Path? _line;
  Size? _lineSize;

  @override
  void paint(Canvas canvas, Size size) {
    var mn = double.infinity;
    var mx = -double.infinity;
    var minI = -1;
    var maxI = -1;
    var lastI = -1;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v.isNaN) continue;
      if (v < mn) {
        mn = v;
        minI = i;
      }
      if (v > mx) {
        mx = v;
        maxI = i;
      }
      lastI = i;
    }
    if (lastI < 0) {
      _drawDashedLine(
        canvas,
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = emptyColor
          ..strokeWidth = 1,
        dash: 3,
        gap: 3,
      );
      return;
    }
    // Inset by the dot radius so end and extreme dots are never clipped.
    final inset = (endDot || minMax) ? 4.0 : strokeWidth;
    final rect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    final n = values.length;
    double x(int i) => n == 1 ? rect.center.dx : rect.left + i / (n - 1) * rect.width;
    double y(double v) => mx == mn ? rect.center.dy : rect.bottom - (v - mn) / (mx - mn) * rect.height;

    if (_line == null || _lineSize != size) {
      final path = Path();
      var pen = false;
      for (var i = 0; i < n; i++) {
        final v = values[i];
        if (v.isNaN) {
          pen = false;
          continue;
        }
        pen ? path.lineTo(x(i), y(v)) : path.moveTo(x(i), y(v));
        pen = true;
      }
      _line = path;
      _lineSize = size;
    }

    if (area) {
      final fill = Path();
      var runStart = -1;
      void closeRun(int end) {
        if (runStart < 0) return;
        fill.moveTo(x(runStart), rect.bottom);
        for (var i = runStart; i <= end; i++) {
          fill.lineTo(x(i), y(values[i]));
        }
        fill
          ..lineTo(x(end), rect.bottom)
          ..close();
        runStart = -1;
      }

      for (var i = 0; i < n; i++) {
        if (values[i].isNaN) {
          closeRun(i - 1);
        } else if (runStart < 0) {
          runStart = i;
        }
      }
      closeRun(n - 1);
      canvas.drawPath(
        fill,
        Paint()
          ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
            color.withValues(alpha: 0.4 * color.a),
            color.withValues(alpha: 0),
          ]),
      );
    }

    canvas.drawPath(
      _line!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    void dot(int i, double r) {
      final c = Offset(x(i), y(values[i]));
      canvas.drawCircle(c, r + 1.5, Paint()..color = ringColor);
      canvas.drawCircle(c, r, Paint()..color = color);
    }

    if (minMax && mx != mn) {
      dot(minI, 1.75);
      dot(maxI, 1.75);
    }
    if (endDot) dot(lastI, 2.5);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      !identical(old.values, values) ||
      old.color != color ||
      old.area != area ||
      old.endDot != endDot ||
      old.minMax != minMax ||
      old.strokeWidth != strokeWidth ||
      old.ringColor != ringColor ||
      old.emptyColor != emptyColor;
}

class _SparklineSkeletonPainter extends CustomPainter {
  _SparklineSkeletonPainter({required this.color, required this.dark});

  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const samples = 40;
    final mid = size.height / 2;
    final amp = size.height * 0.3;
    for (var i = 0; i <= samples; i++) {
      final px = i / samples * size.width;
      final py = mid - _chartLoaderWave(i / samples * 2 * math.pi) * amp;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: dark ? 0.5 : 0.8),
    );
  }

  @override
  bool shouldRepaint(_SparklineSkeletonPainter old) => old.color != color || old.dark != dark;
}
