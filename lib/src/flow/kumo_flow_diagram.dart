import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';

part 'kumo_flow_anchor.dart';
part 'kumo_flow_entries.dart';
part 'kumo_flow_layout.dart';
part 'kumo_flow_node_view.dart';
part 'kumo_flow_viewport.dart';

/// Which way a [KumoFlowDiagram] runs.
enum KumoFlowOrientation {
  /// Steps run left to right (right to left under RTL), branches stack
  /// vertically. Kumo's default.
  horizontal,

  /// Steps run top to bottom, branches sit side by side.
  vertical,

  /// Horizontal when the whole diagram fits the available width, vertical
  /// when it does not. Decided from the measured nodes on every layout, so a
  /// phone in portrait gets a vertical diagram and the same screen in
  /// landscape gets the horizontal one.
  auto,
}

/// Cross-axis alignment of nodes in a [KumoFlowDiagram].
enum KumoFlowAlign {
  /// Nodes line up along the top (horizontal) or leading edge (vertical).
  start,

  /// Nodes are centered across the cross axis, for nodes of mixed sizes.
  center,
}

/// Whether a [KumoFlowDiagram]'s content is larger than its viewport on
/// each axis (Kumo's `onOverflowChange` payload).
@immutable
class KumoFlowOverflow {
  const KumoFlowOverflow({this.x = false, this.y = false});

  final bool x;
  final bool y;

  @override
  bool operator ==(Object other) => other is KumoFlowOverflow && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'KumoFlowOverflow(x: $x, y: $y)';
}

/// One drawn connector in a [KumoFlowGeometry].
@immutable
class KumoFlowConnector {
  const KumoFlowConnector({
    required this.from,
    required this.to,
    required this.start,
    required this.end,
    this.disabled = false,
  });

  /// Index of the source node in [KumoFlowGeometry.nodes].
  final int from;

  /// Index of the target node.
  final int to;

  /// Where the connector leaves the source node, in content coordinates.
  final Offset start;

  /// Where it meets the target node's edge. The arrow tip stops just short.
  final Offset end;

  /// True when either node is disabled; drawn at 40% opacity.
  final bool disabled;

  @override
  bool operator ==(Object other) =>
      other is KumoFlowConnector &&
      other.from == from &&
      other.to == to &&
      other.start == start &&
      other.end == end &&
      other.disabled == disabled;

  @override
  int get hashCode => Object.hash(from, to, start, end, disabled);

  @override
  String toString() => 'KumoFlowConnector($from -> $to, $start -> $end${disabled ? ', disabled' : ''})';
}

/// The laid-out diagram: node rectangles and connector endpoints in content
/// coordinates (origin at the top-left of the content box, inside the
/// padding, before panning). Delivered by [KumoFlowDiagram.onGeometryChange]
/// after every layout that changes it, for overlays such as status badges
/// and for tests.
@immutable
class KumoFlowGeometry {
  const KumoFlowGeometry({
    required this.orientation,
    required this.size,
    required this.nodes,
    required this.connectors,
    this.ids = const [],
  });

  /// The orientation actually used: never [KumoFlowOrientation.auto].
  final KumoFlowOrientation orientation;

  /// Size of the content box (Kumo's `computeDiagramRect`).
  final Size size;

  /// One rectangle per [KumoFlowNode], in the order the nodes appear in the
  /// tree (depth first).
  final List<Rect> nodes;

  /// The node ids in the same order, null where a node has none.
  final List<String?> ids;
  final List<KumoFlowConnector> connectors;

  /// The rectangle of the node with [id].
  Rect? rectOf(String id) {
    final i = ids.indexOf(id);
    return i < 0 || i >= nodes.length ? null : nodes[i];
  }

  KumoFlowGeometry _withIds(List<String?> ids) =>
      KumoFlowGeometry(orientation: orientation, size: size, nodes: nodes, connectors: connectors, ids: ids);

  @override
  bool operator ==(Object other) =>
      other is KumoFlowGeometry &&
      other.orientation == orientation &&
      other.size == size &&
      listEquals(other.nodes, nodes) &&
      listEquals(other.ids, ids) &&
      listEquals(other.connectors, connectors);

  @override
  int get hashCode =>
      Object.hash(orientation, size, Object.hashAll(nodes), Object.hashAll(ids), Object.hashAll(connectors));
}

