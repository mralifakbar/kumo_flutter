import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../system/kumo_focus_trap.dart';
import '../theme/kumo_motion.dart';

/// Which side of the anchor a popup opens on.
enum KumoSide { top, bottom, left, right }

/// How a popup lines up with its anchor along the anchor's edge.
enum KumoAlign {
  /// Leading edges line up (left in LTR, right in RTL).
  start,
  center,

  /// Trailing edges line up.
  end,
}

/// Where a popup ended up after collision handling, handed to
/// [KumoAnchoredOverlay.overlayBuilder].
@immutable
class KumoPopupPlacement {
  const KumoPopupPlacement({
    required this.side,
    required this.align,
    required this.anchorRect,
    required this.maxWidth,
    required this.maxHeight,
    required this.popupRect,
  });

  /// The side actually used: the requested side, or its opposite when the
  /// requested side had too little room.
  final KumoSide side;
  final KumoAlign align;

  /// The anchor's bounds in overlay coordinates.
  final Rect anchorRect;

  /// Room available for the popup on [side], already minus padding.
  final double maxWidth;
  final double maxHeight;

  /// The popup's final bounds, updated during layout. Read it while
  /// painting (an arrow that points at the anchor), not while building.
  final ValueListenable<Rect> popupRect;

  /// Center of the anchor along the popup's edge, in popup coordinates. Use
  /// it in a painter to place an arrow.
  double arrowOffset(Rect popup) => side == KumoSide.top || side == KumoSide.bottom
      ? (anchorRect.center.dx - popup.left).clamp(12.0, math.max(12.0, popup.width - 12))
      : (anchorRect.center.dy - popup.top).clamp(12.0, math.max(12.0, popup.height - 12));
}

/// Builds a popup for a resolved placement.
typedef KumoPopupBuilder = Widget Function(BuildContext context, KumoPopupPlacement placement);

/// The positioning primitive behind every Kumo popover, tooltip, menu,
/// select and combobox.
///
/// * Places the popup on [side] of [child], aligned by [align], and flips to
///   the opposite side when there is not enough room; it then shifts along
///   the edge to stay [collisionPadding] inside the screen.
/// * Follows the anchor as it scrolls or moves.
/// * Opens and closes along the same path: scale from 0.9 and fade, with the
///   transform origin on the anchor (Kumo's 150ms popup motion). The scale is
///   a spring, so reopening mid-close turns around from where it is. Reduced
///   motion leaves only the fade.
/// * Tapping outside (anywhere but the anchor and the popup) and Escape call
///   [onDismiss].
/// * With [trapFocus], focus moves into the popup and Tab cycles inside it;
///   focus returns to the anchor when it closes.
///
/// The parent owns [open]; this widget only reports dismissal:
///
/// ```dart
/// KumoAnchoredOverlay(
///   open: _open,
///   onDismiss: () => setState(() => _open = false),
///   overlayBuilder: (context, placement) => const MyMenu(),
///   child: KumoButton(label: 'Options', onPress: () => setState(() => _open = !_open)),
/// )
/// ```
class KumoAnchoredOverlay extends StatefulWidget {
  const KumoAnchoredOverlay({
    super.key,
    required this.open,
    required this.child,
    required this.overlayBuilder,
    this.onDismiss,
    this.side = KumoSide.bottom,
    this.align = KumoAlign.center,
    this.sideOffset = 8,
    this.alignOffset = 0,
    this.collisionPadding = 8,
    this.preferredExtent = 200,
    this.matchAnchorWidth = false,
    this.dismissOnOutsideTap = true,
    this.closeOnEscape = true,
    this.trapFocus = false,
    this.restoreFocus = true,
    this.useRootOverlay = true,
    this.animate = true,
    this.onClosed,
    this.tapRegionGroupId,
    this.focusPopupWhenUnfocused = true,
  });

  /// Shows the popup while true. Changes animate.
  final bool open;

  /// The anchor (trigger) the popup attaches to.
  final Widget child;
  final KumoPopupBuilder overlayBuilder;

  /// Called on an outside tap or Escape. Set `open` to false in response.
  final VoidCallback? onDismiss;
  final KumoSide side;
  final KumoAlign align;

  /// Gap between anchor and popup.
  final double sideOffset;

