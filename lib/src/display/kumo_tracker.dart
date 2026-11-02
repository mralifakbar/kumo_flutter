import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_popup_surface.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Status of one day in a [KumoTracker].
enum KumoTrackerStatus {
  /// Everything worked. `bg-kumo-success`.
  operational(KumoColor.success, 'Operational'),

  /// Partly working: elevated errors or latency. `bg-kumo-warning`.
  degraded(KumoColor.warning, 'Degraded'),

  /// Not working for part or all of the day. `bg-kumo-danger`.
  outage(KumoColor.danger, 'Outage'),

  /// No checks ran, for example before the monitor existed. `bg-kumo-fill`.
  noData(KumoColor.fill, 'No data');

  const KumoTrackerStatus(this.color, this.label);
  final KumoColor color;

  /// English name, shown in the tooltip, legend and summary. Override with
  /// [KumoTracker.statusLabels].
  final String label;
}

/// One bar of a [KumoTracker].
///
/// ```dart
/// KumoTrackerDay(date: DateTime(2026, 3, 4), status: KumoTrackerStatus.degraded, note: 'Elevated 5xx for 12 min')
/// ```
@immutable
class KumoTrackerDay {
  const KumoTrackerDay({required this.date, required this.status, this.note});

  final DateTime date;
  final KumoTrackerStatus status;

  /// Extra detail for the tooltip, such as what happened and for how long.
  final String? note;
}

/// An uptime tracker: a row of day bars colored by status, with a tooltip
/// per bar and a legend.
///
/// ```dart
/// KumoTracker(
///   label: 'image-resizer',
///   valueText: '98.9% uptime',
///   startLabel: '30 days ago',
///   endLabel: 'Today',
///   days: [
///     for (var i = 29; i >= 0; i--)
///       KumoTrackerDay(
///         date: DateTime(2026, 3, 31).subtract(Duration(days: i)),
///         status: i == 6 ? KumoTrackerStatus.outage : KumoTrackerStatus.operational,
///       ),
///   ],
/// )
/// ```
///
/// Status is never color alone: each bar's tooltip names the date and the
/// status, the legend names every color, and screen readers hear a summary
/// ("30 days: 29 operational, 1 outage") with the bars reachable through
/// increase and decrease actions.
///
/// * **Mouse:** hovering a bar shows its tooltip at once.
/// * **Touch:** tap a bar, or long press and slide to scrub across days.
/// * **Keyboard:** the tracker is one Tab stop; arrow keys move between
///   days, Home and End jump to the first and last.
///
/// [loading], [error] and an empty [days] list each draw their own state.
/// Kumo has no tracker; this one is drawn from its status tokens.
class KumoTracker extends StatefulWidget {
  const KumoTracker({
    super.key,
    required this.days,
    this.label,
    this.valueText,
    this.startLabel,
    this.endLabel,
    this.showLegend = true,
    this.loading = false,
    this.error,
    this.emptyText = 'No status checks ran in this period',
    this.statusLabels,
    this.height = 32,
    this.semanticLabel,
  });

  /// Days in order, oldest first. They draw from the start edge.
  final List<KumoTrackerDay> days;

  /// Name of what is tracked, shown above the bars (14px medium).
  final String? label;

  /// Figure shown opposite the label, such as "99.95% uptime".
  final String? valueText;

  /// Caption under the first bar, such as "90 days ago".
  final String? startLabel;

  /// Caption under the last bar, such as "Today".
  final String? endLabel;

  /// Shows a swatch and name for each status present in [days].
  final bool showLegend;

  /// Draws placeholder bars and ignores input while the history loads.
  final bool loading;

  /// Replaces the bars with this message, for a failed request. Name the
  /// cause ("Could not load health checks for image-resizer").
  final String? error;

  /// Shown when [days] is empty.
  final String emptyText;

  /// Replaces the English status names.
  final Map<KumoTrackerStatus, String>? statusLabels;

  /// Bar height.
  final double height;

  /// Replaces [label] as the accessible name.
  final String? semanticLabel;

  /// Name of [status], honoring [statusLabels].
  String statusLabel(KumoTrackerStatus status) => statusLabels?[status] ?? status.label;

  /// The spoken summary: "30 days: 28 operational, 1 degraded, 1 outage".
  String summary() {
    final counts = <KumoTrackerStatus, int>{};
    for (final d in days) {
      counts[d.status] = (counts[d.status] ?? 0) + 1;
    }
    final parts = [
      for (final s in KumoTrackerStatus.values)
        if (counts[s] != null) '${counts[s]} ${statusLabel(s).toLowerCase()}',
    ];
    return '${days.length} ${days.length == 1 ? 'day' : 'days'}: ${parts.join(', ')}';
  }

