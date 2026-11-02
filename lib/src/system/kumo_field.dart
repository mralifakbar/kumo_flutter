import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_tooltip.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../forms/src/field_motion.dart';
import 'kumo_strings.dart';

/// Kumo's `Label`: medium-weight 14px text with an optional "(optional)"
/// marker and an info tooltip.
///
/// ```dart
/// const KumoLabel('Zone name', showOptional: true, tooltip: 'Shown in the dashboard only')
/// ```
class KumoLabel extends StatelessWidget {
  const KumoLabel(
    this.text, {
    super.key,
    this.showOptional = false,
    this.optionalLabel,
    this.tooltip,
    this.tooltipSemanticLabel,
    this.required = false,
  });

  final String text;

  /// Shows "(optional)" after the label in subtle text.
  final bool showOptional;
  final String? optionalLabel;

  /// Shows an info icon with this tooltip after the label.
  final String? tooltip;
  final String? tooltipSemanticLabel;

  /// Announces the field as required. Kumo marks optional fields rather than
  /// required ones, so nothing is drawn.
  final bool required;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    return Semantics(
      label: required ? '$text, ${strings.required}' : null,
      excludeSemantics: required,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: KumoSpace.s1,
        children: [
          Text(text, style: kumo.text(weight: KumoTypography.medium)),
          if (showOptional) Text(optionalLabel ?? strings.optional, style: kumo.text(color: KumoColor.textSubtle)),
          if (tooltip != null)
            KumoTooltip(
              content: tooltip!,
              child: Semantics(
                label: tooltipSemanticLabel ?? strings.moreInformation,
                child: const KumoIcon(KumoIcons.info, color: KumoColor.textSubtle),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kumo's `Field`: a label above a control, with a description and an error
/// message below it. Error replaces the description and is announced.
///
/// For checkboxes and switches use [controlFirst] layout via the control's
/// own label instead; Field is for text-style controls.
///
/// ```dart
/// KumoField(
///   label: 'Worker name',
///   description: 'Lowercase letters, numbers and dashes.',
///   error: nameError,
///   child: KumoInput(value: name, onValueChange: setName),
/// )
/// ```
class KumoField extends StatelessWidget {
  const KumoField({
    super.key,
    required this.child,
    this.label,
    this.labelWidget,
    this.description,
    this.error,
    this.showOptional = false,
    this.labelTooltip,
    this.required = false,
    this.hideLabel = false,
    this.controlDescribed = false,
  });

  final Widget child;
  final String? label;

  /// Custom label in place of [label].
  final Widget? labelWidget;
  final String? description;

  /// Error message. When set, the control should also show its error state.
  final String? error;
  final bool showOptional;
  final String? labelTooltip;
  final bool required;

  /// Keep the label for screen readers only.
  final bool hideLabel;

  /// The control already announces [description] as its hint, so the text
  /// below is hidden from screen readers to avoid reading it twice.
  final bool controlDescribed;

  @override
  Widget build(BuildContext context) {
    final labelNode =
        labelWidget ??
        (label == null
            ? null
            : KumoLabel(label!, showOptional: showOptional, tooltip: labelTooltip, required: required));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelNode != null) ...[
          hideLabel ? Semantics(label: label, child: const SizedBox.shrink()) : labelNode,
          const SizedBox(height: KumoSpace.s2),
        ],
        child,
        // Grows in, fades out and cross-fades between description and error,
        // so content below slides instead of jumping. Instant under reduced
        // motion.
        FieldMessage(description: description, error: error, controlDescribed: controlDescribed),
      ],
    );
  }
}
