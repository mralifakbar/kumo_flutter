import 'package:flutter/widgets.dart';

import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_control_parts.dart';

/// Checkbox styles. [base] is Kumo's `"default"`.
enum KumoCheckboxVariant {
  /// Hairline ring around the box.
  base,

  /// Red ring for a failed validation. Pair it with an error message.
  error,
}

/// Checkbox presentations.
enum KumoCheckboxAppearance {
  /// A 16px box next to its label.
  base,

  /// A choice card: bordered, padded, with a medium label, an optional
  /// description, and a tinted background while checked.
  card,
}

/// Kumo's `Checkbox`: a 16px box with a label, for a single yes or no
/// choice, or as the "select all" control above a list (with
/// [indeterminate]).
///
/// Controlled: pass [checked] and update it from [onCheckedChange].
///
/// ```dart
/// KumoCheckbox(
///   label: 'Purge cache after deploy',
///   checked: purge,
///   onCheckedChange: (value) => setState(() => purge = value),
/// )
/// ```
///
/// The whole row is the hit area, padded to 44px tall on touch. The check
/// mark lands with Kumo's bounce curve, a small overshoot; under reduced
/// motion it appears at once. Without a [label], pass [semanticLabel].
class KumoCheckbox extends StatelessWidget {
  const KumoCheckbox({
    super.key,
    required this.checked,
    this.onCheckedChange,
    this.indeterminate = false,
    this.label,
    this.labelWidget,
    this.description,
    this.error,
    this.labelTooltip,
    this.required,
    this.controlFirst,
    this.variant = KumoCheckboxVariant.base,
    this.appearance = KumoCheckboxAppearance.base,
    this.disabled = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final bool checked;

  /// Called with the next value. An [indeterminate] checkbox reports `true`,
  /// so a "select all" control selects everything first. Null disables it.
  final ValueChanged<bool>? onCheckedChange;

  /// Shows a dash instead of a check: some, not all, of a set is selected.
  /// Takes precedence over [checked] for the visual and for screen readers.
  final bool indeterminate;

  /// Label text next to the box. Also the accessible name.
  final String? label;

  /// Custom label in place of [label].
  final Widget? labelWidget;

  /// Helper text under the label.
  final String? description;

  /// Error message under the label. Also switches to the error ring.
  final String? error;

  /// Shows an info icon with this tooltip after the label.
  final String? labelTooltip;

  /// When explicitly false, shows "(optional)" after the label, as in Kumo.
  final bool? required;

  /// Box before the label (true) or after it. Defaults to true, and to false
  /// for [KumoCheckboxAppearance.card], where the box sits at the end.
  final bool? controlFirst;
  final KumoCheckboxVariant variant;
  final KumoCheckboxAppearance appearance;
  final bool disabled;

  /// Accessible name when there is no visible label, such as a row checkbox
  /// in a table ("Select api-gateway").
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isError = variant == KumoCheckboxVariant.error || error != null;
    final hasLabel = label != null || labelWidget != null;
    final inert = disabled || onCheckedChange == null;
    final labelNode = labelWidget ??
        (label == null
            ? null
            : ControlLabelText(
                text: label!,
                weight: appearance == KumoCheckboxAppearance.card ? KumoTypography.medium : KumoTypography.normal,
                showOptional: required == false,
                tooltip: labelTooltip,
              ));
    return _CheckboxTile(
      checked: checked,
      indeterminate: indeterminate,
      onPress: inert ? null : () => onCheckedChange!(indeterminate ? true : !checked),
      label: labelNode,
      description: description,
      error: error,
      isError: isError,
      card: appearance == KumoCheckboxAppearance.card,
      controlFirst: controlFirst ?? appearance != KumoCheckboxAppearance.card,
      disabled: inert,
      // Kumo dims only the box of a lone checkbox, and the whole row of an
      // item in a group or a card.
      dimRow: appearance == KumoCheckboxAppearance.card || !hasLabel,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// One option of a [KumoCheckboxGroup].
///
/// ```dart
/// const KumoCheckboxGroupItem(value: 'logs', label: 'Workers Logs')
/// ```
@immutable
class KumoCheckboxGroupItem<T> {
  const KumoCheckboxGroupItem({
    required this.value,
    required this.label,
    this.description,
    this.disabled = false,
    this.variant,
    this.appearance,
  });

  final T value;
  final String label;

  /// Helper text under the label.
  final String? description;
  final bool disabled;

  /// Overrides the group's error state for this item.
  final KumoCheckboxVariant? variant;

  /// Overrides the group's [KumoCheckboxGroup.appearance] for this item.
  final KumoCheckboxAppearance? appearance;
}

/// Kumo's `Checkbox.Group`: a legend over a set of checkboxes, with an
/// error and a description below. Controlled with a list of the checked
/// values.
///
/// ```dart
/// KumoCheckboxGroup<String>(
///   legend: 'Email alerts',
///   description: 'Sent to the account owner.',
///   value: alerts,
///   onValueChange: (next) => setState(() => alerts = next),
///   items: const [
///     KumoCheckboxGroupItem(value: 'deploys', label: 'Failed deployments'),
///     KumoCheckboxGroupItem(value: 'usage', label: 'Usage limits'),
///   ],
/// )
/// ```
///
/// Card groups ([KumoCheckboxAppearance.card]) join their items into one
/// bordered surface: a column, or a two-column grid when [orientation] is
/// horizontal.
class KumoCheckboxGroup<T> extends StatelessWidget {
  const KumoCheckboxGroup({
    super.key,
    required this.items,
    required this.value,
    this.onValueChange,
    this.legend,
    this.hideLegend = false,
    this.description,
    this.error,
    this.disabled = false,
    this.orientation = Axis.vertical,
    this.appearance = KumoCheckboxAppearance.base,
    this.controlFirst,
  });

  final List<KumoCheckboxGroupItem<T>> items;

  /// The checked values.
  final List<T> value;

  /// Called with the next list of checked values. A newly checked value is
  /// appended. Null disables the group.
  final ValueChanged<List<T>>? onValueChange;

  /// Group title, medium weight above the items.
  final String? legend;

  /// Keep the legend for screen readers only (Kumo's `sr-only` legend).
  final bool hideLegend;
  final String? description;

  /// Error for the whole group. Items switch to the error ring.
  final String? error;
  final bool disabled;

  /// Vertical stacks the items; horizontal wraps them in rows (or a
  /// two-column grid for cards).
  final Axis orientation;
  final KumoCheckboxAppearance appearance;

  /// Box before the label. Defaults to true, false for cards.
  final bool? controlFirst;

  void _toggle(T v, bool checked) {
    final next = checked ? [...value, v] : [for (final x in value) if (x != v) x];
    onValueChange!(next);
  }

  @override
  Widget build(BuildContext context) {
    final groupCard = appearance == KumoCheckboxAppearance.card;
    Widget tile(int i, {required bool joined}) {
      final item = items[i];
      final itemAppearance = item.appearance ?? appearance;
      final card = itemAppearance == KumoCheckboxAppearance.card;
      final checked = value.contains(item.value);
      final isError = (item.variant ?? (error != null ? KumoCheckboxVariant.error : KumoCheckboxVariant.base)) ==
          KumoCheckboxVariant.error;
      final itemDisabled = disabled || item.disabled;
      return _CheckboxTile(
        checked: checked,
        onPress: itemDisabled || onValueChange == null ? null : () => _toggle(item.value, !checked),
        label: ControlLabelText(
          text: item.label,
          weight: card ? KumoTypography.medium : KumoTypography.normal,
        ),
        description: item.description,
        isError: isError,
        card: card,
        joined: joined && card,
        controlFirst: controlFirst ?? !card,
        disabled: itemDisabled,
        dimRow: true,
      );
    }

    Widget body;
    if (groupCard) {
      body = JoinedCards(
        horizontal: orientation == Axis.horizontal,
        children: [for (var i = 0; i < items.length; i++) tile(i, joined: true)],
      );
    } else if (orientation == Axis.horizontal) {
      body = Wrap(
        spacing: KumoSpace.s2,
        runSpacing: controlRowGap(context, multiline: items.any((item) => item.description != null)),
        children: [for (var i = 0; i < items.length; i++) tile(i, joined: false)],
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: controlRowGap(context, multiline: items.any((item) => item.description != null)),
        children: [for (var i = 0; i < items.length; i++) tile(i, joined: false)],
      );
    }
    return ControlFieldset(
      legend: legend,
      hideLegend: hideLegend,
      description: description,
      error: error,
      gap: groupCard ? KumoSpace.s2 : KumoSpace.s4,
      child: body,
    );
  }
}

/// The interactive row behind [KumoCheckbox] and group items: box, label,
/// description and error, in the inline or card layout.
class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({
    required this.checked,
    required this.onPress,
    required this.label,
    required this.isError,
    required this.card,
    required this.controlFirst,
    required this.disabled,
    required this.dimRow,
    this.indeterminate = false,
    this.description,
    this.error,
    this.joined = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final bool checked;
  final bool indeterminate;
  final VoidCallback? onPress;
  final Widget? label;
  final String? description;
  final String? error;
  final bool isError;
  final bool card;
  final bool joined;
  final bool controlFirst;
  final bool disabled;
  final bool dimRow;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final on = checked || indeterminate;
    return KumoPressable(
      onPress: onPress,
      disabled: disabled || onPress == null,
      isButton: false,
      checked: indeterminate ? false : checked,
      mixed: indeterminate ? true : null,
      semanticLabel: semanticLabel,
      showFocusRing: false,
      scaleOnPress: false,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, state) {
        // The row is the hit area; the box answers the press.
        final box = PressScale(
          pressed: state.pressed && !disabled,
          child: _CheckboxBox(
            on: on,
            indeterminate: indeterminate,
            error: isError,
            focused: state.focused,
            hovered: state.active,
            card: card,
          ),
        );
        final dimBoxOnly = !dimRow && disabled;
        final control = dimBoxOnly ? Opacity(opacity: 0.5, child: box) : box;
        Widget? text;
        if (label != null || description != null || error != null) {
          text = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s0_5,
            children: [
              ?label,
              if (description != null)
                Text(description!, style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle)),
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(error!, style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textDanger)),
                ),
            ],
          );
        }

        Widget result;
        if (card) {
          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              if (controlFirst) Padding(padding: const EdgeInsets.only(top: KumoSpace.s0_5), child: control),
              Expanded(child: text ?? const SizedBox.shrink()),
              if (!controlFirst) Padding(padding: const EdgeInsets.only(top: KumoSpace.s0_5), child: control),
            ],
          );
          final background = checked && !isError
              ? c.tint
              : (state.active && !checked && !disabled && !isError ? c.elevated : c.base);
          Border? border;
          if (!joined) {
            final borderColor = isError ? c.danger : (checked ? c.interact : c.hairline);
            border = Border.all(color: borderColor);
          }
          result = Container(
            padding: const EdgeInsets.all(KumoSpace.s3),
            decoration: BoxDecoration(
              color: background,
              border: border,
              borderRadius: joined ? null : BorderRadius.circular(KumoRadius.lg),
            ),
            child: row,
          );
        } else if (text == null) {
          result = control;
        } else {
          result = ControlRow(control: control, label: text, controlFirst: controlFirst);
        }
        if (dimRow && disabled) result = Opacity(opacity: 0.5, child: result);
        return result;
      },
    );
  }
}

