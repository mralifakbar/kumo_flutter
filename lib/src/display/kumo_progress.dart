import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../feedback/kumo_loader.dart';
import '../feedback/kumo_swap.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_meter.dart';

/// Shape of a [KumoProgress].
enum KumoProgressVariant {
  /// A horizontal track, like [KumoMeter]'s.
  linear,

  /// A ring that fills clockwise from the top.
  circular,
}

/// [KumoProgress] sizes.
enum KumoProgressSize {
  /// 4px track, 16px ring.
  sm(4, 16, 2),

  /// 8px track (Kumo's meter `h-2`), 24px ring.
  base(8, 24, 2.5),

  /// 12px track, 40px ring.
  lg(12, 40, 3.5);

  const KumoProgressSize(this.trackHeight, this.ringDiameter, this.ringStroke);
  final double trackHeight;
  final double ringDiameter;
  final double ringStroke;
}

/// Task progress: an upload, a deployment, a migration.
///
/// ```dart
/// KumoProgress(value: uploaded, max: total, label: 'Uploading assets', showValue: true)
/// const KumoProgress(variant: KumoProgressVariant.circular, value: 40)
/// const KumoProgress(label: 'Provisioning database') // indeterminate
/// ```
///
/// Pass a [value] whenever the amount of work is known. A null [value] is
/// the indeterminate state: a looping animation that means "working, length
/// unknown". Show it only while the work runs and remove it when the work
/// ends, because nothing in Kumo loops forever. It pauses off screen and
/// stands still under reduced motion.
///
/// Kumo has no progress component; this one is drawn from [KumoMeter]'s
/// track and indicator tokens. Use [KumoMeter] for a measured level (quota,
/// storage) and this for work that finishes.
class KumoProgress extends StatefulWidget {
  const KumoProgress({
    super.key,
    this.value,
    this.max = 100,
    this.variant = KumoProgressVariant.linear,
    this.size = KumoProgressSize.base,
    this.label,
    this.showValue = false,
    this.tone = KumoMeterTone.brand,
    this.semanticLabel,
  }) : assert(max > 0);

  /// Work done, 0 to [max]. Null means indeterminate.
  final double? value;
  final double max;
  final KumoProgressVariant variant;
  final KumoProgressSize size;

  /// What is in progress, shown as 12px subtle text.
  final String? label;

  /// Shows the percentage next to the label. Ignored while indeterminate.
  final bool showValue;

  /// Indicator color with its paired text color.
  final KumoMeterTone tone;

  /// Accessible name when there is no visible [label]. Defaults to
  /// [KumoStrings.loading].
  final String? semanticLabel;

  @override
  State<KumoProgress> createState() => _KumoProgressState();
}

class _KumoProgressState extends State<KumoProgress> with SingleTickerProviderStateMixin {
  AnimationController? _loop;

  bool get _indeterminate => widget.value == null;

  void _sync() {
    final linearLoop =
        _indeterminate && widget.variant == KumoProgressVariant.linear && !KumoMotion.reduceMotion(context);
    if (linearLoop) {
      _loop ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    } else {
      _loop?.dispose();
      _loop = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KumoProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _loop?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final fraction = _indeterminate ? 0.0 : (widget.value! / widget.max).clamp(0.0, 1.0);
    final percent = '${(fraction * 100).round()}%';
    final showValue = widget.showValue && !_indeterminate;
    final fill = kumo.color(widget.tone.fill);
    final circular = widget.variant == KumoProgressVariant.circular;

    final Widget indicator;
    if (circular) {
      final d = widget.size.ringDiameter;
      indicator = _indeterminate
          ? KumoLoader(dimension: d, dangerouslySetColor: fill, semanticLabel: '')
          : SizedBox.square(
              dimension: d,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: fraction, end: fraction),
                duration: KumoMotion.duration(context, KumoDurations.slow),
                curve: KumoCurves.enter,
                builder: (context, f, _) => CustomPaint(
                  painter: _RingPainter(
                    fraction: f,
                    track: kumo.colors.fill,
                    color: fill,
                    stroke: widget.size.ringStroke,
                  ),
                ),
              ),
            );
    } else if (_indeterminate) {
      indicator = _IndeterminateTrack(height: widget.size.trackHeight, color: fill, loop: _loop);
    } else {
      indicator = KumoMeterTrack(fraction: fraction, color: widget.tone.fill, height: widget.size.trackHeight);
    }
    // Indeterminate to measured (and back) cross-fades rather than flashing.
    final Widget swapped = KumoSwap(
      duration: KumoDurations.quick,
      alignment: AlignmentDirectional.centerStart,
      child: KeyedSubtree(key: ValueKey(_indeterminate), child: indicator),
    );

    final labelText = widget.label == null
        ? null
        : Text(
            widget.label!,
            style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle, height: 4 / 3),
          );
    final valueText = showValue
        ? Text(
            percent,
            style: kumo
                .text(size: KumoTextSize.sm, weight: KumoTypography.medium, height: 1 / 0.85)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          )
        : null;

    Widget body;
    if (circular) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swapped,
          if (labelText != null) ...[const SizedBox(width: KumoSpace.s2), Flexible(child: labelText)],
          if (valueText != null) ...[const SizedBox(width: KumoSpace.s2), valueText],
        ],
      );
    } else if (labelText == null && valueText == null) {
      body = swapped;
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: labelText ?? const SizedBox.shrink()),
              if (valueText != null) ...[const SizedBox(width: KumoSpace.s4), valueText],
            ],
          ),
          const SizedBox(height: KumoSpace.s2),
          swapped,
        ],
      );
    }

    return Semantics(
      label: widget.label ?? widget.semanticLabel ?? context.kumoStrings.loading,
      value: _indeterminate ? null : percent,
      excludeSemantics: true,
      child: body,
    );
  }
}

class _IndeterminateTrack extends StatelessWidget {
  const _IndeterminateTrack({required this.height, required this.color, required this.loop});

  final double height;
  final Color color;
  final AnimationController? loop;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return ClipRRect(
      borderRadius: BorderRadius.circular(KumoRadius.full),
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _SlidePainter(
            track: kumo.colors.fill,
            color: color,
            loop: loop,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _SlidePainter extends CustomPainter {
  _SlidePainter({required this.track, required this.color, required this.loop, required this.rtl})
    : super(repaint: loop);

  final Color track;
  final Color color;
  final Animation<double>? loop;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = track);
    final radius = Radius.circular(size.height / 2);
    final l = loop;
    if (l == null) {
      // Reduced motion: a still, half-strength full bar reads as "busy"
      // without suggesting a partial amount.
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), Paint()..color = color.withValues(alpha: color.a * 0.4));
      return;
    }
    final segment = size.width * 0.4;
    final t = Curves.easeInOut.transform(l.value);
    var left = -segment + t * (size.width + segment);
    if (rtl) left = size.width - left - segment;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, segment, size.height), radius),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SlidePainter old) =>
      old.track != track || old.color != color || old.loop != loop || old.rtl != rtl;
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.track, required this.color, required this.stroke});

  final double fraction;
  final Color track;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = track);
    final f = fraction.clamp(0.0, 1.0);
    if (f <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * f,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.color != color || old.stroke != stroke;
}
