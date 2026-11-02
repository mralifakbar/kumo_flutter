part of 'kumo_charts.dart';

/// One shape of a [KumoMapChart], in any coordinate space shared by all
/// regions of the map (the chart scales them together to fit).
///
/// The package ships no geometry. Build regions from your own data, for
/// example a public domain Natural Earth GeoJSON file you bundle with your
/// app, with [KumoMapRegion.fromPolygons], or from SVG paths you convert to
/// a [Path].
///
/// ```dart
/// final region = KumoMapRegion(
///   id: 'weur',
///   name: 'Western Europe',
///   path: Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10)),
/// );
/// ```
@immutable
class KumoMapRegion {
  const KumoMapRegion({required this.id, required this.path, this.name});

  /// Builds a region from longitude/latitude rings, the coordinate arrays of
  /// a GeoJSON `Polygon` or `MultiPolygon` (`Offset(longitude, latitude)`),
  /// with an equirectangular projection (north up). Holes are cut with the
  /// even-odd rule.
  ///
  /// ```dart
  /// KumoMapRegion.fromPolygons(id: 'box', rings: const [
  ///   [Offset(-10, 50), Offset(10, 50), Offset(10, 40), Offset(-10, 40)],
  /// ])
  /// ```
  factory KumoMapRegion.fromPolygons({required String id, required List<List<Offset>> rings, String? name}) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final ring in rings) {
      if (ring.length < 3) continue;
      path.addPolygon([for (final p in ring) Offset(p.dx, -p.dy)], true);
    }
    return KumoMapRegion(id: id, path: path, name: name);
  }

  /// Key into [KumoMapChart.values].
  final String id;
  final Path path;

  /// Shown in the tooltip and read by screen readers. Defaults to [id].
  final String? name;

  String get label => name ?? id;
}

/// A choropleth map: Kumo's `ChoroplethMap`, drawn over region shapes you
/// provide. Each region is filled from a continuous color scale by its
/// value; regions without a value take the neutral no-data fill.
///
/// ```dart
/// KumoMapChart(
///   regions: regions,
///   values: const {'weur': 1200, 'enam': 860},
///   showLegend: true,
///   valueFormat: (v) => '${v.round()} req/s',
/// )
/// ```
///
/// Hover or tap a region to highlight it (the others fade, as in Kumo) and
/// see its value. With keyboard focus, arrow keys move between regions with
/// data and Enter activates [onRegionPress]. Value changes cross-fade the
/// fills (instantly under reduced motion).
class KumoMapChart extends StatefulWidget {
  const KumoMapChart({
    super.key,
    required this.regions,
    required this.values,
    this.colorRange,
    this.min,
    this.max,
    this.noDataColor,
    this.showLegend = false,
    this.showTooltip = true,
    this.valueFormat,
    this.tooltipBuilder,
    this.onRegionHover,
    this.onRegionPress,
    this.height,
    this.aspectRatio,
    this.bounds,
    this.loading = false,
    this.error,
    this.onRetry,
    this.emptyMessage = 'No data for these regions',
    this.emptyDescription = 'Values appear once traffic reaches a region.',
    this.semanticLabel,
  });

  final List<KumoMapRegion> regions;

  /// Value per region id.
  final Map<String, double> values;

  /// Color stops from low to high, interpolated in OKLCH. Defaults to
  /// [KumoChartMapColors.scale].
  final List<Color>? colorRange;

  /// Bottom of the scale. Defaults to the smallest value.
  final double? min;

  /// Top of the scale. Defaults to the largest value.
  final double? max;

  /// Fill for regions without a value. Defaults to [KumoChartMapColors.area].
  final Color? noDataColor;

  /// Shows a `Low` to `High` gradient legend under the map.
  final bool showLegend;
  final bool showTooltip;

  /// Formats values for the tooltip, legend ends and screen readers.
  final String Function(double value)? valueFormat;

  /// Replaces the default tooltip content (Kumo's `tooltipFormatter`).
  final Widget Function(BuildContext context, KumoMapRegion region, double value)? tooltipBuilder;

