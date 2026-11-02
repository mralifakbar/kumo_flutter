import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_popup_surface.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Open state and actions handed to a [KumoPopover.triggerBuilder].
@immutable
class KumoPopoverController {
  const KumoPopoverController({required this.isOpen, required this.open, required this.close, required this.toggle});

  final bool isOpen;
  final VoidCallback open;
  final VoidCallback close;
  final VoidCallback toggle;
}

/// Builds the trigger of a [KumoPopover] from its controller.
typedef KumoPopoverTriggerBuilder = Widget Function(BuildContext context, KumoPopoverController popover);

/// Kumo's `Popover`: rich, interactive content anchored to a trigger
/// (a settings form, a notification list, a confirmation with buttons).
///
/// ```dart
/// KumoPopover(
///   triggerBuilder: (context, popover) => KumoButton(
///     icon: KumoIcons.bell,
///     shape: KumoButtonShape.square,
///     semanticLabel: 'Notifications',
///     onPress: popover.toggle,
///   ),
///   children: const [
///     KumoPopoverTitle('Notifications'),
///     KumoPopoverDescription('No new alerts for example.com.'),
///   ],
/// )
/// ```
///
/// * Opens from the trigger with a scale-from-anchor spring (Kumo's
///   `scale-90` + fade, 150ms) and closes the same way.
/// * Focus moves into the popover and Tab stays inside it; Escape, an
///   outside tap or a [KumoPopoverClose] closes it and focus returns to the
///   trigger.
/// * Use [KumoTooltip] for short non-interactive labels, and
///   [KumoHoverCard] for previews that open on hover.
class KumoPopover extends StatefulWidget {
  const KumoPopover({
    super.key,
    required this.children,
    this.trigger,
    this.triggerBuilder,
    this.open,
    this.onOpenChange,
    this.side = KumoSide.bottom,
    this.align = KumoAlign.center,
    this.sideOffset = 8,
    this.alignOffset = 0,
    this.showArrow = true,
    this.width,
    this.maxWidth = 360,
    this.padding = const EdgeInsets.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s3),
    this.semanticLabel,
    this.dismissOnOutsideTap = true,
    this.closeOnEscape = true,
    this.disabled = false,
    this.onClosed,
  }) : assert((trigger == null) != (triggerBuilder == null), 'Pass either trigger or triggerBuilder');

  /// Popup content, stacked top to bottom (Kumo's `flex flex-col`). Usually
  /// a [KumoPopoverTitle], a [KumoPopoverDescription] and controls.
  final List<Widget> children;

  /// Non-interactive trigger content. The popover makes it pressable. A
  /// [KumoButton] without `onPress` renders disabled, so use
  /// [triggerBuilder] for buttons.
  final Widget? trigger;

  /// Builds an interactive trigger that calls `popover.toggle`.
  final KumoPopoverTriggerBuilder? triggerBuilder;

  /// Controls the open state. Leave null to let the popover manage it.
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final KumoSide side;
  final KumoAlign align;

  /// Gap between trigger and popup. Kumo's default is 8; the arrow sits in it.
  final double sideOffset;
  final double alignOffset;

  /// Kumo's `Popover.Arrow`.
  final bool showArrow;

  /// Fixed width (Kumo demos use `w-72`, 288). Null sizes to the content up
  /// to [maxWidth].
  final double? width;
  final double maxWidth;

  /// Kumo's `px-4 py-3`.
  final EdgeInsetsGeometry padding;

  /// Accessible name of the popup. Defaults to the title text when the first
  /// child is a [KumoPopoverTitle].
  final String? semanticLabel;
  final bool dismissOnOutsideTap;
  final bool closeOnEscape;
  final bool disabled;

  /// Called after the close animation finishes.
  final VoidCallback? onClosed;

  /// Closes the popover that [context] is inside, from custom content such
  /// as a form's submit button. Returns false when there is none.
  ///
  /// ```dart
  /// KumoButton(label: 'Apply', onPress: () => KumoPopover.closeFrom(context))
  /// ```
  static bool closeFrom(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_PopoverScope>();
    scope?.close();
    return scope != null;
  }

  @override
  State<KumoPopover> createState() => _KumoPopoverState();
}

