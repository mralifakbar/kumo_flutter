// Shared plumbing for the text-style controls in this folder. Not exported
// from the package barrel.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../icons/kumo_icon.dart';
import '../../overlays/kumo_anchored_overlay.dart';
import '../../overlays/kumo_tooltip.dart';
import '../../system/kumo_field.dart';
import '../../system/kumo_field_box.dart';
import '../../system/kumo_focus_ring.dart';
import '../../system/kumo_pressable.dart';
import '../../theme/generated/kumo_colors.g.dart';
import '../../theme/kumo_theme.dart';
import '../../theme/kumo_tokens.dart';
import 'field_motion.dart';

/// Keeps the label above and the description below a focused field visible
/// when it scrolls into view above the keyboard.
const EdgeInsets formsScrollPadding = EdgeInsets.fromLTRB(20, 56, 20, 56);

/// Icon size Kumo pairs with each field size (`size-3` small, `size-4` default).
double formsIconSize(KumoFieldSize size) => size == KumoFieldSize.xs || size == KumoFieldSize.sm ? 12 : 16;

/// The button size one step down from the field, so a button inside a field
/// stays subordinate to it (Kumo's `COMPACT_BUTTON_SIZE`).
double formsCompactButtonExtent(KumoFieldSize size) => switch (size) {
  KumoFieldSize.xs => 20,
  KumoFieldSize.sm => 20,
  KumoFieldSize.base => 26,
  KumoFieldSize.lg => 36,
};

/// Owns the controller and focus node of a text control: an internal
/// controller synced to a controlled `value`, or an external one.
abstract class FormsTextState<T extends StatefulWidget> extends State<T> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  bool focused = false;

  /// The controlled value, or null when uncontrolled.
  String? get controlledValue;
  TextEditingController? get externalController;
  FocusNode? get externalFocusNode;

  TextEditingController get controller =>
      externalController ?? (_ownController ??= TextEditingController(text: controlledValue ?? ''));

  FocusNode get focusNode => externalFocusNode ?? (_ownFocusNode ??= FocusNode());

  /// The controller that was in use before an update that may have swapped
  /// [externalController], so listeners can move off it.
  TextEditingController? previousController(TextEditingController? oldExternal) => oldExternal ?? _ownController;

  @override
  void initState() {
    super.initState();
    final value = controlledValue;
    if (externalController != null && value != null && value != externalController!.text) {
      externalController!.text = value;
    }
    focusNode.addListener(_handleFocus);
    focused = focusNode.hasFocus;
  }

  /// Call from didUpdateWidget with the old widget's controller and node.
  void syncWidget(TextEditingController? oldController, FocusNode? oldFocusNode) {
    if (oldFocusNode != externalFocusNode) {
      (oldFocusNode ?? _ownFocusNode)?.removeListener(_handleFocus);
      focusNode.addListener(_handleFocus);
      focused = focusNode.hasFocus;
    }
    if (oldController != null && externalController == null) {
      _ownController ??= TextEditingController(text: oldController.text);
    }
    writeValue(controlledValue);
  }

  /// Writes [value] into the controller. A value equal to the text leaves the
  /// caret alone; a different one keeps the selection, clamped to the new text.
  void writeValue(String? value) {
    if (value == null) return;
    final c = controller;
    if (value == c.text) return;
    final sel = c.selection;
    final len = value.length;
    final selection = sel.isValid
        ? TextSelection(baseOffset: sel.baseOffset.clamp(0, len), extentOffset: sel.extentOffset.clamp(0, len))
        : TextSelection.collapsed(offset: len);
    c.value = TextEditingValue(text: value, selection: selection);
  }

  void _handleFocus() {
    if (!mounted) return;
    if (focused != focusNode.hasFocus) {
      setState(() => focused = focusNode.hasFocus);
      onFocusChanged(focused);
    }
  }

  /// Hook for subclasses.
  void onFocusChanged(bool hasFocus) {}

  @override
  void dispose() {
    focusNode.removeListener(_handleFocus);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }
}

/// Gives the editable inside [child] its accessible name and state, the way
/// `<label for>` and `aria-describedby` do on the web.
class FormsFieldSemantics extends StatelessWidget {
  const FormsFieldSemantics({
    super.key,
    required this.child,
    this.label,
    this.description,
    this.error,
    this.tooltip,
    this.required = false,
  });

  final Widget child;
  final String? label;
  final String? description;
  final String? error;
  final String? tooltip;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final hint = error ?? description;
    return MergeSemantics(
      child: Semantics(
        label: label,
        hint: hint,
        tooltip: tooltip,
        isRequired: required ? true : null,
        validationResult: error != null ? SemanticsValidationResult.invalid : SemanticsValidationResult.none,
        child: child,
      ),
    );
  }
}

/// Lays out a control with Kumo's `Field` parts when it has a label,
/// description or error: the label above (tapping it focuses the control)
/// and the message below, which opens, closes and cross-fades through
/// [FieldMessage] instead of popping.
///
/// The control sits under a [GlobalKey], so gaining or losing the frame (an
/// error appearing on an unlabeled field) moves it without rebuilding it: a
/// field being typed in keeps its focus, text and keyboard.
///
/// By default the visible label is hidden from screen readers, because the
/// control carries the name itself (see [FormsFieldSemantics]), and so is the
/// description, which the control announces as its hint. Controls that do not
/// (a select trigger) pass [controlLabeled] and [controlDescribed] false.
class FormsFieldFrame extends StatefulWidget {
  const FormsFieldFrame({
    super.key,
    required this.child,
    this.label,
    this.labelWidget,
    this.labelTooltip,
    this.description,
    this.error,
    this.required = false,
    this.showOptional = false,
    this.onLabelTap,
    this.controlLabeled = true,
    this.controlDescribed = true,
  });

