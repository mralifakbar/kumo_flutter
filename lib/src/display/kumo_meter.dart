import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Colors a [KumoMeter] or [KumoProgress] indicator can take. Each tone
/// pairs a fill with a text color and an icon, so a state reached through a
/// [KumoMeterThreshold] is also written out.
enum KumoMeterTone {
  /// `bg-kumo-brand`, Kumo's default indicator.
  brand(KumoColor.brand, KumoColor.textSubtle, KumoIcons.info),

  /// `bg-kumo-success`.
  success(KumoColor.success, KumoColor.textSuccess, KumoIcons.checkCircle),

  /// `bg-kumo-warning`.
  warning(KumoColor.warning, KumoColor.textWarning, KumoIcons.warning),

  /// `bg-kumo-danger`.
  danger(KumoColor.danger, KumoColor.textDanger, KumoIcons.warningCircle);

  const KumoMeterTone(this.fill, this.text, this.icon);

  /// Indicator color.
  final KumoColor fill;

  /// Color of the status text shown for a threshold in this tone.
  final KumoColor text;

  /// Icon shown before the status text.
  final IconData icon;
}

/// A level at which a [KumoMeter] changes tone and shows a status line.
///
/// ```dart
/// const KumoMeterThreshold(value: 80, tone: KumoMeterTone.warning, label: 'Approaching the 10 GB limit')
/// ```
@immutable
class KumoMeterThreshold {
  const KumoMeterThreshold({required this.value, required this.tone, required this.label});

  /// Applies once the meter's value is at or above this, in the meter's units.
  final double value;
  final KumoMeterTone tone;

  /// Status text shown under the track and read by screen readers. Name the
  /// state and what happens next ("Requests are throttled above 1,000").
  final String label;
}

/// Kumo's `Meter`: a labeled bar for a measured value within a known range,
/// such as storage or request quota.
///
/// ```dart
/// const KumoMeter(label: 'Storage used', value: 65)
/// const KumoMeter(label: 'API requests', value: 750, max: 1000, customValue: '750 / 1,000')
/// const KumoMeter(
///   label: 'R2 storage',
///   value: 9.2,
///   max: 10,
///   customValue: '9.2 / 10 GB',
///   thresholds: [
///     KumoMeterThreshold(value: 8, tone: KumoMeterTone.warning, label: 'Approaching the 10 GB limit'),
///     KumoMeterThreshold(value: 10, tone: KumoMeterTone.danger, label: 'Limit reached. Uploads are paused'),
///   ],
/// )
/// ```
///
/// A meter shows a measurement, not task progress; use [KumoProgress] for
/// work that finishes. When the value changes the bar eases from where it is
/// to the new width (300ms ease-out, Kumo's width transition).
class KumoMeter extends StatelessWidget {
  const KumoMeter({
    super.key,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.customValue,
    this.showValue = true,
    this.tone = KumoMeterTone.brand,
    this.thresholds = const [],
    this.indicatorColor,
  }) : assert(max > min);

  /// Text above the track (12px subtle).
  final String label;

  /// Current value, clamped to [min]..[max].
  final double value;
  final double min;
  final double max;

  /// Replaces the percentage, for example "750 / 1,000".
  final String? customValue;

  /// Shows the percentage (or [customValue]) next to the label.
  final bool showValue;

  /// Indicator tone when no threshold applies.
  final KumoMeterTone tone;

  /// Levels that switch the tone and add a status line. Order does not
  /// matter; the highest threshold at or below [value] wins.
  final List<KumoMeterThreshold> thresholds;

  /// Overrides the indicator color (Kumo's `indicatorClassName`).
  final KumoColor? indicatorColor;

  double get _fraction => ((value - min) / (max - min)).clamp(0.0, 1.0);

  /// The threshold that applies to [value], if any.
  KumoMeterThreshold? get activeThreshold {
    KumoMeterThreshold? best;
    for (final t in thresholds) {
      if (value >= t.value && (best == null || t.value > best.value)) best = t;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final threshold = activeThreshold;
    final activeTone = threshold?.tone ?? tone;
    final percent = '${(_fraction * 100).round()}%';
    final valueText = customValue ?? percent;
    final spokenValue = [valueText, if (threshold != null) threshold.label].join(', ');

    return Semantics(
      label: label,
      value: spokenValue,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle, height: 4 / 3),
                ),
              ),
              if (customValue != null || showValue) ...[
                const SizedBox(width: KumoSpace.s4),
                Text(
                  valueText,
                  style: kumo
                      .text(size: KumoTextSize.sm, weight: KumoTypography.medium, height: 1 / 0.85)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ],
          ),
          const SizedBox(height: KumoSpace.s2),
          KumoMeterTrack(fraction: _fraction, color: indicatorColor ?? activeTone.fill),
          if (threshold != null) ...[
            const SizedBox(height: KumoSpace.s2),
            _StatusLine(tone: threshold.tone, label: threshold.label),
          ],
        ],
      ),
    );
  }
}

/// The bare 8px rounded track and indicator of [KumoMeter], for custom
/// layouts (a table cell, a compact card). It eases between fractions from
/// wherever it is.
///
/// ```dart
/// const SizedBox(width: 120, child: KumoMeterTrack(fraction: 0.4))
/// ```
class KumoMeterTrack extends StatelessWidget {
  const KumoMeterTrack({super.key, required this.fraction, this.color = KumoColor.brand, this.height = 8});

  /// Filled share, 0 to 1.
  final double fraction;
  final KumoColor color;

  /// Track height. Kumo's meter uses `h-2`.
  final double height;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final target = fraction.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(KumoRadius.full);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        color: kumo.colors.fill,
        alignment: AlignmentDirectional.centerStart,
        // TweenAnimationBuilder animates from its current value whenever the
        // target changes, so an update mid-animation never jumps back.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: target, end: target),
          duration: KumoMotion.duration(context, KumoDurations.slow),
          curve: KumoCurves.enter,
          builder: (context, f, child) => FractionallySizedBox(
            widthFactor: f.clamp(0.0, 1.0),
            heightFactor: 1,
            child: child,
          ),
          // Crossing a threshold eases the indicator to its new tone along
          // with the width, instead of flashing.
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: kumo.color(color)),
            duration: KumoMotion.duration(context, KumoDurations.slow),
            curve: KumoCurves.standard,
            builder: (context, tone, _) => DecoratedBox(
              decoration: BoxDecoration(color: tone, borderRadius: radius),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.tone, required this.label});

  final KumoMeterTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = context.kumo.text(size: KumoTextSize.xs, color: tone.text, height: 4 / 3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 16,
          child: Center(child: KumoIcon(tone.icon, size: 12, color: tone.text)),
        ),
        const SizedBox(width: KumoSpace.s1),
        Expanded(child: Text(label, style: style)),
      ],
    );
  }
}
