part of 'kumo_flow_diagram.dart';

/// What layout found out, handed back to the diagram state after a frame.
@immutable
class _FlowMetrics {
  const _FlowMetrics({required this.available, required this.content, required this.orientation});

  /// Viewport size minus padding.
  final Size available;
  final Size content;
  final KumoFlowOrientation orientation;

  double get maxX => math.max(0, content.width - available.width);
  double get maxY => math.max(0, content.height - available.height);

  @override
  bool operator ==(Object other) =>
      other is _FlowMetrics &&
      other.available == available &&
      other.content == content &&
      other.orientation == orientation;

  @override
  int get hashCode => Object.hash(available, content, orientation);
}

/// Width of the edge fade that shows more of the diagram is off screen.
const double _kFadeExtent = KumoSpace.s6;

/// Kumo's scrollbar: `w-1.5`, inset `1` (4px), thumb at least 10% long.
const double _kScrollbarThickness = KumoSpace.s1_5;
const double _kScrollbarInset = KumoSpace.s1;
const double _kMinThumbFraction = 0.1;

class _FlowParentData extends ContainerBoxParentData<RenderBox> {}

class _FlowViewport extends MultiChildRenderObjectWidget {
  const _FlowViewport({
    super.key,
    required this.tree,
    required this.signature,
    required this.disabled,
    required this.pressable,
    required this.orientation,
    required this.align,
    required this.padding,
    required this.textDirection,
    required this.scrollX,
    required this.scrollY,
    required this.anchors,
    required this.canvas,
    required this.chromeVisible,
    required this.connectorColor,
    required this.trackColor,
    required this.thumbColor,
    required this.minTapTarget,
    required this.onMetrics,
    required this.onGeometry,
    required this.onShowNode,
    super.children,
  });

  final _FlowTree tree;

  /// Structural fingerprint of [tree]; relayout only when it changes.
  final String signature;
  final List<bool> disabled;
  final List<bool> pressable;
  final KumoFlowOrientation orientation;
  final KumoFlowAlign align;
  final EdgeInsetsGeometry padding;
  final TextDirection textDirection;
  final AnimationController scrollX;
  final AnimationController scrollY;
  final _FlowAnchorRegistry anchors;
  final bool canvas;
  final bool chromeVisible;
  final Color connectorColor;
  final Color trackColor;
  final Color thumbColor;
  final double minTapTarget;
  final ValueChanged<_FlowMetrics> onMetrics;
  final ValueChanged<KumoFlowGeometry>? onGeometry;
  final ValueChanged<int> onShowNode;

  @override
  _RenderFlowViewport createRenderObject(BuildContext context) => _RenderFlowViewport(
    tree: tree,
    signature: signature,
    disabled: disabled,
    pressable: pressable,
    orientation: orientation,
    align: align,
    padding: padding,
    textDirection: textDirection,
    scrollX: scrollX,
    scrollY: scrollY,
    anchors: anchors,
    canvas: canvas,
    chromeVisible: chromeVisible,
    connectorColor: connectorColor,
    trackColor: trackColor,
    thumbColor: thumbColor,
    minTapTarget: minTapTarget,
    onMetrics: onMetrics,
    onGeometry: onGeometry,
    onShowNode: onShowNode,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderFlowViewport r) {
    r
      ..setStructure(tree, signature, disabled, pressable)
      ..orientation = orientation
      ..align = align
      ..padding = padding
      ..textDirection = textDirection
      ..setScroll(scrollX, scrollY)
      ..anchors = anchors
      ..canvas = canvas
      ..chromeVisible = chromeVisible
      ..connectorColor = connectorColor
      ..trackColor = trackColor
      ..thumbColor = thumbColor
      ..minTapTarget = minTapTarget
      ..onMetrics = onMetrics
      ..onGeometry = onGeometry
      ..onShowNode = onShowNode;
  }
}

class _Connector {
  const _Connector(this.from, this.to, this.start, this.end, this.disabled);
  final int from;
  final int to;
  final Offset start;
  final Offset end;
  final bool disabled;
}

