part of 'kumo_charts.dart';

/// Formats a number with thousands separators and up to [maxFractionDigits]
/// decimals, trailing zeros dropped: `1234.5` is `1,234.5`.
String _formatChartNumber(num value, {int maxFractionDigits = 3}) {
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value > 0 ? 'Infinity' : '-Infinity';
  final negative = value < 0;
  var s = value.abs().toStringAsFixed(maxFractionDigits);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  final dot = s.indexOf('.');
  final intPart = dot < 0 ? s : s.substring(0, dot);
  final frac = dot < 0 ? '' : s.substring(dot);
  final grouped = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) grouped.write(',');
    grouped.write(intPart[i]);
  }
  final out = '$grouped$frac';
  return negative && out != '0' ? '-$out' : out;
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Kumo's default tooltip timestamp: `Mar 4, 14:05:09` (24-hour clock).
String _formatChartTimestamp(DateTime d, KumoStrings s) =>
    '${s.monthNamesShort[d.month - 1]} ${d.day}, ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

/// A shorter timestamp for screen reader summaries: `Mar 4, 14:05`.
String _formatChartShortTime(DateTime d, KumoStrings s) =>
    '${s.monthNamesShort[d.month - 1]} ${d.day}, ${_two(d.hour)}:${_two(d.minute)}';

/// Axis text: `text-kumo-subtle` at 12px with tabular figures, so tick
/// labels line up and do not shift width as values change.
TextStyle _axisTextStyle(KumoThemeData kumo, {FontWeight weight = KumoTypography.normal}) => kumo
    .text(size: KumoTextSize.xs, color: KumoColor.textSubtle, weight: weight, height: 1.2)
    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

TextPainter _layoutText(String text, TextStyle style, TextScaler scaler, {double maxWidth = double.infinity}) {
  return TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
    ellipsis: maxWidth.isFinite ? '…' : null,
  )..layout(maxWidth: maxWidth);
}

/// Strokes [path] with a dash pattern of alternating on/off lengths.
void _drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> pattern) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    var i = 0;
    var draw = true;
    while (distance < metric.length) {
      final len = pattern[i % pattern.length];
      if (draw) canvas.drawPath(metric.extractPath(distance, math.min(distance + len, metric.length)), paint);
      distance += len;
      draw = !draw;
      i++;
    }
  }
}

/// A straight dashed line without path metrics, for gridlines.
void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 4, double gap = 4}) {
  final total = (b - a).distance;
  if (total <= 0) return;
  final dir = (b - a) / total;
  var d = 0.0;
  while (d < total) {
    final end = math.min(d + dash, total);
    canvas.drawLine(a + dir * d, a + dir * end, paint);
    d += dash + gap;
  }
}

/// The floating panel of chart tooltips: `bg-kumo-base rounded-lg p-2
/// shadow-md outline-kumo-line`, 150 to 320px wide.
class _ChartTooltipSurface extends StatelessWidget {
  const _ChartTooltipSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kumo.colors.base,
          borderRadius: BorderRadius.circular(KumoRadius.lg),
          border: KumoRing.border(kumo.colors.line),
          boxShadow: KumoShadow.md.boxShadows,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KumoSpace.s2),
          child: DefaultTextStyle(
            style: kumo.text(size: KumoTextSize.xs).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            child: IntrinsicWidth(child: child),
          ),
        ),
      ),
    );
  }
}

/// One `dot name ... value` row of a tooltip.
class _ChartTooltipRow extends StatelessWidget {
  const _ChartTooltipRow({required this.color, required this.name, required this.value});