class _KumoPopoverState extends State<KumoPopover> {
  bool _internalOpen = false;

  bool get _open => widget.open ?? _internalOpen;

  void _setOpen(bool value) {
    if (value && widget.disabled) return;
    if (value == _open) return;
    if (widget.open == null) setState(() => _internalOpen = value);
    widget.onOpenChange?.call(value);
  }

  KumoPopoverController get _controller => KumoPopoverController(
    isOpen: _open,
    open: () => _setOpen(true),
    close: () => _setOpen(false),
    toggle: () => _setOpen(!_open),
  );

  String? get _label {
    if (widget.semanticLabel != null) return widget.semanticLabel;
    final first = widget.children.isEmpty ? null : widget.children.first;
    return first is KumoPopoverTitle ? first.text : null;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final trigger =
        widget.triggerBuilder?.call(context, _controller) ??
        KumoPressable(
          onPress: widget.disabled ? null : () => _setOpen(!_open),
          disabled: widget.disabled,
          expanded: _open,
          borderRadius: BorderRadius.circular(KumoRadius.lg),
          child: widget.trigger,
        );

    return KumoAnchoredOverlay(
      open: _open,
      side: widget.side,
      align: widget.align,
      sideOffset: widget.sideOffset,
      alignOffset: widget.alignOffset,
      trapFocus: true,
      dismissOnOutsideTap: widget.dismissOnOutsideTap,
      closeOnEscape: widget.closeOnEscape,
      onDismiss: () => _setOpen(false),
      onClosed: widget.onClosed,
      overlayBuilder: (context, placement) {
        Widget body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.children,
        );
        body = SingleChildScrollView(child: body);
        body = widget.width != null ? SizedBox(width: widget.width, child: body) : IntrinsicWidth(child: body);
        return _PopoverScope(
          close: () => _setOpen(false),
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            scopesRoute: true,
            namesRoute: _label != null,
            label: _label,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.width ?? widget.maxWidth, maxHeight: placement.maxHeight),
              child: KumoPopupSurface(
                placement: placement,
                showArrow: widget.showArrow,
                shadow: KumoShadow.md,
                padding: widget.padding,
                child: DefaultTextStyle(
                  style: kumo.text(size: KumoTextSize.sm),
                  child: body,
                ),
              ),
            ),
          ),
        );
      },
      child: trigger,
    );
  }
}

class _PopoverScope extends InheritedWidget {
  const _PopoverScope({required this.close, required super.child});

  final VoidCallback close;

  @override
  bool updateShouldNotify(_PopoverScope oldWidget) => false;
}

/// Heading of a [KumoPopover]: `text-base leading-6 font-medium`.
class KumoPopoverTitle extends StatelessWidget {
  const KumoPopoverTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: context.kumo.text(weight: KumoTypography.medium, height: 24 / 14),
    ),
  );
}

/// Supporting text of a [KumoPopover]: `text-base leading-6 text-kumo-subtle`.
class KumoPopoverDescription extends StatelessWidget {
  const KumoPopoverDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.kumo.text(color: KumoColor.textSubtle, height: 24 / 14),
  );
}

/// A button that closes its [KumoPopover] (Kumo's `Popover.Close` rendered
/// as a small secondary button). [onPress] runs first.
///
/// ```dart
/// KumoPopoverClose(label: 'Got it')
/// KumoPopoverClose(label: 'Save', variant: KumoButtonVariant.primary, onPress: save)
/// ```
class KumoPopoverClose extends StatelessWidget {
  const KumoPopoverClose({
    super.key,
    this.label,
    this.onPress,
    this.variant = KumoButtonVariant.secondary,
    this.size = KumoButtonSize.sm,
    this.icon,
    this.alignment = AlignmentDirectional.centerStart,
  });

  /// Defaults to [KumoStrings.close].
  final String? label;
  final VoidCallback? onPress;
  final KumoButtonVariant variant;
  final KumoButtonSize size;
  final IconData? icon;

  /// Where the button sits in the popover's full-width column.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: KumoButton(
        label: label ?? context.kumoStrings.close,
        icon: icon,
        variant: variant,
        size: size,
        onPress: () {
          onPress?.call();
          KumoPopover.closeFrom(context);
        },
      ),
    );
  }
}
