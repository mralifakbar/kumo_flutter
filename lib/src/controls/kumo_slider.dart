import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../system/kumo_haptics.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_control_parts.dart';

/// The two ends of a range slider.
typedef KumoSliderRange = ({double start, double end});

/// Formats a slider value for the thumb badge, the min and max labels and
/// screen readers.
typedef KumoSliderFormat = String Function(double value);

/// Slider track heights: `sm` 24px (`h-6 rounded-md`), `base` 32px
/// (`h-8 rounded-lg`).
enum KumoSliderSize {
  sm(24, KumoRadius.md, KumoRadius.sm, KumoTextSize.xs),
  base(32, KumoRadius.lg, KumoRadius.md, KumoTextSize.sm);

  const KumoSliderSize(this.height, this.radius, this.innerRadius, this.textSize);
  final double height;
  final double radius;

  /// One step smaller than [radius], so the inset indicator and thumbs stay
  /// concentric with the 3px-padded track.
  final double innerRadius;
  final KumoTextSize textSize;
}

/// Kumo's `Slider`: pick a number, or a range between two numbers, by
/// dragging a thumb along a recessed track. The current value shows in a
/// badge under each thumb, with the min and max at the ends.
///
/// ```dart
/// KumoSlider(
///   label: 'Sampling rate',
///   value: rate,
///   min: 0,
///   max: 1,
///   step: 0.05,
///   format: (v) => '${(v * 100).round()}%',
///   onValueChange: (v) => setState(() => rate = v),
/// )
/// ```
///
/// The thumb follows the finger 1:1 from wherever it was grabbed and lands
/// on the nearest step with a spring when released. Tapping the track moves
/// the nearest thumb there. Keyboard: arrows step (mirrored in RTL), Page Up
/// and Page Down or Shift+arrow take [largeStep], Home and End go to the
/// ends. Each thumb is a screen reader slider with increase and decrease
/// actions.
class KumoSlider extends StatefulWidget {
  /// A slider with one thumb.
  const KumoSlider({
    super.key,
    // Non-null here although the field is shared with the range constructor.
    // ignore: type_init_formals
    required double this.value,
    this.onValueChange,
    this.onValueCommitted,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.largeStep = 10,
    this.size = KumoSliderSize.base,
    this.label,
    this.disabled = false,
    this.format,
    this.thumbSemanticLabel,
  })  : values = null,
        onValuesChange = null,
        onValuesCommitted = null,
        assert(max > min),
        assert(step > 0);

  /// A slider with two thumbs selecting a range. The thumbs never cross.
  ///
  /// ```dart
  /// KumoSlider.range(
  ///   label: 'Response time (ms)',
  ///   values: (start: 100, end: 400),
  ///   max: 1000,
  ///   step: 10,
  ///   thumbSemanticLabel: (i) => i == 0 ? 'Minimum response time' : 'Maximum response time',
  ///   onValuesChange: (r) => setState(() => window = r),
  /// )
  /// ```
  const KumoSlider.range({
    super.key,
    // ignore: type_init_formals
    required KumoSliderRange this.values,
    this.onValuesChange,
    this.onValuesCommitted,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.largeStep = 10,
    this.size = KumoSliderSize.base,
    this.label,
    this.disabled = false,
    this.format,
    this.thumbSemanticLabel,
  })  : value = null,
        onValueChange = null,
        onValueCommitted = null,
        assert(max > min),
        assert(step > 0);

  /// The value of a single-thumb slider.
  final double? value;

  /// Called while the value changes, with values snapped to [step]. Null
  /// (and null [onValuesChange]) disables the slider.
  final ValueChanged<double>? onValueChange;

  /// Called once when a drag, tap or key press finishes changing the value.
  final ValueChanged<double>? onValueCommitted;

  /// The range of a two-thumb slider.
  final KumoSliderRange? values;
  final ValueChanged<KumoSliderRange>? onValuesChange;
  final ValueChanged<KumoSliderRange>? onValuesCommitted;
  final double min;
  final double max;

