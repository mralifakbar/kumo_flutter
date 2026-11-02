import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../feedback/kumo_loader.dart';
import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'data_hover_scope.dart';

/// One item in a [KumoTree].
///
/// ```dart
/// const KumoTreeNode(
///   id: 'src',
///   label: 'src',
///   icon: KumoIcons.folder,
///   children: [KumoTreeNode(id: 'src/index.ts', label: 'index.ts', icon: KumoIcons.fileTs)],
/// )
/// ```
@immutable
class KumoTreeNode {
  const KumoTreeNode({
    required this.id,
    required this.label,
    this.icon,
    this.expandedIcon,
    this.children,
    this.hasChildren = false,
    this.trailing,
    this.disabled = false,
  });

  /// Unique across the whole tree.
  final Object id;
  final String label;

  /// Leading icon, 16px.
  final IconData? icon;

  /// Icon while expanded (an open folder). Defaults to [icon].
  final IconData? expandedIcon;

  /// Child nodes. Leave null and set [hasChildren] to load them on first
  /// expand through [KumoTree.loadChildren].
  final List<KumoTreeNode>? children;

  /// The node has children that are not loaded yet.
  final bool hasChildren;

  /// Content at the row's end (a count, a badge).
  final Widget? trailing;
  final bool disabled;

  /// Whether the node can expand.
  bool get isBranch => children != null ? children!.isNotEmpty : hasChildren;
}

/// A nested list of expandable items: files in a Worker bundle, objects in
/// an R2 bucket, zones grouped by account.
///
/// ```dart
/// KumoTree(
///   nodes: nodes,
///   expanded: expanded,
///   onExpandedChange: (ids) => setState(() => expanded = ids),
///   value: selectedId,
///   onValueChange: (id) => setState(() => selectedId = id),
/// )
/// ```
///
/// * Controlled: [expanded] and [value] come from you; the tree reports
///   changes and keeps only transient state (focus, loaded children).
/// * Pressing a row selects it; pressing a branch also toggles it (turn
///   off with [expandOnPress]).
/// * Keyboard, as in the ARIA tree pattern: Up and Down move, Right expands
///   or moves to the first child, Left collapses or moves to the parent,
///   Home and End jump, Enter and Space select. Tab enters and leaves the
///   tree at one row.
/// * Children slide open and closed, clipped so rows never reflow mid
///   animation; reduced motion opens them instantly.
/// * Lazy children: give a node `hasChildren: true` and no `children`, and
///   pass [loadChildren]. A loading row shows while it runs; a failed load
///   shows [loadErrorText] and retries on press.
class KumoTree extends StatefulWidget {
  const KumoTree({
    super.key,
    required this.nodes,
    this.expanded = const {},
    this.onExpandedChange,
    this.value,
    this.onValueChange,
    this.loadChildren,
    this.expandOnPress = true,
    this.showGuides = false,
    this.indent = KumoSpace.s4,
    this.loadErrorText,
    this.semanticLabel,
  });

  final List<KumoTreeNode> nodes;

  /// Ids of expanded nodes.
  final Set<Object> expanded;
  final ValueChanged<Set<Object>>? onExpandedChange;

  /// Id of the selected node.
  final Object? value;
  final ValueChanged<Object>? onValueChange;

  /// Loads the children of a node with `hasChildren: true` and no
  /// `children`. Results are cached for the life of the tree.
  final Future<List<KumoTreeNode>> Function(KumoTreeNode node)? loadChildren;

  /// Pressing a branch row also expands or collapses it.
  final bool expandOnPress;

  /// Draw a hairline down each level, connecting children to their parent.
  final bool showGuides;

  /// Indent per level.
  final double indent;

  /// Shown when [loadChildren] fails.
  final String? loadErrorText;

  /// Names the tree for screen readers.
  final String? semanticLabel;

  @override
  State<KumoTree> createState() => _KumoTreeState();
}

class _Entry {
  _Entry(this.node, this.parent, this.depth);
  final KumoTreeNode node;
  final _Entry? parent;
  final int depth;
}

class _KumoTreeState extends State<KumoTree> {
  final Map<Object, FocusNode> _focus = {};
  final Map<Object, List<KumoTreeNode>> _loaded = {};
  final Set<Object> _loading = {};
  final Set<Object> _failed = {};
  Object? _tabStop;
  List<_Entry> _visible = const [];