/// The 16px box (`h-4 w-4 rounded-sm ring`). The mark scales in with
/// [KumoCurves.bounce] when the box turns on, and disappears at once when it
/// turns off, as Kumo's indicator does.
class _CheckboxBox extends StatefulWidget {
  const _CheckboxBox({
    required this.on,
    required this.indeterminate,
    required this.error,
    required this.focused,
    required this.hovered,
    this.card = false,
  });

  final bool on;
  final bool indeterminate;
  final bool error;
  final bool focused;
  final bool hovered;

  /// Card items use `ring-kumo-line`, hairline on hover.
  final bool card;

  @override
  State<_CheckboxBox> createState() => _CheckboxBoxState();
}

class _CheckboxBoxState extends State<_CheckboxBox> with SingleTickerProviderStateMixin {
  late final AnimationController _mark;

  @override
  void initState() {
    super.initState();
    _mark = AnimationController(vsync: this, duration: KumoDurations.quick, value: widget.on ? 1 : 0);
  }

  @override
  void didUpdateWidget(_CheckboxBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final turnedOn = widget.on && (!oldWidget.on || oldWidget.indeterminate != widget.indeterminate);
    if (turnedOn) {
      if (KumoMotion.reduceMotion(context)) {
        _mark.value = 1;
      } else {
        _mark.forward(from: 0);
      }
    } else if (!widget.on) {
      _mark.value = 0;
    }
  }

