part of 'kumo_flow_diagram.dart';

/// Tells anchors which node they belong to.
class _FlowNodeScope extends InheritedWidget {
  const _FlowNodeScope({required this.index, required this.anchors, required super.child});

  final int index;
  final _FlowAnchorRegistry anchors;

  @override
  bool updateShouldNotify(_FlowNodeScope old) => old.index != index || old.anchors != anchors;
}

/// The widget the diagram builds for one [KumoFlowNode].
class _FlowNodeView extends StatelessWidget {
  const _FlowNodeView({
    super.key,
    required this.node,
    required this.index,
    required this.position,
    required this.anchors,
    required this.onReveal,
  });

  final KumoFlowNode node;
  final int index;

  /// "Step 2 of 4, branch 1 of 2", read after the node's label.
  final String position;
  final _FlowAnchorRegistry anchors;
  final ValueChanged<int> onReveal;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final sortKey = OrdinalSortKey(index.toDouble());
    final pressable = node.onPress != null;
    final radius = BorderRadius.circular(KumoRadius.md);

    Widget card(KumoPressState? state) {
      final hovered = state?.active ?? false;
      // The resting surface follows hover at once; selection eases its tint
      // and 2px ring in and out over that, from wherever it is.
      final resting = hovered ? kumo.colors.elevated : kumo.colors.base;
      // The label is announced through the node's own semantics, once.
      final content =
          node.child ?? (node.label != null ? ExcludeSemantics(child: Text(node.label!)) : const SizedBox.shrink());
      return TweenAnimationBuilder<double>(
        tween: Tween(end: node.selected ? 1 : 0),
        duration: KumoMotion.duration(context, KumoDurations.fast),
        curve: KumoCurves.standard,
        builder: (context, t, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(resting, kumo.colors.tint, t),
            borderRadius: radius,
            border: KumoRing.border(Color.lerp(kumo.colors.line, kumo.colors.interact, t)!, width: 1 + t),
            boxShadow: KumoShadow.sm.boxShadows,
          ),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s2),
          child: DefaultTextStyle.merge(style: kumo.text(), child: content),
        ),
      );
    }

    final label = node.semanticLabel ?? node.label;
    Widget result;
    if (pressable) {
      result = KumoPressable(
        onPress: node.onPress,
        disabled: node.disabled,
        selected: node.selected,
        semanticLabel: label,
        semanticValue: position,
        borderRadius: radius,
        // The diagram pads the hit area itself so node geometry stays Kumo's.
        minTapTargetSize: 0,
        builder: (context, state) => Semantics(
          sortKey: sortKey,
          onDidGainAccessibilityFocus: () => onReveal(index),
          child: node.render ?? card(state),
        ),
      );
    } else if (node.render != null) {
      result = Semantics(
        container: true,
        sortKey: sortKey,
        label: label,
        value: position,
        selected: node.selected ? true : null,
        enabled: node.disabled ? false : null,
        onDidGainAccessibilityFocus: () => onReveal(index),
        child: MouseRegion(cursor: SystemMouseCursors.basic, child: node.render),
      );
    } else {
      result = MergeSemantics(
        child: Semantics(
          sortKey: sortKey,
          label: label,
          value: position,
          selected: node.selected ? true : null,
          enabled: node.disabled ? false : null,
          onDidGainAccessibilityFocus: () => onReveal(index),
          child: MouseRegion(cursor: SystemMouseCursors.basic, child: card(null)),
        ),
      );
    }

    return _FlowNodeScope(
      index: index,
      anchors: anchors,
      child: FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: (focused) {
            if (focused) onReveal(index);
          },
          child: result,
        ),
      ),
    );
  }
}