  /// Shift along the anchor edge, toward the end for positive values.
  final double alignOffset;

  /// Minimum distance between the popup and the screen edges.
  final double collisionPadding;

  /// Room the popup would like on its side. When [side] has less than this
  /// and the opposite side has more, the popup flips.
  final double preferredExtent;

  /// Make the popup at least as wide as the anchor (selects, comboboxes).
  final bool matchAnchorWidth;
  final bool dismissOnOutsideTap;
  final bool closeOnEscape;

  /// Move focus into the popup and keep Tab inside it (menus, popovers with
  /// forms). Tooltips and comboboxes keep focus on the anchor.
  final bool trapFocus;
  final bool restoreFocus;
  final bool useRootOverlay;

  /// Set false to show and hide instantly.
  final bool animate;

  /// Called after the close animation finishes and the popup is removed.
  final VoidCallback? onClosed;

  /// Taps inside other widgets in this [TapRegion] group do not count as
  /// outside taps. Defaults to a group private to this overlay.
  final Object? tapRegionGroupId;

  /// When nothing has keyboard focus at open (a popup opened by tap), give
  /// the popup focus so Escape reaches it and not a dialog behind it. Focus
  /// returns when the popup closes. Tooltips turn this off.
  final bool focusPopupWhenUnfocused;

  @override
  State<KumoAnchoredOverlay> createState() => _KumoAnchoredOverlayState();
}

