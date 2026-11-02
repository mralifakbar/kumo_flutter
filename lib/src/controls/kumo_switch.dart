import 'package:flutter/gestures.dart' show DragStartBehavior, kMinFlingVelocity;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_control_parts.dart';

/// Switch sizes (Kumo's track classes): `sm` 32x16, `base` 36x18, `lg`
/// 40x20. The thumb is a square as tall as the track.
enum KumoSwitchSize {
  /// `h-4 w-8`.
  sm(16, 32),

  /// `h-4.5 w-9`.
  base(18, 36),

  /// `h-5 w-10`.
  lg(20, 40);

  const KumoSwitchSize(this.height, this.width);
  final double height;
  final double width;

  /// How far the thumb slides.
  double get travel => width - height;
}

/// Switch colors. [base] is Kumo's `"default"`.
enum KumoSwitchVariant {
  /// Blue track when on.
  base,

  /// Monochrome track, for settings that should not draw the eye.
  neutral,
}

// Kumo styles the switch with Tailwind's palette rather than semantic
// tokens, so the exact palette values live here.
const _blue300 = Color(0xFF8EC5FF);
const _blue500 = Color(0xFF2B7FFF);
const _blue600 = Color(0xFF155DFC);
const _neutral150 = Color(0xFFE9E9E9);
const _neutral200 = Color(0xFFE5E5E5);
const _neutral300 = Color(0xFFD4D4D4);
const _neutral400 = Color(0xFFA1A1A1);
const _neutral500 = Color(0xFF737373);
const _neutral600 = Color(0xFF525252);
const _neutral700 = Color(0xFF404040);
const _neutral850 = Color(0xFF1F1F1F);

/// Track, ring and thumb colors for one switch state.
@immutable
class _SwitchColors {
  const _SwitchColors(this.track, this.ring, this.thumb);

  final Color track;
  final Color ring;
  final Color thumb;

  static _SwitchColors of(KumoThemeData kumo, KumoSwitchVariant variant, bool on) {
    final c = kumo.colors;
    final dark = kumo.isDark;
    if (variant == KumoSwitchVariant.neutral) {
      return on
          ? _SwitchColors(dark ? c.base : _neutral500, dark ? _neutral700 : _neutral600, dark ? _neutral400 : c.base)
          : _SwitchColors(dark ? c.base : _neutral150, c.hairline, dark ? _neutral850 : c.base);
    }
    return on
        ? _SwitchColors(dark ? _blue600 : _blue500, dark ? _blue500 : _blue600, dark ? _blue300 : c.base)
        : _SwitchColors(dark ? _neutral700 : _neutral200, dark ? _neutral600 : _neutral300, dark ? _neutral850 : c.base);
  }

  static _SwitchColors lerp(_SwitchColors a, _SwitchColors b, double t) => _SwitchColors(
        Color.lerp(a.track, b.track, t)!,
        Color.lerp(a.ring, b.ring, t)!,
        Color.lerp(a.thumb, b.thumb, t)!,
      );
}

/// Kumo's `Switch`: an on/off control for a setting that takes effect at
/// once.
///
/// Controlled: pass [checked] and update it from [onCheckedChange].
///
/// ```dart
/// KumoSwitch(
///   label: 'Always use HTTPS',
///   checked: httpsOnly,
///   onCheckedChange: (value) => setState(() => httpsOnly = value),
/// )
/// ```
///
/// Tap the switch or its label to toggle. The thumb can also be dragged: it
/// follows the finger, resists past either end, and on release settles on
/// the side the gesture was heading toward, with a spring that carries the
/// release velocity. A selection haptic marks every change. Under reduced
/// motion the thumb moves without animation.
class KumoSwitch extends StatefulWidget {
  const KumoSwitch({
    super.key,
    required this.checked,
    this.onCheckedChange,
    this.label,
    this.labelWidget,
    this.labelTooltip,
    this.required,
    this.controlFirst,
    this.size = KumoSwitchSize.base,
    this.variant = KumoSwitchVariant.base,
    this.disabled = false,
    this.transitioning = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final bool checked;

  /// Called with the next value after a tap, a key press or a drag that
  /// changes sides. Null disables the switch.
  final ValueChanged<bool>? onCheckedChange;

  /// Label text, medium weight. Also the accessible name.
  final String? label;

  /// Custom label in place of [label].
  final Widget? labelWidget;

  /// Shows an info icon with this tooltip after the label.
  final String? labelTooltip;

  /// When explicitly false, shows "(optional)" after the label.
  final bool? required;

  /// Switch before the label (true) or after it. Defaults to the enclosing
  /// [KumoSwitchGroup]'s setting, otherwise true.
  final bool? controlFirst;
  final KumoSwitchSize size;
  final KumoSwitchVariant variant;
  final bool disabled;

  /// A save is in flight. Kumo marks the switch busy (`aria-busy`); here it
  /// also ignores input until the flag clears, so a slow request cannot be
  /// toggled twice.
  final bool transitioning;

  /// Accessible name when there is no visible label.
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KumoSwitch> createState() => _KumoSwitchState();
}

class _KumoSwitchState extends State<KumoSwitch> with TickerProviderStateMixin {
  /// Thumb position: 0 off, 1 on. Goes past either end while rubberbanding.
  late final AnimationController _position;

  /// Thumb stretch while held, 0 to 1.
  late final AnimationController _stretch;
  bool _dragging = false;
  double _dragStart = 0;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this, value: widget.checked ? 1 : 0);
    _stretch = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didUpdateWidget(KumoSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checked != widget.checked && !_dragging) _settle(widget.checked);
  }

