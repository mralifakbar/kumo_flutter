import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Kumo easing curves. Kumo animates with Tailwind's timing functions.
abstract final class KumoCurves {
  /// Tailwind's default `ease` (`cubic-bezier(0.4, 0, 0.2, 1)`), for state changes.
  static const Cubic standard = Cubic(0.4, 0, 0.2, 1);

  /// `ease-out`, for things entering the screen.
  static const Cubic enter = Cubic(0, 0, 0.2, 1);

  /// `ease-in`, for things leaving the screen.
  static const Cubic exit = Cubic(0.4, 0, 1, 1);

  /// Kumo's `--ease-bounce` (`cubic-bezier(0.2, 0, 0, 1.5)`): a small overshoot
  /// reserved for confirmation moments such as a check mark landing.
  static const Cubic bounce = Cubic(0.2, 0, 0, 1.5);
  static const Curve linear = Curves.linear;
}

/// Kumo durations. Kumo's default transition is 100ms; hover color changes
/// are instant and never animated.
abstract final class KumoDurations {
  /// Kumo's `--default-transition-duration`: toggles, checks, small fades.
  static const Duration fast = Duration(milliseconds: 100);

  /// Popover, tooltip and menu enter/exit.
  static const Duration quick = Duration(milliseconds: 150);

  /// Expand and collapse, tab indicator moves.
  static const Duration moderate = Duration(milliseconds: 200);

  /// Dialog and sheet fades, theme cross-fades.
  static const Duration slow = Duration(milliseconds: 300);

  /// Spinner revolution while loading.
  static const Duration spin = Duration(milliseconds: 1000);
}

/// Springs for anything a finger can touch. Springs start from the current
/// value and carry velocity, so they can be interrupted and reversed mid-flight
/// without a jump. Parameters are expressed as damping ratio + response
/// (seconds to reach the target), the way Apple's fluid-interface guidance does.
abstract final class KumoSprings {
  /// Builds a spring from a damping ratio and a response time in seconds.
  static SpringDescription of({required double dampingRatio, required double response}) {
    final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
    return SpringDescription.withDampingRatio(mass: 1, stiffness: stiffness, ratio: dampingRatio);
  }

  /// Default for UI that moves on its own: critically damped, no overshoot.
  static final SpringDescription standard = of(dampingRatio: 1, response: 0.35);

  /// Press-down and release feedback. Quick, no bounce.
  static final SpringDescription press = of(dampingRatio: 1, response: 0.2);

  /// After a flick or drag release, where the gesture carried momentum.
  static final SpringDescription momentum = of(dampingRatio: 0.8, response: 0.35);

  /// Popovers, menus and tooltips scaling in from their anchor. Critically
  /// damped and quick, close to Kumo's 150ms popup transition.
  static final SpringDescription popup = of(dampingRatio: 1, response: 0.22);

  /// Sheets settling after a drag.
  static final SpringDescription sheet = of(dampingRatio: 0.86, response: 0.32);
}

/// Motion helpers shared by components.
abstract final class KumoMotion {
  /// Scale applied to pressable surfaces while held.
  static const double pressScale = 0.98;

  /// True when the platform asks for reduced motion. Components swap slides,
  /// springs and loops for short cross-fades or no motion at all.
  static bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Duration to use for a transition, collapsed to zero under reduced motion.
  static Duration duration(BuildContext context, Duration normal) => reduceMotion(context) ? Duration.zero : normal;

  /// Where a flick would come to rest, using exponential deceleration (the same
  /// projection UIScrollView uses). [velocity] is in logical px per second.
  static double project(double velocity, {double decelerationRate = 0.998}) =>
      (velocity / 1000) * decelerationRate / (1 - decelerationRate);

  /// Progressive resistance past a boundary so drags never stop dead.
  static double rubberband(double overshoot, double dimension, {double constant = 0.55}) {
    if (dimension <= 0) return 0;
    return (overshoot * dimension * constant) / (dimension + constant * overshoot.abs());
  }

  /// Drives [controller] to [target] with a spring that starts from the
  /// controller's current value and [velocity] (in controller units per second).
  static TickerFuture springTo(
    AnimationController controller,
    double target, {
    SpringDescription? spring,
    double velocity = 0,
  }) {
    final simulation = SpringSimulation(
      spring ?? KumoSprings.standard,
      controller.value,
      target,
      velocity,
      tolerance: const Tolerance(distance: 0.0005, velocity: 0.01),
    );
    final future = controller.animateWith(simulation);
    // Springs stop within tolerance of the target; land exactly on it so a
    // resting surface is never left a fraction of a pixel off. `then` only runs
    // on completion, not when another animation interrupts this one.
    future.then((_) {
      if (controller.value != target) controller.value = target;
    });
    return future;
  }
}
