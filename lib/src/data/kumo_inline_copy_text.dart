import 'package:flutter/widgets.dart';

import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../typography/kumo_text.dart';
import 'copy_feedback.dart';
import 'data_hover_scope.dart';

/// Kumo's `InlineCopyText`: a compact, borderless copy control for IDs and
/// other short values inside running text or dense table cells.
///
/// ```dart
/// const KumoInlineCopyText(
///   'f86b3f10-32e9-4db7-ae95-84a1b2c3d4e5',
///   copyLabel: 'Copy database ID',
///   copiedLabel: 'Database ID copied',
/// )
/// ```
///
/// The copy icon appears on hover and keyboard focus, and when the
/// surrounding [KumoTable] or [KumoTree] row is hovered. On touch screens,
/// which have no hover, it is always shown. After a copy it becomes a
/// check for 1.5 seconds and [copiedLabel] is announced.
///
/// Use [KumoClipboardText] when the value should sit in an input-like field
/// with an always-visible copy button.
class KumoInlineCopyText extends StatefulWidget {
  /// Shows [text] and copies it (or [value], when set).
  const KumoInlineCopyText(
    String this.text, {
    super.key,
    this.value,
    this.variant = KumoTextVariant.monoSecondary,
    this.size = KumoTextSize.base,
    this.bold = false,
    this.truncate = true,
    this.alwaysShowIcon = false,
    this.copyLabel,
    this.copiedLabel,
    this.onCopy,
  })  : child = null,
        assert(variant != KumoTextVariant.heading, 'Heading variants are not supported');

  /// Shows any [child] and copies [value].
  const KumoInlineCopyText.rich({
    super.key,
    required Widget this.child,
    required String this.value,
    this.variant = KumoTextVariant.body,
    this.size = KumoTextSize.base,
    this.bold = false,
    this.truncate = true,
    this.alwaysShowIcon = false,
    this.copyLabel,
    this.copiedLabel,
    this.onCopy,
  })  : text = null,
        assert(variant != KumoTextVariant.heading, 'Heading variants are not supported');

  final String? text;
  final Widget? child;

  /// The value to copy. Defaults to [text].
  final String? value;

  /// Text style. Mono variants only take `size: KumoTextSize.lg` (14px).
  /// [KumoTextVariant.monoSecondary] (the default) brightens to the default
  /// text color on hover and focus.
  final KumoTextVariant variant;
  final KumoTextSize size;

  /// Medium weight. Ignored by mono variants.
  final bool bold;

  /// One line with an ellipsis.
  final bool truncate;

  /// Show the copy icon at rest, not only on hover or focus.
  final bool alwaysShowIcon;

  /// Accessible name before copying. Defaults to [KumoStrings.copy].
  final String? copyLabel;

  /// Accessible name and announcement after copying. Defaults to
  /// [KumoStrings.copied].
  final String? copiedLabel;

  /// Called after a successful copy.
  final VoidCallback? onCopy;

  @override
  State<KumoInlineCopyText> createState() => _KumoInlineCopyTextState();
}

class _KumoInlineCopyTextState extends State<KumoInlineCopyText>
    with SingleTickerProviderStateMixin, DataCopyFeedback<KumoInlineCopyText> {
  @override
  Duration get copyFeedbackDuration => const Duration(milliseconds: 1500);

  Future<void> _copy() async {
    final strings = context.kumoStrings;
    final ok = await copyText(
      widget.value ?? widget.text!,
      copied: widget.copiedLabel ?? strings.copied,
      failed: strings.copyFailed,
    );
    if (ok) widget.onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final rowActive = DataHoverScope.of(context);
    final touch = kumo.tapTargetSize == KumoTapTargetSize.padded;
    final label = switch (copyStatus) {
      DataCopyStatus.copied => widget.copiedLabel ?? strings.copied,
      DataCopyStatus.failed => strings.copyFailed,
      DataCopyStatus.idle => widget.copyLabel ?? strings.copy,
    };
    return KumoPressable(
      onPress: _copy,
      semanticLabel: label,
      semanticValue: widget.text,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(KumoRadius.xs),
      builder: (context, state) {
        final lit = state.active || state.focused;
        final mono = widget.variant == KumoTextVariant.mono || widget.variant == KumoTextVariant.monoSecondary;
        var style = KumoText.styleOf(
          context,
          variant: widget.variant,
          size: mono && widget.size != KumoTextSize.lg ? KumoTextSize.base : widget.size,
          bold: widget.bold && !mono,
        );
        if (widget.variant == KumoTextVariant.monoSecondary && lit) {
          style = style.copyWith(color: kumo.color(KumoColor.textDefault));
        }
        final iconColor = DefaultTextStyle.of(context).style.color ?? kumo.colors.textDefault;
        // Copy, check and warning cross-fade into each other, there and back.
        final Widget icon = KumoSwap(
          child: switch (copyStatus) {
            DataCopyStatus.copied => ScaleTransition(
                key: const ValueKey(DataCopyStatus.copied),
                scale: copyBump,
                child: KumoIcon(KumoIcons.check, size: 14, dangerouslySetColor: iconColor),
              ),
            DataCopyStatus.failed => ScaleTransition(
                key: const ValueKey(DataCopyStatus.failed),
                scale: copyBump,
                child: const KumoIcon(KumoIcons.warningCircle, size: 14, color: KumoColor.textDanger),
              ),
            DataCopyStatus.idle => AnimatedOpacity(
                key: const ValueKey(DataCopyStatus.idle),
                opacity: lit || rowActive || touch || widget.alwaysShowIcon ? 1 : 0,
                duration: KumoMotion.duration(context, KumoDurations.quick),
                child: KumoIcon(KumoIcons.copySimple, size: 14, dangerouslySetColor: iconColor),
              ),
          },
        );
        final content = widget.child != null
            ? DefaultTextStyle.merge(
                style: style,
                maxLines: widget.truncate ? 1 : null,
                overflow: widget.truncate ? TextOverflow.ellipsis : null,
                child: widget.child!,
              )
            : Text(
                widget.text!,
                style: style,
                maxLines: widget.truncate ? 1 : null,
                overflow: widget.truncate ? TextOverflow.ellipsis : null,
                softWrap: !widget.truncate,
              );
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1,
          children: [Flexible(child: content), icon],
        );
      },
    );
  }
}