String _defaultStep(int index, int count) => 'Step $index of $count';
String _defaultBranch(int index, int count) => 'branch $index of $count';
String _defaultSteps(int count) => count == 1 ? '1 step' : '$count steps';

/// Screen reader copy for [KumoFlowDiagram]. Override for another language.
///
/// ```dart
/// KumoFlowDiagram(
///   strings: KumoFlowStrings(
///     diagram: 'Diagrama de flujo',
///     step: (i, n) => 'Paso $i de $n',
///     branch: (i, n) => 'rama $i de $n',
///     steps: (n) => '$n pasos',
///   ),
///   children: const [KumoFlowNode(label: 'Inicio')],
/// )
/// ```
@immutable
class KumoFlowStrings {
  const KumoFlowStrings({
    this.diagram = 'Flow diagram',
    this.step = _defaultStep,
    this.branch = _defaultBranch,
    this.steps = _defaultSteps,
  });

  /// The flow strings of the nearest [KumoLocale].
  factory KumoFlowStrings.of(BuildContext context) {
    final s = context.kumoStrings;
    return KumoFlowStrings(diagram: s.flowDiagram, step: s.flowStep, branch: s.flowBranch, steps: s.flowSteps);
  }

  /// Label of the diagram as a whole when it has no `semanticLabel`.
  final String diagram;

  /// A node's place in a sequence: "Step 2 of 4".
  final String Function(int index, int count) step;

  /// A node's branch inside a parallel group: "branch 1 of 3".
  final String Function(int index, int count) branch;

  /// The diagram's value: "4 steps".
  final String Function(int count) steps;
}

/// A directed step diagram (Kumo's `Flow`): nodes, connectors with rounded
/// elbows, parallel branches and custom anchor points. Use it for request
/// pipelines, deploy stages and routing rules, where the order of steps is
/// the point.
///
/// Nodes are measured first, then placed with Kumo's layout algorithm, then
/// connectors are painted over them; any change in a node's size (text
/// scale, an expanding section) re-runs the layout and the connectors follow.
///
/// When the content is larger than the diagram, it pans: drag anywhere
/// (including on a node) and the content follows the finger, flings with
/// momentum and rubber-bands at the edges. Mouse wheels and trackpads pan
/// too, an edge fade marks the side with more content, and Kumo's thin
/// scrollbars show while hovered or moving. Focusing a node (Tab, or a
/// screen reader) pans it into view.
///
/// Screen readers read the steps in order, each with its place in the
/// diagram: "image-resizer, Step 2 of 4" or "WAF, Step 2 of 3, branch 1 of 2".
///
/// ```dart
/// const KumoFlowDiagram(
///   semanticLabel: 'Request path',
///   children: [
///     KumoFlowNode(label: 'Request'),
///     KumoFlowNode(label: 'WAF'),
///     KumoFlowNode(label: 'image-resizer'),
///     KumoFlowNode(label: 'Origin'),
///   ],
/// )
/// ```
class KumoFlowDiagram extends StatefulWidget {
  const KumoFlowDiagram({
    super.key,
    required this.children,
    this.orientation = KumoFlowOrientation.horizontal,
    this.align = KumoFlowAlign.start,
    this.canvas = true,
    this.padding = const EdgeInsets.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s16),
    this.onOverflowChange,
    this.onGeometryChange,
    this.semanticLabel,
    this.strings,
  });

  /// The steps, in order: [KumoFlowNode], [KumoFlowParallel] and
  /// [KumoFlowList] entries.
  final List<KumoFlowEntry> children;

  /// Which way steps run. [KumoFlowOrientation.auto] switches to vertical
  /// when the horizontal layout does not fit.
  final KumoFlowOrientation orientation;

  /// Cross-axis alignment of the nodes.
  final KumoFlowAlign align;

  /// Kumo's `canvas`: pan, wheel, edge fade and scrollbars when the content
  /// overflows. With false, overflowing content is clipped and stays put.
  final bool canvas;

  /// Space between the diagram's edge and its content. Kumo's default is 16
  /// horizontally and 64 vertically, which leaves room for the scrollbars.
  final EdgeInsetsGeometry padding;

  /// Called after the first layout with the overflow on each axis, then
  /// whenever the content starts or stops overflowing either axis.
  final ValueChanged<KumoFlowOverflow>? onOverflowChange;

  /// Called after layout with node rectangles and connector endpoints, when
  /// they change. Also tells you which orientation `auto` picked.
  ///
  /// ```dart
  /// KumoFlowDiagram(
  ///   orientation: KumoFlowOrientation.auto,
  ///   onGeometryChange: (g) => debugPrint('${g.orientation}'),
  ///   children: const [KumoFlowNode(label: 'Request'), KumoFlowNode(label: 'Origin')],
  /// )
  /// ```
  final ValueChanged<KumoFlowGeometry>? onGeometryChange;

  /// What the diagram shows, read before its step count ("Request path, 4
  /// steps"). Defaults to the nearest [KumoLocale] strings.
  final String? semanticLabel;
  final KumoFlowStrings? strings;

  @override
  State<KumoFlowDiagram> createState() => _KumoFlowDiagramState();
}