  @override
  void dispose() {
    _position.dispose();
    _stretch.dispose();
    super.dispose();
  }

  _SwitchGroupScope? get _group => context.dependOnInheritedWidgetOfExactType<_SwitchGroupScope>();

  bool get _disabled => widget.disabled || (_group?.disabled ?? false) || widget.onCheckedChange == null;

  bool get _interactive => !_disabled && !widget.transitioning;

  double get _direction => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _settle(bool on, {double velocity = 0, bool flick = false}) {
    final target = on ? 1.0 : 0.0;
    if (KumoMotion.reduceMotion(context)) {
      _position.value = target;
      return;
    }
    KumoMotion.springTo(
      _position,
      target,
      spring: flick ? KumoSprings.momentum : KumoSprings.standard,
      velocity: velocity == 0 ? _position.velocity : velocity,
    );
  }

  void _setStretch(bool held) {
    if (KumoMotion.reduceMotion(context)) {
      _stretch.value = 0;
      return;
    }
    KumoMotion.springTo(_stretch, held ? 1 : 0, spring: KumoSprings.press, velocity: _stretch.velocity);
  }

  void _commit(bool on) {
    if (on == widget.checked) return;
    widget.onCheckedChange?.call(on);
    // A controlled parent may refuse the change; return to its value.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dragging && widget.checked != on) _settle(widget.checked);
    });
  }

  void _onDragStart(DragStartDetails details) {
    _position.stop();
    _dragging = true;
    _dragStart = _position.value.clamp(0.0, 1.0);
    _dragDx = 0;
    _setStretch(true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final travel = widget.size.travel;
    _dragDx += (details.primaryDelta ?? 0) * _direction;
    var px = _dragStart * travel + _dragDx;
    if (px < 0) {
      px = KumoMotion.rubberband(px, travel);
    } else if (px > travel) {
      px = travel + KumoMotion.rubberband(px - travel, travel);
    }
    _position.value = px / travel;
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    _setStretch(false);
    final travel = widget.size.travel;
    final velocity = (details.primaryVelocity ?? 0) * _direction;
    final projected = _position.value * travel + KumoMotion.project(velocity);
    final on = projected >= travel / 2;
    _settle(on, velocity: velocity / travel, flick: velocity.abs() >= kMinFlingVelocity);
    if (on != widget.checked) {
      kumoHaptic(KumoHaptic.selection);
      _commit(on);
    }
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _setStretch(false);
    _settle(widget.checked);
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final group = _group;
    final controlFirst = widget.controlFirst ?? group?.controlFirst ?? true;
    final disabled = _disabled;
    final labelNode = widget.labelWidget ??
        (widget.label == null
            ? null
            : ControlLabelText(
                text: widget.label!,
                weight: KumoTypography.medium,
                showOptional: widget.required == false,
                tooltip: widget.labelTooltip,
              ));

    Widget result = KumoPressable(
      onPress: _interactive ? () => widget.onCheckedChange!(!widget.checked) : null,
      onPressIn: () => _setStretch(true),
      onPressOut: () {
        if (!_dragging) _setStretch(false);
      },
      disabled: disabled,
      loading: widget.transitioning,
      isButton: false,
      toggled: widget.checked,
      semanticLabel: widget.semanticLabel ?? (labelNode == null ? context.kumoStrings.switchLabel : null),
      semanticHint: widget.transitioning ? context.kumoStrings.loading : null,
      showFocusRing: false,
      scaleOnPress: false,
      haptic: KumoHaptic.selection,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      builder: (context, state) {
        Widget track = _SwitchTrack(
          position: _position,
          stretch: _stretch,
          size: widget.size,
          variant: widget.variant,
          focused: state.focused,
          rtl: _direction < 0,
          kumo: kumo,
        );
        final inGroup = group != null;
        if (disabled && !inGroup) track = Opacity(opacity: 0.5, child: track);
        Widget row = labelNode == null
            ? track
            : ControlRow(control: track, label: labelNode, controlFirst: controlFirst, centered: true);
        if (disabled && inGroup) row = Opacity(opacity: 0.5, child: row);
        return row;
      },
    );

    if (_interactive) {
      result = withDragSlop(
        context,
        slop: 4,
        build: (restore) => GestureDetector(
          excludeFromSemantics: true,
          // Count movement from the touch point so the thumb never lags the
          // finger by the drag slop.
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: restore(result),
        ),
      );
    }
    return result;
  }
}

