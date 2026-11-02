import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import 'kumo_focus_ring.dart';
import 'kumo_haptics.dart';

/// Interaction state handed to [KumoPressable.builder].
@immutable
class KumoPressState {
  const KumoPressState({this.hovered = false, this.pressed = false, this.focused = false, this.disabled = false});

  /// A pointer hovers the control. Kumo switches hover colors instantly.
  final bool hovered;

  /// A pointer or key is holding the control down.
  final bool pressed;

  /// Keyboard focus is on the control (focus-visible, not after a tap).
  final bool focused;
  final bool disabled;

  /// Hovered or pressed: the moments Kumo shows a hover background.
  bool get active => hovered || pressed;

  @override
  bool operator ==(Object other) =>
      other is KumoPressState &&
      other.hovered == hovered &&
      other.pressed == pressed &&
      other.focused == focused &&
      other.disabled == disabled;

  @override
  int get hashCode => Object.hash(hovered, pressed, focused, disabled);
}

/// Builds a control's visuals from its interaction state.
typedef KumoPressableBuilder = Widget Function(BuildContext context, KumoPressState state);

/// The interaction primitive every tappable Kumo component is built on.
///
/// * Feedback starts on pointer-down: the surface scales to 0.98 with a spring
///   that starts from wherever it is, so rapid taps never jump.
/// * Hover and pressed colors change instantly, never with a transition (a
///   Kumo rule: animated hover colors feel sluggish).
/// * Keyboard focus shows Kumo's 2px brand ring; Enter and Space activate.
/// * On touch platforms the hit area grows to 44x44 (see
///   [KumoThemeData.tapTargetSize]).
/// * Reduced motion turns the scale off and keeps the color feedback.
///
/// Components draw their own surface from the state:
///
/// ```dart
/// KumoPressable(
///   onPress: save,
///   semanticLabel: 'Save',
///   borderRadius: BorderRadius.circular(KumoRadius.lg),
///   builder: (context, state) => Container(
///     color: state.active ? context.kumo.colors.tint : context.kumo.colors.base,
///     child: const Text('Save'),
///   ),
/// )
/// ```
class KumoPressable extends StatefulWidget {
  const KumoPressable({
    super.key,
    this.child,
    this.builder,
    this.onPress,
    this.onLongPress,
    this.onPressIn,
    this.onPressOut,
    this.disabled = false,
    this.loading = false,
    this.borderRadius = BorderRadius.zero,
    this.focusRingColor = KumoColor.brand,
    this.focusRingWidth = 2,
    this.focusRingOffset = 0,
    this.showFocusRing = true,
    this.scaleOnPress = true,
    this.pressScale = KumoMotion.pressScale,
    this.haptic = KumoHaptic.none,
    this.debounce = Duration.zero,
    this.minTapTargetSize,
    this.semanticLabel,
    this.semanticHint,
    this.semanticValue,
    this.selected,
    this.toggled,
    this.checked,
    this.mixed,
    this.expanded,
    this.inMutuallyExclusiveGroup,
    this.isButton = true,
    this.isLink = false,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.mouseCursor,
    this.excludeChildSemantics = false,
    this.mergeChildSemantics = true,
    this.behavior = HitTestBehavior.opaque,
  }) : assert(child != null || builder != null, 'Pass child or builder');

  /// Static content. Use [builder] when the visuals depend on hover or press.
  final Widget? child;
  final KumoPressableBuilder? builder;
  final VoidCallback? onPress;
  final VoidCallback? onLongPress;
  final VoidCallback? onPressIn;
  final VoidCallback? onPressOut;
  final bool disabled;

  /// Blocks presses without the disabled look.
  final bool loading;

  /// Shape of the focus ring.
  final BorderRadius borderRadius;
  final KumoColor focusRingColor;
  final double focusRingWidth;
  final double focusRingOffset;

  /// Set false when the component paints its own focus treatment.
  final bool showFocusRing;
  final bool scaleOnPress;
  final double pressScale;
  final KumoHaptic haptic;

  /// Presses within this window after a press are ignored. Off by default;
  /// navigation surfaces pass about 500ms to stop double pushes.
  final Duration debounce;

  /// Overrides the theme's minimum hit-area edge (44 on touch, 0 with a mouse).
  final double? minTapTargetSize;
  final String? semanticLabel;
  final String? semanticHint;
  final String? semanticValue;
  final bool? selected;
  final bool? toggled;
  final bool? checked;

  /// Indeterminate checkbox state.
  final bool? mixed;

  /// Disclosure state for collapsibles, menus and selects.
  final bool? expanded;
  final bool? inMutuallyExclusiveGroup;
  final bool isButton;

  /// Announce as a link instead of a button.
  final bool isLink;
  final FocusNode? focusNode;
  final bool autofocus;