/// The diagram's entries flattened into node widgets plus the layout tree.
class _Flattened {
  _Flattened(List<KumoFlowEntry> entries, KumoFlowStrings strings) {
    final buffer = StringBuffer();
    _FlowTree visit(KumoFlowEntry entry, List<String> place) {
      switch (entry) {
        case KumoFlowNode():
          final index = nodes.length;
          nodes.add(entry);
          positions.add(place.join(', '));
          buffer.write('n');
          return _FlowTreeNode(index);
        case KumoFlowParallel(:final children, :final align):
          buffer.write(align == KumoFlowParallelAlign.end ? 'P(' : 'p(');
          final branches = [
            for (var i = 0; i < children.length; i++)
              visit(children[i], [...place, strings.branch(i + 1, children.length)]),
          ];
          buffer.write(')');
          return _FlowTreeParallel(branches, alignEnd: align == KumoFlowParallelAlign.end);
        case KumoFlowList(:final children):
          buffer.write('l(');
          final list = _list(children, place, visit, strings);
          buffer.write(')');
          return list;
      }
    }

    tree = _list(entries, const [], visit, strings);
    signature = buffer.toString();
    stepCount = entries.length;
  }

  static _FlowTreeList _list(
    List<KumoFlowEntry> entries,
    List<String> place,
    _FlowTree Function(KumoFlowEntry, List<String>) visit,
    KumoFlowStrings strings,
  ) => _FlowTreeList([
    for (var i = 0; i < entries.length; i++) visit(entries[i], [...place, strings.step(i + 1, entries.length)]),
  ]);

  final List<KumoFlowNode> nodes = [];
  final List<String> positions = [];
  late final _FlowTree tree;
  late final String signature;
  late final int stepCount;
}

class _KumoFlowDiagramState extends State<KumoFlowDiagram> with TickerProviderStateMixin {
  late final AnimationController _scrollX;
  late final AnimationController _scrollY;
  final _FlowAnchorRegistry _anchors = _FlowAnchorRegistry();
  final GlobalKey _viewportKey = GlobalKey();

  _FlowMetrics? _metrics;
  bool _metricsScheduled = false;
  KumoFlowOverflow? _overflow;
  List<String?> _ids = const [];