class _SwitchTrack extends StatelessWidget {
  const _SwitchTrack({
    required this.position,
    required this.stretch,
    required this.size,
    required this.variant,
    required this.focused,
    required this.rtl,
    required this.kumo,
  });

  final AnimationController position;
  final AnimationController stretch;
  final KumoSwitchSize size;
  final KumoSwitchVariant variant;
  final bool focused;
  final bool rtl;
  final KumoThemeData kumo;

  @override
  Widget build(BuildContext context) {
    final off = _SwitchColors.of(kumo, variant, false);
    final on = _SwitchColors.of(kumo, variant, true);
    final radius = BorderRadius.circular(5);
    return AnimatedBuilder(
      animation: Listenable.merge([position, stretch]),
      builder: (context, _) {
        final p = position.value;
        final colors = _SwitchColors.lerp(off, on, p.clamp(0.0, 1.0));
        // The held thumb widens by a quarter, growing toward the side it can
        // travel to, so it stays inside the track.
        final extra = size.height * 0.25 * stretch.value.clamp(0.0, 1.0);
        final thumbWidth = size.height + extra;
        final travel = size.travel - extra;
        final x = rtl ? travel * (1 - p) : travel * p;
        return SizedBox(
          width: size.width,
          height: size.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.track,
              borderRadius: radius,
              border: KumoRing.border(focused ? kumo.colors.brand : colors.ring, width: focused ? 2 : 1),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  width: thumbWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.thumb,
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(blurRadius: 1, spreadRadius: 0.5, color: kumo.colors.shadowEdge),
                        BoxShadow(offset: const Offset(0, 1), blurRadius: 2, color: kumo.colors.shadowDrop),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SwitchGroupScope extends InheritedWidget {
  const _SwitchGroupScope({required this.controlFirst, required this.disabled, required super.child});

  final bool controlFirst;
  final bool disabled;

  @override
  bool updateShouldNotify(_SwitchGroupScope old) => old.controlFirst != controlFirst || old.disabled != disabled;
}

/// Kumo's `Switch.Group`: a legend over related [KumoSwitch]es, each with its
/// own value, and an error and description below.
///
/// ```dart
/// KumoSwitchGroup(
///   legend: 'Notifications',
///   children: [
///     KumoSwitch(label: 'Deploy failures', checked: failures, onCheckedChange: setFailures),
///     KumoSwitch(label: 'Weekly usage report', checked: report, onCheckedChange: setReport),
///   ],
/// )
/// ```
class KumoSwitchGroup extends StatelessWidget {
  const KumoSwitchGroup({
    super.key,
    required this.children,
    this.legend,
    this.hideLegend = false,
    this.description,
    this.error,
    this.disabled = false,
    this.controlFirst = true,
  });

  /// Usually [KumoSwitch]es.
  final List<Widget> children;

  /// Group title, medium weight above the switches.
  final String? legend;

  /// Keep the legend for screen readers only (Kumo's `sr-only` legend).
  final bool hideLegend;
  final String? description;
  final String? error;

  /// Disables every switch in the group.
  final bool disabled;

  /// Switch before its label, for every switch that does not set its own.
  final bool controlFirst;

  @override
  Widget build(BuildContext context) {
    return _SwitchGroupScope(
      controlFirst: controlFirst,
      disabled: disabled,
      child: ControlFieldset(
        legend: legend,
        hideLegend: hideLegend,
        description: description,
        error: error,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: controlRowGap(context),
          children: children,
        ),
      ),
    );
  }
}