  @override
  void dispose() {
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  FocusNode _nodeFor(Object id) => _focus.putIfAbsent(id, () => FocusNode(debugLabel: 'KumoTree $id'));

  List<KumoTreeNode>? _childrenOf(KumoTreeNode node) => node.children ?? _loaded[node.id];

  bool _isExpanded(KumoTreeNode node) => node.isBranch && widget.expanded.contains(node.id);

  void _setExpanded(KumoTreeNode node, bool open) {
    if (!node.isBranch || node.disabled) return;
    final next = {...widget.expanded};
    open ? next.add(node.id) : next.remove(node.id);
    widget.onExpandedChange?.call(next);
  }

  void _load(KumoTreeNode node, {bool retry = false}) {
    final loader = widget.loadChildren;
    if (loader == null || node.children != null || _loaded.containsKey(node.id)) return;
    // A failed load waits for a press on the error row.
    if (_failed.contains(node.id) && !retry) return;
    if (!_loading.add(node.id)) return;
    _failed.remove(node.id);
    // Started after this frame so the loading row's setState is never
    // called during build.
    scheduleMicrotask(() async {
      try {
        final children = await loader(node);
        if (!mounted) return;
        setState(() {
          _loading.remove(node.id);
          _loaded[node.id] = children;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading.remove(node.id);
          _failed.add(node.id);
        });
      }
    });
  }

  void _collectVisible(List<KumoTreeNode> nodes, _Entry? parent, int depth, List<_Entry> out) {
    for (final node in nodes) {
      final entry = _Entry(node, parent, depth);
      out.add(entry);
      if (_isExpanded(node)) {
        final kids = _childrenOf(node);
        if (kids != null) _collectVisible(kids, entry, depth + 1, out);
      }
    }
  }

  void _moveFocus(Object id) {
    setState(() => _tabStop = id);
    _nodeFor(id).requestFocus();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final index = _visible.indexWhere((e) => _focus[e.node.id]?.hasPrimaryFocus ?? false);
    if (index < 0) return KeyEventResult.ignored;
    final entry = _visible[index];
    final node = entry.node;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
    final back = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (index + 1 < _visible.length) _moveFocus(_visible[index + 1].node.id);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (index > 0) _moveFocus(_visible[index - 1].node.id);
    } else if (key == LogicalKeyboardKey.home) {
      _moveFocus(_visible.first.node.id);
    } else if (key == LogicalKeyboardKey.end) {
      _moveFocus(_visible.last.node.id);
    } else if (key == forward) {
      if (!node.isBranch) return KeyEventResult.handled;
      if (!_isExpanded(node)) {
        _setExpanded(node, true);
      } else if (index + 1 < _visible.length && _visible[index + 1].parent?.node.id == node.id) {
        _moveFocus(_visible[index + 1].node.id);
      }
    } else if (key == back) {
      if (_isExpanded(node)) {
        _setExpanded(node, false);
      } else if (entry.parent != null) {
        _moveFocus(entry.parent!.node.id);
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final visible = <_Entry>[];
    _collectVisible(widget.nodes, null, 0, visible);
    _visible = visible;
    // One row is in the Tab order: the last focused, else the selected,
    // else the first.
    final ids = {for (final e in visible) e.node.id};
    if (_tabStop == null || !ids.contains(_tabStop)) {
      _tabStop = ids.contains(widget.value) ? widget.value : (visible.isEmpty ? null : visible.first.node.id);
    }
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _branch(context, widget.nodes, 0),
        ),
      ),
    );
  }

  List<Widget> _branch(BuildContext context, List<KumoTreeNode> nodes, int depth) {
    return [
      for (final node in nodes) ...[
        _row(context, node, depth),
        if (node.isBranch)
          _TreeCollapsible(
            key: ValueKey(('children', node.id)),
            open: _isExpanded(node),
            builder: (context) => _childrenBlock(context, node, depth),
          ),
      ],
    ];
  }

  Widget _childrenBlock(BuildContext context, KumoTreeNode node, int depth) {
    final kids = _childrenOf(node);
    final Widget block;
    if (kids == null) {
      _load(node);
      final failed = _failed.contains(node.id);
      block = KeyedSubtree(
        key: ValueKey(failed ? 'failed' : 'loading'),
        child: _statusRow(context, depth + 1, failed: failed, onRetry: failed ? () => setState(() => _load(node, retry: true)) : null),
      );
    } else {
      block = Column(
        key: const ValueKey('children'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _branch(context, kids, depth + 1),
      );
    }
    // Loading, failed and loaded children cross-fade while the block eases to
    // its new height, so rows below slide instead of jumping.
    return ClipRect(child: KumoSwap(animateSize: true, alignment: AlignmentDirectional.topStart, child: block));
  }

  double _start(int depth) => KumoSpace.s2 + depth * widget.indent;

  Widget _guides(BuildContext context, int depth, Widget child) {
    if (!widget.showGuides || depth == 0) return child;
    return CustomPaint(
      painter: _GuidePainter(
        depth: depth,
        start: _start(0) + 8,
        indent: widget.indent,
        color: context.kumo.colors.line,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
      child: child,
    );
  }

  Widget _statusRow(BuildContext context, int depth, {required bool failed, VoidCallback? onRetry}) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final content = Container(
      constraints: const BoxConstraints(minHeight: KumoSpace.s8),
      padding: EdgeInsetsDirectional.only(start: _start(depth) + 22, end: KumoSpace.s2),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        spacing: KumoSpace.s1_5,
        children: [
          if (failed)
            const KumoIcon(KumoIcons.warningCircle, size: 14, color: KumoColor.textDanger)
          else
            KumoLoader(size: KumoLoaderSize.sm, dimension: 14, semanticLabel: strings.loading),
          Flexible(
            child: Text(
              failed ? (widget.loadErrorText ?? strings.loadFailedRetry) : strings.loading,
              style: kumo.text(size: KumoTextSize.sm, color: failed ? KumoColor.textDanger : KumoColor.textSubtle),
            ),
          ),
        ],
      ),
    );
    final guided = _guides(context, depth, content);
    if (onRetry == null) return guided;
    return KumoPressable(
      onPress: onRetry,
      scaleOnPress: false,
      borderRadius: BorderRadius.circular(KumoRadius.md),
      child: guided,
    );
  }

  Widget _row(BuildContext context, KumoTreeNode node, int depth) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final expanded = _isExpanded(node);
    final selected = widget.value != null && widget.value == node.id;
    final focus = _nodeFor(node.id)..skipTraversal = node.id != _tabStop;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final interactive =
        !node.disabled && (widget.onValueChange != null || (node.isBranch && widget.expandOnPress && widget.onExpandedChange != null));

    return KumoPressable(
      key: ValueKey(('row', node.id)),
      focusNode: focus,
      disabled: node.disabled,
      onPress: interactive
          ? () {
              setState(() => _tabStop = node.id);
              widget.onValueChange?.call(node.id);
              if (node.isBranch && widget.expandOnPress) _setExpanded(node, !expanded);
            }
          : null,
      semanticLabel: node.label,
      semanticHint: node.isBranch ? (expanded ? strings.collapse : strings.expand) : null,
      selected: widget.onValueChange != null ? selected : null,
      expanded: node.isBranch ? expanded : null,
      excludeChildSemantics: node.trailing == null,
      scaleOnPress: false,
      focusRingOffset: -2,
      borderRadius: BorderRadius.circular(KumoRadius.md),
      builder: (context, state) {
        final active = state.active;
        final caret = node.isBranch
            ? AnimatedRotation(
                turns: expanded ? (rtl ? -0.25 : 0.25) : 0,
                duration: KumoMotion.duration(context, KumoDurations.moderate),
                curve: KumoCurves.standard,
                child: KumoIcon(rtl ? KumoIcons.caretLeft : KumoIcons.caretRight, size: 12, color: KumoColor.textSubtle),
              )
            : null;
        final icon = expanded ? (node.expandedIcon ?? node.icon) : node.icon;
        final row = Container(
          constraints: const BoxConstraints(minHeight: KumoSpace.s8),
          padding: EdgeInsetsDirectional.only(start: _start(depth), end: KumoSpace.s2),
          decoration: BoxDecoration(
            color: selected || active ? c.tint : null,
            borderRadius: BorderRadius.circular(KumoRadius.md),
          ),
          child: Opacity(
            opacity: node.disabled ? 0.5 : 1,
            child: Row(
              spacing: KumoSpace.s1_5,
              children: [
                SizedBox.square(dimension: 16, child: Center(child: caret)),
                if (icon != null) KumoIcon(icon, size: 16, color: KumoColor.textSubtle),
                Expanded(
                  child: Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kumo.text(
                      weight: selected ? KumoTypography.medium : KumoTypography.normal,
                      color: selected ? KumoColor.textStrong : KumoColor.textDefault,
                    ),
                  ),
                ),
                if (node.trailing != null) node.trailing!,
              ],
            ),
          ),
        );
        return DataHoverScope(active: active || state.focused, child: _guides(context, depth, row));
      },
    );
  }
}

