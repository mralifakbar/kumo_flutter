import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import 'src/forms_internal.dart';

/// Kumo's `Input`: a single-line text field with a built-in label,
/// description and error message.
///
/// It is controlled: pass [value] and update it in [onValueChange]. The
/// field keeps an internal [TextEditingController] in sync with [value], so
/// the caret stays put while typing and moves only when the value changes
/// from outside. Pass [controller] instead to drive the text yourself.
///
/// ```dart
/// KumoInput(
///   label: 'Worker name',
///   description: 'Lowercase letters, numbers and dashes.',
///   placeholder: 'image-resizer',
///   value: name,
///   onValueChange: (v) => setState(() => name = v),
/// )
/// ```
///
/// Without a [label], give the field a [semanticLabel] (Kumo's `aria-label`):
///
/// ```dart
/// KumoInput(
///   semanticLabel: 'Search Workers',
///   placeholder: 'Search...',
///   leadingIcon: KumoIcons.magnifyingGlass,
///   value: query,
///   onValueChange: (v) => setState(() => query = v),
/// )
/// ```
class KumoInput extends StatefulWidget {
  const KumoInput({
    super.key,
    this.value,
    this.onValueChange,
    this.controller,
    this.focusNode,
    this.size = KumoFieldSize.base,
    this.label,
    this.labelWidget,
    this.labelTooltip,
    this.description,
    this.error,
    this.required = false,
    this.showOptional = false,
    this.placeholder,
    this.semanticLabel,
    this.disabled = false,
    this.readOnly = false,
    this.leadingIcon,
    this.trailingIcon,
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.mono = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.passwordManagerIgnore = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.scrollPadding = formsScrollPadding,
  });

  /// The text. Null leaves the field uncontrolled (the controller owns it).
  final String? value;

  /// Called with the new text on every edit.
  final ValueChanged<String>? onValueChange;

  /// Drives the text directly instead of [value]. When both are set, a new
  /// [value] is written into this controller.
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// `xs` 20, `sm` 26, `base` 36 (default), `lg` 40 px tall at 1x text.
  final KumoFieldSize size;

  /// Text above the field. Setting a label, description or error wraps the
  /// field in a [KumoField].
  final String? label;

  /// Custom label content in place of [label]. Set [semanticLabel] too, since
  /// a widget label cannot name the field for screen readers.
  final Widget? labelWidget;

  /// Info icon next to the label with this tooltip.
  final String? labelTooltip;

  /// Helper text below the field. Hidden while [error] is set.
  final String? description;

  /// Error message below the field. Also turns the ring red and marks the
  /// field invalid for screen readers.
  final String? error;

  /// Announces the field as required. Kumo draws no asterisk.
  final bool required;

  /// Shows "(optional)" after the label (Kumo's `required={false}`).
  final bool showOptional;
  final String? placeholder;

  /// Accessible name when there is no [label] (Kumo's `aria-label`).
  final String? semanticLabel;
  final bool disabled;

  /// Selectable but not editable, on a recessed fill.
  final bool readOnly;

  /// Icon inside the field at the start, sized to the field.
  final IconData? leadingIcon;

  /// Icon inside the field at the end.
  final IconData? trailingIcon;

  /// Widget at the start, in place of [leadingIcon].
  final Widget? leading;

  /// Widget at the end, in place of [trailingIcon] (a clear button, a unit).
  final Widget? trailing;

  /// Masks the text, like `type="password"`.
  final bool obscureText;

  /// Monospace text, for IDs, tokens and hostnames.
  final bool mono;

  /// The on-screen keyboard: [TextInputType.emailAddress] for `type="email"`,
  /// [TextInputType.url], [TextInputType.phone], [TextInputType.number].
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  /// Autofill hints such as [AutofillHints.email]. Null (the default) keeps
  /// the field out of autofill.
  final Iterable<String>? autofillHints;

  /// Keeps password managers away from a field that is not a credential
  /// (an API token, a search box). Drops [autofillHints] and turns off
  /// suggestions. iOS may still offer saved passwords on an [obscureText]
  /// field; there is no platform switch to stop that.
  final bool passwordManagerIgnore;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;

  /// Hard limit on characters, like `maxLength`. No counter is drawn.
  final int? maxLength;
  final TextAlign textAlign;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;

  /// Space kept around the field when it scrolls into view above the
  /// keyboard. The default leaves room for the label and description.
  final EdgeInsets scrollPadding;

  @override
  State<KumoInput> createState() => _KumoInputState();
}

class _KumoInputState extends FormsTextState<KumoInput> {
  @override
  String? get controlledValue => widget.value;
  @override
  TextEditingController? get externalController => widget.controller;
  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void didUpdateWidget(KumoInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidget(oldWidget.controller, oldWidget.focusNode);
  }

  void _focus() {
    if (!widget.disabled) focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final iconSize = formsIconSize(size);
    final leading =
        widget.leading ?? (widget.leadingIcon != null ? KumoIcon(widget.leadingIcon!, size: iconSize) : null);
    final trailing =
        widget.trailing ?? (widget.trailingIcon != null ? KumoIcon(widget.trailingIcon!, size: iconSize) : null);
    final ignorePm = widget.passwordManagerIgnore;

    final editable = KumoEditable(
      controller: controller,
      focusNode: focusNode,
      placeholder: widget.placeholder,
      size: size.textSize,
      mono: widget.mono,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect && !ignorePm,
      enableSuggestions: widget.enableSuggestions && !ignorePm,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      textAlign: widget.textAlign,
      autofillHints: ignorePm ? null : widget.autofillHints,
      onChanged: widget.onValueChange,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onTap: widget.onTap,
      scrollPadding: widget.scrollPadding,
    );

    final box = GestureDetector(
      // Taps on the padding or an icon focus the field, like a web <label>.
      behavior: HitTestBehavior.translucent,
      onTap: _focus,
      child: KumoFieldBox(
        size: size,
        focused: focused && !widget.readOnly,
        error: widget.error != null,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        leading: leading,
        trailing: trailing,
        child: FormsFieldSemantics(
          label: widget.label ?? widget.semanticLabel,
          description: widget.description,
          error: widget.error,
          tooltip: widget.labelTooltip,
          required: widget.required,
          child: editable,
        ),
      ),
    );

    return FormsFieldFrame(
      label: widget.label,
      labelWidget: widget.labelWidget,
      labelTooltip: widget.labelTooltip,
      description: widget.description,
      error: widget.error,
      required: widget.required,
      showOptional: widget.showOptional,
      onLabelTap: _focus,
      child: box,
    );
  }
}