class _KumoAnchoredOverlayState extends State<KumoAnchoredOverlay> with TickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _scale;
  late final AnimationController _fade;
  final ValueNotifier<Rect> _popupRect = ValueNotifier(Rect.zero);
  final Object _ownGroup = Object();
  final FocusNode _popupFocus = FocusNode(debugLabel: 'KumoAnchoredOverlay popup', skipTraversal: true);
  FocusNode? _focusBeforeOpen;
  bool _closing = false;

  // Open overlays, most recent last. When nothing has keyboard focus (a
  // popup opened by mouse or touch), Escape closes the most recent one.
  static final List<_KumoAnchoredOverlayState> _openStack = [];
  static bool _keyHandlerAdded = false;

  static bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (_openStack.isEmpty) return false;
    final focus = FocusManager.instance.primaryFocus;
    final nothingFocused = focus == null || focus == FocusManager.instance.rootScope;
    if (!nothingFocused) return false;
    final top = _openStack.last;
    if (!top.widget.closeOnEscape) return false;
    top._dismiss();
    return true;
  }

  void _register(bool open) {
    _openStack.remove(this);
    if (open) {
      _openStack.add(this);
      if (!_keyHandlerAdded) {
        _keyHandlerAdded = true;
        HardwareKeyboard.instance.addHandler(_handleGlobalKey);
      }
    }
  }

  Object get _group => widget.tapRegionGroupId ?? _ownGroup;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 0.9);
    _fade = AnimationController(vsync: this, duration: KumoDurations.quick);
    if (widget.open) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.open) _show();
      });
    }
  }

  @override
  void didUpdateWidget(KumoAnchoredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      // OverlayPortalController cannot change during build; defer a frame.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.open ? _show() : _hide();
      });
    }
  }

  @override
  void dispose() {
    _register(false);
    _popupFocus.dispose();
    _scale.dispose();
    _fade.dispose();
    _popupRect.dispose();
    super.dispose();
  }

  bool get _instant => !widget.animate || KumoMotion.reduceMotion(context);

  void _show() {
    _register(true);
    _closing = false;
    final focus = FocusManager.instance.primaryFocus;
    if (!widget.trapFocus && widget.focusPopupWhenUnfocused && (focus == null || focus is FocusScopeNode)) {
      _focusBeforeOpen = focus;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.open && _popupFocus.context != null) _popupFocus.requestFocus();
      });
    }
    if (!_portal.isShowing) {
      setState(_portal.show);
      if (_fade.value == 0) _scale.value = 0.9;
    }
    if (!widget.animate) {
      _fade.value = 1;
      _scale.value = 1;
      return;
    }
    if (KumoMotion.reduceMotion(context)) {
      _scale.value = 1;
      _fade.forward();
      return;
    }
    _fade.forward();
    KumoMotion.springTo(_scale, 1, spring: KumoSprings.popup, velocity: _scale.velocity);
  }

  void _hide() {
    _register(false);
    if (_popupFocus.hasFocus) {
      final previous = _focusBeforeOpen;
      if (previous != null && previous.context != null && previous.canRequestFocus) {
        previous.requestFocus();
      } else {
        _popupFocus.unfocus();
      }
    }
    _focusBeforeOpen = null;
    if (!_portal.isShowing) return;
    setState(() => _closing = true);
    void finish() {
      if (!mounted || !_closing) return;
      setState(_portal.hide);
      _closing = false;
      widget.onClosed?.call();
    }

    if (_instant) {
      _fade.value = 0;
      finish();
      return;
    }
    KumoMotion.springTo(_scale, 0.9, spring: KumoSprings.popup, velocity: _scale.velocity);
    _fade.reverse().whenComplete(finish);
  }

  void _dismiss() {
    if (widget.open) widget.onDismiss?.call();
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final anchorRect = MatrixUtils.transformRect(info.childPaintTransform, Offset.zero & info.childSize);
    final overlay = info.overlaySize;
    final padding = widget.collisionPadding;
    final viewPadding = MediaQuery.maybeViewPaddingOf(context) ?? EdgeInsets.zero;
    // The on-screen keyboard counts as an edge, so popups flip above it.
    final keyboard = MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0;
    final bounds = Rect.fromLTRB(
      padding + viewPadding.left,
      padding + viewPadding.top,
      overlay.width - padding - viewPadding.right,
      overlay.height - padding - (keyboard > viewPadding.bottom ? keyboard : viewPadding.bottom),
    );

    double room(KumoSide s) => switch (s) {
      KumoSide.bottom => bounds.bottom - anchorRect.bottom - widget.sideOffset,
      KumoSide.top => anchorRect.top - widget.sideOffset - bounds.top,
      KumoSide.left => anchorRect.left - widget.sideOffset - bounds.left,
      KumoSide.right => bounds.right - anchorRect.right - widget.sideOffset,
    };
    KumoSide opposite(KumoSide s) => switch (s) {
      KumoSide.bottom => KumoSide.top,
      KumoSide.top => KumoSide.bottom,
      KumoSide.left => KumoSide.right,
      KumoSide.right => KumoSide.left,
    };

    var side = widget.side;
    if (room(side) < widget.preferredExtent && room(opposite(side)) > room(side)) side = opposite(side);
    final vertical = side == KumoSide.top || side == KumoSide.bottom;
    final maxHeight = math.max(0.0, vertical ? room(side) : bounds.height);
    final maxWidth = math.max(0.0, vertical ? bounds.width : room(side));

    final rtl = Directionality.of(context) == TextDirection.rtl;
    final placement = KumoPopupPlacement(
      side: side,
      align: widget.align,
      anchorRect: anchorRect,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      popupRect: _popupRect,
    );

    final origin = _origin(side, widget.align, rtl);
    Widget popup = widget.overlayBuilder(context, placement);
    popup = AnimatedBuilder(
      animation: Listenable.merge([_scale, _fade]),
      builder: (context, child) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: _scale.value, alignment: origin, child: child),
      ),
      child: popup,
    );
    if (widget.trapFocus) {
      popup = KumoFocusTrap(
        onEscPress: widget.closeOnEscape ? _dismiss : null,
        restoreFocusOnUnmount: widget.restoreFocus,
        child: popup,
      );
    } else {
      // The Escape handler must sit above the focus node: key events bubble
      // up from the focused node, never down into its children.
      popup = Focus(focusNode: _popupFocus, child: popup);
      if (widget.closeOnEscape) popup = _EscapeHandler(onEscape: _dismiss, child: popup);
    }
    popup = TapRegion(
      groupId: _group,
      onTapOutside: widget.dismissOnOutsideTap ? (_) => _dismiss() : null,
      child: popup,
    );
    // While closing, the popup ignores pointers so a quick tap behind it lands.
    popup = IgnorePointer(ignoring: _closing, child: popup);

    return CustomSingleChildLayout(
      delegate: _PopupLayout(
        anchor: anchorRect,
        bounds: bounds,
        side: side,
        align: widget.align,
        rtl: rtl,
        sideOffset: widget.sideOffset,
        alignOffset: widget.alignOffset,
        minWidth: widget.matchAnchorWidth ? anchorRect.width : 0,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        onPositioned: (rect) => _popupRect.value = rect,
      ),
      child: popup,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always present (with no bindings while closed) so opening never
    // changes the tree above the anchor and drops its focus.
    final anchor = CallbackShortcuts(
      bindings: {if (widget.open && widget.closeOnEscape) const SingleActivator(LogicalKeyboardKey.escape): _dismiss},
      child: TapRegion(groupId: _group, child: widget.child),
    );
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayLocation: widget.useRootOverlay ? OverlayChildLocation.rootOverlay : OverlayChildLocation.nearestOverlay,
      overlayChildBuilder: _buildOverlay,
      child: anchor,
    );
  }
}

