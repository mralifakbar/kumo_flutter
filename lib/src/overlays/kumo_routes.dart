import 'package:flutter/widgets.dart';

import '../system/kumo_focus_trap.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import 'kumo_scrim.dart';

/// How a dialog route enters and leaves.
enum KumoDialogTransition {
  /// Fade plus a scale from 0.9, Kumo's dialog motion (150ms).
  scale,

  /// Fade plus a 40px rise, for full-screen pages on phones.
  slideUp,
}

/// A route that draws the Kumo backdrop and runs Kumo dialog motion around
/// [builder]. Escape, a backdrop tap and the system back gesture pop it.
///
/// Usually reached through `showKumoDialog`; use it directly to push a
/// custom dialog:
///
/// ```dart
/// Navigator.of(context).push(KumoDialogRoute<void>(builder: (_) => const MyPanel()));
/// ```
class KumoDialogRoute<T> extends PopupRoute<T> {
  KumoDialogRoute({
    required this.builder,
    this.transition = KumoDialogTransition.scale,
    this.dismissible = true,
    this.closeOnEscape = true,
    this.restoreFocusOnUnmount = true,
    this.showScrim = true,
    this.semanticLabel,
    super.settings,
  });

  final WidgetBuilder builder;
  final KumoDialogTransition transition;

  /// A backdrop tap closes the dialog. Alert dialogs turn this off.
  final bool dismissible;
  final bool closeOnEscape;
  final bool restoreFocusOnUnmount;
  final bool showScrim;
  final String? semanticLabel;

  bool get _reduceMotion {
    final nav = navigator;
    return nav != null && KumoMotion.reduceMotion(nav.context);
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => _reduceMotion ? KumoDurations.fast : KumoDurations.quick;

  @override
  Duration get reverseTransitionDuration => _reduceMotion ? KumoDurations.fast : KumoDurations.quick;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    // ModalRoute only handles Escape for barrier-dismissible routes, and the
    // backdrop here is drawn by the route itself, so Escape is wired directly.
    final kumo = KumoTheme.of(context);
    // Dialogs live in their own route, outside the app's DefaultTextStyle.
    final content = KumoFocusTrap(
      restoreFocusOnUnmount: restoreFocusOnUnmount,
      onEscPress: closeOnEscape ? () => navigator?.maybePop() : null,
      child: DefaultTextStyle(
        style: kumo.text(),
        child: IconTheme(
          data: IconThemeData(color: kumo.colors.textDefault, size: 16),
          child: Builder(builder: builder),
        ),
      ),
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: semanticLabel != null,
      explicitChildNodes: true,
      label: semanticLabel,
      child: content,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduce = KumoMotion.reduceMotion(context);
    final fade = CurvedAnimation(parent: animation, curve: KumoCurves.standard);
    Widget content = FadeTransition(opacity: fade, child: child);
    if (!reduce) {
      content = transition == KumoDialogTransition.scale
          ? ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1).animate(fade), child: content)
          : AnimatedBuilder(
              animation: fade,
              builder: (context, child) => Transform.translate(offset: Offset(0, 40 * (1 - fade.value)), child: child),
              child: content,
            );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showScrim)
          FadeTransition(
            opacity: fade,
            child: KumoScrim(onPress: dismissible ? () => navigator?.maybePop() : null),
          ),
        content,
      ],
    );
  }
}

/// Route for sheets opened with [showKumoSheet]. The sheet widget owns all motion; the
/// route only waits for the sheet to say its exit is done before it
/// finalizes, so `Navigator.pop` still animates the sheet out along the path
/// it came in on.
class KumoSheetRoute<T> extends PopupRoute<T> {
  KumoSheetRoute({required this.builder, this.semanticLabel, super.settings});

  final WidgetBuilder builder;
  final String? semanticLabel;
  bool _exitDone = false;

  /// Called by the sheet once it is fully off screen.
  void completeExit() => _exitDone = true;

  /// True once a pop has started (by gesture, back button or code).
  bool get isExiting => animation?.status == AnimationStatus.reverse || _exitDone;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Simulation? createSimulation({required bool forward}) => forward ? null : _SheetExitSimulation(this);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Semantics(
      scopesRoute: true,
      namesRoute: semanticLabel != null,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Builder(builder: builder),
    );
  }
}

/// Holds the route "visible" until the sheet reports its exit finished. The
/// time cap keeps a route from lingering if its sheet never reports back.
class _SheetExitSimulation extends Simulation {
  _SheetExitSimulation(this.route);

  final KumoSheetRoute<dynamic> route;

  @override
  double x(double time) => route._exitDone ? 0 : 1;

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => route._exitDone || time > 2;
}
