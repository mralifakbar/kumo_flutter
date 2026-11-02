import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_collapsible.dart';

/// Where a step stands. Each state has its own marker, so status never rests
/// on color alone.
enum KumoStepsState {
  /// Not reached yet: an outlined circle with the step number.
  upcoming,

  /// The step in progress: a filled circle with the step number.
  current,

  /// Done: a filled circle with a check.
  complete,

  /// Needs attention: a red circle with a cross, and the title in danger text.
  error,
}

/// Layout of a [KumoSteps].
enum KumoStepsOrientation {
  /// Horizontal when every step gets about 150px and the window is at least
  /// 768px wide; vertical otherwise.
  auto,
  horizontal,
  vertical,
}

/// Default screen reader names for each [KumoStepsState].
const Map<KumoStepsState, String> kumoStepsStateLabels = {
  KumoStepsState.upcoming: 'Not started',
  KumoStepsState.current: 'Current step',
  KumoStepsState.complete: 'Completed',
  KumoStepsState.error: 'Has errors',
};

/// One step of a [KumoSteps].
///
/// ```dart
/// const KumoStepsItem(title: 'Add DNS records', description: 'Point example.com at Cloudflare')
/// ```
@immutable
class KumoStepsItem {
  const KumoStepsItem({required this.title, this.description, this.state});

  final String title;
  final String? description;

  /// Overrides the state derived from [KumoSteps.current] (to flag an error).
  final KumoStepsState? state;
}

/// A progress indicator for multi-step flows: numbered markers joined by
/// connectors, horizontal on wide layouts and vertical on narrow ones.
/// Shaped after shadcn's steps, drawn with Kumo tokens.
///
/// Steps before [current] are complete, [current] is in progress and the
/// rest are upcoming, unless an item sets its own [KumoStepsItem.state].
///
/// ```dart
/// KumoSteps(
///   current: 1,
///   steps: const [
///     KumoStepsItem(title: 'Choose a plan'),
///     KumoStepsItem(title: 'Add DNS records'),
///     KumoStepsItem(title: 'Change nameservers'),
///   ],
/// )
/// ```
///
/// With [onStepPress], steps become buttons (to jump back to an earlier one).
/// For a flow with content and Back / Continue buttons, use [KumoStepper].
class KumoSteps extends StatelessWidget {
  const KumoSteps({
    super.key,
    required this.steps,
    required this.current,
    this.orientation = KumoStepsOrientation.auto,
    this.onStepPress,
    this.stateLabels = kumoStepsStateLabels,
    this.semanticLabel,
  });

  final List<KumoStepsItem> steps;

  /// Index of the step in progress, 0-based. `steps.length` marks all done.
  final int current;
  final KumoStepsOrientation orientation;

  /// Makes steps pressable; receives the pressed index.
  final ValueChanged<int>? onStepPress;

  /// Screen reader names for each state.
  final Map<KumoStepsState, String> stateLabels;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _StepsView(
      steps: [for (final s in steps) (title: s.title, description: s.description, state: s.state)],
      current: current,
      orientation: orientation,
      onStepPress: onStepPress,
      stateLabels: stateLabels,
      semanticLabel: semanticLabel,
    );
  }
}

/// One step of a [KumoStepper]: its marker, title and the content shown
/// while it is current.
@immutable
class KumoStepperStep {
  const KumoStepperStep({
    required this.title,
    required this.child,
    this.description,
    this.state,
    this.canContinue = true,
  });

  final String title;
  final String? description;

  /// Content shown while this step is current.
  final Widget child;

  /// Overrides the derived state, for example [KumoStepsState.error] after
  /// a failed validation.
  final KumoStepsState? state;

  /// False disables the Continue button on this step.
  final bool canContinue;
}

/// A multi-step flow: [KumoSteps] plus the current step's content and Back /
/// Continue buttons. Horizontal layouts show the content below the steps
/// with a short cross-fade; vertical layouts open it under the current step.
///
/// Controlled: [value] is the current index and [onValueChange] receives
/// the next one. The last step's primary button calls [onComplete].
///
/// ```dart
/// KumoStepper(
///   value: step,
///   onValueChange: (v) => setState(() => step = v),
///   completeLabel: 'Activate zone',
///   onComplete: activate,
///   steps: const [
///     KumoStepperStep(title: 'Add site', child: KumoText('Enter example.com')),
///     KumoStepperStep(title: 'Review DNS', child: KumoText('12 records found')),
///     KumoStepperStep(title: 'Change nameservers', child: KumoText('Update at your registrar')),
///   ],
/// )
/// ```
class KumoStepper extends StatelessWidget {
  const KumoStepper({
    super.key,
    required this.steps,
    required this.value,
    required this.onValueChange,
    this.onComplete,
    this.completeLabel,
    this.nextLabel,
    this.backLabel,
    this.orientation = KumoStepsOrientation.auto,
    this.linear = true,
    this.completing = false,
    this.stateLabels = kumoStepsStateLabels,
    this.semanticLabel,
  });