  @override
  State<KumoTracker> createState() => _KumoTrackerState();
}

class _KumoTrackerState extends State<KumoTracker> with SingleTickerProviderStateMixin {
  int? _active;

  /// The last inspected day, kept while the tooltip fades out so it leaves
  /// with its content instead of emptying first.
  int? _shown;
  bool _keyboardFocused = false;
  Timer? _touchTimer;
  final FocusNode _focus = FocusNode(debugLabel: 'KumoTracker');

  /// Where the tooltip points, in (fractional) bar indexes. Moving between
  /// days springs it from wherever it is to the next bar, so scrubbing and
  /// arrowing glide instead of teleporting.
  late final AnimationController _tip;

  @override
  void initState() {
    super.initState();
    _tip = AnimationController.unbounded(vsync: this);
  }

  bool get _interactive => !widget.loading && widget.error == null && widget.days.isNotEmpty;

  @override
  void didUpdateWidget(KumoTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) {
      _active = null;
      _shown = null;
    } else if (_active != null && _active! >= widget.days.length) {
      _active = widget.days.length - 1;
      _shown = _active;
      _tip.value = _active!.toDouble();
    }
    if (_shown != null && _shown! >= widget.days.length) _shown = null;
  }

  @override
  void dispose() {
    _touchTimer?.cancel();
    _tip.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setActive(int? index) {
    if (!_interactive) index = null;
    if (index == _active) return;
    final wasOpen = _active != null;
    setState(() {
      _active = index;
      if (index != null) _shown = index;
    });
    if (index == null) return;
    if (!wasOpen || KumoMotion.reduceMotion(context)) {
      // A fresh tooltip opens at its bar; only moves between bars glide.
      _tip.value = index.toDouble();
    } else {
      KumoMotion.springTo(_tip, index.toDouble(), spring: KumoSprings.popup, velocity: _tip.velocity);
    }
  }

  int _indexAt(double x, _BarGeometry g) {
    final n = g.count;
    final step = g.bar + g.gap;
    final visual = step <= 0 ? 0 : (x / step).floor().clamp(0, n - 1);
    return g.rtl ? n - 1 - visual : visual;
  }

  void _touchShow(int index) {
    _touchTimer?.cancel();
    _setActive(index);
  }

  void _touchRelease() {
    _touchTimer?.cancel();
    // The same 1.5s KumoTooltip keeps a long-press tooltip up.
    _touchTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && !_keyboardFocused) _setActive(null);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (!_interactive) return KeyEventResult.ignored;
    final n = widget.days.length;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final current = _active ?? n - 1;
    final key = event.logicalKey;
    int? next;
    if (key == LogicalKeyboardKey.arrowLeft) next = current + (rtl ? 1 : -1);
    if (key == LogicalKeyboardKey.arrowRight) next = current + (rtl ? -1 : 1);
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = n - 1;
    if (key == LogicalKeyboardKey.escape && _active != null) {
      _setActive(null);
      return KeyEventResult.handled;
    }
    if (next == null) return KeyEventResult.ignored;
    _setActive(next.clamp(0, n - 1));
    return KeyEventResult.handled;
  }

  String _dayText(KumoTrackerDay day) {
    final strings = context.kumoStrings;
    return [strings.shortDate(day.date), widget.statusLabel(day.status), ?day.note].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final days = widget.days;

    final header = widget.label == null && widget.valueText == null
        ? null
        // The bars' semantics node already reads the label and value.
        : Padding(
            padding: const EdgeInsets.only(bottom: KumoSpace.s2),
            child: ExcludeSemantics(
              excluding: _interactive,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: widget.label == null
                        ? const SizedBox.shrink()
                        : Text(widget.label!, style: kumo.text(weight: KumoTypography.medium)),
                  ),
                  if (widget.valueText != null) ...[
                    const SizedBox(width: KumoSpace.s4),
                    Text(
                      widget.valueText!,
                      style: kumo
                          .text(size: KumoTextSize.sm, color: KumoColor.textSubtle, height: 1 / 0.85)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ],
              ),
            ),
          );

    Widget bars;
    final String kind;
    if (widget.error != null) {
      kind = 'error';
      bars = _StateBox(height: widget.height, icon: KumoIcons.warningCircle, text: widget.error!, danger: true);
    } else if (!widget.loading && days.isEmpty) {
      kind = 'empty';
      bars = _StateBox(height: widget.height, text: widget.emptyText);
    } else {
      kind = widget.loading ? 'loading' : 'bars';
      bars = _buildBars(context, rtl);
    }
    // Placeholder bars, history, error and empty cross-fade into each other.
    bars = KumoSwap(
      duration: KumoDurations.quick,
      child: KeyedSubtree(key: ValueKey(kind), child: bars),
    );

    final captions = widget.startLabel == null && widget.endLabel == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: KumoSpace.s1_5),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Expanded(child: _caption(context, widget.startLabel ?? '')),
                  const SizedBox(width: KumoSpace.s4),
                  _caption(context, widget.endLabel ?? ''),
                ],
              ),
            ),
          );

    final present = {for (final d in days) d.status};
    final legend = !widget.showLegend || present.isEmpty || widget.loading || widget.error != null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: KumoSpace.s3),
            child: ExcludeSemantics(
              child: Wrap(
                spacing: KumoSpace.s3,
                runSpacing: KumoSpace.s1,
                children: [
                  for (final s in KumoTrackerStatus.values)
                    if (present.contains(s))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Swatch(color: kumo.color(s.color)),
                          const SizedBox(width: KumoSpace.s1_5),
                          _caption(context, widget.statusLabel(s)),
                        ],
                      ),
                ],
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [?header, bars, ?captions, ?legend],
    );
  }

  Widget _caption(BuildContext context, String text) => Text(
    text,
    style: context.kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle, height: 4 / 3),
  );

  Widget _buildBars(BuildContext context, bool rtl) {
    final kumo = context.kumo;
    final days = widget.days;
    final loading = widget.loading;
    final count = loading && days.isEmpty ? 30 : days.length;
    final colors = [for (var i = 0; i < count; i++) loading ? kumo.colors.fill : kumo.color(days[i].status.color)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final geometry = _BarGeometry(count: count, width: width, rtl: rtl);
        final active = _active;

        Widget paint = SizedBox(
          height: widget.height,
          width: width,
          child: CustomPaint(
            painter: _BarsPainter(geometry: geometry, colors: colors, active: active),
          ),
        );

        if (!_interactive) {
          return Semantics(
            label: loading
                ? '${widget.semanticLabel ?? widget.label ?? ''} ${context.kumoStrings.loading}'.trim()
                : null,
            excludeSemantics: true,
            child: paint,
          );
        }

        paint = MouseRegion(
          onHover: (e) {
            if (e.kind == PointerDeviceKind.touch) return;
            _setActive(_indexAt(e.localPosition.dx, geometry));
          },
          onExit: (_) {
            if (!_keyboardFocused) _setActive(null);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _touchShow(_indexAt(d.localPosition.dx, geometry)),
            onTapUp: (_) => _touchRelease(),
            onLongPressStart: (d) => _touchShow(_indexAt(d.localPosition.dx, geometry)),
            onLongPressMoveUpdate: (d) => _setActive(_indexAt(d.localPosition.dx, geometry)),
            onLongPressEnd: (_) => _touchRelease(),
            child: paint,
          ),
        );

        paint = KumoFocusRing(
          visible: _keyboardFocused,
          borderRadius: BorderRadius.circular(KumoRadius.xs),
          offset: 2,
          child: paint,
        );

        paint = Focus(
          focusNode: _focus,
          onKeyEvent: _onKey,
          onFocusChange: (focused) {
            final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
            setState(() => _keyboardFocused = focused && keyboard);
            if (_keyboardFocused) {
              _setActive(_active ?? days.length - 1);
            } else if (!focused) {
              _setActive(null);
            }
          },
          child: paint,
        );

        final day = active == null ? null : days[active];
        final interactive = paint;
        paint = AnimatedBuilder(
          animation: _tip,
          child: interactive,
          builder: (context, child) => KumoAnchoredOverlay(
            open: day != null,
            side: KumoSide.top,
            sideOffset: 6 + KumoPopupSurface.arrowHeight,
            preferredExtent: 72,
            // Centered on the tracker, then shifted to the bar the tooltip is
            // gliding toward.
            alignOffset: _shown == null ? 0 : (rtl ? -1 : 1) * (geometry.centerAt(_tip.value) - width / 2),
            focusPopupWhenUnfocused: false,
            onDismiss: () => _setActive(null),
            overlayBuilder: (context, placement) {
              final index = _shown;
              if (index == null || index >= widget.days.length) return const SizedBox.shrink();
              final shown = widget.days[index];
              final bar = geometry.rectAt(_tip.value, widget.height);
              final anchored = KumoPopupPlacement(
                side: placement.side,
                align: placement.align,
                anchorRect: bar.shift(placement.anchorRect.topLeft),
                maxWidth: placement.maxWidth,
                maxHeight: placement.maxHeight,
                popupRect: placement.popupRect,
              );
              return IgnorePointer(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: KumoPopupSurface(
                    placement: anchored,
                    showArrow: true,
                    borderRadius: KumoRadius.md,
                    shadow: KumoShadow.md,
                    padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2_5, vertical: KumoSpace.s1_5),
                    child: ExcludeSemantics(
                      child: _TooltipBody(day: shown, statusLabel: widget.statusLabel(shown.status)),
                    ),
                  ),
                ),
              );
            },
            child: child!,
          ),
        );

        final n = days.length;
        return Semantics(
          container: true,
          label:
              [?(widget.semanticLabel ?? widget.label), ?widget.valueText].join(', ') +
              (widget.label == null && widget.semanticLabel == null && widget.valueText == null ? '' : '. ') +
              widget.summary(),
          value: day == null ? null : _dayText(day),
          // Semantics needs these whenever value is set; at either end the
          // next value is the current one.
          increasedValue: active == null ? null : _dayText(days[math.min(active + 1, n - 1)]),
          decreasedValue: active == null ? null : _dayText(days[math.max(active - 1, 0)]),
          onIncrease: () => _setActive(((_active ?? -1) + 1).clamp(0, n - 1)),
          onDecrease: () => _setActive(((_active ?? n) - 1).clamp(0, n - 1)),
          excludeSemantics: true,
          child: paint,
        );
      },
    );
  }
}