Alignment _origin(KumoSide side, KumoAlign align, bool rtl) {
  final cross = switch (align) {
    KumoAlign.start => rtl ? 1.0 : -1.0,
    KumoAlign.center => 0.0,
    KumoAlign.end => rtl ? -1.0 : 1.0,
  };
  return switch (side) {
    KumoSide.bottom => Alignment(cross, -1),
    KumoSide.top => Alignment(cross, 1),
    KumoSide.left => Alignment(1, cross == 0 ? 0 : (align == KumoAlign.start ? -1 : 1)),
    KumoSide.right => Alignment(-1, cross == 0 ? 0 : (align == KumoAlign.start ? -1 : 1)),
  };
}

class _EscapeHandler extends StatelessWidget {
  const _EscapeHandler({required this.onEscape, required this.child});

  final VoidCallback onEscape;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CallbackShortcuts(bindings: {const SingleActivator(LogicalKeyboardKey.escape): onEscape}, child: child);
}

class _PopupLayout extends SingleChildLayoutDelegate {
  _PopupLayout({
    required this.anchor,
    required this.bounds,
    required this.side,
    required this.align,
    required this.rtl,
    required this.sideOffset,
    required this.alignOffset,
    required this.minWidth,
    required this.maxWidth,
    required this.maxHeight,
    required this.onPositioned,
  });

  final Rect anchor;
  final Rect bounds;
  final KumoSide side;
  final KumoAlign align;
  final bool rtl;
  final double sideOffset;
  final double alignOffset;
  final double minWidth;
  final double maxWidth;
  final double maxHeight;
  final ValueChanged<Rect> onPositioned;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(minWidth: math.min(minWidth, maxWidth), maxWidth: maxWidth, maxHeight: maxHeight);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final vertical = side == KumoSide.top || side == KumoSide.bottom;
    double x;
    double y;
    if (vertical) {
      y = side == KumoSide.bottom ? anchor.bottom + sideOffset : anchor.top - sideOffset - childSize.height;
      final start = rtl ? anchor.right - childSize.width : anchor.left;
      final end = rtl ? anchor.left : anchor.right - childSize.width;
      x = switch (align) {
        KumoAlign.start => start,
        KumoAlign.center => anchor.center.dx - childSize.width / 2,
        KumoAlign.end => end,
      };
      x += rtl ? -alignOffset : alignOffset;
      x = x.clamp(bounds.left, math.max(bounds.left, bounds.right - childSize.width));
    } else {
      x = side == KumoSide.right ? anchor.right + sideOffset : anchor.left - sideOffset - childSize.width;
      y = switch (align) {
        KumoAlign.start => anchor.top,
        KumoAlign.center => anchor.center.dy - childSize.height / 2,
        KumoAlign.end => anchor.bottom - childSize.height,
      };
      y += alignOffset;
      y = y.clamp(bounds.top, math.max(bounds.top, bounds.bottom - childSize.height));
    }
    final rect = Offset(x, y) & childSize;
    // Painters read this after layout; the notifier must not rebuild widgets.
    onPositioned(rect);
    return rect.topLeft;
  }

  @override
  bool shouldRelayout(_PopupLayout old) =>
      old.anchor != anchor ||
      old.bounds != bounds ||
      old.side != side ||
      old.align != align ||
      old.rtl != rtl ||
      old.sideOffset != sideOffset ||
      old.alignOffset != alignOffset ||
      old.minWidth != minWidth ||
      old.maxWidth != maxWidth ||
      old.maxHeight != maxHeight;
}
