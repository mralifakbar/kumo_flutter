import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// How a [KumoCollapsible] panel is dressed.
enum KumoCollapsiblePanelStyle {
  /// Kumo's `DefaultPanel`: a 2px `kumo-fill` rule on the start edge, 16px
  /// inset, 8px above and below.
  accent,

  /// Kumo's bare `Panel`: the content as given.
  plain,
}

/// Builds a custom trigger. Call [toggle] to open or close.
typedef KumoCollapsibleTriggerBuilder = Widget Function(BuildContext context, bool open, VoidCallback toggle);

/// Kumo's `Collapsible`: a trigger that shows and hides a panel.
///
/// The panel's height animates while its content keeps its full size and is
/// clipped, so text never reflows mid-animation. The animation can be
/// reversed mid-flight and collapses to an instant change under reduced
/// motion.
///
/// The default trigger is Kumo's `DefaultTrigger`: medium text and a caret
/// that turns as the panel opens.
///
/// ```dart
/// KumoCollapsible(
///   open: open,
///   onOpenChange: (v) => setState(() => open = v),
///   label: 'Advanced settings',
///   child: const KumoText('Compatibility date, usage model and placement.'),
/// )
/// ```
///
/// For a custom trigger, pass [triggerBuilder]:
///
/// ```dart
/// KumoCollapsible(
///   open: open,
///   onOpenChange: (v) => setState(() => open = v),
///   panelStyle: KumoCollapsiblePanelStyle.plain,
///   triggerBuilder: (context, open, toggle) => KumoButton(
///     label: open ? 'Hide details' : 'Show details',
///     size: KumoButtonSize.sm,
///     onPress: toggle,
///   ),
///   child: const KumoText('Routes, bindings and environment variables.'),
/// )
/// ```
class KumoCollapsible extends StatelessWidget {
  const KumoCollapsible({
    super.key,
    required this.open,
    required this.onOpenChange,
    required this.child,
    this.label,
    this.triggerBuilder,
    this.panelStyle = KumoCollapsiblePanelStyle.accent,
    this.disabled = false,
    this.keepMounted = false,
    this.semanticLabel,
  }) : assert(label != null || triggerBuilder != null, 'Pass label or triggerBuilder');

  /// Whether the panel is shown. Changes animate.
  final bool open;

  /// Called with the next open state when the trigger is pressed.
  final ValueChanged<bool>? onOpenChange;

  /// Panel content.
  final Widget child;

  /// Text of the default trigger.
  final String? label;

  /// Replaces the default trigger.
  final KumoCollapsibleTriggerBuilder? triggerBuilder;
  final KumoCollapsiblePanelStyle panelStyle;
  final bool disabled;

  /// Keep the panel's widgets alive while closed (form fields keep their
  /// text). Closed content is hidden from focus and screen readers either way.
  final bool keepMounted;

  /// Accessible name of the default trigger, when it differs from [label].
  final String? semanticLabel;

  void _toggle() {
    if (disabled) return;
    onOpenChange?.call(!open);
  }

  @override
  Widget build(BuildContext context) {
    final trigger =
        triggerBuilder?.call(context, open, _toggle) ??
        KumoCollapsibleTrigger(
          label: label!,
          open: open,
          disabled: disabled || onOpenChange == null,
          onPress: _toggle,
          semanticLabel: semanticLabel,
        );
    Widget panel = child;
    if (panelStyle == KumoCollapsiblePanelStyle.accent) {
      panel = Padding(
        padding: const EdgeInsets.symmetric(vertical: KumoSpace.s2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: context.kumo.colors.fill, width: 2)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: KumoSpace.s4,
              end: KumoSpace.s1,
              top: KumoSpace.s1,
              bottom: KumoSpace.s1,
            ),
            child: child,
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: trigger),
        KumoCollapsiblePanel(open: open, keepMounted: keepMounted, child: panel),
      ],
    );
  }
}

/// Kumo's `Collapsible.DefaultTrigger`: medium 14px text followed by a 12px
/// caret that turns half a revolution while open, in step with the panel. Announced as expanded or
/// collapsed.
///
/// ```dart
/// KumoCollapsibleTrigger(label: 'Show routes', open: open, onPress: toggle)
/// ```
class KumoCollapsibleTrigger extends StatelessWidget {
  const KumoCollapsibleTrigger({
    super.key,
    required this.label,
    required this.open,
    required this.onPress,
    this.disabled = false,
    this.semanticLabel,
  });

  final String label;
  final bool open;
  final VoidCallback? onPress;
  final bool disabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return KumoPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      expanded: open,
      semanticLabel: semanticLabel,
      borderRadius: BorderRadius.circular(KumoRadius.sm),
      builder: (context, state) {
        final row = Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1,
          children: [
            Flexible(
              child: Text(label, style: kumo.text(weight: KumoTypography.medium)),
            ),
            SizedBox(
              width: 16,
              child: Center(child: KumoDisclosureCaret(open: open, size: 12)),
            ),
          ],
        );
        return Opacity(opacity: disabled ? 0.5 : 1, child: row);
      },
    );
  }
}