/// Where each bar sits for a given width.
@immutable
class _BarGeometry {
  _BarGeometry({required this.count, required this.width, required this.rtl}) {
    // Wide trackers get 2px gaps, dense ones 1px, and very dense ones none,
    // so 90 days still fit a 358px phone column.
    final room = count <= 0 ? 0.0 : width / count;
    gap = count <= 1 ? 0 : (room >= 6 ? 2 : (room >= 3 ? 1 : 0));
    bar = count <= 0 ? 0 : math.max(0.0, (width - gap * (count - 1)) / count);
  }

  final int count;
  final double width;
  final bool rtl;
  late final double gap;
  late final double bar;

  double left(int i) {
    final visual = rtl ? count - 1 - i : i;
    return visual * (bar + gap);
  }

  double center(int i) => left(i) + bar / 2;

  Rect rect(int i, double height) => Rect.fromLTWH(left(i), 0, bar, height);

  /// [center] for a fractional index, for a tooltip moving between bars.
  double centerAt(double i) => (rtl ? count - 1 - i : i) * (bar + gap) + bar / 2;

  Rect rectAt(double i, double height) => Rect.fromLTWH(centerAt(i) - bar / 2, 0, bar, height);

  @override
  bool operator ==(Object other) =>
      other is _BarGeometry && other.count == count && other.width == width && other.rtl == rtl;

