part of 'kumo_charts.dart';

/// A node of a [KumoSankeyChart]: Kumo's `SankeyNodeData`.
///
/// ```dart
/// KumoSankeyNode(name: 'Workers', value: 80000, tooltipData: {'Scripts': 42})
/// ```
@immutable
class KumoSankeyNode {
  const KumoSankeyNode({required this.name, this.id, this.color, this.value, this.tooltipData});

  /// Stable identity for animating between data sets. Defaults to [name].
  final String? id;
  final String name;

  /// Defaults to the chart's `defaultNodeColor`, then the categorical color
  /// for the node's position.
  final Color? color;

  /// Shown with the label when node values are on. A node is at least as
  /// tall as the larger of its inflows and outflows, and at least this.
  final double? value;

  /// Extra `label: value` rows for the default tooltip.
  final Map<String, Object>? tooltipData;

  String get key => id ?? name;

  @override
  bool operator ==(Object other) =>
      other is KumoSankeyNode &&
      other.id == id &&
      other.name == name &&
      other.color == color &&
      other.value == value &&
      mapEquals(other.tooltipData, tooltipData);

  @override
  int get hashCode => Object.hash(id, name, color, value);
}

/// A flow between two nodes, by index into the chart's `nodes`. Kumo's
/// `SankeyLinkData`.
@immutable
class KumoSankeyLink {
  const KumoSankeyLink({required this.source, required this.target, required this.value, this.id});

  final int source;
  final int target;

  /// Flow size; link width is proportional to it.
  final double value;
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is KumoSankeyLink &&
      other.source == source &&
      other.target == target &&
      other.value == value &&
      other.id == id;

  @override
  int get hashCode => Object.hash(source, target, value, id);
}

/// Which column a node without outflows (or inflows) sits in.
enum KumoSankeyNodeAlign {
  /// Sources at the left edge, sinks at the right edge (ECharts default).
  justify,

  /// Each node as far left as its depth allows.
  left,

  /// Each node as far right as its height allows.
  right,
}

/// How links are colored.
enum KumoSankeyLinkColor {
  /// A blend from the source node's color to the target's.
  gradient,

  /// Flat gray (`#d1d5db` at 40%), for diagrams where nodes carry the color.
  gray,
}

/// How a node's value and name are arranged when values are shown.
enum KumoSankeyLabelLayout {
  /// Value on top, name below.
  stacked,

  /// `name value` on one line, for small nodes.
  inline,
}

/// What hovering or pressing a node highlights.
enum KumoSankeyFocus {
  /// The node, its links and the nodes at their other ends (Kumo's
  /// `focus: "adjacency"`).
  adjacency,

  /// Every flow upstream and downstream of the node: the whole path through it.
  path,
}

/// What a Sankey tooltip describes: a node or a link.
@immutable
class KumoSankeyTooltipDetails {
  const KumoSankeyTooltipDetails.node({required KumoSankeyNode this.node, required this.nodeIndex, required this.color})
      : link = null,
        source = null,
        target = null;

  const KumoSankeyTooltipDetails.link({
    required KumoSankeyLink this.link,
    required KumoSankeyNode this.source,
    required KumoSankeyNode this.target,
    required this.color,
  })  : node = null,
        nodeIndex = null;

  final KumoSankeyNode? node;
  final int? nodeIndex;
  final KumoSankeyLink? link;
  final KumoSankeyNode? source;
  final KumoSankeyNode? target;

  /// The node's color, or the source color for a link.
  final Color color;

  bool get isNode => node != null;
}

/// Kumo's `SankeyChart`: flows between nodes, each link as wide as its value.
///
/// ```dart
/// KumoSankeyChart(
///   height: 300,
///   nodes: const [
///     KumoSankeyNode(name: 'Users'),
///     KumoSankeyNode(name: 'Devices'),
///     KumoSankeyNode(name: 'Workers'),
///     KumoSankeyNode(name: 'Tunnels'),
///   ],
///   links: const [
///     KumoSankeyLink(source: 0, target: 2, value: 80000),
///     KumoSankeyLink(source: 0, target: 3, value: 23600),
///     KumoSankeyLink(source: 1, target: 2, value: 42600),
///     KumoSankeyLink(source: 1, target: 3, value: 8200),
///   ],
/// )
/// ```
///
/// Layout follows the d3/ECharts Sankey algorithm: nodes take columns by
/// depth ([nodeAlign]), heights scale to fit the tallest column, and 32
/// relaxation passes pull each node toward the nodes it connects to.
///
/// Hovering (or pressing, on touch) a node or link highlights it with
/// [focus] and shows a tooltip; tapping empty space clears it. With keyboard
/// focus, arrow keys move between nodes, Enter or Space activates
/// [onNodePress] and Escape clears. A screen reader summary lists every flow.
class KumoSankeyChart extends StatefulWidget {
  const KumoSankeyChart({
    super.key,
    required this.nodes,
    required this.links,
    this.height = 400,
    this.nodeWidth = 8,
    this.nodePadding = 10,
    this.showTooltip = true,
    this.showNodeValues,
    this.nodeLabelLayout = KumoSankeyLabelLayout.stacked,
    this.formatValue,
    this.tooltipBuilder,
    this.defaultNodeColor,
    this.left = 0,
    this.right = 0,
    this.linkColor = KumoSankeyLinkColor.gradient,
    this.linkOpacity = 0.5,
    this.nodeAlign = KumoSankeyNodeAlign.justify,
    this.focus = KumoSankeyFocus.adjacency,
    this.onNodePress,
    this.onLinkPress,
    this.loading = false,
    this.error,
    this.onRetry,
    this.emptyMessage = 'No flows to show',
    this.emptyDescription = 'Flows appear once traffic moves between these resources.',
    this.semanticLabel,
  });

