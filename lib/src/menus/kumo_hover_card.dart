import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_popup_surface.dart';
import '../system/kumo_haptics.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// A preview card that opens while the pointer rests on [child]: a Worker's
/// latest deployment behind its name, a zone's status behind a link.
///
/// Inspired by shadcn's `HoverCard` (Kumo has no hover card).
///
/// ```dart
/// KumoHoverCard(
///   content: const Column(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     mainAxisSize: MainAxisSize.min,
///     children: [KumoText('image-resizer', bold: true), KumoText('Deployed 2 hours ago')],
///   ),
///   child: KumoButton(label: 'image-resizer', variant: KumoButtonVariant.ghost, onPress: openWorker),
/// )
/// ```
///
/// * Pointer: opens after [openDelay], stays open while the pointer is on
///   the trigger or the card, and closes [closeDelay] after it leaves both.
/// * Keyboard: opens while the trigger has keyboard focus.
/// * Touch: a long press opens it; a tap anywhere else closes it. A plain
///   tap still activates the trigger.
///
/// Touch and screen reader users can miss a hover card, so it must never be
/// the only way to reach what it shows: link the trigger to the full page.
class KumoHoverCard extends StatefulWidget {
  const KumoHoverCard({
    super.key,
    required this.child,
    required this.content,
    this.openDelay = const Duration(milliseconds: 700),
    this.closeDelay = const Duration(milliseconds: 300),
    this.side = KumoSide.bottom,
    this.align = KumoAlign.center,
    this.sideOffset = 8,
    this.alignOffset = 0,
    this.showArrow = false,
    this.width = 256,
    this.padding = const EdgeInsets.all(KumoSpace.s4),
    this.disabled = false,
    this.open,
    this.onOpenChange,
  });

  /// The trigger. Keep it interactive on its own (a link or button).
  final Widget child;

  /// Card content.
  final Widget content;
  final Duration openDelay;
  final Duration closeDelay;
  final KumoSide side;
  final KumoAlign align;
  final double sideOffset;
  final double alignOffset;
  final bool showArrow;

  /// shadcn's `w-64`. Null sizes to the content.
  final double? width;
  final EdgeInsetsGeometry padding;
  final bool disabled;

  /// Controls the open state. Leave null to let hover and focus drive it.
  final bool? open;
  final ValueChanged<bool>? onOpenChange;

  @override
  State<KumoHoverCard> createState() => _KumoHoverCardState();
}

class _KumoHoverCardState extends State<KumoHoverCard> {
  bool _internalOpen = false;
  bool _overTrigger = false;
  bool _overCard = false;
  bool _focused = false;
  Timer? _timer;

  bool get _open => widget.open ?? _internalOpen;

  @override
  void didUpdateWidget(KumoHoverCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled && _open) _setOpen(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setOpen(bool value) {
    _timer?.cancel();
    if (!mounted || value == _open) return;
    if (value && widget.disabled) return;
    if (widget.open == null) setState(() => _internalOpen = value);
    widget.onOpenChange?.call(value);
  }

  void _scheduleOpen() {
    _timer?.cancel();
    if (_open || widget.disabled) return;
    _timer = Timer(widget.openDelay, () => _setOpen(true));
  }

  void _scheduleClose() {
    _timer?.cancel();
    if (_overTrigger || _overCard || _focused) return;
    if (!_open) return;
    _timer = Timer(widget.closeDelay, () => _setOpen(false));
  }

  @override
  Widget build(BuildContext context) {
    final trigger = MouseRegion(
      opaque: false,
      onEnter: (event) {
        if (event.kind == PointerDeviceKind.touch) return;
        _overTrigger = true;
        _scheduleOpen();
      },
      onExit: (_) {
        _overTrigger = false;
        _scheduleClose();
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (hasFocus) {
          final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
          _focused = hasFocus && keyboard;
          if (_focused) {
            _setOpen(true);
          } else {
            _scheduleClose();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.stylus},
          onLongPress: widget.disabled
              ? null
              : () {
                  kumoHaptic(KumoHaptic.medium);
                  _setOpen(true);
                },
          child: widget.child,
        ),
      ),
    );

    return KumoAnchoredOverlay(
      open: _open,
      side: widget.side,
      align: widget.align,
      sideOffset: widget.sideOffset,
      alignOffset: widget.alignOffset,
      // A preview never takes focus from the page.
      focusPopupWhenUnfocused: false,
      onDismiss: () => _setOpen(false),
      overlayBuilder: (context, placement) => MouseRegion(
        onEnter: (_) {
          _overCard = true;
          _timer?.cancel();
        },
        onExit: (_) {
          _overCard = false;
          _scheduleClose();
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: placement.maxHeight),
          child: SizedBox(
            width: widget.width,
            child: KumoPopupSurface(
              placement: placement,
              showArrow: widget.showArrow,
              shadow: KumoShadow.md,
              padding: widget.padding,
              child: DefaultTextStyle(
                style: context.kumo.text(size: KumoTextSize.base),
                child: SingleChildScrollView(child: widget.content),
              ),
            ),
          ),
        ),
      ),
      child: trigger,
    );
  }
}
