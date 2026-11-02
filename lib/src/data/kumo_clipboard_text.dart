import 'package:flutter/widgets.dart';

import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_popup_surface.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'copy_feedback.dart';

/// [KumoClipboardText] sizes. Heights match the input of the same size.
enum KumoClipboardTextSize {
  /// 26px, 12px mono, small buttons.
  sm(26, KumoRadius.md, 12, 14),

  /// 36px, 13px mono.
  base(36, KumoRadius.lg, 13, 16),

  /// 40px, 13px mono. Kumo's default.
  lg(40, KumoRadius.lg, 13, 16);

  const KumoClipboardTextSize(this.height, this.radius, this.fontSize, this.iconSize);
  final double height;
  final double radius;
  final double fontSize;
  final double iconSize;
}

/// Tooltip mode for [KumoClipboardText]: a tooltip on hover, and an anchored
/// "Copied" bubble after a copy that bumps on every repeat.
@immutable
class KumoClipboardTextTooltip {
  const KumoClipboardTextTooltip({this.text, this.copiedText, this.side = KumoSide.top});

  /// Shown on hover. Defaults to [KumoStrings.copy].
  final String? text;

  /// Shown after copying. Defaults to [KumoStrings.copied].
  final String? copiedText;
  final KumoSide side;
}

/// Kumo's `ClipboardText`: a read-only, input-like field holding a value
/// (an ID, an API token, a command) with a copy button at its end.
///
/// ```dart
/// const KumoClipboardText(text: '023e105f4ecef8ad9ca31a8372d0c353')
/// const KumoClipboardText(text: 'cf_live_7Hq2...', textToCopy: 'cf_live_7Hq2xK9mZ', masked: true)
/// ```
///
/// After a copy the copy icon slides up and out as a check slides in; it
/// returns after 1.5 seconds. "Copied" is announced to screen readers. If
/// the clipboard write fails, a warning icon replaces the check and
/// [KumoStrings.copyFailed] is announced.
class KumoClipboardText extends StatefulWidget {
  const KumoClipboardText({
    super.key,
    required this.text,
    this.textToCopy,
    this.masked = false,
    this.size = KumoClipboardTextSize.lg,
    this.block = false,
    this.onCopy,
    this.tooltip,
    this.copyLabel,
    this.revealLabel,
    this.hideLabel,
  });

  /// The value shown, and copied unless [textToCopy] is set.
  final String text;

  /// Copied instead of [text] (show a shortened value, copy the full one).
  final String? textToCopy;

  /// Hide the value behind dots, with a button to reveal it.
  final bool masked;
  final KumoClipboardTextSize size;

  /// Fill the parent's width (Kumo's `className="w-full"`).
  final bool block;

  /// Called after a successful copy.
  final VoidCallback? onCopy;

  /// Tooltip mode; null shows the in-button check only.
  final KumoClipboardTextTooltip? tooltip;

  /// Accessible name of the copy button. Defaults to [KumoStrings.copy].
  final String? copyLabel;

  /// Accessible name of the reveal button. Defaults to [KumoStrings.show].
  final String? revealLabel;

  /// Accessible name of the hide button. Defaults to [KumoStrings.hide].
  final String? hideLabel;

  @override
  State<KumoClipboardText> createState() => _KumoClipboardTextState();
}

