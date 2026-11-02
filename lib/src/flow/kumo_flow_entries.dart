part of 'kumo_flow_diagram.dart';

/// One entry in a [KumoFlowDiagram]: a [KumoFlowNode], a [KumoFlowParallel]
/// group of branches, or a [KumoFlowList] sequence.
///
/// Entries describe the diagram's structure; the diagram turns them into
/// widgets, measures the nodes and draws the connectors. Like Material's
/// `Step`, they are plain configuration objects, not widgets, so they only
/// work as children of a diagram, a parallel group or a list.
///
/// ```dart
/// const KumoFlowDiagram(children: [
///   KumoFlowNode(label: 'Request'),
///   KumoFlowParallel(children: [
///     KumoFlowNode(label: 'WAF'),
///     KumoFlowNode(label: 'Rate limit'),
///   ]),
///   KumoFlowNode(label: 'Origin'),
/// ])
/// ```
@immutable
sealed class KumoFlowEntry {
  const KumoFlowEntry();
}

/// A single step in a [KumoFlowDiagram] (Kumo's `Flow.Node`).
///
/// By default it renders Kumo's node card: base surface, 6px corners, a 1px
/// ring and a small shadow around 14px text. Pass [label] for text, [child]
/// for other content inside the same card, or [render] to replace the card
/// entirely (Kumo's `render` prop).
///
/// Give it [onPress] to make it pressable; [selected] then marks the node the
/// rest of the screen is showing details for.
///
/// ```dart
/// KumoFlowNode(
///   id: 'worker',
///   label: 'image-resizer',
///   selected: selectedId == 'worker',
///   onPress: () => setState(() => selectedId = 'worker'),
/// )
/// ```
final class KumoFlowNode extends KumoFlowEntry {
  const KumoFlowNode({
    this.id,
    this.label,
    this.child,
    this.render,
    this.disabled = false,
    this.selected = false,
    this.onPress,
    this.semanticLabel,
  }) : assert(label == null || child == null, 'Pass label or child, not both'),
       assert(
         render == null || (label == null && child == null),
         'render replaces the node card; put the content inside it',
       );

  /// Stable identity (Kumo's `id`). Keeps the node's widget state when nodes
  /// before it are added or removed, and names it in [KumoFlowGeometry].
  /// Must be unique within the diagram.
  final String? id;

  /// Text shown in the node card, also its screen reader label.
  final String? label;

  /// Content shown inside the default node card, for anything beyond a label.
  final Widget? child;

  /// Replaces the node card with your own widget. The diagram still measures
  /// it, positions it and connects it. Its own buttons stay reachable by
  /// screen readers, because a custom node is not merged into one element.
  ///
  /// ```dart
  /// KumoFlowNode(render: Container(width: 16, height: 16, decoration: dot))
  /// ```
  final Widget? render;

  /// Greys out every connector that touches this node (40% opacity), and
  /// blocks [onPress]. Kumo does not restyle the node itself, so say it in
  /// the label as well ("Backup handler, paused").
  final bool disabled;

  /// Marks the node as the current selection: tinted background and a 2px
  /// ring, announced as selected.
  final bool selected;

  /// Makes the node pressable. Feedback starts on pointer-down, Enter and
  /// Space activate it, and the hit area grows to 44x44 on touch without
  /// changing the diagram's geometry.
  final VoidCallback? onPress;

  /// Screen reader label when [label] is not set or does not say enough.
  final String? semanticLabel;
}

/// How branches of different sizes line up inside a [KumoFlowParallel].
enum KumoFlowParallelAlign {
  /// Branches start at the group's leading edge (left in a horizontal LTR
  /// flow, top in a vertical one). Kumo's default.
  start,

  /// Branches end at the trailing edge of the widest branch (right in a
  /// horizontal LTR flow, bottom in a vertical one). Kumo's `align="end"`.
  end,
}

/// Parallel branches (Kumo's `Flow.Parallel`).
///
/// The step before the group connects to the first node of every branch, and
/// the last node of every branch connects to the step after it. Two parallel
/// groups next to each other are not connected. Use a [KumoFlowList] as a
/// branch to give it several steps.
///
/// ```dart
/// KumoFlowParallel(children: [
///   KumoFlowList(children: [
///     KumoFlowNode(label: 'Validate token'),
///     KumoFlowNode(label: 'Load session'),
///   ]),
///   KumoFlowNode(label: 'Rate limit'),
/// ])
/// ```
final class KumoFlowParallel extends KumoFlowEntry {
  const KumoFlowParallel({required this.children, this.align = KumoFlowParallelAlign.start});

  /// One entry per branch.
  final List<KumoFlowEntry> children;
  final KumoFlowParallelAlign align;
}

/// A sequence of connected steps (Kumo's `Flow.List`). The diagram itself is
/// a list; use this inside a [KumoFlowParallel] for a branch with more than
/// one step. Entries outside connect to its first and last node only.
///
/// ```dart
/// KumoFlowList(children: [
///   KumoFlowNode(label: 'Cache lookup'),
///   KumoFlowNode(label: 'Serve from cache'),
/// ])
/// ```
final class KumoFlowList extends KumoFlowEntry {
  const KumoFlowList({required this.children});
  final List<KumoFlowEntry> children;
}
