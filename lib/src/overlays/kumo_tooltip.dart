import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_anchored_overlay.dart';
import 'kumo_popup_surface.dart';

/// Kumo's `Tooltip`: a short label for a control, shown on hover after a
/// delay, immediately on keyboard focus, and on long press with touch.
///
/// Tooltips only describe; they never hold the only copy of information or
/// any interactive content. The text is also exposed to screen readers as
/// the child's tooltip.
///
/// ```dart
/// KumoTooltip(
///   content: 'Copy API token',
///   child: KumoButton(icon: KumoIcons.copy, shape: KumoButtonShape.square, semanticLabel: 'Copy', onPress: copy),
/// )
/// ```
class KumoTooltip extends StatefulWidget {
  const KumoTooltip({
    super.key,
    required this.content,
    required this.child,
    this.side = KumoSide.top,
    this.align = KumoAlign.center,
    this.delay = const Duration(milliseconds: 600),
    this.closeDelay = Duration.zero,
    this.touchDuration = const Duration(milliseconds: 1500),
    this.disabled = false,
    this.showArrow = true,
    this.open,
    this.onOpenChange,
  });

  final String content;
  final Widget child;
  final KumoSide side;
  final KumoAlign align;

  /// Hover time before the tooltip shows. After one tooltip closes, the next
  /// shows without delay and without its entrance animation for a moment, so
  /// scanning a toolbar is quick. Closing starts as soon as the pointer
  /// leaves (see [closeDelay]); Escape closes without animating.
  final Duration delay;
  final Duration closeDelay;

  /// How long a long-press tooltip stays up on touch screens.
  final Duration touchDuration;
  final bool disabled;
  final bool showArrow;

  /// Controls visibility from outside. Null (the default) keeps the built-in
  /// hover, focus and long-press behavior.
  final bool? open;

  /// Called when the tooltip wants to open or close (hover, focus, long
  /// press, Escape). Required to react to those when [open] is set.
  final ValueChanged<bool>? onOpenChange;

  @override
  State<KumoTooltip> createState() => _KumoTooltipState();
}

// Shared warm-up window: a tooltip that closed recently lets the next one
// open instantly.
DateTime? _lastClosed;
const Duration _warmWindow = Duration(milliseconds: 400);

class _KumoTooltipState extends State<KumoTooltip> {
  bool _open = false;
  Timer? _timer;
  bool _hovered = false;
  bool _focused = false;

  /// Skip the scale and fade, like Base UI's `data-instant`: a tooltip that
  /// opens during the warm-up window (scanning a toolbar) appears at once,
  /// and one dismissed with Escape disappears at once.
  bool _instant = false;

  /// When this tooltip last closed. Hovering it again while its exit is
  /// still running turns the exit around from where it is, rather than
  /// snapping to the open state.
  DateTime? _closedAt;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(KumoTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled && _visible) _setOpen(false);
  }

  bool get _visible => widget.open ?? _open;

  void _setOpen(bool value, {bool instant = false}) {
    _timer?.cancel();
    if (_visible == value || !mounted) return;
    if (!value) _lastClosed = _closedAt = clock.now();
    if (widget.open != null) {
      if (_instant != instant) setState(() => _instant = instant);
      widget.onOpenChange?.call(value);
      return;
    }
    setState(() {
      _open = value;
      _instant = instant;
    });
    widget.onOpenChange?.call(value);
  }

  void _scheduleOpen() {
    if (widget.disabled) return;
    _timer?.cancel();
    final now = clock.now();
    bool within(DateTime? at, Duration window) {
      if (at == null) return false;
      final since = now.difference(at);
      // A clock that moved backwards (a test's fake clock, a device time
      // change) must not leave every tooltip warm.
      return !since.isNegative && since < window;
    }

    final warm = within(_lastClosed, _warmWindow);
    final stillClosing = within(_closedAt, KumoDurations.slow);
    if (warm) {
      _setOpen(true, instant: !stillClosing);
    } else if (widget.delay == Duration.zero) {
      _setOpen(true);
    } else {
      _timer = Timer(widget.delay, () => _setOpen(true));
    }
  }

  void _scheduleClose() {
    _timer?.cancel();
    if (_hovered || _focused) return;
    if (widget.closeDelay == Duration.zero) {
      _setOpen(false);
    } else {
      _timer = Timer(widget.closeDelay, () => _setOpen(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final Widget trigger = MouseRegion(
      opaque: false,
      onEnter: (e) {
        if (e.kind == PointerDeviceKind.touch) return;
        _hovered = true;
        _scheduleOpen();
      },
      onExit: (_) {
        _hovered = false;
        _scheduleClose();
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (hasFocus) {
          // Only keyboard focus shows a tooltip; a tap that focuses a button
          // should not.
          final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
          _focused = hasFocus && keyboard;
          if (_focused) {
            _setOpen(!widget.disabled);
          } else {
            _scheduleClose();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: widget.disabled
              ? null
              : () {
                  _setOpen(true);
                  _timer = Timer(widget.touchDuration, () => _setOpen(false));
                },
          child: Semantics(tooltip: widget.content, child: widget.child),
        ),
      ),
    );

    return KumoAnchoredOverlay(
      open: _visible && !widget.disabled,
      side: widget.side,
      align: widget.align,
      sideOffset: widget.showArrow ? 6 + KumoPopupSurface.arrowHeight : 6,
      preferredExtent: 40,
      focusPopupWhenUnfocused: false,
      animate: !_instant,
      onDismiss: () => _setOpen(false, instant: true),
      overlayBuilder: (context, placement) => IgnorePointer(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: KumoPopupSurface(
            placement: placement,
            showArrow: widget.showArrow,
            borderRadius: KumoRadius.md,
            shadow: KumoShadow.md,
            padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2_5, vertical: KumoSpace.s1_5),
            child: ExcludeSemantics(
              child: Text(widget.content, style: kumo.text(size: KumoTextSize.sm, height: 1.4)),
            ),
          ),
        ),
      ),
      child: trigger,
    );
  }
}
