import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_typography.dart';

/// The bare text-editing core shared by every Kumo field (input, textarea,
/// select search, combobox, tag input, date input, command palette).
///
/// It draws no box, border or label: just Kumo-styled text, a Kumo caret and
/// selection color, the placeholder, and platform selection handles and
/// context menu. Components put it inside their own field chrome.
///
/// ```dart
/// KumoEditable(
///   controller: controller,
///   focusNode: focusNode,
///   placeholder: 'my-worker',
///   onChanged: (v) => setState(() => name = v),
/// )
/// ```
class KumoEditable extends StatelessWidget {
  const KumoEditable({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.size = KumoTextSize.base,
    this.mono = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.semanticLabel,
    this.color = KumoColor.textDefault,
    this.scrollPadding = const EdgeInsets.all(20),
    this.showCursor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final KumoTextSize size;

  /// Monospace text (API tokens, IDs, code).
  final bool mono;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? minLines;

  /// 1 for single line, null to grow without limit.
  final int? maxLines;
  final TextAlign textAlign;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;

  /// Accessible name when there is no visible label wired up by the parent.
  final String? semanticLabel;
  final KumoColor color;

  /// Space kept between the field and the screen edge (or the keyboard) when
  /// the field scrolls into view on focus.
  final EdgeInsets scrollPadding;

  /// Null shows the cursor while focused; false hides it (hidden-field
  /// patterns such as one-time-code inputs).
  final bool? showCursor;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final style = mono
        ? kumo.code(large: size == KumoTextSize.base || size == KumoTextSize.lg, color: color)
        : kumo.text(size: size, color: color);
    final caret = kumo.colors.textDefault;
    final multiline = maxLines != 1;

    Widget field = TextSelectionTheme(
      data: TextSelectionThemeData(
        cursorColor: caret,
        selectionColor: kumo.colors.brand.withValues(alpha: 0.24),
        selectionHandleColor: kumo.colors.brand,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        autofocus: autofocus,
        autocorrect: autocorrect && !obscureText,
        enableSuggestions: enableSuggestions && !obscureText,
        keyboardType: keyboardType ?? (multiline ? TextInputType.multiline : null),
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        buildCounter: _noCounter,
        minLines: minLines,
        maxLines: obscureText ? 1 : maxLines,
        textAlign: textAlign,
        textAlignVertical: multiline ? TextAlignVertical.top : TextAlignVertical.center,
        autofillHints: autofillHints,
        style: style,
        cursorColor: caret,
        showCursor: showCursor,
        cursorWidth: 1.5,
        cursorRadius: const Radius.circular(1),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        onTapOutside: onTapOutside,
        onEditingComplete: onEditingComplete,
        scrollPadding: scrollPadding,
        decoration: InputDecoration.collapsed(
          hintText: placeholder,
          hintStyle: style.copyWith(color: kumo.colors.textPlaceholder),
        ).copyWith(isDense: true, contentPadding: EdgeInsets.zero),
      ),
    );
    if (semanticLabel != null) {
      field = Semantics(label: semanticLabel, textField: true, child: field);
    }
    // TextField needs a Material ancestor for ink and selection toolbars;
    // a transparent one keeps Kumo surfaces visible.
    return Material(type: MaterialType.transparency, child: field);
  }

  static Widget? _noCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}