  /// False keeps the control out of the Tab order (roving focus groups manage
  /// focus themselves).
  final bool canRequestFocus;
  final MouseCursor? mouseCursor;

  /// Use [semanticLabel] alone instead of merging the child's text into it.
  final bool excludeChildSemantics;

  /// Merge the child's semantics into this node. Set false when the surface
  /// holds its own buttons, so each stays separately reachable.
  final bool mergeChildSemantics;
  final HitTestBehavior behavior;

  @override
  State<KumoPressable> createState() => _KumoPressableState();
}

class _KumoPressableState extends State<KumoPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  bool _pressed = false;
  bool _hovered = false;
  bool _focusHighlight = false;
  DateTime? _lastPress;
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode {
    if (widget.focusNode != null) return widget.focusNode!;
    final node = _ownFocusNode ??= FocusNode(debugLabel: 'KumoPressable');
    node
      ..canRequestFocus = widget.canRequestFocus
      ..skipTraversal = !widget.canRequestFocus;
    return node;
  }

  bool get _interactive =>
      !widget.disabled && !widget.loading && (widget.onPress != null || widget.onLongPress != null);

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _commit()),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => _commit()),
  };

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy controller would first be built in dispose()
    // when the press scale is off, which asserts.
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void didUpdateWidget(KumoPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive && _pressed) _setPressed(false);
  }

  @override
  void dispose() {
    _scale.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
    if (value) {
      widget.onPressIn?.call();
    } else {
      widget.onPressOut?.call();
    }
    if (!widget.scaleOnPress || KumoMotion.reduceMotion(context)) {
      _scale.value = 1;
      return;
    }
    KumoMotion.springTo(
      _scale,
      value ? widget.pressScale : 1,
      spring: value ? KumoSprings.press : KumoSprings.standard,
      velocity: _scale.velocity,
    );
  }

  void _commit() {
    if (!_interactive || widget.onPress == null) return;
    // `clock` follows the fake clock in widget tests; DateTime.now() does not.
    final now = clock.now();
    if (widget.debounce > Duration.zero && _lastPress != null && now.difference(_lastPress!) < widget.debounce) {
      return;
    }
    _lastPress = now;
    kumoHaptic(widget.haptic);
    widget.onPress!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.kumo;
    final state = KumoPressState(
      hovered: _hovered && _interactive,
      pressed: _pressed,
      focused: _focusHighlight,
      disabled: widget.disabled,
    );

    Widget surface = widget.builder?.call(context, state) ?? widget.child!;

    if (_focusHighlight && widget.showFocusRing) {
      surface = CustomPaint(
        foregroundPainter: KumoFocusRingPainter(
          borderRadius: widget.borderRadius,
          color: theme.color(widget.focusRingColor),
          width: widget.focusRingWidth,
          offset: widget.focusRingOffset,
        ),
        child: surface,
      );
    }

    if (widget.scaleOnPress) {
      surface = AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: surface,
      );
    }

    final minTarget = widget.minTapTargetSize ?? theme.minTapTarget;
    if (minTarget > 0) {
      surface = ConstrainedBox(
        constraints: BoxConstraints(minWidth: minTarget, minHeight: minTarget),
        child: Center(widthFactor: 1, heightFactor: 1, child: surface),
      );
    }

    // Hover is tracked directly rather than through the focus highlight mode,
    // so a mouse on a touch device (a tablet with a trackpad) still gets it.
    surface = MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: surface,
    );

    final interactive = _interactive;
    Widget result = GestureDetector(
      behavior: widget.behavior,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      onTap: interactive && widget.onPress != null ? _commit : null,
      onLongPress: interactive && widget.onLongPress != null
          ? () {
              _setPressed(false);
              kumoHaptic(KumoHaptic.medium);
              widget.onLongPress!();
            }
          : null,
      child: surface,
    );

    // Semantics sits inside the focus detector so excluding child semantics
    // never drops the focusable flag and focus action.
    result = Semantics(
      button: widget.isButton && !widget.isLink,
      link: widget.isLink,
      enabled: !widget.disabled && !widget.loading,
      selected: widget.selected,
      toggled: widget.toggled,
      checked: widget.checked,
      mixed: widget.mixed,
      expanded: widget.expanded,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      value: widget.semanticValue,
      onTap: interactive && widget.onPress != null ? _commit : null,
      excludeSemantics: widget.excludeChildSemantics,
      child: result,
    );

    result = FocusableActionDetector(
      enabled: interactive,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      actions: _actions,
      mouseCursor: interactive ? (widget.mouseCursor ?? SystemMouseCursors.click) : SystemMouseCursors.basic,
      onShowFocusHighlight: (v) {
        if (_focusHighlight != v) setState(() => _focusHighlight = v);
      },
      child: result,
    );
    return widget.mergeChildSemantics ? MergeSemantics(child: result) : result;
  }
}