  /// Granularity of the value.
  final double step;

  /// Step for Page Up, Page Down and Shift+arrow, in value units.
  final double largeStep;
  final KumoSliderSize size;

  /// Medium-weight label above the track. Also the thumbs' accessible name.
  final String? label;
  final bool disabled;

  /// Formats the value badge, the min and max labels and the announced
  /// value. Defaults to the number with as many decimals as [step] has.
  final KumoSliderFormat? format;

  /// Accessible name for each thumb (index 0 is the start thumb). Use it
  /// without a visible [label], or to tell a range's thumbs apart.
  final String Function(int index)? thumbSemanticLabel;

  bool get _isRange => values != null;

  @override
  State<KumoSlider> createState() => _KumoSliderState();
}

/// Track padding (`p-[3px]`).
const double _pad = 3;

/// Thumb width (`w-4`).
const double _thumbWidth = 16;

class _KumoSliderState extends State<KumoSlider> with TickerProviderStateMixin {
  late final List<AnimationController> _positions;
  late final List<double> _targets;
  late final List<bool> _focused;
  late final List<FocusNode> _nodes;

  double _innerWidth = 1;
  int? _dragIndex;

  /// The thumb under a pointer that is down, for press feedback before any
  /// drag starts.
  int? _held;
  double _grabOffset = 0;
  List<double> _dragValues = const [];

  List<double> get _values => widget._isRange ? [widget.values!.start, widget.values!.end] : [widget.value!];