/// Measures every node, places them with Kumo's layout, paints connectors on
/// top, and pans the whole content under a clip.
class _RenderFlowViewport extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FlowParentData> {
  _RenderFlowViewport({
    required _FlowTree tree,
    required String signature,
    required List<bool> disabled,
    required List<bool> pressable,
    required KumoFlowOrientation orientation,
    required KumoFlowAlign align,
    required EdgeInsetsGeometry padding,
    required TextDirection textDirection,
    required AnimationController scrollX,
    required AnimationController scrollY,
    required _FlowAnchorRegistry anchors,
    required bool canvas,
    required bool chromeVisible,
    required Color connectorColor,
    required Color trackColor,
    required Color thumbColor,
    required double minTapTarget,
    required this.onMetrics,
    required this.onGeometry,
    required this.onShowNode,
  }) : _tree = tree,
       _edges = _computeEdges(tree),
       _signature = signature,
       _disabled = disabled,
       _pressable = pressable,
       _orientation = orientation,
       _align = align,
       _padding = padding,
       _textDirection = textDirection,
       _scrollX = scrollX,
       _scrollY = scrollY,
       _anchors = anchors,
       _canvas = canvas,
       _chromeVisible = chromeVisible,
       _connectorColor = connectorColor,
       _trackColor = trackColor,
       _thumbColor = thumbColor,
       _minTapTarget = minTapTarget;

  _FlowTree _tree;
  List<(int, int)> _edges;
  String _signature;
  List<bool> _disabled;
  List<bool> _pressable;

  ValueChanged<_FlowMetrics> onMetrics;
  ValueChanged<KumoFlowGeometry>? onGeometry;
  ValueChanged<int> onShowNode;

  void setStructure(_FlowTree tree, String signature, List<bool> disabled, List<bool> pressable) {
    _tree = tree;
    _pressable = pressable;
    if (signature != _signature) {
      _signature = signature;
      _edges = _computeEdges(tree);
      markNeedsLayout();
    }
    if (!listEquals(disabled, _disabled)) {
      _disabled = disabled;
      markNeedsPaint();
    }
  }

  KumoFlowOrientation _orientation;
  set orientation(KumoFlowOrientation v) {
    if (v == _orientation) return;
    _orientation = v;
    markNeedsLayout();
  }

  KumoFlowAlign _align;
  set align(KumoFlowAlign v) {
    if (v == _align) return;
    _align = v;
    markNeedsLayout();
  }

  EdgeInsetsGeometry _padding;
  set padding(EdgeInsetsGeometry v) {
    if (v == _padding) return;
    _padding = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  AnimationController _scrollX;
  AnimationController _scrollY;
  void setScroll(AnimationController x, AnimationController y) {
    if (x == _scrollX && y == _scrollY) return;
    if (attached) {
      _scrollX.removeListener(_handleScroll);
      _scrollY.removeListener(_handleScroll);
    }
    _scrollX = x;
    _scrollY = y;
    if (attached) {
      _scrollX.addListener(_handleScroll);
      _scrollY.addListener(_handleScroll);
    }
    markNeedsPaint();
  }

  _FlowAnchorRegistry _anchors;
  set anchors(_FlowAnchorRegistry v) {
    if (v == _anchors) return;
    if (attached) _anchors.onChange = null;
    _anchors = v;
    if (attached) _anchors.onChange = markNeedsPaint;
    markNeedsPaint();
  }

  bool _canvas;
  set canvas(bool v) {
    if (v == _canvas) return;
    _canvas = v;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  bool _chromeVisible;
  set chromeVisible(bool v) {
    if (v == _chromeVisible) return;
    _chromeVisible = v;
    markNeedsPaint();
  }

  Color _connectorColor;
  set connectorColor(Color v) {
    if (v == _connectorColor) return;
    _connectorColor = v;
    markNeedsPaint();
  }

  Color _trackColor;
  set trackColor(Color v) {
    if (v == _trackColor) return;
    _trackColor = v;
    markNeedsPaint();
  }

  Color _thumbColor;
  set thumbColor(Color v) {
    if (v == _thumbColor) return;
    _thumbColor = v;
    markNeedsPaint();
  }

  double _minTapTarget;
  set minTapTarget(double v) => _minTapTarget = v;

  // Layout results.
  List<Size> _sizes = const [];
  List<Offset> _ltr = const [];
  Size _content = Size.zero;
  bool _vertical = false;
  bool _overflowX = false;
  bool _overflowY = false;
  KumoFlowGeometry? _lastGeometry;

  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();
  final LayerHandle<ShaderMaskLayer> _fadeXLayer = LayerHandle<ShaderMaskLayer>();
  final LayerHandle<ShaderMaskLayer> _fadeYLayer = LayerHandle<ShaderMaskLayer>();

  bool get _rtl => _textDirection == TextDirection.rtl;
  EdgeInsets get _resolvedPadding => _padding.resolve(_textDirection);

  void _handleScroll() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FlowParentData) child.parentData = _FlowParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollX.addListener(_handleScroll);
    _scrollY.addListener(_handleScroll);
    _anchors.onChange = markNeedsPaint;
  }