  final Widget child;
  final String? label;
  final Widget? labelWidget;
  final String? labelTooltip;
  final String? description;
  final String? error;
  final bool required;
  final bool showOptional;
  final VoidCallback? onLabelTap;
  final bool controlLabeled;
  final bool controlDescribed;

  @override
  State<FormsFieldFrame> createState() => _FormsFieldFrameState();
}

class _FormsFieldFrameState extends State<FormsFieldFrame> {
  final GlobalKey _controlKey = GlobalKey();
  bool _built = false;

  /// Stays true while a message that went away is still closing.
  bool _framed = false;

  bool get _hasLabel =>
      widget.label != null || widget.labelWidget != null || widget.showOptional || widget.labelTooltip != null;

  bool get _needsFrame => _hasLabel || widget.description != null || widget.error != null;

  @override
  Widget build(BuildContext context) {
    final animateIn = _built;
    _built = true;
    final control = KeyedSubtree(key: _controlKey, child: widget.child);
    if (_needsFrame) _framed = true;
    if (!_framed) return control;

    Widget? labelNode;
    if (_hasLabel) {
      labelNode = Align(
        alignment: AlignmentDirectional.centerStart,
        child:
            widget.labelWidget ??
            KumoLabel(
              widget.label ?? '',
              showOptional: widget.showOptional,
              tooltip: widget.labelTooltip,
              required: widget.required,
            ),
      );
      if (widget.controlLabeled) labelNode = ExcludeSemantics(child: labelNode);
      if (widget.onLabelTap != null) {
        labelNode = GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onLabelTap, child: labelNode);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelNode != null) ...[labelNode, const SizedBox(height: KumoSpace.s2)],
        control,
        FieldMessage(
          description: widget.description,
          error: widget.error,
          controlDescribed: widget.controlDescribed,
          animateIn: animateIn,
          onHidden: () {
            if (mounted && !_needsFrame && _framed) setState(() => _framed = false);
          },
        ),
      ],
    );
  }
}

/// A square ghost icon button sized to sit inside a field: the toggle, copy,
/// clear and stepper buttons. The visual is one size down from the field; on
/// touch the hit area widens to 44 and takes the field's full height.
class FormsCompactButton extends StatelessWidget {
  const FormsCompactButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.fieldSize,
    this.onPress,
    this.onPressIn,
    this.onPressOut,
    this.disabled = false,
    this.tooltip,
    this.radius,
    this.iconSize,
    this.extent,
    this.color = KumoColor.textSubtle,
    this.canRequestFocus = true,
    this.focusNode,
  });

  final IconData icon;
  final String semanticLabel;
  final KumoFieldSize fieldSize;
  final VoidCallback? onPress;
  final VoidCallback? onPressIn;
  final VoidCallback? onPressOut;
  final bool disabled;
  final String? tooltip;

  /// Corner radius; defaults to concentric with the field corner.
  final double? radius;
  final double? iconSize;

  /// Visual edge; defaults to [formsCompactButtonExtent].
  final double? extent;
  final KumoColor color;
  final bool canRequestFocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final edge = extent ?? formsCompactButtonExtent(fieldSize);
    final inset = (fieldSize.height - edge) / 2;
    final r = radius ?? KumoRadius.concentric(fieldSize.radius, inset.clamp(0, fieldSize.radius));
    final borderRadius = BorderRadius.circular(r);
    final touch = kumo.minTapTarget > 0;

    Widget button = KumoPressable(
      onPress: disabled ? null : onPress,
      onPressIn: onPressIn,
      onPressOut: onPressOut,
      disabled: disabled,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      borderRadius: borderRadius,
      // The ring is drawn around the visual, not the wider touch hit area.
      showFocusRing: false,
      minTapTargetSize: 0,
      canRequestFocus: canRequestFocus,
      focusNode: focusNode,
      builder: (context, state) {
        final fg = state.active && !disabled ? c.textDefault : kumo.color(color);
        Widget visual = Container(
          width: edge,
          height: edge,
          decoration: BoxDecoration(color: state.active && !disabled ? c.tint : null, borderRadius: borderRadius),
          alignment: Alignment.center,
          child: KumoIcon(icon, size: iconSize ?? (edge <= 20 ? 12 : 16), dangerouslySetColor: fg),
        );
        if (disabled) visual = Opacity(opacity: 0.5, child: visual);
        visual = KumoFocusRing(
          visible: state.focused,
          borderRadius: borderRadius,
          color: KumoColor.focus,
          width: 1.5,
          child: visual,
        );
        // On touch the hit area is wider than the visual and as tall as the
        // field, so it never grows the field past its Kumo height.
        return touch
            ? SizedBox(
                width: 44,
                height: fieldSize.height,
                child: Center(child: visual),
              )
            : visual;
      },
    );
    if (tooltip != null) {
      button = KumoTooltip(content: tooltip!, side: KumoSide.bottom, child: button);
    }
    return button;
  }
}

/// Announces [message] to screen readers.
void formsAnnounce(BuildContext context, String message) {
  final view = View.maybeOf(context);
  if (view == null) return;
  SemanticsService.sendAnnouncement(view, message, Directionality.maybeOf(context) ?? TextDirection.ltr);
}