  final List<KumoSankeyNode> nodes;
  final List<KumoSankeyLink> links;

  /// Kumo's default is 400.
  final double height;

  /// Node bar thickness. Kumo's default is 8.
  final double nodeWidth;

  /// Vertical gap between nodes in a column. Kumo's default is 10.
  final double nodePadding;
  final bool showTooltip;

  /// Shows node values with the labels. Defaults to true when any node has
  /// a value.
  final bool? showNodeValues;
  final KumoSankeyLabelLayout nodeLabelLayout;

  /// Formats node and link values. Defaults to grouped digits (`103,600`).
  final String Function(double value)? formatValue;

  /// Replaces the default tooltip content (Kumo's `tooltipFormatter`).
  /// Return null to show no tooltip for that item.
  final Widget? Function(BuildContext context, KumoSankeyTooltipDetails details)? tooltipBuilder;

  /// Color for nodes without their own, before the categorical palette.
  final Color? defaultNodeColor;

  /// Space left of the first column, in pixels.
  final double left;

  /// Space right of the last column, in pixels.
  final double right;
  final KumoSankeyLinkColor linkColor;

  /// Link opacity for [KumoSankeyLinkColor.gradient]. Kumo's default is 0.5.
  final double linkOpacity;
  final KumoSankeyNodeAlign nodeAlign;
  final KumoSankeyFocus focus;

  /// Called when a node is pressed (Kumo's `onNodeClick`).
  final void Function(KumoSankeyNode node, int index)? onNodePress;

  /// Called when a link is pressed (Kumo's `onLinkClick`).
  final void Function(KumoSankeyLink link)? onLinkPress;

  /// Shows a static skeleton of nodes and flows, with a sheen while loading.
  final bool loading;

  /// Shows this message with a warning icon in place of the diagram.
  final String? error;

  /// Adds a Retry button to the [error] state.
  final VoidCallback? onRetry;

  /// Title of the state shown when there are no valid links.
  final String emptyMessage;
  final String? emptyDescription;

  /// Leads the screen reader summary.
  final String? semanticLabel;

  @override
  State<KumoSankeyChart> createState() => _KumoSankeyChartState();
}

class _SNode {
  _SNode(this.index, this.key, this.color);

  final int index;
  final String key;
  final Color color;
  final List<_SLink> sourceLinks = [];
  final List<_SLink> targetLinks = [];
  double value = 0;
  int depth = 0;
  int height = 0;
  int layer = 0;
  double x0 = 0;
  double x1 = 0;
  double y0 = 0;
  double y1 = 0;
  double alpha = 1;

  Rect get rect => Rect.fromLTRB(x0, y0, x1, y1);
}

class _SLink {
  _SLink(this.index, this.key, this.source, this.target, this.value);

  final int index;
  final String key;
  final _SNode source;
  final _SNode target;
  final double value;
  double width = 0;

  /// Centre of the link where it leaves [source] and enters [target].
  double y0 = 0;
  double y1 = 0;
  double alpha = 1;

  Path band() => _sankeyBand(source.x1, y0 - width / 2, y0 + width / 2, target.x0, y1 - width / 2, y1 + width / 2);
}

class _SankeyLayout {
  _SankeyLayout(this.nodes, this.links, this.size);

  final List<_SNode> nodes;
  final List<_SLink> links;
  final Size size;

  List<Path>? _bands;

  List<Path> get bands => _bands ??= [for (final l in links) l.band()];

  static _SankeyLayout lerp(_SankeyLayout a, _SankeyLayout b, double t) {
    final fromNodes = {for (final n in a.nodes) n.key: n};
    final nodes = <_SNode>[];
    final byOld = <_SNode, _SNode>{};
    for (final n in b.nodes) {
      final f = fromNodes[n.key];
      final out = _SNode(n.index, n.key, f == null ? n.color : Color.lerp(f.color, n.color, t)!)
        ..value = n.value
        ..layer = n.layer
        ..x0 = f == null ? n.x0 : _lerp(f.x0, n.x0, t)
        ..x1 = f == null ? n.x1 : _lerp(f.x1, n.x1, t)
        ..y0 = f == null ? n.y0 : _lerp(f.y0, n.y0, t)
        ..y1 = f == null ? n.y1 : _lerp(f.y1, n.y1, t)
        ..alpha = f == null ? t : 1;
      nodes.add(out);
      byOld[n] = out;
    }
    final fromLinks = {for (final l in a.links) l.key: l};
    final links = <_SLink>[];
    for (final l in b.links) {
      final f = fromLinks[l.key];
      final out = _SLink(l.index, l.key, byOld[l.source]!, byOld[l.target]!, l.value)
        ..width = f == null ? l.width : _lerp(f.width, l.width, t)
        ..y0 = f == null ? l.y0 : _lerp(f.y0, l.y0, t)
        ..y1 = f == null ? l.y1 : _lerp(f.y1, l.y1, t)
        ..alpha = f == null ? t : 1;
      links.add(out);
    }
    return _SankeyLayout(nodes, links, b.size);
  }
}

