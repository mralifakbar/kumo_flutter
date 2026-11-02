import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps keyboard focus inside [child] while it is on screen and hands it
/// back to whatever had focus before when it goes away.
///
/// * Tab and Shift+Tab cycle through the focusable widgets inside and wrap at
///   the ends instead of escaping to the page behind.
/// * Escape calls [onEscPress] when it is set.
/// * On mount, focus moves into the trap; on unmount, the previously focused
///   widget gets focus back ([restoreFocusOnUnmount]).
///
/// Every Kumo modal overlay (dialog, sheet, command palette) already
/// wraps its content in a focus trap. Use this directly for custom overlays.
///
/// ```dart
/// KumoFocusTrap(
///   onEscPress: close,
///   child: MyCustomDialog(),
/// )
/// ```
class KumoFocusTrap extends StatefulWidget {
  const KumoFocusTrap({
    super.key,
    required this.child,
    this.onEscPress,
    this.disableFocusTrap = false,
    this.restoreFocusOnUnmount = true,
    this.disableAutoFocus = false,
    this.disableArrowKeyNavigation = true,
  });

  final Widget child;

  /// Called when Escape is pressed while focus is inside the trap.
  final VoidCallback? onEscPress;

  /// Let Tab move focus out of [child] at the ends.
  final bool disableFocusTrap;

  /// Return focus to the previously focused widget when the trap unmounts.
  final bool restoreFocusOnUnmount;

  /// Do not move focus into the trap on mount.
  final bool disableAutoFocus;

  /// When false, Up and Down arrows also move focus to the previous and next
  /// focusable widget. Off by default so arrow keys keep working inside
  /// multi-line text fields.
  final bool disableArrowKeyNavigation;

  @override
  State<KumoFocusTrap> createState() => _KumoFocusTrapState();
}

class _KumoFocusTrapState extends State<KumoFocusTrap> {
  late final FocusScopeNode _scope = FocusScopeNode(
    debugLabel: 'KumoFocusTrap',
    traversalEdgeBehavior: widget.disableFocusTrap
        ? TraversalEdgeBehavior.parentScope
        : TraversalEdgeBehavior.closedLoop,
  );
  FocusNode? _previousFocus;

  @override
  void initState() {
    super.initState();
    _previousFocus = FocusManager.instance.primaryFocus;
    if (!widget.disableAutoFocus) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_scope.hasFocus) _scope.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(KumoFocusTrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scope.traversalEdgeBehavior = widget.disableFocusTrap
        ? TraversalEdgeBehavior.parentScope
        : TraversalEdgeBehavior.closedLoop;
  }

  bool _hadFocusAtUnmount = false;

  @override
  void deactivate() {
    _hadFocusAtUnmount = _scope.hasFocus;
    super.deactivate();
  }

  @override
  void dispose() {
    final previous = _previousFocus;
    if (widget.restoreFocusOnUnmount && previous != null) {
      // The trap's own scope is still being torn down in this frame; asking
      // for focus afterwards stops the teardown from stealing it back.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Only take focus back when it is still lost (inside this trap or
        // nowhere): another overlay that opened meanwhile keeps its focus.
        final current = FocusManager.instance.primaryFocus;
        final lost =
            current == null ||
            current == FocusManager.instance.rootScope ||
            current.context == null ||
            _hadFocusAtUnmount;
        if (lost && previous.context != null && previous.canRequestFocus) previous.requestFocus();
      });
    }
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = FocusScope(node: _scope, child: widget.child);
    final shortcuts = <ShortcutActivator, Intent>{
      if (widget.onEscPress != null) const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      if (!widget.disableArrowKeyNavigation) ...{
        const SingleActivator(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
      },
    };
    if (widget.onEscPress != null) {
      child = Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              widget.onEscPress!();
              return null;
            },
          ),
        },
        child: child,
      );
    }
    if (shortcuts.isNotEmpty) child = Shortcuts(shortcuts: shortcuts, child: child);
    return child;
  }
}
