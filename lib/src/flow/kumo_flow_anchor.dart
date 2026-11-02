part of 'kumo_flow_diagram.dart';

/// Which connectors a [KumoFlowAnchor] attracts.
enum KumoFlowAnchorType {
  /// Outgoing connectors leave from this anchor.
  start,

  /// Incoming connectors arrive at this anchor.
  end,

  /// Both incoming and outgoing connectors (Kumo's default when `type` is
  /// omitted).
  both,
}

/// Marks where connectors attach inside a node (Kumo's `Flow.Anchor`).
///
/// By default connectors meet a node at its vertical center. Wrap part of a
/// node's content in an anchor and they meet the center of that part instead.
/// Anchors apply to horizontal flows; vertical connectors always meet the
/// node's top and bottom centers, as in Kumo.
///
/// Use it inside a [KumoFlowNode]'s `child` or `render`. Anywhere else it
/// throws.
///
/// ```dart
/// KumoFlowNode(
///   render: Column(mainAxisSize: MainAxisSize.min, children: [
///     KumoFlowAnchor(type: KumoFlowAnchorType.end, child: Text('my-worker')),
///     KumoFlowAnchor(type: KumoFlowAnchorType.start, child: Text('Bindings 2')),
///   ]),
/// )
/// ```
class KumoFlowAnchor extends StatelessWidget {
  const KumoFlowAnchor({super.key, this.type = KumoFlowAnchorType.both, required this.child});

  final KumoFlowAnchorType type;

  /// The content connectors line up with.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FlowNodeScope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary('KumoFlowAnchor must be used within a KumoFlowNode.'),
        ErrorHint('Place it inside the child or render widget of a KumoFlowNode in a KumoFlowDiagram.'),
      ]);
    }
    return _FlowAnchorBox(registry: scope.anchors, nodeIndex: scope.index, type: type, child: child);
  }
}

/// Where each node's anchors are, so the diagram can aim connectors at them.
class _FlowAnchorRegistry {
  final Map<int, RenderBox> start = {};
  final Map<int, RenderBox> end = {};

  /// Set by the viewport: repaints the connectors.
  VoidCallback? onChange;

  void register(int node, KumoFlowAnchorType type, RenderBox box) {
    if (type != KumoFlowAnchorType.end) start[node] = box;
    if (type != KumoFlowAnchorType.start) end[node] = box;
    onChange?.call();
  }

  void unregister(int node, KumoFlowAnchorType type, RenderBox box) {
    if (start[node] == box) start.remove(node);
    if (end[node] == box) end.remove(node);
    onChange?.call();
  }
}

class _FlowAnchorBox extends SingleChildRenderObjectWidget {
  const _FlowAnchorBox({required this.registry, required this.nodeIndex, required this.type, super.child});

  final _FlowAnchorRegistry registry;
  final int nodeIndex;
  final KumoFlowAnchorType type;

  @override
  _RenderFlowAnchor createRenderObject(BuildContext context) =>
      _RenderFlowAnchor(registry: registry, nodeIndex: nodeIndex, type: type);

  @override
  void updateRenderObject(BuildContext context, _RenderFlowAnchor renderObject) =>
      renderObject.update(registry, nodeIndex, type);
}

class _RenderFlowAnchor extends RenderProxyBox {
  _RenderFlowAnchor({required _FlowAnchorRegistry registry, required int nodeIndex, required KumoFlowAnchorType type})
    : _registry = registry,
      _nodeIndex = nodeIndex,
      _type = type;

  _FlowAnchorRegistry _registry;
  int _nodeIndex;
  KumoFlowAnchorType _type;

  void update(_FlowAnchorRegistry registry, int nodeIndex, KumoFlowAnchorType type) {
    if (registry == _registry && nodeIndex == _nodeIndex && type == _type) return;
    if (attached) _registry.unregister(_nodeIndex, _type, this);
    _registry = registry;
    _nodeIndex = nodeIndex;
    _type = type;
    if (attached) _registry.register(_nodeIndex, _type, this);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registry.register(_nodeIndex, _type, this);
  }

  @override
  void detach() {
    _registry.unregister(_nodeIndex, _type, this);
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    // The anchor may have moved inside an unchanged node; connectors are
    // aimed at paint time, so a repaint is enough.
    _registry.onChange?.call();
  }
}
