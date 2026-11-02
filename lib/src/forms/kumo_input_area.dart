import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import 'src/forms_internal.dart';

/// Kumo's `InputArea`: a multi-line text field (a textarea) with a built-in
/// label, description and error message.
///
/// By default it shows [rows] lines and scrolls past them. With [autoResize]
/// it starts at [minRows] lines and grows with its content up to [maxRows]
/// (or without limit when [maxRows] is null), then scrolls.
///
/// ```dart
/// KumoInputArea(
///   label: 'Deployment notes',
///   placeholder: 'What changed in this version?',
///   autoResize: true,
///   minRows: 2,
///   maxRows: 8,
///   value: notes,
///   onValueChange: (v) => setState(() => notes = v),
/// )
/// ```
///
/// The web drag handle (`resize`) has no touch equivalent; use [autoResize].
class KumoInputArea extends StatefulWidget {
  const KumoInputArea({
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
    this.rows = 3,
    this.autoResize = false,
    this.minRows = 1,
    this.maxRows,
    this.mono = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.maxLength,
    this.autofocus = false,
    this.onTap,
    this.scrollPadding = formsScrollPadding,
  }) : assert(rows > 0 && minRows > 0),
       assert(maxRows == null || maxRows >= minRows);

  /// The text. Null leaves the field uncontrolled.
  final String? value;
  final ValueChanged<String>? onValueChange;

  /// Drives the text directly instead of [value].
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Sets the text size and horizontal padding. The height comes from the rows.
  final KumoFieldSize size;
  final String? label;

  /// Custom label content; set [semanticLabel] with it.
  final Widget? labelWidget;
  final String? labelTooltip;
  final String? description;
  final String? error;
  final bool required;

  /// Shows "(optional)" after the label.
  final bool showOptional;
  final String? placeholder;

  /// Accessible name when there is no [label].
  final String? semanticLabel;
  final bool disabled;
  final bool readOnly;

  /// Visible lines when [autoResize] is off (the HTML `rows` attribute).
  final int rows;

  /// Grow and shrink with the content between [minRows] and [maxRows].
  final bool autoResize;

  /// Lines shown when empty, with [autoResize].
  final int minRows;

  /// Lines to grow to before scrolling, with [autoResize]. Null grows
  /// without limit.
  final int? maxRows;

  /// Monospace text, for scripts and config.
  final bool mono;
  final TextInputType? keyboardType;

  /// Defaults to a newline key.
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool autofocus;
  final VoidCallback? onTap;

  /// Space kept around the field when it scrolls into view above the keyboard.
  final EdgeInsets scrollPadding;

  @override
  State<KumoInputArea> createState() => _KumoInputAreaState();
}

class _KumoInputAreaState extends FormsTextState<KumoInputArea> {
  @override
  String? get controlledValue => widget.value;
  @override
  TextEditingController? get externalController => widget.controller;
  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void didUpdateWidget(KumoInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidget(oldWidget.controller, oldWidget.focusNode);
  }

  void _focus() {
    if (!widget.disabled) focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final minLines = widget.autoResize ? widget.minRows : widget.rows;
    final maxLines = widget.autoResize ? widget.maxRows : widget.rows;

    final editable = KumoEditable(
      controller: controller,
      focusNode: focusNode,
      placeholder: widget.placeholder,
      size: widget.size.textSize,
      mono: widget.mono,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      keyboardType: widget.keyboardType ?? TextInputType.multiline,
      textInputAction: widget.textInputAction ?? TextInputAction.newline,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: widget.onValueChange,
      onTap: widget.onTap,
      scrollPadding: widget.scrollPadding,
    );

    final box = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _focus,
      child: KumoFieldBox(
        size: widget.size,
        multiline: true,
        focused: focused && !widget.readOnly,
        error: widget.error != null,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
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
