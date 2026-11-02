import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/kumo_motion.dart';

/// A brief cross-fade between two states of one slot (an icon turning into a
/// spinner, a loader giving way to content, a badge changing status), so the
/// change reads as a change instead of a flash. Give each state's child its
/// own [Key]; a child with the same key and type updates in place.
///
/// * The outgoing child leaves the semantics tree and stops taking pointers
///   at once, so screen readers and taps only ever meet the current state.
/// * The slot takes the incoming child's size from the first frame (the
///   outgoing one overlaps it while it fades), and [animateSize] eases the
///   slot between the two sizes, so neighbors slide instead of jumping.
/// * Reduced motion swaps instantly and the size snaps.
///
/// Internal to the package: not exported.
class KumoSwap extends StatelessWidget {
  const KumoSwap({
    super.key,
    required this.child,
    this.duration = KumoDurations.fast,
    this.alignment = AlignmentDirectional.center,
    this.animateSize = false,
    this.sizeDuration = KumoDurations.moderate,
  });

  final Widget? child;
  final Duration duration;
  final AlignmentGeometry alignment;
  final bool animateSize;
  final Duration sizeDuration;

  @override
  Widget build(BuildContext context) {
    Widget result = AnimatedSwitcher(
      duration: KumoMotion.duration(context, duration),
      switchInCurve: KumoCurves.enter,
      switchOutCurve: KumoCurves.exit,
      transitionBuilder: (child, animation) => _SwapTransition(animation: animation, child: child),
      layoutBuilder: (current, previous) => _SwapLayout(
        alignment: alignment.resolve(Directionality.maybeOf(context) ?? TextDirection.ltr),
        sizedByLast: current != null,
        children: [...previous, ?current],
      ),
      child: child,
    );
    // Under reduced motion the size simply snaps. AnimatedSize is skipped
    // rather than given a zero duration: its render object would finish the
    // animation inside its own layout, which asserts.
    if (animateSize && !KumoMotion.reduceMotion(context)) {
      result = AnimatedSize(
        duration: sizeDuration,
        curve: KumoCurves.standard,
        alignment: alignment,
        clipBehavior: Clip.none,
        child: result,
      );
    }
    return result;
  }
}

/// Fades a [KumoSwap] child and drops it from semantics and hit testing as
/// soon as it starts leaving.
class _SwapTransition extends StatefulWidget {
  const _SwapTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_SwapTransition> createState() => _SwapTransitionState();
}

class _SwapTransitionState extends State<_SwapTransition> {
  bool _leaving = false;

  static bool _isLeaving(AnimationStatus s) => s == AnimationStatus.reverse || s == AnimationStatus.dismissed;

  @override
  void initState() {
    super.initState();
    _leaving = _isLeaving(widget.animation.status);
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(_SwapTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_onStatus);
      widget.animation.addStatusListener(_onStatus);
      _leaving = _isLeaving(widget.animation.status);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    final leaving = _isLeaving(status);
    if (leaving != _leaving && mounted) setState(() => _leaving = leaving);
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: _leaving,
        child: ExcludeSemantics(
          excluding: _leaving,
          child: FadeTransition(opacity: widget.animation, child: widget.child),
        ),
      );
}

/// Lays the swap's children over each other like a [Stack], but sizes itself
/// to the incoming child only, so an outgoing child that is larger never
/// holds the slot open while it fades.
class _SwapLayout extends MultiChildRenderObjectWidget {
  const _SwapLayout({required this.alignment, required this.sizedByLast, required super.children});

  final Alignment alignment;

  /// The last child is the incoming one. False while switching to nothing.
  final bool sizedByLast;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSwapLayout(alignment: alignment, sizedByLast: sizedByLast);

  @override
  void updateRenderObject(BuildContext context, _RenderSwapLayout renderObject) {
    renderObject
      ..alignment = alignment
      ..sizedByLast = sizedByLast;
  }
}

class _SwapParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSwapLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _SwapParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _SwapParentData> {
  _RenderSwapLayout({required Alignment alignment, required bool sizedByLast})
      : _alignment = alignment,
        _sizedByLast = sizedByLast;

  Alignment _alignment;
  set alignment(Alignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  bool _sizedByLast;
  set sizedByLast(bool value) {
    if (value == _sizedByLast) return;
    _sizedByLast = value;
    markNeedsLayout();
  }

  RenderBox? get _sizing => _sizedByLast ? lastChild : null;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SwapParentData) child.parentData = _SwapParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _sizing?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) => _sizing?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) => _sizing?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) => _sizing?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final child = _sizing;
    if (child == null) return null;
    final offset = (child.parentData! as _SwapParentData).offset;
    final distance = child.getDistanceToActualBaseline(baseline);
    return distance == null ? null : distance + offset.dy;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = _sizing;
    return child == null ? constraints.smallest : constraints.constrain(child.getDryLayout(constraints.loosen()));
  }

  @override
  void performLayout() {
    final inner = constraints.loosen();
    var child = firstChild;
    while (child != null) {
      child.layout(inner, parentUsesSize: true);
      child = childAfter(child);
    }
    final sizing = _sizing;
    size = sizing == null ? constraints.smallest : constraints.constrain(sizing.size);
    child = firstChild;
    while (child != null) {
      (child.parentData! as _SwapParentData).offset = _alignment.alongOffset(size - child.size as Offset);
      child = childAfter(child);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
