import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';

/// Kumo's `SkeletonLine`: a placeholder bar that stands in for a line of
/// text while it loads.
///
/// ```dart
/// const Column(children: [
///   KumoSkeletonLine(widthFactor: 0.5),
///   SizedBox(height: 8),
///   KumoSkeletonLine(),
/// ])
/// const KumoSkeletonLine(animate: true, semanticLabel: 'Loading DNS records')
/// ```
///
/// Without [widthFactor], each line picks a width between [minWidth] and
/// [maxWidth] percent of the available width once, when it mounts, so a stack
/// of lines looks like ragged text.
///
/// **Static by default.** Kumo's web shimmer loops forever. Here the line
/// only shimmers when [animate] is true, which callers should tie to a real
/// loading state, so a placeholder that stays on screen (a stalled request,
/// a list that never fills) stops moving instead of drawing the eye
/// indefinitely. The shimmer also pauses off screen (`TickerMode`) and is
/// replaced by the still line under reduced motion.
class KumoSkeletonLine extends StatefulWidget {
  const KumoSkeletonLine({
    super.key,
    this.widthFactor,
    this.minWidth = 30,
    this.maxWidth = 100,
    this.height = 8,
    this.blockHeight,
    this.animate = false,
    this.semanticLabel,
  }) : assert(widthFactor == null || (widthFactor >= 0 && widthFactor <= 1)),
       assert(minWidth >= 0 && maxWidth <= 100 && minWidth <= maxWidth);

  /// Exact width as a fraction of the available width (0 to 1). Overrides
  /// [minWidth] and [maxWidth].
  final double? widthFactor;

  /// Lower bound of the random width, in percent of the available width.
  final double minWidth;

  /// Upper bound of the random width, in percent.
  final double maxWidth;

  /// Bar height. Kumo's default is 0.5rem (8px).
  final double height;

  /// Height of a box that vertically centers the bar, to stand in for text of
  /// a known line height without the layout jumping when the text arrives.
  final double? blockHeight;

  /// Runs the shimmer. Pass the loading flag, never a constant `true`.
  final bool animate;

  /// Announces the placeholder. Leave null on all but one line of a group,
  /// so a screen reader hears "Loading DNS records" once.
  final String? semanticLabel;

  @override
  State<KumoSkeletonLine> createState() => _KumoSkeletonLineState();
}

// Kumo's skeleton colors are hard-coded in its CSS (neutral-100 in light,
// white at 6% in dark) rather than theme tokens.
const Color _lightFill = Color(0xFFF3F4F6);
const Color _darkFill = Color(0x0FFFFFFF);
const Color _lightShine = Color(0x14000000);
const Color _darkShine = Color(0x0DFFFFFF);

class _KumoSkeletonLineState extends State<KumoSkeletonLine> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final double _randomFactor;
  late final double _phase;
  late final Duration _duration;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _randomFactor = (widget.minWidth + random.nextDouble() * (widget.maxWidth - widget.minWidth)) / 100;
    // Kumo staggers lines with a random 1.3-1.7s period and 0-0.5s delay.
    final seconds = 1.3 + random.nextDouble() * 0.4;
    _phase = random.nextDouble() * 0.5 / seconds;
    _duration = Duration(milliseconds: (seconds * 1000).round());
  }

  bool get _shouldRun => widget.animate && !KumoMotion.reduceMotion(context);

  void _sync() {
    if (_shouldRun) {
      _controller ??= AnimationController(vsync: this, duration: _duration)..repeat();
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KumoSkeletonLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _sync();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.kumo.isDark;
    final controller = _controller;
    Widget line = ClipRRect(
      borderRadius: BorderRadius.circular(KumoRadius.xs),
      child: SizedBox(
        height: widget.height,
        child: CustomPaint(
          painter: _ShimmerPainter(
            fill: dark ? _darkFill : _lightFill,
            shine: dark ? _darkShine : _lightShine,
            phase: _phase,
            progress: controller,
          ),
        ),
      ),
    );
    line = FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widget.widthFactor ?? _randomFactor,
      child: line,
    );
    if (widget.blockHeight != null) {
      line = SizedBox(
        height: widget.blockHeight,
        child: Center(child: line),
      );
    }
    return widget.semanticLabel == null
        ? ExcludeSemantics(child: line)
        : Semantics(
            label: widget.semanticLabel,
            child: ExcludeSemantics(child: line),
          );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.fill, required this.shine, required this.phase, this.progress})
    : super(repaint: progress);

  final Color fill;
  final Color shine;
  final double phase;
  final Animation<double>? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = fill);
    final p = progress;
    if (p == null) return;
    // translateX(-100%) to translateX(100%), ease-in-out, like Kumo's keyframes.
    final t = Curves.easeInOut.transform((p.value - phase) % 1.0);
    final dx = (t * 2 - 1) * size.width;
    final band = rect.shift(Offset(dx, 0));
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [shine.withValues(alpha: 0), shine, shine.withValues(alpha: 0)],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.fill != fill || old.shine != shine || old.progress != progress || old.phase != phase;
}