  /// Called as the pointer enters a region with data (or null on leaving).
  final ValueChanged<KumoMapRegion?>? onRegionHover;

  /// Called when a region with data is pressed.
  final ValueChanged<KumoMapRegion>? onRegionPress;

  /// Fixed height. Without it the height follows [aspectRatio], or the
  /// aspect of the shapes' bounds.
  final double? height;

  /// Width over height, used when [height] is null.
  final double? aspectRatio;

  /// The area of the coordinate space to show. Defaults to the bounds of
  /// all regions.
  final Rect? bounds;
  final bool loading;

  /// Shows this message with a warning icon in place of the map.
  final String? error;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final String? emptyDescription;

  /// Leads the screen reader summary.
  final String? semanticLabel;

  @override
  State<KumoMapChart> createState() => _KumoMapChartState();
}

class _KumoMapChartState extends State<KumoMapChart> with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final FocusNode _focusNode;
  Map<String, Color>? _fromColors;
  Map<String, Color>? _lastColors;
  String? _active;
  Offset? _pointer;
  bool _touch = false;
  bool _focusHighlight = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: KumoDurations.slow, value: 1);
    _focusNode = FocusNode(debugLabel: 'KumoMapChart');
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void didUpdateWidget(KumoMapChart old) {
    super.didUpdateWidget(old);
    if (!mapEquals(old.values, widget.values) || !listEquals(old.colorRange, widget.colorRange)) {
      if (_lastColors != null && !KumoMotion.reduceMotion(context)) {
        _fromColors = _lastColors;
        _fade.forward(from: 0);
      } else {
        _fromColors = null;
      }
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _fade.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode _) => _updateFocusHighlight();

  void _updateFocusHighlight() {
    final v = _focusNode.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (v != _focusHighlight && mounted) setState(() => _focusHighlight = v);
  }

  String _format(double v) => widget.valueFormat?.call(v) ?? _formatChartNumber(v);

  (double, double) _range() {
    final vs = widget.values.values.where((v) => v.isFinite);
    final lo = widget.min ?? (vs.isEmpty ? 0 : vs.reduce(math.min));
    var hi = widget.max ?? (vs.isEmpty ? 1 : vs.reduce(math.max));
    if (hi <= lo) hi = lo + 1;
    return (lo, hi);
  }

  Color _scaleColor(List<Color> stops, double t) {
    if (stops.length == 1) return stops.first;
    final pos = t.clamp(0.0, 1.0) * (stops.length - 1);
    final i = pos.floor().clamp(0, stops.length - 2);
    return KumoColorUtils.mix(stops[i], stops[i + 1], pos - i);
  }

  Map<String, Color> _targetColors(KumoChartMapColors palette) {
    final stops = widget.colorRange ?? palette.scale;
    final (lo, hi) = _range();
    return {
      for (final e in widget.values.entries)
        if (e.value.isFinite) e.key: _scaleColor(stops, (e.value - lo) / (hi - lo)),
    };
  }

  Rect _bounds() {
    if (widget.bounds != null) return widget.bounds!;
    Rect? r;
    for (final region in widget.regions) {
      final b = region.path.getBounds();
      r = r == null ? b : r.expandToInclude(b);
    }
    return r == null || r.isEmpty ? const Rect.fromLTWH(0, 0, 1, 1) : r;
  }

  Matrix4 _transform(Rect bounds, Size size) {
    final s = math.min(size.width / bounds.width, size.height / bounds.height);
    final dx = (size.width - bounds.width * s) / 2 - bounds.left * s;
    final dy = (size.height - bounds.height * s) / 2 - bounds.top * s;
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  KumoMapRegion? _hit(Offset p, Matrix4 m) {
    final inverse = Matrix4.tryInvert(m);
    if (inverse == null) return null;
    final local = MatrixUtils.transformPoint(inverse, p);
    for (final r in widget.regions.reversed) {
      if (widget.values.containsKey(r.id) && r.path.contains(local)) return r;
    }
    return null;
  }

  void _setActive(String? id, {Offset? pointer, bool? touch}) {
    if (id == _active && pointer == _pointer) return;
    final changed = id != _active;
    setState(() {
      _active = id;
      _pointer = pointer;
      if (touch != null) _touch = touch;
    });
    if (changed) {
      widget.onRegionHover?.call(id == null ? null : widget.regions.firstWhere((r) => r.id == id));
    }
  }

  List<KumoMapRegion> get _withData => widget.regions.where((r) => widget.values.containsKey(r.id)).toList();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final list = _withData;
    if (list.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final i = list.indexWhere((r) => r.id == _active);
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.arrowDown) {
      _setActive(list[i < 0 ? 0 : (i + 1) % list.length].id);
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowUp) {
      _setActive(list[i < 0 ? list.length - 1 : (i - 1 + list.length) % list.length].id);
    } else if ((key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) && i >= 0) {
      widget.onRegionPress?.call(list[i]);
    } else if (key == LogicalKeyboardKey.escape && _active != null) {
      _setActive(null);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _summary() {
    final parts = <String>[];
    if (widget.semanticLabel != null) parts.add(widget.semanticLabel!);
    final list = _withData..sort((a, b) => widget.values[b.id]!.compareTo(widget.values[a.id]!));
    parts.add('Map, ${widget.regions.length} regions, ${list.length} with data');
    for (final r in list) {
      parts.add('${r.label}: ${_format(widget.values[r.id]!)}');
    }
    return '${parts.join('. ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final palette = KumoChartColors.forBrightness(kumo.brightness).map;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
      final bounds = _bounds();
      final aspect = widget.aspectRatio ?? (bounds.height == 0 ? 2 : bounds.width / bounds.height);
      final height = widget.height ?? (width / aspect).clamp(120.0, 640.0);
      final size = Size(width, height);
      Widget body;
      if (widget.error != null) {
        body = Semantics(
          liveRegion: true,
          child: _ChartMessage(icon: KumoIcons.warningCircle, title: widget.error!, onRetry: widget.onRetry, danger: true),
        );
        body = SizedBox(width: width, height: math.max(height, 160), child: body);
      } else {
        body = AnimatedBuilder(animation: _fade, builder: (context, _) => _buildMap(context, size, bounds, palette));
      }
      if (!widget.showLegend || widget.loading || widget.error != null || widget.values.isEmpty) return body;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [body, const SizedBox(height: KumoSpace.s2), _buildLegend(context, palette)],
      );
    });
  }

  Widget _buildLegend(BuildContext context, KumoChartMapColors palette) {
    final kumo = context.kumo;
    final stops = widget.colorRange ?? palette.scale;
    final (lo, hi) = _range();
    final style = kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle).copyWith(fontSize: 11);
    return Semantics(
      label: 'Color scale from ${_format(lo)} to ${_format(hi)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: KumoSpace.s2,
        children: [
          Text('Low', style: style),
          SizedBox(
            width: 120,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KumoRadius.xs),
                gradient: LinearGradient(colors: [
                  for (var i = 0; i <= 8; i++) _scaleColor(stops, i / 8),
                ]),
              ),
            ),
          ),
          Text('High', style: style),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context, Size size, Rect bounds, KumoChartMapColors palette) {
    final kumo = context.kumo;
    final skeleton = KumoChartColors.forBrightness(kumo.brightness).semantic(KumoChartSemanticColor.skeleton);
    final target = _targetColors(palette);
    Map<String, Color> colors = target;
    final from = _fromColors;
    if (from != null && _fade.value < 1) {
      final t = KumoCurves.standard.transform(_fade.value);
      final noData = widget.noDataColor ?? palette.area;
      colors = {
        for (final id in {...from.keys, ...target.keys})
          id: Color.lerp(from[id] ?? noData, target[id] ?? noData, t)!,
      };
    } else {
      _lastColors = target;
    }
    final matrix = _transform(bounds, size);

    Widget map = CustomPaint(
      size: size,
      painter: _MapPainter(
        regions: widget.regions,
        colors: widget.loading ? const {} : colors,
        noData: widget.loading ? skeleton.withValues(alpha: kumo.isDark ? 0.35 : 0.5) : (widget.noDataColor ?? palette.area),
        matrix: matrix,
        active: widget.loading ? null : _active,
      ),
    );

    if (widget.loading) {
      return Semantics(
        label: widget.semanticLabel == null ? 'Loading map' : 'Loading map: ${widget.semanticLabel}',
        liveRegion: true,
        container: true,
        child: SizedBox.fromSize(size: size, child: map),
      );
    }
    if (widget.values.isEmpty) {
      return SizedBox.fromSize(
        size: Size(size.width, math.max(size.height, 160)),
        child: Stack(children: [
          Positioned.fill(child: Opacity(opacity: 0.6, child: map)),
          Positioned.fill(
            child: _ChartMessage(icon: KumoIcons.mapTrifold, title: widget.emptyMessage, description: widget.emptyDescription),
          ),
        ]),
      );
    }

    final active = _active == null ? null : widget.regions.where((r) => r.id == _active).firstOrNull;
    Widget? tooltip;
    if (widget.showTooltip && active != null) {
      final value = widget.values[active.id]!;
      final custom = widget.tooltipBuilder?.call(context, active, value);
      tooltip = _ChartTooltipSurface(
        child: custom ??
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s0_5,
              children: [
                Text(active.label, style: kumo.text(size: KumoTextSize.sm, weight: KumoTypography.semibold)),
                Text(
                  _format(value),
                  style: kumo
                      .text(size: KumoTextSize.sm, color: KumoColor.textSubtle)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
      );
    }
    Offset anchor = Offset.zero;
    if (_pointer != null) {
      anchor = _touch ? Offset(_pointer!.dx + 8, math.max(0, _pointer!.dy - 56)) : _pointer!;
    } else if (active != null) {
      final b = MatrixUtils.transformRect(matrix, active.path.getBounds());
      anchor = b.topRight;
    }

    map = Stack(
      clipBehavior: Clip.none,
      children: [
        map,
        if (tooltip != null)
          Positioned.fill(
            child: IgnorePointer(child: CustomSingleChildLayout(delegate: _ChartTooltipLayout(anchor: anchor), child: tooltip)),
          ),
      ],
    );
    map = KumoFocusRing(visible: _focusHighlight, borderRadius: BorderRadius.circular(KumoRadius.lg), child: map);
    map = MouseRegion(
      cursor: active != null && widget.onRegionPress != null ? SystemMouseCursors.click : MouseCursor.defer,
      onHover: (e) => _setActive(_hit(e.localPosition, matrix)?.id, pointer: e.localPosition, touch: false),
      onExit: (_) {
        if (!_touch) _setActive(null);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          if (d.kind == PointerDeviceKind.mouse) return;
          _setActive(_hit(d.localPosition, matrix)?.id, pointer: d.localPosition, touch: true);
        },
        onTapUp: (d) {
          final r = _hit(d.localPosition, matrix);
          if (r != null) widget.onRegionPress?.call(r);
        },
        child: map,
      ),
    );
    map = TapRegion(
      onTapOutside: (_) {
        if (_touch && _active != null) _setActive(null);
      },
      child: map,
    );
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      onFocusChange: (_) => _updateFocusHighlight(),
      child: Semantics(
        container: true,
        label: _summary(),
        value: active == null ? null : '${active.label}, ${_format(widget.values[active.id]!)}',
        child: ExcludeSemantics(child: SizedBox.fromSize(size: size, child: map)),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.regions,
    required this.colors,
    required this.noData,
    required this.matrix,
    required this.active,
  });

  final List<KumoMapRegion> regions;
  final Map<String, Color> colors;
  final Color noData;
  final Matrix4 matrix;
  final String? active;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(matrix.storage);
    for (final r in regions) {
      var color = colors[r.id] ?? noData;
      // Kumo's blur state: other regions drop to 45% while one is focused.
      if (active != null && r.id != active && colors.containsKey(r.id)) {
        color = color.withValues(alpha: color.a * 0.45);
      }
      canvas.drawPath(r.path, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      !identical(old.regions, regions) && !listEquals(old.regions, regions) ||
      !mapEquals(old.colors, colors) ||
      old.noData != noData ||
      old.matrix != matrix ||
      old.active != active;
}