/// The d3-sankey layout (as ECharts uses it) for [nodes] and [links] in
/// [area]. Invalid links (out of range, self links, non-positive values)
/// are skipped.
_SankeyLayout _layoutSankey({
  required List<KumoSankeyNode> nodes,
  required List<KumoSankeyLink> links,
  required List<Color> colors,
  required Rect area,
  required Size size,
  required double nodeWidth,
  required double nodePadding,
  required KumoSankeyNodeAlign align,
  int iterations = 32,
}) {
  final sNodes = [for (var i = 0; i < nodes.length; i++) _SNode(i, nodes[i].key, colors[i])];
  final sLinks = <_SLink>[];
  for (var i = 0; i < links.length; i++) {
    final l = links[i];
    if (l.source < 0 || l.source >= nodes.length || l.target < 0 || l.target >= nodes.length) continue;
    if (l.source == l.target || !(l.value > 0)) continue;
    final link = _SLink(i, l.id ?? '${sNodes[l.source].key}->${sNodes[l.target].key}#$i', sNodes[l.source],
        sNodes[l.target], l.value);
    sLinks.add(link);
    link.source.sourceLinks.add(link);
    link.target.targetLinks.add(link);
  }
  for (final n in sNodes) {
    final inSum = n.targetLinks.fold<double>(0, (s, l) => s + l.value);
    final outSum = n.sourceLinks.fold<double>(0, (s, l) => s + l.value);
    n.value = math.max(math.max(inSum, outSum), nodes[n.index].value ?? 0);
  }
  // Only nodes that take part in a flow are laid out.
  final active = sNodes.where((n) => n.sourceLinks.isNotEmpty || n.targetLinks.isNotEmpty).toList();
  final count = active.length;

  var current = <_SNode>{...active};
  var depth = 0;
  while (current.isNotEmpty && depth <= count) {
    final next = <_SNode>{};
    for (final n in current) {
      n.depth = depth;
      for (final l in n.sourceLinks) {
        next.add(l.target);
      }
    }
    current = next;
    depth++;
  }
  current = <_SNode>{...active};
  var height = 0;
  while (current.isNotEmpty && height <= count) {
    final next = <_SNode>{};
    for (final n in current) {
      n.height = height;
      for (final l in n.targetLinks) {
        next.add(l.source);
      }
    }
    current = next;
    height++;
  }
  final maxDepth = active.fold<int>(0, (m, n) => math.max(m, n.depth));
  final layers = maxDepth + 1;
  for (final n in active) {
    n.layer = switch (align) {
      KumoSankeyNodeAlign.left => n.depth,
      KumoSankeyNodeAlign.right => maxDepth - n.height,
      KumoSankeyNodeAlign.justify => n.sourceLinks.isEmpty ? maxDepth : n.depth,
    }
        .clamp(0, maxDepth);
  }
  final columns = List.generate(layers, (_) => <_SNode>[]);
  for (final n in active) {
    columns[n.layer].add(n);
  }
  final kx = layers <= 1 ? 0.0 : (area.width - nodeWidth) / (layers - 1);
  for (final n in active) {
    n.x0 = area.left + n.layer * kx;
    n.x1 = n.x0 + nodeWidth;
  }

  var ky = double.infinity;
  for (final c in columns) {
    final sum = c.fold<double>(0, (s, n) => s + n.value);
    if (sum <= 0) continue;
    ky = math.min(ky, math.max(0, area.height - (c.length - 1) * nodePadding) / sum);
  }
  if (!ky.isFinite) ky = 0;
  final py = nodePadding;

  for (final c in columns) {
    var y = area.top;
    for (final n in c) {
      n.y0 = y;
      n.y1 = y + n.value * ky;
      y = n.y1 + py;
      for (final l in n.sourceLinks) {
        l.width = l.value * ky;
      }
    }
    final spare = (area.bottom - y + py) / (c.length + 1);
    for (var i = 0; i < c.length; i++) {
      c[i].y0 += spare * (i + 1);
      c[i].y1 += spare * (i + 1);
    }
    _reorderLinks(c);
  }

  for (var i = 0; i < iterations; i++) {
    final alpha = math.pow(0.99, i).toDouble();
    final beta = math.max(1 - alpha, (i + 1) / iterations);
    _relaxRightToLeft(columns, alpha, beta, py, area);
    _relaxLeftToRight(columns, alpha, beta, py, area);
  }

  for (final n in active) {
    var y0 = n.y0;
    var y1 = n.y0;
    for (final l in n.sourceLinks) {
      l.y0 = y0 + l.width / 2;
      y0 += l.width;
    }
    for (final l in n.targetLinks) {
      l.y1 = y1 + l.width / 2;
      y1 += l.width;
    }
  }
  return _SankeyLayout(active, sLinks, size);
}

int _byBreadth(_SNode a, _SNode b) => a.y0.compareTo(b.y0);