  final List<KumoStepperStep> steps;

  /// Current step, 0-based.
  final int value;
  final ValueChanged<int>? onValueChange;

  /// Called by the primary button on the last step.
  final VoidCallback? onComplete;

  /// Label of the primary button on the last step. Name the outcome
  /// ("Create Worker", "Activate zone"). Defaults to [KumoStrings.finish].
  final String? completeLabel;

  /// Defaults to [KumoStrings.next].
  final String? nextLabel;

  /// Defaults to [KumoStrings.previous].
  final String? backLabel;
  final KumoStepsOrientation orientation;

  /// When true, only earlier steps can be revisited by pressing them; later
  /// steps are reached with Continue.
  final bool linear;

  /// Shows the complete button as loading while the flow submits.
  final bool completing;
  final Map<KumoStepsState, String> stateLabels;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final last = value >= steps.length - 1;
    final step = value.clamp(0, steps.length - 1);

    Widget controls() => Wrap(
      alignment: WrapAlignment.end,
      spacing: KumoSpace.s2,
      runSpacing: KumoSpace.s2,
      children: [
        KumoButton(
          label: backLabel ?? strings.previous,
          onPress: value > 0 && onValueChange != null ? () => onValueChange!(value - 1) : null,
        ),
        KumoButton(
          label: last ? (completeLabel ?? strings.finish) : (nextLabel ?? strings.next),
          variant: KumoButtonVariant.primary,
          loading: last && completing,
          onPress: !steps[step].canContinue
              ? null
              : last
              ? onComplete
              : (onValueChange == null ? null : () => onValueChange!(value + 1)),
        ),
      ],
    );

    return _StepsView(
      steps: [for (final s in steps) (title: s.title, description: s.description, state: s.state)],
      current: value,
      orientation: orientation,
      stateLabels: stateLabels,
      semanticLabel: semanticLabel,
      onStepPress: onValueChange == null
          ? null
          : (i) {
              if (i == value) return;
              if (linear && i > value) return;
              onValueChange!(i);
            },
      pressable: (i) => !linear || i < value,
      inlineContent: (i) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s4,
        children: [steps[i].child, controls()],
      ),
      belowContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s4,
        children: [
          _StepContent(
            child: AnimatedSwitcher(
              duration: KumoMotion.duration(context, KumoDurations.moderate),
              switchInCurve: KumoCurves.enter,
              switchOutCurve: KumoCurves.exit,
              layoutBuilder: (current, previous) => Stack(
                alignment: AlignmentDirectional.topStart,
                // Same wrappers, keyed like the transitions, for outgoing and
                // incoming content, so a child keeps its state as it leaves.
                children: [
                  for (final p in previous)
                    ExcludeFocus(
                      key: p.key,
                      child: ExcludeSemantics(child: p),
                    ),
                  if (current != null)
                    ExcludeFocus(
                      key: current.key,
                      excluding: false,
                      child: ExcludeSemantics(excluding: false, child: current),
                    ),
                ],
              ),
              child: KeyedSubtree(key: ValueKey(step), child: steps[step].child),
            ),
          ),
          controls(),
        ],
      ),
    );
  }
}

typedef _StepData = ({String title, String? description, KumoStepsState? state});

class _StepsView extends StatefulWidget {
  const _StepsView({
    required this.steps,
    required this.current,
    required this.orientation,
    required this.stateLabels,
    this.onStepPress,
    this.pressable,
    this.semanticLabel,
    this.inlineContent,
    this.belowContent,
  });

  final List<_StepData> steps;
  final int current;
  final KumoStepsOrientation orientation;
  final Map<KumoStepsState, String> stateLabels;
  final ValueChanged<int>? onStepPress;
  final bool Function(int index)? pressable;
  final String? semanticLabel;

  /// Vertical layout: content opened under the current step.
  final Widget Function(int index)? inlineContent;

  /// Horizontal layout: content under the row of steps.
  final Widget? belowContent;

  @override
  State<_StepsView> createState() => _StepsViewState();
}