class _KumoClipboardTextState extends State<KumoClipboardText>
    with TickerProviderStateMixin, DataCopyFeedback<KumoClipboardText> {
  bool _revealed = false;
  late final AnimationController _slide;

  @override
  Duration get copyFeedbackDuration => const Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: KumoDurations.moderate);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final strings = context.kumoStrings;
    final ok = await copyText(
      widget.textToCopy ?? widget.text,
      copied: widget.tooltip?.copiedText ?? strings.copied,
      failed: strings.copyFailed,
    );
    if (ok) widget.onCopy?.call();
  }

  @override
  void didChangeCopyStatus() {
    final target = copyStatus == DataCopyStatus.idle ? 0.0 : 1.0;
    _slide.duration = KumoMotion.duration(context, KumoDurations.moderate);
    _slide.animateTo(target, curve: KumoCurves.standard);
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final size = widget.size;
    final height = size.height < kumo.minTapTarget ? kumo.minTapTarget : size.height;
    final radius = BorderRadius.circular(size.radius);

    final textStyle = kumo.typography.code(color: c.textDefault, height: 1.25).copyWith(fontSize: size.fontSize);
    Widget value = Padding(
      padding: const EdgeInsetsDirectional.only(start: KumoSpace.s4, end: KumoSpace.s2),
      // Revealing and hiding cross-fade the value and ease the field's width.
      child: KumoSwap(
        animateSize: true,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          widget.masked && !_revealed ? '••••••••' : widget.text,
          key: ValueKey(widget.masked && !_revealed),
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
    value = widget.block ? Expanded(child: value) : Flexible(child: value);

    Widget sideButton({
      required String label,
      required VoidCallback onPress,
      required Widget icon,
      bool? toggled,
      BorderRadius? corner,
    }) {
      final minWidth = 40.0 > kumo.minTapTarget ? 40.0 : kumo.minTapTarget;
      return KumoPressable(
        onPress: onPress,
        semanticLabel: label,
        toggled: toggled,
        excludeChildSemantics: true,
        minTapTargetSize: 0,
        focusRingOffset: -2,
        borderRadius: corner ?? BorderRadius.zero,
        builder: (context, state) => Container(
          constraints: BoxConstraints(minWidth: minWidth),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
          decoration: BoxDecoration(
            color: state.active ? c.tint : null,
            borderRadius: corner,
            border: BorderDirectional(start: BorderSide(color: c.line)),
          ),
          alignment: Alignment.center,
          child: icon,
        ),
      );
    }

    final failed = copyStatus == DataCopyStatus.failed;
    final copyIcon = ClipRect(
      child: SizedBox.square(
        dimension: size.iconSize,
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, _) {
            final t = _slide.value;
            final d = size.iconSize;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: Offset(0, -d * t),
                  child: Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: KumoIcon(KumoIcons.copy, size: d, color: KumoColor.textDefault),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, d * (1 - t)),
                  child: Opacity(
                    opacity: t.clamp(0, 1),
                    child: ScaleTransition(
                      scale: copyBump,
                      child: KumoIcon(
                        failed ? KumoIcons.warningCircle : KumoIcons.check,
                        size: d,
                        color: failed ? KumoColor.textDanger : KumoColor.textDefault,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final directionalRadius = BorderRadiusDirectional.only(topEnd: radius.topRight, bottomEnd: radius.bottomRight)
        .resolve(Directionality.of(context));
    Widget copyButton = sideButton(
      label: widget.copyLabel ?? strings.copy,
      onPress: _copy,
      icon: copyIcon,
      corner: directionalRadius,
    );

    final tooltip = widget.tooltip;
    if (tooltip != null) {
      copyButton = KumoAnchoredOverlay(
        open: copyStatus != DataCopyStatus.idle,
        side: tooltip.side,
        dismissOnOutsideTap: false,
        focusPopupWhenUnfocused: false,
        preferredExtent: 40,
        overlayBuilder: (context, placement) => IgnorePointer(
          child: ScaleTransition(
            scale: copyBump,
            child: KumoPopupSurface(
              borderRadius: KumoRadius.md,
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s1_5),
              child: ExcludeSemantics(
                child: Text(
                  failed ? strings.copyFailed : (tooltip.copiedText ?? strings.copied),
                  style: kumo.text(size: KumoTextSize.xs, height: 1.4),
                ),
              ),
            ),
          ),
        ),
        child: KumoTooltip(
          content: tooltip.text ?? strings.copy,
          side: tooltip.side,
          disabled: copyStatus != DataCopyStatus.idle,
          child: copyButton,
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(color: c.base, borderRadius: radius, border: KumoRing.border(c.line)),
      child: ClipRRect(
        borderRadius: radius,
        child: Row(
          mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
          children: [
            value,
            if (widget.masked)
              sideButton(
                label: _revealed ? (widget.hideLabel ?? strings.hide) : (widget.revealLabel ?? strings.show),
                onPress: () => setState(() => _revealed = !_revealed),
                toggled: _revealed,
                icon: KumoSwap(
                  child: KumoIcon(
                    _revealed ? KumoIcons.eyeSlash : KumoIcons.eye,
                    key: ValueKey(_revealed),
                    size: size.iconSize,
                  ),
                ),
              ),
            copyButton,
          ],
        ),
      ),
    );
  }
}