/// A disclosure caret that turns half a revolution as its panel opens.
///
/// It runs on the same clock as [KumoCollapsiblePanel] (same [duration],
/// same curve, forward and reverse from wherever it is), so a caret and a
/// panel toggled together stay in step, including when the toggle is
/// reversed mid-flight. Reduced motion turns it instantly.
///
/// Use it in custom triggers next to a [KumoCollapsiblePanel]:
///
/// ```dart
/// Row(children: [
///   const KumoText('Routes'),
///   KumoDisclosureCaret(open: open),
/// ])
/// ```
class KumoDisclosureCaret extends StatefulWidget {
  const KumoDisclosureCaret({
    super.key,
    required this.open,
    this.size = 16,
    this.color,
    this.icon = KumoIcons.caretDown,
    this.turns = 0.5,
    this.duration = KumoDurations.moderate,
  });

  final bool open;
  final double size;

  /// Null inherits the surrounding icon color, like [KumoIcon].
  final KumoColor? color;

  /// The glyph at rest (closed).
  final IconData icon;

  /// Rotation while open, in full turns. 0.5 flips a down caret up; 0.25
  /// turns a right-pointing caret down (pass -0.25 for a left-pointing
  /// caret in RTL).
  final double turns;

  /// Match the panel's duration when it is not the default.
  final Duration duration;

  @override
  State<KumoDisclosureCaret> createState() => _KumoDisclosureCaretState();
}

class _KumoDisclosureCaretState extends State<KumoDisclosureCaret> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration, value: widget.open ? 1 : 0);
    _curve = CurvedAnimation(parent: _c, curve: KumoCurves.standard);
  }

  @override
  void didUpdateWidget(KumoDisclosureCaret oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) _disclosureRun(context, _c, widget.open, widget.duration);
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: KumoIcon(widget.icon, size: widget.size, color: widget.color),
      builder: (context, child) => Transform.rotate(angle: _curve.value * widget.turns * 2 * math.pi, child: child),
    );
  }
}

/// Opens or closes a disclosure controller from wherever it is. Shared by
/// the panel and the caret so both follow the same timing.
void _disclosureRun(BuildContext context, AnimationController c, bool open, Duration duration) {
  c.duration = KumoMotion.duration(context, duration);
  if (c.duration == Duration.zero) {
    c.value = open ? 1 : 0;
  } else if (open) {
    c.forward();
  } else {
    c.reverse();
  }
}

/// Kumo's `Collapsible.Panel`: content that opens and closes in place.
///
/// The height animates from where it is (so reopening mid-close turns
/// around without a jump) while the content is laid out at its full height
/// and clipped. Use it to build disclosure patterns of your own; accordions
/// and steppers in this package use it too.
///
/// ```dart
/// KumoCollapsiblePanel(open: showLogs, child: const LogList())
/// ```
class KumoCollapsiblePanel extends StatefulWidget {
  const KumoCollapsiblePanel({
    super.key,
    required this.open,
    required this.child,
    this.keepMounted = false,
    this.duration = KumoDurations.moderate,
    this.fade = true,
  });

  final bool open;
  final Widget child;

  /// Keep [child] alive while closed. Hidden content is excluded from focus
  /// and semantics either way.
  final bool keepMounted;
  final Duration duration;

  /// Fade the content with the height, like Kumo's `opacity` transition.
  final bool fade;

  @override
  State<KumoCollapsiblePanel> createState() => _KumoCollapsiblePanelState();
}

class _KumoCollapsiblePanelState extends State<KumoCollapsiblePanel> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration, value: widget.open ? 1 : 0);
    _curve = CurvedAnimation(parent: _c, curve: KumoCurves.standard);
  }

  @override
  void didUpdateWidget(KumoCollapsiblePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) _disclosureRun(context, _c, widget.open, widget.duration);
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        final shown = _c.value > 0 || widget.open;
        if (!shown && !widget.keepMounted) return const SizedBox.shrink();
        final settled = _c.value == 1 && widget.open;
        // The wrappers stay in place in every state so the content's own
        // state (text fields, scroll offsets) survives opening and closing.
        Widget content = ExcludeFocus(
          excluding: !widget.open,
          child: ExcludeSemantics(excluding: !widget.open, child: child!),
        );
        content = Opacity(opacity: widget.fade ? t : 1, child: content);
        content = ClipRect(
          clipBehavior: settled ? Clip.none : Clip.hardEdge,
          child: Align(alignment: AlignmentDirectional.topStart, heightFactor: t, child: content),
        );
        if (widget.keepMounted) content = Visibility(visible: shown, maintainState: true, child: content);
        return content;
      },
    );
  }
}