class _StepsViewState extends State<_StepsView> {
  // A step turns into a button once it can be revisited. The keys keep its
  // marker and connector (and their running animations) across that change.
  final List<GlobalKey> _stepKeys = [];

  List<_StepData> get steps => widget.steps;
  int get current => widget.current;
  KumoStepsOrientation get orientation => widget.orientation;
  Map<KumoStepsState, String> get stateLabels => widget.stateLabels;
  ValueChanged<int>? get onStepPress => widget.onStepPress;
  bool Function(int index)? get pressable => widget.pressable;
  String? get semanticLabel => widget.semanticLabel;
  Widget Function(int index)? get inlineContent => widget.inlineContent;
  Widget? get belowContent => widget.belowContent;

  KumoStepsState _stateOf(int i) =>
      steps[i].state ??
      (i < current
          ? KumoStepsState.complete
          : i == current
          ? KumoStepsState.current
          : KumoStepsState.upcoming);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = switch (orientation) {
          KumoStepsOrientation.horizontal => false,
          KumoStepsOrientation.vertical => true,
          KumoStepsOrientation.auto => context.kumoIsNarrow || constraints.maxWidth < steps.length * 150,
        };
        final list = vertical ? _vertical(context) : _horizontal(context);
        final labelled = Semantics(container: true, explicitChildNodes: true, label: semanticLabel, child: list);
        if (vertical || belowContent == null) return labelled;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s6,
          children: [labelled, belowContent!],
        );
      },
    );
  }

  bool _filled(int i) => _stateOf(i) == KumoStepsState.complete;

  Widget _horizontal(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _pressableStep(
              context,
              i,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: KumoSpace.s2,
                children: [
                  Row(
                    spacing: KumoSpace.s2,
                    children: [
                      _Marker(index: i, state: _stateOf(i)),
                      Expanded(
                        child: i == steps.length - 1
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsetsDirectional.only(end: KumoSpace.s2),
                                child: SizedBox(
                                  height: 2,
                                  child: _Connector(filled: _filled(i), axis: Axis.horizontal),
                                ),
                              ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: KumoSpace.s3),
                    child: _labels(context, i),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _vertical(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Stack(
            children: [
              if (i < steps.length - 1)
                PositionedDirectional(
                  start: 11,
                  width: 2,
                  top: 24 + KumoSpace.s1,
                  bottom: KumoSpace.s1,
                  child: _Connector(filled: _filled(i), axis: Axis.vertical),
                ),
              Padding(
                padding: EdgeInsets.only(bottom: i < steps.length - 1 ? KumoSpace.s5 : 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _pressableStep(
                      context,
                      i,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: KumoSpace.s3,
                        children: [
                          _Marker(index: i, state: _stateOf(i)),
                          Expanded(
                            child: Padding(padding: const EdgeInsets.only(top: 1.5), child: _labels(context, i)),
                          ),
                        ],
                      ),
                    ),
                    if (inlineContent != null)
                      KumoCollapsiblePanel(
                        open: i == current,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 24 + KumoSpace.s3, top: KumoSpace.s3),
                          child: inlineContent!(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _labels(BuildContext context, int i) {
    final kumo = context.kumo;
    final state = _stateOf(i);
    final color = switch (state) {
      KumoStepsState.upcoming => KumoColor.textSubtle,
      KumoStepsState.error => KumoColor.textDanger,
      _ => KumoColor.textDefault,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          steps[i].title,
          style: kumo.text(
            weight: state == KumoStepsState.current ? KumoTypography.medium : KumoTypography.normal,
            color: color,
          ),
        ),
        if (steps[i].description != null)
          Text(
            steps[i].description!,
            style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
          ),
      ],
    );
  }

  Widget _pressableStep(BuildContext context, int i, Widget child) {
    while (_stepKeys.length <= i) {
      _stepKeys.add(GlobalKey(debugLabel: 'KumoSteps step ${_stepKeys.length}'));
    }
    child = KeyedSubtree(key: _stepKeys[i], child: child);
    final state = _stateOf(i);
    final label = '${steps[i].title}, ${stateLabels[state] ?? state.name}';
    final value = context.kumoStrings.stepOf(i + 1, steps.length);
    final canPress = onStepPress != null && (pressable?.call(i) ?? true);
    if (!canPress) {
      return Semantics(container: true, label: label, value: value, excludeSemantics: true, child: child);
    }
    return KumoPressable(
      onPress: () => onStepPress!(i),
      semanticLabel: label,
      semanticValue: value,
      excludeChildSemantics: true,
      scaleOnPress: false,
      showFocusRing: false,
      minTapTargetSize: 0,
      builder: (context, s) => KumoFocusRing(
        visible: s.focused,
        borderRadius: BorderRadius.circular(KumoRadius.md),
        offset: 2,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.kumo.minTapTarget),
          child: Opacity(opacity: s.pressed ? 0.8 : 1, child: child),
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.index, required this.state});

  final int index;
  final KumoStepsState state;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    const white = Color(0xFFFFFFFF);
    final (Color fill, Border? ring) = switch (state) {
      KumoStepsState.upcoming => (c.base, KumoRing.inset(c.line)),
      KumoStepsState.current => (c.brand, null),
      KumoStepsState.complete => (c.brand, null),
      KumoStepsState.error => (c.danger, null),
    };
    final Widget glyph = switch (state) {
      KumoStepsState.complete => const KumoIcon(
        KumoIcons.check,
        key: ValueKey('check'),
        size: 14,
        dangerouslySetColor: white,
      ),
      KumoStepsState.error => const KumoIcon(KumoIcons.x, key: ValueKey('error'), size: 14, dangerouslySetColor: white),
      _ => Text(
        key: ValueKey(state == KumoStepsState.current ? 'current' : 'number'),
        '${index + 1}',
        textScaler: TextScaler.noScaling,
        style: kumo
            .text(
              size: KumoTextSize.xs,
              weight: KumoTypography.medium,
              color: state == KumoStepsState.current ? KumoColor.textDefault : KumoColor.textSubtle,
              height: 1,
            )
            .copyWith(color: state == KumoStepsState.current ? white : null),
      ),
    };
    return AnimatedContainer(
      duration: KumoMotion.duration(context, KumoDurations.moderate),
      curve: KumoCurves.standard,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: ring,
        boxShadow: state == KumoStepsState.current
            ? [BoxShadow(color: c.brand.withValues(alpha: 0.25), spreadRadius: 3)]
            : const [],
      ),
      child: AnimatedSwitcher(
        duration: KumoMotion.duration(context, KumoDurations.moderate),
        reverseDuration: KumoMotion.duration(context, KumoDurations.fast),
        transitionBuilder: (child, animation) {
          final fade = FadeTransition(
            opacity: animation.drive(CurveTween(curve: const Interval(0, 0.5))),
            child: child,
          );
          // The check (and the error cross) land with Kumo's small bounce;
          // the number just fades.
          final lands = child.key == const ValueKey('check') || child.key == const ValueKey('error');
          if (!lands) return fade;
          return ScaleTransition(
            scale: animation.drive(Tween<double>(begin: 0.5, end: 1).chain(CurveTween(curve: KumoCurves.bounce))),
            child: fade,
          );
        },
        child: glyph,
      ),
    );
  }
}

/// The line between two markers. When the step before it completes, a brand
/// fill grows along it from the start (top in vertical layouts), and drains
/// back the same way when the flow steps back. Starts from where it is, so
/// quick back and forth never jumps; instant under reduced motion.
class _Connector extends StatelessWidget {
  const _Connector({required this.filled, required this.axis});

  final bool filled;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final radius = BorderRadius.circular(1);
    final horizontal = axis == Axis.horizontal;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: filled ? 1 : 0),
      duration: KumoMotion.duration(context, KumoDurations.moderate),
      curve: KumoCurves.standard,
      builder: (context, t, _) => DecoratedBox(
        decoration: BoxDecoration(color: c.line, borderRadius: radius),
        child: Align(
          alignment: horizontal ? AlignmentDirectional.centerStart : AlignmentDirectional.topCenter,
          child: FractionallySizedBox(
            widthFactor: horizontal ? t : 1,
            heightFactor: horizontal ? 1 : t,
            child: DecoratedBox(
              key: const ValueKey('kumo-steps-connector-fill'),
              decoration: BoxDecoration(color: c.brand, borderRadius: radius),
            ),
          ),
        ),
      ),
    );
  }
}

/// The horizontal stepper's content area. The height eases to the new
/// step's while the content cross-fades, so the buttons below slide instead
/// of jumping. Reduced motion drops the size animation (AnimatedSize cannot
/// run with a zero duration).
class _StepContent extends StatelessWidget {
  const _StepContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (KumoMotion.reduceMotion(context)) return child;
    return AnimatedSize(
      duration: KumoDurations.moderate,
      curve: KumoCurves.standard,
      alignment: AlignmentDirectional.topStart,
      child: child,
    );
  }
}