  bool get _enabled => !widget.disabled && (widget.onValueChange != null || widget.onValuesChange != null);

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    final values = _values;
    _positions = [for (final v in values) AnimationController.unbounded(vsync: this, value: _fraction(v))];
    _targets = [for (final v in values) _fraction(v)];
    _focused = List.filled(values.length, false);
    _nodes = [for (var i = 0; i < values.length; i++) FocusNode(debugLabel: 'KumoSlider thumb $i')];
  }

  @override
  void didUpdateWidget(KumoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(oldWidget._isRange == widget._isRange, 'A slider cannot switch between single and range');
    final values = _values;
    for (var i = 0; i < _positions.length; i++) {
      if (i == _dragIndex) continue;
      final target = _fraction(values[i]);
      if ((target - _targets[i]).abs() < 1e-9) continue;
      _targets[i] = target;
      _settle(i);
    }
  }

  @override
  void dispose() {
    for (final c in _positions) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  double _fraction(double v) => ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  int get _decimals {
    final s = widget.step.toString();
    if (s.contains('e')) return 6;
    final dot = s.indexOf('.');
    if (dot < 0) return 0;
    final decimals = s.substring(dot + 1);
    return decimals == '0' ? 0 : decimals.length;
  }

  /// Snaps [raw] to the step grid from [KumoSlider.min], inside the bounds.
  double _snap(double raw) {
    final steps = ((raw - widget.min) / widget.step).round();
    final v = (widget.min + steps * widget.step).clamp(widget.min, widget.max);
    return double.parse(v.toStringAsFixed(_decimals + 2));
  }

  String _format(double v) {
    if (widget.format != null) return widget.format!(v);
    return v.toStringAsFixed(_decimals);
  }

  void _settle(int i) {
    if (KumoMotion.reduceMotion(context)) {
      _positions[i].value = _targets[i];
      return;
    }
    KumoMotion.springTo(_positions[i], _targets[i], velocity: _positions[i].velocity);
  }

  void _emit(List<double> next, {required bool commit}) {
    if (widget._isRange) {
      final range = (start: next[0], end: next[1]);
      widget.onValuesChange?.call(range);
      if (commit) widget.onValuesCommitted?.call(range);
    } else {
      widget.onValueChange?.call(next[0]);
      if (commit) widget.onValueCommitted?.call(next[0]);
    }
  }

  /// Thumb center within the inner track, measured from the left edge.
  double _centerX(double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    final ltr = _thumbWidth / 2 + f * (_innerWidth - _thumbWidth);
    return _rtl ? _innerWidth - ltr : ltr;
  }

  /// Fraction under an x position in the inner track.
  double _fractionAt(double x) {
    final usable = math.max(1.0, _innerWidth - _thumbWidth);
    final f = ((x - _thumbWidth / 2) / usable).clamp(0.0, 1.0);
    return _rtl ? 1 - f : f;
  }

  int _nearestThumb(double x) {
    if (!widget._isRange) return 0;
    final d0 = (x - _centerX(_positions[0].value)).abs();
    final d1 = (x - _centerX(_positions[1].value)).abs();
    if ((d0 - d1).abs() < 0.5) {
      // Stacked thumbs: take the one that can move toward the pointer.
      return _fractionAt(x) > _positions[0].value ? 1 : 0;
    }
    return d0 < d1 ? 0 : 1;
  }

  /// Keeps range thumbs from crossing.
  double _bound(int i, double fraction, List<double> fractions) {
    if (!widget._isRange) return fraction;
    return i == 0 ? math.min(fraction, fractions[1]) : math.max(fraction, fractions[0]);
  }

  bool get _hapticSteps => (widget.max - widget.min) / widget.step <= 20;

  void _onTapUp(TapUpDetails details) {
    final x = details.localPosition.dx - _pad;
    final i = _nearestThumb(x);
    if ((x - _centerX(_positions[i].value)).abs() <= _thumbWidth / 2) return;
    final values = _values;
    final fractions = [for (final v in values) _fraction(v)];
    final f = _bound(i, _fractionAt(x), fractions);
    final v = _snap(widget.min + f * (widget.max - widget.min));
    if (v == values[i]) return;
    _nodes[i].requestFocus();
    _emit(List.of(values)..[i] = v, commit: true);
  }

  void _onDragStart(DragStartDetails details) {
    final x = details.localPosition.dx - _pad;
    final i = _nearestThumb(x);
    final center = _centerX(_positions[i].value);
    // Grabbing the thumb keeps the finger where it touched it; a drag that
    // starts on the track brings the thumb under the finger.
    _grabOffset = (x - center).abs() <= _thumbWidth / 2 ? x - center : 0;
    _dragIndex = i;
    _positions[i].stop();
    _dragValues = _values;
    _follow(x);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragIndex == null) return;
    _follow(details.localPosition.dx - _pad);
  }

  void _follow(double x) {
    final i = _dragIndex!;
    final fractions = [for (final c in _positions) c.value.clamp(0.0, 1.0)];
    final f = _bound(i, _fractionAt(x - _grabOffset), fractions);
    _positions[i].value = f;
    final v = _snap(widget.min + f * (widget.max - widget.min));
    if (v != _dragValues[i]) {
      if (_hapticSteps) kumoHaptic(KumoHaptic.selection);
      _dragValues = List.of(_dragValues)..[i] = v;
      _emit(_dragValues, commit: false);
    }
  }

  void _onDragEnd([DragEndDetails? _]) {
    final i = _dragIndex;
    if (i == null) return;
    _dragIndex = null;
    _emit(_dragValues, commit: true);
    // Land on the snapped value the parent now holds.
    _targets[i] = _fraction(_dragValues[i]);
    _settle(i);
  }

  void _release() {
    if (_held != null) setState(() => _held = null);
  }

  (double, double) _limits(int i) {
    final values = _values;
    final lower = widget._isRange && i == 1 ? values[0] : widget.min;
    final upper = widget._isRange && i == 0 ? values[1] : widget.max;
    return (lower, upper);
  }

  void _setValue(int i, double raw) {
    if (!_enabled) return;
    final (lower, upper) = _limits(i);
    final v = _snap(raw).clamp(lower, upper);
    final values = _values;
    if (v == values[i]) return;
    _emit(List.of(values)..[i] = v, commit: true);
  }

  void _stepBy(int i, double delta) => _setValue(i, _values[i] + delta);

  Map<ShortcutActivator, VoidCallback> _bindings(int i) {
    final step = widget.step;
    final big = math.max(widget.largeStep, step);
    final dir = _rtl ? -1.0 : 1.0;
    final (lower, upper) = _limits(i);
    return {
      const SingleActivator(LogicalKeyboardKey.arrowRight): () => _stepBy(i, step * dir),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _stepBy(i, -step * dir),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => _stepBy(i, step),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => _stepBy(i, -step),
      const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () => _stepBy(i, big * dir),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () => _stepBy(i, -big * dir),
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () => _stepBy(i, big),
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () => _stepBy(i, -big),
      const SingleActivator(LogicalKeyboardKey.pageUp): () => _stepBy(i, big),
      const SingleActivator(LogicalKeyboardKey.pageDown): () => _stepBy(i, -big),
      const SingleActivator(LogicalKeyboardKey.home): () => _setValue(i, lower),
      const SingleActivator(LogicalKeyboardKey.end): () => _setValue(i, upper),
    };
  }

  Widget _thumb(BuildContext context, int i, double thumbHeight) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final enabled = _enabled;
    final v = _values[i];
    final (lower, upper) = _limits(i);
    final up = _snap(math.min(upper, v + widget.step));
    final down = _snap(math.max(lower, v - widget.step));
    final name = widget.thumbSemanticLabel?.call(i) ?? widget.label;
    final radius = BorderRadius.circular(widget.size.innerRadius);

    Widget thumb = SizedBox(
      width: _thumbWidth,
      height: thumbHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: _focused[i] ? KumoRing.border(c.focus, width: 2) : null,
        ),
        child: Center(
          child: Container(
            width: 2,
            height: thumbHeight / 2,
            decoration: BoxDecoration(
              // The grip darkens while the thumb is held.
              color: c.contrast.withValues(alpha: _held == i || _dragIndex == i ? 0.5 : 0.25),
              borderRadius: BorderRadius.circular(KumoRadius.full),
            ),
          ),
        ),
      ),
    );
    thumb = CallbackShortcuts(
      bindings: enabled ? _bindings(i) : const {},
      child: Focus(
        focusNode: _nodes[i],
        canRequestFocus: enabled,
        skipTraversal: !enabled,
        includeSemantics: false,
        onFocusChange: (_) => _syncFocusHighlight(i),
        child: thumb,
      ),
    );
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.grab : SystemMouseCursors.basic,
      child: Semantics(
        slider: true,
        enabled: enabled,
        focusable: enabled,
        focused: _nodes[i].hasFocus,
        label: name,
        value: _format(v),
        increasedValue: v < upper ? _format(up) : null,
        decreasedValue: v > lower ? _format(down) : null,
        onIncrease: enabled && v < upper ? () => _stepBy(i, widget.step) : null,
        onDecrease: enabled && v > lower ? () => _stepBy(i, -widget.step) : null,
        child: thumb,
      ),
    );
  }

  /// Shows the focus ring only for keyboard focus, like `focus-visible`.
  void _syncFocusHighlight(int i) {
    final show = _nodes[i].hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    // Rebuild even when the ring does not change: semantics report focus.
    setState(() => _focused[i] = show);
  }

  Widget _badge(BuildContext context, double value) {
    final kumo = context.kumo;
    final disabled = widget.disabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s1_5),
      decoration: BoxDecoration(
        color: disabled ? kumo.colors.fill : kumo.colors.contrast,
        borderRadius: BorderRadius.circular(KumoRadius.sm),
      ),
      child: Text(
        _format(value),
        maxLines: 1,
        softWrap: false,
        style: kumo
            .text(
              size: widget.size.textSize,
              weight: KumoTypography.medium,
              color: disabled ? KumoColor.textDefault : KumoColor.textInverse,
            )
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final size = widget.size;
    final enabled = _enabled;
    final thumbHeight = size.height - _pad * 2;
    final textStyle = kumo
        .text(size: size.textSize, color: KumoColor.textSubtle)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 288.0;
        _innerWidth = math.max(_thumbWidth * 2, width - _pad * 2);
        final values = _values;
        return SizedBox(
          width: width,
          child: AnimatedBuilder(
            animation: Listenable.merge(_positions),
            builder: (context, _) {
              final centers = [for (final p in _positions) _centerX(p.value)];
              double indicatorLeft;
              double indicatorRight;
              if (widget._isRange) {
                indicatorLeft = math.min(centers[0], centers[1]) - _thumbWidth / 2;
                indicatorRight = math.max(centers[0], centers[1]) + _thumbWidth / 2;
              } else if (_rtl) {
                indicatorLeft = centers[0] - _thumbWidth / 2;
                indicatorRight = _innerWidth;
              } else {
                indicatorLeft = 0;
                indicatorRight = centers[0] + _thumbWidth / 2;
              }
              final innerRadius = BorderRadius.circular(size.innerRadius);
              final track = Container(
                height: size.height,
                padding: const EdgeInsets.all(_pad),
                decoration: BoxDecoration(
                  color: c.recessed,
                  borderRadius: BorderRadius.circular(size.radius),
                  border: KumoRing.border(c.line),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: indicatorLeft,
                      width: math.max(0, indicatorRight - indicatorLeft),
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.overlay,
                          borderRadius: innerRadius,
                          border: KumoRing.border(c.line),
                          boxShadow: KumoShadow.sm.boxShadows,
                        ),
                      ),
                    ),
                    for (var i = 0; i < centers.length; i++)
                      Positioned(
                        left: centers[i] - _thumbWidth / 2,
                        top: 0,
                        bottom: 0,
                        child: _thumb(context, i, thumbHeight),
                      ),
                  ],
                ),
              );
              final ends = ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(widget.min), style: textStyle),
                    Text(_format(widget.max), style: textStyle),
                  ],
                ),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: KumoSpace.s2,
                    children: [track, ends],
                  ),
                  for (var i = 0; i < centers.length; i++)
                    Positioned(
                      top: size.height + KumoSpace.s2,
                      left: 0,
                      right: 0,
                      child: ExcludeSemantics(
                        child: CustomSingleChildLayout(
                          delegate: _BadgeLayout(centerX: _pad + centers[i]),
                          child: _badge(context, values[i]),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );

    Widget slider = GestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: enabled ? _onTapUp : null,
      onHorizontalDragStart: enabled ? _onDragStart : null,
      onHorizontalDragUpdate: enabled ? _onDragUpdate : null,
      onHorizontalDragEnd: enabled ? _onDragEnd : null,
      onHorizontalDragCancel: enabled ? _onDragEnd : null,
      child: body,
    );
    slider = Listener(
      onPointerDown: enabled
          ? (event) {
              final x = event.localPosition.dx - _pad;
              final i = _nearestThumb(x);
              if ((x - _centerX(_positions[i].value)).abs() <= _thumbWidth / 2) setState(() => _held = i);
            }
          : null,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: slider,
    );
    final gestures = slider;
    slider = withDragSlop(context, slop: 8, build: (_) => gestures);

    slider = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s2,
      children: [
        if (widget.label != null)
          // The thumbs carry the label as their accessible name.
          ExcludeSemantics(
            child: Text(widget.label!, style: kumo.text(size: size.textSize, weight: KumoTypography.medium)),
          ),
        slider,
      ],
    );
    return Opacity(opacity: widget.disabled ? 0.5 : 1, child: slider);
  }
}

/// Centers the value badge under its thumb, kept inside the slider's width
/// so it never spills past the screen edge at the ends of the range.
class _BadgeLayout extends SingleChildLayoutDelegate {
  const _BadgeLayout({required this.centerX});

  final double centerX;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Size getSize(BoxConstraints constraints) => Size(constraints.maxWidth, 0);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (centerX - childSize.width / 2).clamp(0.0, math.max(0.0, size.width - childSize.width)).toDouble();
    return Offset(x, 0);
  }

  @override
  bool shouldRelayout(_BadgeLayout old) => old.centerX != centerX;
}