  @override
  void detach() {
    _scrollX.removeListener(_handleScroll);
    _scrollY.removeListener(_handleScroll);
    _anchors.onChange = null;
    super.detach();
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    _fadeXLayer.layer = null;
    _fadeYLayer.layer = null;
    super.dispose();
  }

  List<RenderBox> get _children {
    final out = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      out.add(child);
      child = childAfter(child);
    }
    return out;
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    final pad = _resolvedPadding;
    if (!constraints.hasBoundedWidth) return const BoxConstraints();
    return BoxConstraints(maxWidth: math.max(0, constraints.maxWidth - pad.horizontal));
  }

  /// Runs Kumo's layout over measured sizes and picks the orientation.
  ({Map<int, Offset> positions, Size content, bool vertical}) _place(List<Size> sizes, double availableWidth) {
    final center = _align == KumoFlowAlign.center;
    ({Map<int, Offset> positions, Size content, bool vertical}) run(bool vertical) {
      final positions = _computePositions(_tree, sizes, vertical: vertical, alignCenter: center);
      return (positions: positions, content: _computeDiagramSize(positions, sizes), vertical: vertical);
    }

    switch (_orientation) {
      case KumoFlowOrientation.horizontal:
        return run(false);
      case KumoFlowOrientation.vertical:
        return run(true);
      case KumoFlowOrientation.auto:
        final horizontal = run(false);
        return horizontal.content.width <= availableWidth ? horizontal : run(true);
    }
  }

  Size _sizeFor(BoxConstraints constraints, Size content) {
    final pad = _resolvedPadding;
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : content.width + pad.horizontal;
    return constraints.constrain(Size(width, content.height + pad.vertical));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final cc = _childConstraints(constraints);
    final sizes = [for (final c in _children) c.getDryLayout(cc)];
    final placed = _place(sizes, cc.maxWidth);
    return _sizeFor(constraints, placed.content);
  }

  @override
  double computeMinIntrinsicWidth(double height) => computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) {
    final sizes = [for (final c in _children) c.getDryLayout(const BoxConstraints())];
    return _place(sizes, double.infinity).content.width + _resolvedPadding.horizontal;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width.isFinite ? width : double.infinity)).height;

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  void performLayout() {
    final cc = _childConstraints(constraints);
    final children = _children;
    final sizes = <Size>[];
    for (final child in children) {
      child.layout(cc, parentUsesSize: true);
      sizes.add(child.size);
    }
    final placed = _place(sizes, cc.maxWidth);
    _sizes = sizes;
    _vertical = placed.vertical;
    _content = placed.content;
    _ltr = [for (var i = 0; i < children.length; i++) placed.positions[i] ?? Offset.zero];
    for (var i = 0; i < children.length; i++) {
      final p = _ltr[i];
      (children[i].parentData! as _FlowParentData).offset = _rtl
          ? Offset(_content.width - p.dx - sizes[i].width, p.dy)
          : p;
    }
    size = _sizeFor(constraints, _content);

    final pad = _resolvedPadding;
    final available = Size(math.max(0, size.width - pad.horizontal), math.max(0, size.height - pad.vertical));
    final overflowX = _content.width > available.width + 0.5;
    final overflowY = _content.height > available.height + 0.5;
    if (overflowX != _overflowX || overflowY != _overflowY) {
      _overflowX = overflowX;
      _overflowY = overflowY;
      markNeedsCompositingBitsUpdate();
    }
    onMetrics(
      _FlowMetrics(
        available: available,
        content: _content,
        orientation: _vertical ? KumoFlowOrientation.vertical : KumoFlowOrientation.horizontal,
      ),
    );
  }

  Size get _available {
    final pad = _resolvedPadding;
    return Size(math.max(0, size.width - pad.horizontal), math.max(0, size.height - pad.vertical));
  }

  /// Top-left of the content box in viewport coordinates, after panning.
  Offset get _origin {
    final pad = _resolvedPadding;
    final available = _available;
    final double x;
    if (!_overflowX) {
      x = pad.left + (available.width - _content.width) / 2;
    } else if (_rtl) {
      x = pad.left + available.width - _content.width + _scrollX.value;
    } else {
      x = pad.left - _scrollX.value;
    }
    final y = _overflowY ? pad.top - _scrollY.value : pad.top;
    return Offset(x, y);
  }

  /// Scroll position (distance from the start on each axis) that brings node
  /// [index] into view with a little room, or null when it already is.
  Offset? revealOffset(int index, {double margin = KumoSpace.s4}) {
    if (!hasSize || index < 0 || index >= _ltr.length) return null;
    final rect = _ltr[index] & _sizes[index];
    final available = _available;
    final maxX = math.max(0.0, _content.width - available.width);
    final maxY = math.max(0.0, _content.height - available.height);
    double fit(double current, double start, double end, double extent, double max) {
      var target = current;
      if (end - start + 2 * margin > extent) {
        target = start - margin;
      } else if (start - margin < current) {
        target = start - margin;
      } else if (end + margin > current + extent) {
        target = end + margin - extent;
      }
      return target.clamp(0.0, max);
    }

    final x = _overflowX ? fit(_scrollX.value, rect.left, rect.right, available.width, maxX) : _scrollX.value;
    final y = _overflowY ? fit(_scrollY.value, rect.top, rect.bottom, available.height, maxY) : _scrollY.value;
    final target = Offset(x, y);
    return target == Offset(_scrollX.value, _scrollY.value) ? null : target;
  }

  double? _anchorY(Map<int, RenderBox> anchors, int index, RenderBox node) {
    final anchor = anchors[index];
    if (anchor == null || !anchor.attached || !anchor.hasSize) return null;
    RenderObject? walker = anchor;
    while (walker != null && walker != node) {
      walker = walker.parent;
    }
    if (walker == null) return null;
    return MatrixUtils.transformPoint(anchor.getTransformTo(node), Offset(0, anchor.size.height / 2)).dy;
  }

  /// Kumo's `FlowConnectors`: right-center to left-center (or the anchors) in
  /// horizontal flows, bottom-center to top-center in vertical ones. Left to
  /// right coordinates.
  List<_Connector> _buildConnectors(List<RenderBox> children) {
    final out = <_Connector>[];
    for (final (from, to) in _edges) {
      if (from >= _ltr.length || to >= _ltr.length) continue;
      final fp = _ltr[from], tp = _ltr[to];
      final fs = _sizes[from], ts = _sizes[to];
      final Offset a;
      final Offset b;
      if (_vertical) {
        a = Offset(fp.dx + fs.width / 2, fp.dy + fs.height);
        b = Offset(tp.dx + ts.width / 2, tp.dy);
      } else {
        a = Offset(fp.dx + fs.width, fp.dy + (_anchorY(_anchors.start, from, children[from]) ?? fs.height / 2));
        b = Offset(tp.dx, tp.dy + (_anchorY(_anchors.end, to, children[to]) ?? ts.height / 2));
      }
      final disabled = (from < _disabled.length && _disabled[from]) || (to < _disabled.length && _disabled[to]);
      out.add(_Connector(from, to, a, b, disabled));
    }
    // Disabled connectors sit under active ones, as in Kumo.
    return [...out.where((c) => c.disabled), ...out.where((c) => !c.disabled)];
  }

  Offset _mirror(Offset p) => _rtl ? Offset(_content.width - p.dx, p.dy) : p;

  void _reportGeometry(List<_Connector> connectors) {
    final callback = onGeometry;
    if (callback == null) return;
    final geometry = KumoFlowGeometry(
      orientation: _vertical ? KumoFlowOrientation.vertical : KumoFlowOrientation.horizontal,
      size: _content,
      nodes: [
        for (var i = 0; i < _ltr.length; i++)
          (_rtl ? Offset(_content.width - _ltr[i].dx - _sizes[i].width, _ltr[i].dy) : _ltr[i]) & _sizes[i],
      ],
      connectors: [
        for (final c in connectors)
          KumoFlowConnector(from: c.from, to: c.to, start: _mirror(c.start), end: _mirror(c.end), disabled: c.disabled),
      ],
    );
    if (geometry == _lastGeometry) return;
    _lastGeometry = geometry;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached && _lastGeometry == geometry) callback(geometry);
    });
  }

  bool get _fades => _canvas && (_overflowX || _overflowY);

  @override
  bool get alwaysNeedsCompositing => _fades;

  @override
  void paint(PaintingContext context, Offset offset) {
    final children = _children;
    final connectors = _buildConnectors(children);
    _reportGeometry(connectors);

    _clipLayer.layer = context.pushClipRect(needsCompositing, offset, Offset.zero & size, (context, offset) {
      _paintFaded(context, offset, children, connectors);
      _paintScrollbars(context.canvas, offset);
    }, oldLayer: _clipLayer.layer);
  }

  /// How much to fade each edge: 0 when nothing is hidden there, 1 once at
  /// least [_kFadeExtent] of content is.
  (double, double) _fadeAmounts(double scroll, double max) =>
      ((scroll / _kFadeExtent).clamp(0.0, 1.0), ((max - scroll) / _kFadeExtent).clamp(0.0, 1.0));

  Shader _fadeShader(Rect rect, double leading, double trailing, {required bool horizontal}) {
    final extent = horizontal ? rect.width : rect.height;
    final f = extent <= 0 ? 0.0 : (_kFadeExtent / extent).clamp(0.0, 0.5);
    const opaque = Color(0xFFFFFFFF);
    return LinearGradient(
      begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
      end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
      colors: [
        opaque.withValues(alpha: 1 - leading),
        opaque,
        opaque,
        opaque.withValues(alpha: 1 - trailing),
      ],
      stops: [0, f, 1 - f, 1],
    ).createShader(rect);
  }

  void _paintFaded(PaintingContext context, Offset offset, List<RenderBox> children, List<_Connector> connectors) {
    void content(PaintingContext context, Offset offset) => _paintContent(context, offset, children, connectors);

    if (!_fades) {
      _fadeXLayer.layer = null;
      _fadeYLayer.layer = null;
      content(context, offset);
      return;
    }
    final available = _available;
    final rect = Offset.zero & size;
    var (startX, endX) = _overflowX ? _fadeAmounts(_scrollX.value, _content.width - available.width) : (0.0, 0.0);
    if (_rtl) (startX, endX) = (endX, startX);
    final (top, bottom) = _overflowY ? _fadeAmounts(_scrollY.value, _content.height - available.height) : (0.0, 0.0);

    void faded(PaintingContext context, Offset offset) {
      if (top == 0 && bottom == 0) {
        _fadeYLayer.layer = null;
        content(context, offset);
        return;
      }
      final layer = (_fadeYLayer.layer ?? ShaderMaskLayer())
        ..shader = _fadeShader(rect, top, bottom, horizontal: false)
        ..maskRect = offset & size
        ..blendMode = BlendMode.dstIn;
      _fadeYLayer.layer = layer;
      context.pushLayer(layer, content, offset);
    }

    if (startX == 0 && endX == 0) {
      _fadeXLayer.layer = null;
      faded(context, offset);
      return;
    }
    final layer = (_fadeXLayer.layer ?? ShaderMaskLayer())
      ..shader = _fadeShader(rect, startX, endX, horizontal: true)
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    _fadeXLayer.layer = layer;
    context.pushLayer(layer, faded, offset);
  }

  void _paintContent(PaintingContext context, Offset offset, List<RenderBox> children, List<_Connector> connectors) {
    final origin = offset + _origin;
    for (final child in children) {
      context.paintChild(child, origin + (child.parentData! as _FlowParentData).offset);
    }
    if (connectors.isEmpty) return;
    final canvas = context.canvas
      ..save()
      ..translate(origin.dx, origin.dy);
    if (_rtl) {
      canvas
        ..translate(_content.width, 0)
        ..scale(-1, 1);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..style = PaintingStyle.fill;
    for (final c in connectors) {
      final color = c.disabled ? _connectorColor.withValues(alpha: _connectorColor.a * 0.4) : _connectorColor;
      final path = _roundedPath(c.start, c.end, vertical: _vertical);
      canvas.drawPath(path.path, stroke..color = color);
      final head = _arrowhead.transform(
        (Matrix4.translationValues(
          path.tip.dx,
          path.tip.dy,
          0,
        )..rotateZ(math.atan2(path.direction.dy, path.direction.dx))).storage,
      );
      canvas.drawPath(head, fill..color = color);
    }
    canvas.restore();
  }

  void _paintScrollbars(Canvas canvas, Offset offset) {
    final animating = _scrollX.isAnimating || _scrollY.isAnimating;
    if (!_canvas || !(_chromeVisible || animating)) return;
    final available = _available;
    final track = Paint()..color = _trackColor.withValues(alpha: _trackColor.a * 0.5);
    final thumb = Paint()..color = _thumbColor;
    const radius = Radius.circular(_kScrollbarThickness / 2);

    if (_overflowY) {
      final x = _rtl ? _kScrollbarInset : size.width - _kScrollbarInset - _kScrollbarThickness;
      final trackRect = Rect.fromLTWH(
        x,
        _kScrollbarInset,
        _kScrollbarThickness,
        size.height - 2 * _kScrollbarInset,
      ).shift(offset);
      final fraction = math.max(_kMinThumbFraction, available.height / _content.height);
      final max = _content.height - available.height;
      final progress = max <= 0 ? 0.0 : (_scrollY.value / max).clamp(0.0, 1.0);
      final length = trackRect.height * fraction;
      canvas
        ..drawRRect(RRect.fromRectAndRadius(trackRect, radius), track)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              trackRect.left,
              trackRect.top + progress * (trackRect.height - length),
              _kScrollbarThickness,
              length,
            ),
            radius,
          ),
          thumb,
        );
    }
    if (_overflowX) {
      final trackRect = Rect.fromLTWH(
        _kScrollbarInset,
        size.height - _kScrollbarInset - _kScrollbarThickness,
        size.width - 2 * _kScrollbarInset,
        _kScrollbarThickness,
      ).shift(offset);
      final fraction = math.max(_kMinThumbFraction, available.width / _content.width);
      final max = _content.width - available.width;
      var progress = max <= 0 ? 0.0 : (_scrollX.value / max).clamp(0.0, 1.0);
      if (_rtl) progress = 1 - progress;
      final length = trackRect.width * fraction;
      canvas
        ..drawRRect(RRect.fromRectAndRadius(trackRect, radius), track)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              trackRect.left + progress * (trackRect.width - length),
              trackRect.top,
              length,
              _kScrollbarThickness,
            ),
            radius,
          ),
          thumb,
        );
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final o = _origin + (child.parentData! as _FlowParentData).offset;
    transform.translateByDouble(o.dx, o.dy, 0, 1);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => Offset.zero & size;

  @override
  Rect? describeSemanticsClip(RenderObject? child) => Offset.zero & size;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final origin = _origin;
    final children = _children;
    for (final child in children.reversed) {
      final hit = result.addWithPaintOffset(
        offset: origin + (child.parentData! as _FlowParentData).offset,
        position: position,
        hitTest: (result, transformed) => child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    // A pressable node smaller than the minimum touch target still answers
    // taps just outside its edge, without that padding entering the layout.
    if (_minTapTarget <= 0) return false;
    for (var i = children.length - 1; i >= 0; i--) {
      if (i >= _pressable.length || !_pressable[i]) continue;
      final child = children[i];
      final local = position - origin - (child.parentData! as _FlowParentData).offset;
      final s = child.size;
      final dx = math.max(0.0, (_minTapTarget - s.width) / 2);
      final dy = math.max(0.0, (_minTapTarget - s.height) / 2);
      if (dx == 0 && dy == 0) continue;
      final slop = Rect.fromLTRB(-dx, -dy, s.width + dx, s.height + dy);
      if (!slop.contains(local)) continue;
      final inside = Offset(
        local.dx.clamp(0.5, math.max(0.5, s.width - 0.5)),
        local.dy.clamp(0.5, math.max(0.5, s.height - 0.5)),
      );
      final hit = result.addWithPaintOffset(
        offset: origin + (child.parentData! as _FlowParentData).offset,
        position: origin + (child.parentData! as _FlowParentData).offset + inside,
        hitTest: (result, transformed) => child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (descendant != null && descendant != this) {
      RenderObject? walker = descendant;
      while (walker != null && walker.parent != this) {
        walker = walker.parent;
      }
      if (walker is RenderBox) {
        final index = _children.indexOf(walker);
        if (index >= 0) onShowNode(index);
      }
    }
    super.showOnScreen(descendant: descendant, rect: rect, duration: duration, curve: curve);
  }
}