/// Keeps children mounted while they slide closed, then drops them. The
/// content keeps its full size and is clipped while the height animates.
class _TreeCollapsible extends StatefulWidget {
  const _TreeCollapsible({super.key, required this.open, required this.builder});

  final bool open;
  final WidgetBuilder builder;

  @override
  State<_TreeCollapsible> createState() => _TreeCollapsibleState();
}

class _TreeCollapsibleState extends State<_TreeCollapsible> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: KumoDurations.moderate, value: widget.open ? 1 : 0)
      ..addStatusListener((_) => setState(() {}));
    _curve = CurvedAnimation(parent: _controller, curve: KumoCurves.standard);
  }

  @override
  void didUpdateWidget(_TreeCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    _controller.duration = KumoMotion.duration(context, KumoDurations.moderate);
    widget.open ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed && !widget.open) return const SizedBox.shrink();
    // Height and opacity share the caret's 200ms curve, so the caret, the
    // rows sliding in and their fade all finish together.
    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(opacity: _curve, child: widget.builder(context)),
    );
  }
}

class _GuidePainter extends CustomPainter {
  const _GuidePainter({
    required this.depth,
    required this.start,
    required this.indent,
    required this.color,
    required this.rtl,
  });

  final int depth;
  final double start;
  final double indent;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var level = 0; level < depth; level++) {
      final x = start + level * indent;
      final dx = (rtl ? size.width - x : x).roundToDouble() + 0.5;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.depth != depth || old.start != start || old.indent != indent || old.color != color || old.rtl != rtl;
}