  bool _hovered = false;
  bool _dragging = false;
  Offset _dragRaw = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scrollX = AnimationController.unbounded(vsync: this);
    _scrollY = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _scrollX.dispose();
    _scrollY.dispose();
    super.dispose();
  }

  double get _maxX => _metrics?.maxX ?? 0;
  double get _maxY => _metrics?.maxY ?? 0;
  bool get _canX => widget.canvas && _maxX > 0;
  bool get _canY => widget.canvas && _maxY > 0;

  /// +1 when the start of the flow is on the left.
  double get _dir => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _handleMetrics(_FlowMetrics metrics) {
    if (metrics == _metrics) return;
    _metrics = metrics;
    if (_metricsScheduled) return;
    _metricsScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _metricsScheduled = false;
      if (!mounted) return;
      final m = _metrics!;
      // Content that shrank after panning snaps back inside the new bounds.
      if (!_dragging) {
        if (_scrollX.value > m.maxX || _scrollX.value < 0) _scrollX.value = _scrollX.value.clamp(0.0, m.maxX);
        if (_scrollY.value > m.maxY || _scrollY.value < 0) _scrollY.value = _scrollY.value.clamp(0.0, m.maxY);
      }
      final overflow = KumoFlowOverflow(x: m.maxX > 0, y: m.maxY > 0);
      setState(() {});
      if (overflow != _overflow) {
        _overflow = overflow;
        widget.onOverflowChange?.call(overflow);
      }
    });
  }

  void _handleGeometry(KumoFlowGeometry geometry) {
    if (!mounted) return;
    widget.onGeometryChange?.call(geometry._withIds(_ids));
  }

  _RenderFlowViewport? get _viewport => _viewportKey.currentContext?.findRenderObject() as _RenderFlowViewport?;

  void _animateTo(Offset target) {
    if (KumoMotion.reduceMotion(context)) {
      _scrollX.value = target.dx;
      _scrollY.value = target.dy;
      return;
    }
    KumoMotion.springTo(_scrollX, target.dx, velocity: _scrollX.velocity);
    KumoMotion.springTo(_scrollY, target.dy, velocity: _scrollY.velocity);
  }

  void _reveal(int index) {
    if (!widget.canvas || _dragging) return;
    final target = _viewport?.revealOffset(index);
    if (target != null) _animateTo(target);
  }

  double _resist(double raw, double max, double extent) {
    if (raw < 0) return KumoMotion.rubberband(raw, extent);
    if (raw > max) return max + KumoMotion.rubberband(raw - max, extent);
    return raw;
  }

  void _handleDown() {
    // Catching a moving canvas stops it where it is.
    _scrollX.stop();
    _scrollY.stop();
  }

  void _handleDragStart() {
    _scrollX.stop();
    _scrollY.stop();
    _dragRaw = Offset(_scrollX.value, _scrollY.value);
    setState(() => _dragging = true);
  }

  void _handleDragUpdate(Offset delta) {
    final m = _metrics;
    if (m == null) return;
    if (_canX) {
      final raw = _dragRaw.dx - delta.dx * _dir;
      _dragRaw = Offset(raw, _dragRaw.dy);
      _scrollX.value = _resist(raw, m.maxX, m.available.width);
    }
    if (_canY) {
      final raw = _dragRaw.dy - delta.dy;
      _dragRaw = Offset(_dragRaw.dx, raw);
      _scrollY.value = _resist(raw, m.maxY, m.available.height);
    }
  }

  void _fling(AnimationController controller, double velocity, double max) {
    if (KumoMotion.reduceMotion(context)) {
      controller.value = controller.value.clamp(0.0, max);
      return;
    }
    final simulation = BouncingScrollSimulation(
      position: controller.value,
      velocity: velocity,
      leadingExtent: 0,
      trailingExtent: max,
      spring: KumoSprings.standard,
      tolerance: const Tolerance(distance: 0.01, velocity: 1),
    );
    controller.animateWith(simulation).then((_) {
      if (mounted && (controller.value < 0 || controller.value > max)) {
        controller.value = controller.value.clamp(0.0, max);
      }
    });
  }

  void _handleDragEnd(Velocity velocity) {
    setState(() => _dragging = false);
    final v = velocity.pixelsPerSecond;
    if (_canX) _fling(_scrollX, -v.dx * _dir, _maxX);
    if (_canY) _fling(_scrollY, -v.dy, _maxY);
  }

  void _settle() {
    if (_dragging) setState(() => _dragging = false);
    if (_scrollX.value < 0 || _scrollX.value > _maxX) _fling(_scrollX, 0, _maxX);
    if (_scrollY.value < 0 || _scrollY.value > _maxY) _fling(_scrollY, 0, _maxY);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    var dx = event.scrollDelta.dx;
    var dy = event.scrollDelta.dy;
    if (dx == 0 && !_canY && HardwareKeyboard.instance.isShiftPressed) (dx, dy) = (dy, 0);
    final useX = _canX && dx != 0;
    final useY = _canY && dy != 0;
    // Wheel movement on an axis that cannot pan goes to the page around us.
    if (!useX && !useY) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      _scrollX.stop();
      _scrollY.stop();
      if (useX) _scrollX.value = (_scrollX.value + dx * _dir).clamp(0.0, _maxX);
      if (useY) _scrollY.value = (_scrollY.value + dy).clamp(0.0, _maxY);
    });
  }

  void _scrollBy(double dx, double dy) {
    final m = _metrics;
    if (m == null) return;
    _animateTo(Offset((_scrollX.value + dx).clamp(0.0, m.maxX), (_scrollY.value + dy).clamp(0.0, m.maxY)));
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final strings = widget.strings ?? KumoFlowStrings.of(context);
    final flat = _Flattened(widget.children, strings);
    _ids = [for (final n in flat.nodes) n.id];
    final textDirection = Directionality.of(context);

    Widget result = _FlowViewport(
      key: _viewportKey,
      tree: flat.tree,
      signature: flat.signature,
      disabled: [for (final n in flat.nodes) n.disabled],
      pressable: [for (final n in flat.nodes) n.onPress != null && !n.disabled],
      orientation: widget.orientation,
      align: widget.align,
      padding: widget.padding,
      textDirection: textDirection,
      scrollX: _scrollX,
      scrollY: _scrollY,
      anchors: _anchors,
      canvas: widget.canvas,
      chromeVisible: _hovered || _dragging,
      connectorColor: kumo.colors.textPlaceholder,
      trackColor: kumo.colors.hairline,
      thumbColor: kumo.colors.fill,
      minTapTarget: kumo.minTapTarget,
      onMetrics: _handleMetrics,
      onGeometry: widget.onGeometryChange == null ? null : _handleGeometry,
      onShowNode: _reveal,
      children: [
        for (var i = 0; i < flat.nodes.length; i++)
          _FlowNodeView(
            key: flat.nodes[i].id == null ? null : ValueKey<String>(flat.nodes[i].id!),
            node: flat.nodes[i],
            index: i,
            position: flat.positions[i],
            anchors: _anchors,
            onReveal: _reveal,
          ),
      ],
    );

    // Tab follows the steps, not screen position, so branches are visited in
    // the same order screen readers read them.
    result = FocusTraversalGroup(policy: OrderedTraversalPolicy(), child: result);

    final canX = _canX, canY = _canY;
    if (widget.canvas) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Count the movement before the drag was recognized, so the content
        // stays under the finger from the first frame.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragDown: canX && !canY ? (_) => _handleDown() : null,
        onHorizontalDragStart: canX && !canY ? (_) => _handleDragStart() : null,
        onHorizontalDragUpdate: canX && !canY ? (d) => _handleDragUpdate(d.delta) : null,
        onHorizontalDragEnd: canX && !canY ? (d) => _handleDragEnd(d.velocity) : null,
        onHorizontalDragCancel: canX && !canY ? _settle : null,
        onVerticalDragDown: canY && !canX ? (_) => _handleDown() : null,
        onVerticalDragStart: canY && !canX ? (_) => _handleDragStart() : null,
        onVerticalDragUpdate: canY && !canX ? (d) => _handleDragUpdate(d.delta) : null,
        onVerticalDragEnd: canY && !canX ? (d) => _handleDragEnd(d.velocity) : null,
        onVerticalDragCancel: canY && !canX ? _settle : null,
        onPanDown: canX && canY ? (_) => _handleDown() : null,
        onPanStart: canX && canY ? (_) => _handleDragStart() : null,
        onPanUpdate: canX && canY ? (d) => _handleDragUpdate(d.delta) : null,
        onPanEnd: canX && canY ? (d) => _handleDragEnd(d.velocity) : null,
        onPanCancel: canX && canY ? _settle : null,
        child: result,
      );
      result = Listener(onPointerSignal: _handlePointerSignal, child: result);
      result = MouseRegion(
        cursor: canX || canY ? (_dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab) : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: result,
      );
    }

    final page = _metrics?.available ?? Size.zero;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel ?? strings.diagram,
      value: strings.steps(flat.stepCount),
      onScrollLeft: canX ? () => _scrollBy(page.width * 0.8 * _dir, 0) : null,
      onScrollRight: canX ? () => _scrollBy(-page.width * 0.8 * _dir, 0) : null,
      onScrollUp: canY ? () => _scrollBy(0, page.height * 0.8) : null,
      onScrollDown: canY ? () => _scrollBy(0, -page.height * 0.8) : null,
      child: result,
    );
  }
}