  final Color color;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KumoSpace.s0_5),
      child: Row(
        children: [
          _ChartDot(color: color, size: 12),
          const SizedBox(width: KumoSpace.s2),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kumo.text(size: KumoTextSize.xs, weight: KumoTypography.medium),
            ),
          ),
          const SizedBox(width: KumoSpace.s4),
          Text(
            value,
            style: kumo
                .text(size: KumoTextSize.xs, weight: KumoTypography.semibold)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _ChartDot extends StatelessWidget {
  const _ChartDot({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );
}

/// Places a tooltip beside an anchor point: to the right and top-aligned
/// with it by default (Kumo's `side="right" align="start"`, 12px away),
/// flipping to the left and shifting vertically to stay inside the chart
/// with 8px of padding.
class _ChartTooltipLayout extends SingleChildLayoutDelegate {
  _ChartTooltipLayout({required this.anchor});

  final Offset anchor;
  static const double gap = 12;
  static const double padding = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(Size(math.max(0, constraints.maxWidth - padding * 2), double.infinity));

  @override
  Offset getPositionForChild(Size size, Size child) {
    var x = anchor.dx + gap;
    if (x + child.width > size.width - padding) {
      final left = anchor.dx - gap - child.width;
      x = left >= padding ? left : size.width - padding - child.width;
    }
    x = x.clamp(padding, math.max(padding, size.width - padding - child.width));
    var y = anchor.dy;
    if (y + child.height > size.height - padding) y = size.height - padding - child.height;
    y = math.max(y, child.height > size.height ? 0 : padding);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_ChartTooltipLayout old) => old.anchor != anchor;
}

/// Centered empty or error message inside a chart's frame. Status is shown
/// with an icon and text, never color alone.
class _ChartMessage extends StatelessWidget {
  const _ChartMessage({required this.icon, required this.title, this.description, this.onRetry, this.danger = false});

  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onRetry;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s6, vertical: KumoSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1,
          children: [
            KumoIcon(icon, size: 20, color: danger ? KumoColor.textDanger : KumoColor.textSubtle),
            const SizedBox(height: KumoSpace.s1),
            KumoText(title, bold: true, textAlign: TextAlign.center),
            if (description != null)
              KumoText(description!, variant: KumoTextVariant.secondary, size: KumoTextSize.sm, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: KumoSpace.s2),
              KumoButton(
                label: context.kumoStrings.retry,
                icon: KumoIcons.arrowsClockwise,
                size: KumoButtonSize.sm,
                onPress: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _SkeletonShape { line, bar, sankey }

double _chartLoaderWave(double theta) =>
    0.45 * math.sin(3 * theta) + 0.3 * math.sin(5 * theta + 0.9) + 0.25 * math.sin(7 * theta + 2.1);

/// Kumo's chart loading skeleton: a static wave (or bars with the same
/// silhouette) in the skeleton color, with a sheen that sweeps across it
/// every 1.8s while loading. Under reduced motion the sheen stays still in
/// the middle, as Kumo's CSS does, and nothing repeats.
class _ChartSkeleton extends StatefulWidget {
  const _ChartSkeleton({required this.shape, required this.semanticLabel});

  final _SkeletonShape shape;
  final String semanticLabel;

  @override
  State<_ChartSkeleton> createState() => _ChartSkeletonState();
}

class _ChartSkeletonState extends State<_ChartSkeleton> with SingleTickerProviderStateMixin {
  AnimationController? _shimmer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (KumoMotion.reduceMotion(context)) {
      _shimmer?.dispose();
      _shimmer = null;
    } else {
      // Repeats only while this skeleton is mounted, which is only while the
      // chart is loading; TickerMode pauses it off screen.
      _shimmer ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    }
  }

  @override
  void dispose() {
    _shimmer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final palette = KumoChartColors.forBrightness(kumo.brightness);
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      container: true,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartSkeletonPainter(
          shape: widget.shape,
          color: palette.semantic(KumoChartSemanticColor.skeleton),
          dark: kumo.isDark,
          shimmer: _shimmer,
        ),
      ),
    );
  }
}

class _ChartSkeletonPainter extends CustomPainter {
  _ChartSkeletonPainter({required this.shape, required this.color, required this.dark, this.shimmer})
      : super(repaint: shimmer);

  final _SkeletonShape shape;
  final Color color;
  final bool dark;
  final Animation<double>? shimmer;

  static const double _viewWidth = 400;
  static const Cubic _easeInOut = Cubic(0.42, 0, 0.58, 1);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final h = size.height;
    final sx = size.width / _viewWidth;
    final clip = Path();

    switch (shape) {
      case _SkeletonShape.bar:
        const bars = 24;
        const slot = _viewWidth / bars;
        const barW = slot * (1 - 0.35);
        final minH = h * 0.15;
        final maxH = h * 0.85;
        final fill = Paint()..color = color.withValues(alpha: dark ? 0.12 : 0.16);
        for (var i = 0; i < bars; i++) {
          final theta = (i + 0.5) / bars * 2 * math.pi;
          final norm = (_chartLoaderWave(theta) + 1) / 2;
          final barH = minH + norm * (maxH - minH);
          final rect = Rect.fromLTWH((i * slot + (slot - barW) / 2) * sx, h - barH, barW * sx, barH);
          canvas.drawRect(rect, fill);
          clip.addRect(rect);
        }
      case _SkeletonShape.line:
        final mid = h / 2;
        final amp = math.min(h * 0.18, 40.0);
        final line = Path();
        const samples = 80;
        for (var i = 0; i <= samples; i++) {
          final x = i / samples * _viewWidth;
          final y = mid - _chartLoaderWave(x / _viewWidth * 2 * math.pi) * amp;
          i == 0 ? line.moveTo(x * sx, y) : line.lineTo(x * sx, y);
        }
        final area = Path.from(line)
          ..lineTo(size.width, h)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = ui.Gradient.linear(Offset(0, mid - amp), Offset(0, h), [
              color.withValues(alpha: dark ? 0.07 : 0.1),
              color.withValues(alpha: 0),
            ]),
        );
        canvas.drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = color.withValues(alpha: dark ? 0.36 : 0.6),
        );
        clip.addPath(area, Offset.zero);
      case _SkeletonShape.sankey:
        final fill = Paint()..color = color.withValues(alpha: dark ? 0.3 : 0.45);
        final link = Paint()..color = color.withValues(alpha: dark ? 0.1 : 0.16);
        const nodeW = 8.0;
        final left = [0.0, 0.42, 0.7, 1.0];
        final right = [0.0, 0.55, 1.0];
        Rect node(double x, double from, double to) =>
            Rect.fromLTRB(x, from * h + (from == 0 ? 0 : 5), x + nodeW, to * h - (to == 1 ? 0 : 5));
        final lefts = [for (var i = 0; i < left.length - 1; i++) node(0, left[i], left[i + 1])];
        final rights = [for (var i = 0; i < right.length - 1; i++) node(size.width - nodeW, right[i], right[i + 1])];
        for (var i = 0; i < lefts.length; i++) {
          final a = lefts[i];
          final b = rights[i % rights.length];
          final band = _sankeyBand(a.right, a.top, a.bottom, b.left, b.top + (i == 2 ? b.height / 2 : 0),
              b.top + (i == 2 ? b.height : b.height / 2));
          canvas.drawPath(band, link);
          clip.addPath(band, Offset.zero);
        }
        for (final r in [...lefts, ...rights]) {
          canvas.drawRect(r, fill);
          clip.addRect(r);
        }
    }

    final sheenOpacity = dark ? 0.16 : 0.24;
    final sheen = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [
        color.withValues(alpha: 0),
        color.withValues(alpha: sheenOpacity),
        color.withValues(alpha: 0),
      ], const [
        0,
        0.5,
        1
      ]);
    final t = shimmer?.value;
    // CSS translates the sheen from -100% to 100% of its width with ease-in-out.
    final dx = t == null ? 0.0 : (-1 + 2 * _easeInOut.transform(t)) * size.width;
    canvas.save();
    canvas.clipPath(clip);
    canvas.translate(dx, 0);
    canvas.drawRect(Offset.zero & size, sheen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChartSkeletonPainter old) =>
      old.shape != shape || old.color != color || old.dark != dark || old.shimmer != shimmer;
}

/// The filled band of a Sankey link: two horizontal-tangent cubic curves
/// (ECharts' curveness 0.5) between a source and a target edge.
Path _sankeyBand(double x0, double y0Top, double y0Bottom, double x1, double y1Top, double y1Bottom) {
  final cx = (x0 + x1) / 2;
  return Path()
    ..moveTo(x0, y0Top)
    ..cubicTo(cx, y0Top, cx, y1Top, x1, y1Top)
    ..lineTo(x1, y1Bottom)
    ..cubicTo(cx, y1Bottom, cx, y0Bottom, x0, y0Bottom)
    ..close();
}

/// A fixed-width skeleton bar: the public [KumoSkeletonLine] (same colors
/// and corner radius as Kumo's `SkeletonLine`), static like the rest of a
/// chart's loading state.
Widget _skeletonBar(double width, double height) =>
    SizedBox(width: width, child: KumoSkeletonLine(widthFactor: 1, height: height));

double _lerp(double a, double b, double t) => a + (b - a) * t;