  @override
  int get hashCode => Object.hash(count, width, rtl);
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({required this.geometry, required this.colors, required this.active});

  final _BarGeometry geometry;
  final List<Color> colors;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(math.min(KumoRadius.xs, geometry.bar / 2));
    final paint = Paint();
    for (var i = 0; i < geometry.count; i++) {
      var color = colors[i];
      // While a day is inspected the rest step back, instantly like a hover.
      if (active != null && i != active) color = color.withValues(alpha: color.a * 0.45);
      paint.color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(geometry.rect(i, size.height), radius), paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.geometry != geometry || old.active != active || !_listEquals(old.colors, colors);

  static bool _listEquals(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(KumoRadius.xs)),
  );
}

class _TooltipBody extends StatelessWidget {
  const _TooltipBody({required this.day, required this.statusLabel});

  final KumoTrackerDay day;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final style = kumo.text(size: KumoTextSize.sm, height: 1.4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.kumoStrings.shortDate(day.date), style: style.copyWith(fontWeight: KumoTypography.medium)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Swatch(color: kumo.color(day.status.color)),
            const SizedBox(width: KumoSpace.s1_5),
            Flexible(child: Text(statusLabel, style: style)),
          ],
        ),
        if (day.note != null)
          Text(
            day.note!,
            style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle, height: 4 / 3),
          ),
      ],
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.height, required this.text, this.icon, this.danger = false});

  final double height;
  final String text;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final color = danger ? KumoColor.textDanger : KumoColor.textSubtle;
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s1_5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kumo.colors.recessed, borderRadius: BorderRadius.circular(KumoRadius.md)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[KumoIcon(icon!, size: 14, color: color), const SizedBox(width: KumoSpace.s1_5)],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: kumo.text(size: KumoTextSize.xs, color: color, height: 4 / 3),
            ),
          ),
        ],
      ),
    );
  }
}
