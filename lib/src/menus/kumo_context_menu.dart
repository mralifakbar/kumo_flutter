import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../overlays/kumo_anchored_overlay.dart';
import '../system/kumo_field_box.dart' show KumoPresentation;
import '../system/kumo_haptics.dart';
import 'kumo_dropdown_menu.dart';

/// A menu that opens where the user right-clicks [child], or long-presses
/// it on touch screens. Takes the same items as [KumoDropdownMenu].
///
/// Inspired by shadcn's `ContextMenu` (Kumo has no context menu).
///
/// ```dart
/// KumoContextMenu(
///   items: [
///     KumoDropdownItem(label: 'Copy record ID', icon: KumoIcons.copy, onPress: copyId),
///     const KumoDropdownSeparator(),
///     KumoDropdownItem(label: 'Delete record', icon: KumoIcons.trash, destructive: true, onPress: delete),
///   ],
///   child: const DnsRecordRow(),
/// )
/// ```
///
/// * Desktop: secondary click opens the menu with its corner at the pointer
///   and flips when there is no room. Right-clicking elsewhere on [child]
///   moves it there.
/// * Touch: a long press opens it, with a haptic tick. Below 768px
///   ([KumoPresentation.auto]) it opens as a bottom sheet.
/// * Keyboard: the Menu key or Shift+F10 while focus is inside [child]
///   opens it at the center of [child].
///
/// Context menus are hard to discover. Keep every action also reachable
/// from a visible control, such as a row's overflow [KumoDropdownMenu].
///
/// On the web, call `BrowserContextMenu.disableContextMenu()` so the
/// browser's own menu does not cover this one.
class KumoContextMenu extends StatefulWidget {
  const KumoContextMenu({
    super.key,
    required this.child,
    required this.items,
    this.onOpenChange,
    this.presentation = KumoPresentation.auto,
    this.disabled = false,
    this.semanticLabel,
    this.sheetTitle,
    this.backLabel,
  });

  final Widget child;

  /// Menu content, as in [KumoDropdownMenu.items].
  final List<Widget> items;
  final ValueChanged<bool>? onOpenChange;
  final KumoPresentation presentation;
  final bool disabled;
  final String? semanticLabel;
  final String? sheetTitle;

  /// Accessible name of the back row in a sheet submenu. Defaults to
  /// `KumoStrings.back`.
  final String? backLabel;

  @override
  State<KumoContextMenu> createState() => _KumoContextMenuState();
}

class _KumoContextMenuState extends State<KumoContextMenu> {
  bool _open = false;
  Offset _point = Offset.zero;
  bool _moving = false;

  void _openAt(Offset local) {
    if (widget.disabled) return;
    if (_open) {
      // The same pointer-down also counts as an outside tap for the open
      // menu; keep it open and move it instead.
      _moving = true;
      SchedulerBinding.instance.addPostFrameCallback((_) => _moving = false);
      setState(() => _point = local);
      return;
    }
    setState(() {
      _point = local;
      _open = true;
    });
    widget.onOpenChange?.call(true);
  }

  void _onOpenChange(bool value) {
    if (!value && _moving) return;
    if (value == _open) return;
    setState(() => _open = value);
    widget.onOpenChange?.call(value);
  }

  void _openFromKeyboard() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    _openAt(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    final child = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse && (event.buttons & kSecondaryMouseButton) != 0) {
          _openAt(event.localPosition);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.stylus},
        onLongPressStart: widget.disabled
            ? null
            : (details) {
                kumoHaptic(KumoHaptic.medium);
                _openAt(details.localPosition);
              },
        child: widget.child,
      ),
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent || widget.disabled) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final shiftF10 = key == LogicalKeyboardKey.f10 && HardwareKeyboard.instance.isShiftPressed;
        if (key == LogicalKeyboardKey.contextMenu || shiftF10) {
          _openFromKeyboard();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            left: _point.dx,
            top: _point.dy,
            child: KumoDropdownMenu(
              open: _open,
              onOpenChange: _onOpenChange,
              items: widget.items,
              side: KumoSide.bottom,
              align: KumoAlign.start,
              sideOffset: 2,
              presentation: widget.presentation,
              semanticLabel: widget.semanticLabel,
              sheetTitle: widget.sheetTitle,
              backLabel: widget.backLabel,
              triggerBuilder: (context, menu) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
