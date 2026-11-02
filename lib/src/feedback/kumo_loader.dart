import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';

/// Loader sizes.
enum KumoLoaderSize {
  /// 16px, inline and inside buttons.
  sm(16),

  /// 24px.
  base(24),

  /// 32px, page and panel loading states.
  lg(32);

  const KumoLoaderSize(this.dimension);
  final double dimension;
}

/// Kumo's spinner: an arc that grows, travels and shrinks around a faint
/// track while work of unknown length runs.
///
/// It animates only while it is on screen, and under reduced motion it shows
/// a still arc. It announces itself as "Loading" (override with
/// [semanticLabel]); pair it with text that says what is loading when the
/// wait is longer than a moment.
///
/// ```dart
/// const KumoLoader()
/// const KumoLoader(size: KumoLoaderSize.lg, semanticLabel: 'Loading deployments')
/// ```
class KumoLoader extends StatefulWidget {
  const KumoLoader({
    super.key,
    this.size = KumoLoaderSize.base,
    this.dimension,
    this.color,
    this.dangerouslySetColor,
    this.semanticLabel,
  });

  final KumoLoaderSize size;

  /// Exact size in px; overrides [size].
  final double? dimension;

  /// Defaults to the surrounding text color.
  final KumoColor? color;
  final Color? dangerouslySetColor;
  /// Accessible name. Defaults to [KumoStrings.loading]; pass an empty
  /// string when surrounding text already says what is loading.
  final String? semanticLabel;

  @override
  State<KumoLoader> createState() => _KumoLoaderState();
}

class _KumoLoaderState extends State<KumoLoader> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (KumoMotion.reduceMotion(context)) {
      _controller?.dispose();
      _controller = null;
    } else {
      // Repeats only while mounted; TickerMode pauses it off screen.
      _controller ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.dangerouslySetColor ??
        (widget.color != null ? context.kumo.color(widget.color!) : DefaultTextStyle.of(context).style.color) ??
        context.kumo.colors.textDefault;
    final d = widget.dimension ?? widget.size.dimension;
    final controller = _controller;
    final painter = controller == null
        ? _LoaderPainter(color: color, t: 0.4, still: true)
        : _LoaderPainter(color: color, t: 0, repaint: controller);
    return Semantics(
      label: widget.semanticLabel ?? context.kumoStrings.loading,
      liveRegion: true,
      child: SizedBox.square(dimension: d, child: CustomPaint(painter: painter)),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({required this.color, required this.t, this.still = false, AnimationController? repaint})
      : _controller = repaint,
        super(repaint: repaint);

  final Color color;
  final double t;
  final bool still;
  final AnimationController? _controller;

  @override
  void paint(Canvas canvas, Size size) {
    // Same geometry as Kumo's SVG: r 9.5 in a 24 box with a 2px stroke.
    final scale = size.width / 24;
    final center = size.center(Offset.zero);
    final radius = 9.5 * scale;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, stroke..color = color.withValues(alpha: color.a * 0.1));

    final circumference = 2 * math.pi * radius;
    final elapsed = (_controller?.value ?? t) * 6; // seconds into a 6s loop
    final rotation = still ? 0.0 : (elapsed % 2) / 2 * 2 * math.pi;
    double dash;
    double offset;
    if (still) {
      dash = 0.28 * circumference;
      offset = 0;
    } else {
      // Kumo animates dasharray 0 -> 42 -> 42 and dashoffset 0 -> -16 -> -59
      // over 1.5s, in units of the 24px viewBox.
      final p = (elapsed % 1.5) / 1.5;
      final first = p < 0.5;
      final k = first ? p / 0.5 : (p - 0.5) / 0.5;
      dash = (first ? 42 * k : 42) * scale;
      offset = (first ? -16 * k : -16 - 43 * k) * scale;
    }
    if (dash <= 0.01) return;
    final start = -offset / radius + rotation;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      math.min(dash, circumference) / radius,
      false,
      stroke..color = color,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.color != color || old.still != still || old.t != t;
}