void _reorderLinks(List<_SNode> column) {
  for (final n in column) {
    n.sourceLinks.sort((a, b) {
      final c = _byBreadth(a.target, b.target);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
    n.targetLinks.sort((a, b) {
      final c = _byBreadth(a.source, b.source);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
  }
}

void _reorderNodeLinks(_SNode node) {
  for (final l in node.targetLinks) {
    l.source.sourceLinks.sort((a, b) {
      final c = _byBreadth(a.target, b.target);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
  }
  for (final l in node.sourceLinks) {
    l.target.targetLinks.sort((a, b) {
      final c = _byBreadth(a.source, b.source);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
  }
}

double _targetTop(_SNode source, _SNode target, double py) {
  var y = source.y0 - (source.sourceLinks.length - 1) * py / 2;
  for (final l in source.sourceLinks) {
    if (identical(l.target, target)) break;
    y += l.width + py;
  }
  for (final l in target.targetLinks) {
    if (identical(l.source, source)) break;
    y -= l.width;
  }
  return y;
}

double _sourceTop(_SNode source, _SNode target, double py) {
  var y = target.y0 - (target.targetLinks.length - 1) * py / 2;
  for (final l in target.targetLinks) {
    if (identical(l.source, source)) break;
    y += l.width + py;
  }
  for (final l in source.sourceLinks) {
    if (identical(l.target, target)) break;
    y -= l.width;
  }
  return y;
}

void _relaxLeftToRight(List<List<_SNode>> columns, double alpha, double beta, double py, Rect area) {
  for (var i = 1; i < columns.length; i++) {
    final column = columns[i];
    for (final target in column) {
      var y = 0.0;
      var w = 0.0;
      for (final l in target.targetLinks) {
        final v = l.value * (target.layer - l.source.layer);
        y += _targetTop(l.source, target, py) * v;
        w += v;
      }
      if (!(w > 0)) continue;
      final dy = (y / w - target.y0) * alpha;
      target.y0 += dy;
      target.y1 += dy;
      _reorderNodeLinks(target);
    }
    column.sort(_byBreadth);
    _resolveCollisions(column, beta, py, area);
  }
}

void _relaxRightToLeft(List<List<_SNode>> columns, double alpha, double beta, double py, Rect area) {
  for (var i = columns.length - 2; i >= 0; i--) {
    final column = columns[i];
    for (final source in column) {
      var y = 0.0;
      var w = 0.0;
      for (final l in source.sourceLinks) {
        final v = l.value * (l.target.layer - source.layer);
        y += _sourceTop(source, l.target, py) * v;
        w += v;
      }
      if (!(w > 0)) continue;
      final dy = (y / w - source.y0) * alpha;
      source.y0 += dy;
      source.y1 += dy;
      _reorderNodeLinks(source);
    }
    column.sort(_byBreadth);
    _resolveCollisions(column, beta, py, area);
  }
}

void _resolveCollisions(List<_SNode> nodes, double alpha, double py, Rect area) {
  if (nodes.isEmpty) return;
  final i = nodes.length >> 1;
  final subject = nodes[i];
  _collideUp(nodes, subject.y0 - py, i - 1, alpha, py);
  _collideDown(nodes, subject.y1 + py, i + 1, alpha, py);
  _collideUp(nodes, area.bottom, nodes.length - 1, alpha, py);
  _collideDown(nodes, area.top, 0, alpha, py);
}

void _collideDown(List<_SNode> nodes, double y, int i, double alpha, double py) {
  for (; i < nodes.length; i++) {
    final n = nodes[i];
    final dy = (y - n.y0) * alpha;
    if (dy > 1e-6) {
      n.y0 += dy;
      n.y1 += dy;
    }
    y = n.y1 + py;
  }
}

void _collideUp(List<_SNode> nodes, double y, int i, double alpha, double py) {
  for (; i >= 0; i--) {
    final n = nodes[i];
    final dy = (n.y1 - y) * alpha;
    if (dy > 1e-6) {
      n.y0 -= dy;
      n.y1 -= dy;
    }
    y = n.y0 - py;
  }
}

class _SankeyFocusSet {
  const _SankeyFocusSet(this.nodes, this.links);

  final Set<int> nodes;
  final Set<int> links;
}

class _KumoSankeyChartState extends State<KumoSankeyChart> with TickerProviderStateMixin {
  late final AnimationController _morph;

  /// Eases nodes and links between dimmed, resting and highlighted when the
  /// hovered or pressed item changes, from wherever they are.
  late final AnimationController _emphasis;
  _SankeyLevels? _emphasisFrom;
  _SankeyLevels? _emphasisTarget;

  /// Holds the emphasis at its start until after the build that changed it,
  /// so the controller never notifies listeners while the tree builds.
  bool _emphasisHold = false;
  late final FocusNode _focusNode;
  _SankeyLayout? _target;
  Object? _targetKey;
  _SankeyLayout? _from;
  bool _dataChanged = false;
  bool _morphPending = false;
  Map<int, TextPainter> _labels = {};
  Object? _labelsKey;

  /// Hovered or pressed item: node index or link index into the widget.
  int? _node;
  int? _link;
  Offset? _pointer;
  bool _touch = false;
  bool _focusHighlight = false;

  @override
  void initState() {
    super.initState();
    _morph = AnimationController(vsync: this, duration: KumoDurations.slow, value: 1)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && _from != null) setState(() => _from = null);
      });
    _emphasis = AnimationController(vsync: this, duration: KumoDurations.quick, value: 1);
    _focusNode = FocusNode(debugLabel: 'KumoSankeyChart');
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void didUpdateWidget(KumoSankeyChart old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.nodes, widget.nodes) || !listEquals(old.links, widget.links)) {
      _dataChanged = true;
      _node = null;
      _link = null;
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _morph.dispose();
    _emphasis.dispose();
    _focusNode.dispose();
    for (final p in _labels.values) {
      p.dispose();
    }
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode _) => _updateFocusHighlight();

  void _updateFocusHighlight() {
    final v = _focusNode.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (v != _focusHighlight && mounted) setState(() => _focusHighlight = v);
  }

  String _format(double v) => widget.formatValue?.call(v) ?? _formatChartNumber(v);

  bool get _showValues => widget.showNodeValues ?? widget.nodes.any((n) => n.value != null);

  List<Color> _colors(KumoChartColors palette) => [
        for (var i = 0; i < widget.nodes.length; i++)
          widget.nodes[i].color ?? widget.defaultNodeColor ?? palette.categorical(i),
      ];

  _SankeyLayout _layoutFor(Size size, KumoChartColors palette) {
    final w = widget;
    final key = (size, w.nodes, w.links, w.nodeWidth, w.nodePadding, w.left, w.right, w.nodeAlign, palette, w.defaultNodeColor);
    if (_target != null && _targetKey == key) return _displayed();
    final pad = size.height * 0.05;
    final next = _layoutSankey(
      nodes: w.nodes,
      links: w.links,
      colors: _colors(palette),
      area: Rect.fromLTRB(w.left, pad, math.max(w.left + w.nodeWidth, size.width - w.right), size.height - pad),
      size: size,
      nodeWidth: w.nodeWidth,
      nodePadding: w.nodePadding,
      align: w.nodeAlign,
    );
    final animate = _dataChanged && _target != null && !KumoMotion.reduceMotion(context);
    _dataChanged = false;
    if (animate) {
      _from = _displayed();
      _target = next;
      _targetKey = key;
      // The morph holds at its start until after this build, so the
      // controller never notifies listeners while the tree is building.
      _morphPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _morphPending = false;
        _morph.forward(from: 0);
      });
    } else {
      _from = null;
      _target = next;
      _targetKey = key;
    }
    return _displayed();
  }

  _SankeyLayout _displayed() {
    final from = _from;
    if (from == null) return _target!;
    final t = _morphPending ? 0.0 : _morph.value;
    if (t >= 1) return _target!;
    return _SankeyLayout.lerp(from, _target!, KumoCurves.standard.transform(t));
  }

  _SankeyLevels _levelsOf(_SankeyFocusSet? focus) {
    final nodes = Float64List(widget.nodes.length);
    final links = Float64List(widget.links.length);
    for (var i = 0; i < nodes.length; i++) {
      nodes[i] = focus == null ? 1 : (focus.nodes.contains(i) ? 2 : 0);
    }
    for (var i = 0; i < links.length; i++) {
      links[i] = focus == null ? 1 : (focus.links.contains(i) ? 2 : 0);
    }
    return _SankeyLevels(nodes, links);
  }

  _SankeyLevels _displayedLevels() {
    final target = _emphasisTarget!;
    final from = _emphasisFrom;
    if (from == null) return target;
    final t = _emphasisHold ? 0.0 : KumoCurves.standard.transform(_emphasis.value);
    return _SankeyLevels.lerp(from, target, t);
  }

  /// The emphasis to paint for [focus], starting a transition when it
  /// changed since the last build.
  _SankeyLevels _emphasisFor(_SankeyFocusSet? focus) {
    final next = _levelsOf(focus);
    final current = _emphasisTarget;
    if (current == null || !current.sameAs(next)) {
      final animate = current != null && current.sameShape(next) && !KumoMotion.reduceMotion(context);
      _emphasisFrom = animate ? _displayedLevels() : null;
      _emphasisTarget = next;
      if (animate) {
        _emphasisHold = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _emphasisHold = false;
          _emphasis.forward(from: 0);
        });
      }
    }
    return _displayedLevels();
  }

  _SankeyFocusSet? _focusSet() {
    final layout = _target;
    if (layout == null) return null;
    if (_link != null) {
      final link = layout.links.where((l) => l.index == _link).firstOrNull;
      if (link == null) return null;
      if (widget.focus == KumoSankeyFocus.path) {
        final up = _trace(link.source, upstream: true);
        final down = _trace(link.target, upstream: false);
        return _SankeyFocusSet({...up.nodes, ...down.nodes}, {link.index, ...up.links, ...down.links});
      }
      return _SankeyFocusSet({link.source.index, link.target.index}, {link.index});
    }
    if (_node != null) {
      final node = layout.nodes.where((n) => n.index == _node).firstOrNull;
      if (node == null) return null;
      if (widget.focus == KumoSankeyFocus.path) {
        final up = _trace(node, upstream: true);
        final down = _trace(node, upstream: false);
        return _SankeyFocusSet({...up.nodes, ...down.nodes}, {...up.links, ...down.links});
      }
      return _SankeyFocusSet(
        {node.index, for (final l in node.sourceLinks) l.target.index, for (final l in node.targetLinks) l.source.index},
        {for (final l in node.sourceLinks) l.index, for (final l in node.targetLinks) l.index},
      );
    }
    return null;
  }

  _SankeyFocusSet _trace(_SNode start, {required bool upstream}) {
    final nodes = <int>{start.index};
    final links = <int>{};
    final queue = [start];
    while (queue.isNotEmpty) {
      final n = queue.removeLast();
      for (final l in upstream ? n.targetLinks : n.sourceLinks) {
        if (links.add(l.index)) {
          final other = upstream ? l.source : l.target;
          if (nodes.add(other.index)) queue.add(other);
        }
      }
    }
    return _SankeyFocusSet(nodes, links);
  }

  (int?, int?) _hitTest(_SankeyLayout layout, Offset p) {
    final slop = _touch ? 8.0 : 2.0;
    for (final n in layout.nodes) {
      if (n.rect.inflate(slop).contains(p)) return (n.index, null);
    }
    final bands = layout.bands;
    for (var i = layout.links.length - 1; i >= 0; i--) {
      if (bands[i].contains(p)) return (null, layout.links[i].index);
    }
    return (null, null);
  }

  void _setHover(Offset? p, {required bool touch, required _SankeyLayout layout}) {
    final (node, link) = p == null ? (null, null) : _hitTest(layout, p);
    if (node == _node && link == _link && p == _pointer && touch == _touch) return;
    setState(() {
      _pointer = p;
      _touch = touch;
      _node = node;
      _link = link;
    });
  }

  void _press(Offset p, _SankeyLayout layout) {
    final (node, link) = _hitTest(layout, p);
    setState(() {
      _pointer = p;
      _node = node;
      _link = link;
    });
    if (node != null) widget.onNodePress?.call(widget.nodes[node], node);
    if (link != null) widget.onLinkPress?.call(widget.links[link]);
  }

  List<_SNode> _keyboardOrder() {
    final nodes = [...?_target?.nodes];
    nodes.sort((a, b) => a.layer != b.layer ? a.layer.compareTo(b.layer) : a.y0.compareTo(b.y0));
    return nodes;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final order = _keyboardOrder();
    if (order.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final current = order.indexWhere((n) => n.index == _node);
    int? next;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowRight) {
      next = current < 0 ? 0 : (current + 1) % order.length;
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowLeft) {
      next = current < 0 ? order.length - 1 : (current - 1 + order.length) % order.length;
    } else if ((key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) && current >= 0) {
      widget.onNodePress?.call(widget.nodes[order[current].index], order[current].index);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape && (_node != null || _link != null)) {
      setState(() {
        _node = null;
        _link = null;
        _pointer = null;
      });
      return KeyEventResult.handled;
    }
    if (next == null) return KeyEventResult.ignored;
    final target = order[next];
    setState(() {
      _node = target.index;
      _link = null;
      _pointer = null;
    });
    return KeyEventResult.handled;
  }

  String _summary() {
    final w = widget;
    final layout = _target;
    final parts = <String>[];
    if (w.semanticLabel != null) parts.add(w.semanticLabel!);
    final links = layout?.links ?? const <_SLink>[];
    parts.add('Sankey chart, ${layout?.nodes.length ?? 0} nodes, ${links.length} ${links.length == 1 ? 'flow' : 'flows'}');
    for (final l in links) {
      parts.add('${w.nodes[l.source.index].name} to ${w.nodes[l.target.index].name}: ${_format(l.value)}');
    }
    return '${parts.join('. ')}.';
  }

  String? _activeValue() {
    final layout = _target;
    if (layout == null) return null;
    final w = widget;
    if (_node != null) {
      final n = layout.nodes.where((n) => n.index == _node).firstOrNull;
      if (n == null) return null;
      final parts = ['${w.nodes[n.index].name}, ${_format(n.value)}'];
      if (n.targetLinks.isNotEmpty) {
        parts.add('from ${n.targetLinks.map((l) => '${w.nodes[l.source.index].name} ${_format(l.value)}').join(', ')}');
      }
      if (n.sourceLinks.isNotEmpty) {
        parts.add('to ${n.sourceLinks.map((l) => '${w.nodes[l.target.index].name} ${_format(l.value)}').join(', ')}');
      }
      return parts.join('; ');
    }
    if (_link != null) {
      final l = layout.links.where((l) => l.index == _link).firstOrNull;
      if (l == null) return null;
      return '${w.nodes[l.source.index].name} to ${w.nodes[l.target.index].name}, ${_format(l.value)}';
    }
    return null;
  }

  Map<int, TextPainter> _labelsFor(KumoThemeData kumo, TextScaler scaler, _SankeyLayout layout) {
    final w = widget;
    final key = (kumo, scaler, w.nodes, w.links, _showValues, w.nodeLabelLayout, layout.size, w.formatValue);
    if (_labelsKey == key) return _labels;
    for (final p in _labels.values) {
      p.dispose();
    }
    _labels = {};
    final color = kumo.colors.textSubtle;
    final nameStyle = kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle, height: 1.3);
    final valueStyle = nameStyle
        .copyWith(fontSize: 11, color: color)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final strongName = nameStyle.copyWith(fontWeight: KumoTypography.semibold);
    final layers = layout.nodes.fold<int>(0, (m, n) => math.max(m, n.layer)) + 1;
    final columnGap = layers <= 1 ? layout.size.width : (layout.size.width - w.left - w.right) / (layers - 1);
    final maxWidth = math.max(48.0, columnGap - w.nodeWidth - 12);
    for (final n in layout.nodes) {
      final node = w.nodes[n.index];
      final showValue = _showValues && node.value != null;
      final InlineSpan span;
      if (!showValue) {
        span = TextSpan(text: node.name, style: nameStyle);
      } else if (w.nodeLabelLayout == KumoSankeyLabelLayout.inline) {
        span = TextSpan(children: [
          TextSpan(text: node.name, style: strongName),
          TextSpan(text: ' ${_format(node.value!)}', style: valueStyle),
        ]);
      } else {
        span = TextSpan(children: [
          TextSpan(text: _format(node.value!), style: valueStyle),
          TextSpan(text: '\n${node.name}', style: strongName),
        ]);
      }
      final rightHalf = n.x0 > layout.size.width / 2;
      _labels[n.index] = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: rightHalf ? TextAlign.right : TextAlign.left,
        textScaler: scaler,
        maxLines: showValue && w.nodeLabelLayout == KumoSankeyLabelLayout.stacked ? 2 : 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
    }
    _labelsKey = key;
    return _labels;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
      final size = Size(width, w.height);
      Widget body;
      final String kind;
      final hasFlows =
          w.links.any((l) => l.value > 0 && l.source != l.target && l.source >= 0 && l.target >= 0 && l.source < w.nodes.length && l.target < w.nodes.length);
      if (w.loading) {
        kind = 'loading';
        body = _ChartSkeleton(
          shape: _SkeletonShape.sankey,
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
      } else if (!hasFlows) {
        kind = 'empty';
        body = _ChartMessage(icon: KumoIcons.flowArrow, title: w.emptyMessage, description: w.emptyDescription);
      } else {
        kind = 'chart';
        body = AnimatedBuilder(
          animation: Listenable.merge([_morph, _emphasis]),
          builder: (context, _) => _buildDiagram(context, size),
        );
      }
      // The skeleton, diagram, error and empty message cross-fade.
      return SizedBox(
        width: width,
        height: w.height,
        child: KumoSwap(duration: KumoDurations.quick, child: KeyedSubtree(key: ValueKey(kind), child: body)),
      );
    });
  }

  Widget _buildDiagram(BuildContext context, Size size) {
    final kumo = context.kumo;
    final palette = KumoChartColors.forBrightness(kumo.brightness);
    final layout = _layoutFor(size, palette);
    final labels = _labelsFor(kumo, MediaQuery.textScalerOf(context), _target!);
    final levels = _emphasisFor(_focusSet());

    Widget? tooltip;
    if (widget.showTooltip && (_node != null || _link != null)) {
      tooltip = _buildTooltip(context, palette);
    }
    Offset anchor;
    if (_pointer != null) {
      anchor = _touch ? Offset(_pointer!.dx + 8, math.max(0, _pointer!.dy - 56)) : _pointer!;
    } else if (_node != null) {
      final n = layout.nodes.where((n) => n.index == _node).firstOrNull;
      anchor = n == null ? Offset.zero : Offset(n.x1, n.y0);
    } else {
      anchor = Offset.zero;
    }

    Widget diagram = Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: size,
          painter: _SankeyPainter(
            layout: layout,
            labels: labels,
            levels: levels,
            linkColor: widget.linkColor,
            linkOpacity: widget.linkOpacity,
          ),
        ),
        if (tooltip != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomSingleChildLayout(delegate: _ChartTooltipLayout(anchor: anchor), child: tooltip),
            ),
          ),
      ],
    );

    diagram = KumoFocusRing(
      visible: _focusHighlight,
      borderRadius: BorderRadius.circular(KumoRadius.lg),
      child: diagram,
    );

    diagram = MouseRegion(
      cursor: (_node != null || _link != null) && (widget.onNodePress != null || widget.onLinkPress != null)
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onHover: (e) => _setHover(e.localPosition, touch: false, layout: layout),
      onExit: (_) {
        if (!_touch) _setHover(null, touch: false, layout: layout);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          _touch = d.kind != PointerDeviceKind.mouse;
          if (_touch) {
            final (node, link) = _hitTest(layout, d.localPosition);
            setState(() {
              _pointer = d.localPosition;
              _node = node;
              _link = link;
            });
          }
        },
        onTapUp: (d) => _press(d.localPosition, layout),
        child: diagram,
      ),
    );

    diagram = TapRegion(
      onTapOutside: (_) {
        if (_touch && (_node != null || _link != null)) {
          setState(() {
            _node = null;
            _link = null;
            _pointer = null;
          });
        }
      },
      child: diagram,
    );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      onFocusChange: (_) => _updateFocusHighlight(),
      child: Semantics(
        container: true,
        label: _summary(),
        value: _activeValue(),
        child: ExcludeSemantics(child: diagram),
      ),
    );
  }

  Widget? _buildTooltip(BuildContext context, KumoChartColors palette) {
    final layout = _target!;
    final w = widget;
    final colors = _colors(palette);
    KumoSankeyTooltipDetails details;
    if (_node != null) {
      details = KumoSankeyTooltipDetails.node(node: w.nodes[_node!], nodeIndex: _node!, color: colors[_node!]);
    } else {
      final l = layout.links.where((l) => l.index == _link).firstOrNull;
      if (l == null) return null;
      details = KumoSankeyTooltipDetails.link(
        link: w.links[l.index],
        source: w.nodes[l.source.index],
        target: w.nodes[l.target.index],
        color: colors[l.source.index],
      );
    }
    if (w.tooltipBuilder != null) {
      final custom = w.tooltipBuilder!(context, details);
      return custom == null ? null : _ChartTooltipSurface(child: custom);
    }
    final kumo = context.kumo;
    final strong = kumo.text(size: KumoTextSize.xs, weight: KumoTypography.semibold);
    if (details.isNode) {
      final node = details.node!;
      return _ChartTooltipSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(spacing: 6, children: [
              _ChartDot(color: details.color, size: 10),
              Flexible(child: Text(node.name, style: strong)),
            ]),
            if (node.tooltipData != null)
              for (final e in node.tooltipData!.entries)
                Padding(
                  padding: const EdgeInsets.only(top: KumoSpace.s1),
                  child: Row(children: [
                    Expanded(child: Text(e.key, style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle))),
                    const SizedBox(width: KumoSpace.s4),
                    Text(
                      e.value is num ? _format((e.value as num).toDouble()) : '${e.value}',
                      style: strong.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ]),
                ),
          ],
        ),
      );
    }
    final link = details.link!;
    return _ChartTooltipSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ChartDot(color: colors[link.source], size: 10),
              Text(details.source!.name, style: strong),
              const KumoIcon(KumoIcons.arrowRight, size: 12, color: KumoColor.textSubtle),
              _ChartDot(color: colors[link.target], size: 10),
              Text(details.target!.name, style: strong),
            ],
          ),
          const SizedBox(height: KumoSpace.s1),
          Text(_format(link.value), style: strong.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// Emphasis per node and link, indexed like the widget's lists: 0 dimmed
/// (another item is highlighted), 1 resting, 2 highlighted. Fractions are
/// mid-transition.
class _SankeyLevels {
  const _SankeyLevels(this.nodes, this.links);

  final Float64List nodes;
  final Float64List links;

  bool sameShape(_SankeyLevels o) => o.nodes.length == nodes.length && o.links.length == links.length;

  bool sameAs(_SankeyLevels o) => sameShape(o) && listEquals(o.nodes, nodes) && listEquals(o.links, links);

  static _SankeyLevels lerp(_SankeyLevels a, _SankeyLevels b, double t) {
    final nodes = Float64List(b.nodes.length);
    final links = Float64List(b.links.length);
    for (var i = 0; i < nodes.length; i++) {
      nodes[i] = _lerp(a.nodes[i], b.nodes[i], t);
    }
    for (var i = 0; i < links.length; i++) {
      links[i] = _lerp(a.links[i], b.links[i], t);
    }
    return _SankeyLevels(nodes, links);
  }
}

class _SankeyPainter extends CustomPainter {
  _SankeyPainter({
    required this.layout,
    required this.labels,
    required this.levels,
    required this.linkColor,
    required this.linkOpacity,
  });

  final _SankeyLayout layout;
  final Map<int, TextPainter> labels;
  final _SankeyLevels levels;
  final KumoSankeyLinkColor linkColor;
  final double linkOpacity;

  static const Color _gray = Color(0xFFD1D5DB);

  static double _level(Float64List list, int i) => i < list.length ? list[i] : 1;

  @override
  void paint(Canvas canvas, Size size) {
    final bands = layout.bands;
    final base = linkColor == KumoSankeyLinkColor.gradient ? linkOpacity : 0.4;
    final focusedOpacity = math.min(1.0, base + 0.25);
    for (var i = 0; i < layout.links.length; i++) {
      final l = layout.links[i];
      final level = _level(levels.links, l.index);
      final emphasis = level <= 1 ? _lerp(0.08, base, level) : _lerp(base, focusedOpacity, level - 1);
      final opacity = emphasis * l.alpha;
      final paint = Paint();
      if (linkColor == KumoSankeyLinkColor.gradient) {
        paint.shader = ui.Gradient.linear(Offset(l.source.x1, 0), Offset(l.target.x0, 0), [
          l.source.color.withValues(alpha: opacity),
          l.target.color.withValues(alpha: opacity),
        ]);
      } else {
        paint.color = _gray.withValues(alpha: opacity);
      }
      canvas.drawPath(bands[i], paint);
    }
    for (final n in layout.nodes) {
      final level = _level(levels.nodes, n.index).clamp(0.0, 1.0);
      final alpha = _lerp(0.25, 1, level) * n.alpha;
      canvas.drawRect(n.rect, Paint()..color = n.color.withValues(alpha: n.color.a * alpha));
      final label = labels[n.index];
      if (label == null) continue;
      final rightHalf = n.x0 > size.width / 2;
      final dx = rightHalf ? n.x0 - 5 - label.width : n.x1 + 5;
      final dy = n.rect.center.dy - label.height / 2;
      if (level < 1) {
        // Dimmed labels fade to 40%, like the nodes stepping back.
        canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, _lerp(0.4, 1, level)));
        label.paint(canvas, Offset(dx, dy));
        canvas.restore();
      } else {
        label.paint(canvas, Offset(dx, dy));
      }
    }
  }

  @override
  bool shouldRepaint(_SankeyPainter old) =>
      !identical(old.layout, layout) ||
      !identical(old.labels, labels) ||
      !old.levels.sameAs(levels) ||
      old.linkColor != linkColor ||
      old.linkOpacity != linkOpacity;
}