  @override
  void dispose() {
    _mark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    Color ring;
    double ringWidth = 1;
    if (widget.focused) {
      ring = c.brand;
      ringWidth = 2;
    } else if (widget.on) {
      ring = c.contrast;
    } else if (widget.error) {
      ring = c.danger;
    } else if (widget.card) {
      ring = widget.hovered ? c.hairline : c.line;
    } else {
      ring = c.hairline;
    }
    return SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.on ? c.contrast : c.base,
          borderRadius: BorderRadius.circular(KumoRadius.sm),
          border: KumoRing.border(ring, width: ringWidth),
        ),
        child: AnimatedBuilder(
          animation: _mark,
          builder: (context, _) {
            final t = _mark.value;
            if (t == 0) return const SizedBox.shrink();
            final scale = 0.6 + 0.4 * KumoCurves.bounce.transform(t);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: _CheckMarkPainter(color: c.textInverse, dash: widget.indeterminate),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Phosphor's bold check and minus at 12px inside the 16px box, drawn as
/// strokes so the mark stays crisp while it scales.
class _CheckMarkPainter extends CustomPainter {
  const _CheckMarkPainter({required this.color, required this.dash});

  final Color color;
  final bool dash;

  @override
  void paint(Canvas canvas, Size size) {
    const icon = 12.0;
    final origin = Offset((size.width - icon) / 2, (size.height - icon) / 2);
    Offset p(double x, double y) => origin + Offset(x / 256 * icon, y / 256 * icon);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24 / 256 * icon
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (dash) {
      path
        ..moveTo(p(40, 128).dx, p(40, 128).dy)
        ..lineTo(p(216, 128).dx, p(216, 128).dy);
    } else {
      path
        ..moveTo(p(40, 144).dx, p(40, 144).dy)
        ..lineTo(p(96, 200).dx, p(96, 200).dy)
        ..lineTo(p(224, 72).dx, p(224, 72).dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckMarkPainter old) => old.color != color || old.dash != dash;
}
