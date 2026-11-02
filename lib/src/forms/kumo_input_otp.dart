import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import 'src/forms_internal.dart';

/// A one-time code field drawn as [length] cells, for verification codes
/// sent by SMS, email or an authenticator app. Kumo has no such component;
/// this follows shadcn's `InputOTP` with Kumo's field chrome.
///
/// One hidden text field drives every cell, so typing fills the next cell,
/// backspace clears the previous one, pasting a code (even "123 456") fills
/// them all, and the platform's one-time-code autofill works. Digits only by
/// default, with the number keyboard; set [alphanumeric] for letter codes.
///
/// ```dart
/// KumoInputOtp(
///   label: 'Verification code',
///   description: 'Enter the 6-digit code from your authenticator app.',
///   value: code,
///   groups: const [3, 3],
///   onValueChange: (v) => setState(() => code = v),
///   onComplete: verify,
/// )
/// ```
class KumoInputOtp extends StatefulWidget {
  const KumoInputOtp({
    super.key,
    this.length = 6,
    this.value,
    this.onValueChange,
    this.onComplete,
    this.controller,
    this.focusNode,
    this.groups,
    this.size = KumoFieldSize.lg,
    this.label,
    this.labelTooltip,
    this.description,
    this.error,
    this.required = false,
    this.showOptional = false,
    this.semanticLabel,
    this.disabled = false,
    this.obscureText = false,
    this.alphanumeric = false,
    this.autofocus = false,
    this.scrollPadding = formsScrollPadding,
  }) : assert(length > 0);

  /// Number of cells.
  final int length;

  /// The code typed so far. Null leaves the field uncontrolled.
  final String? value;

  /// Called with the whole code after every edit.
  final ValueChanged<String>? onValueChange;

  /// Called each time the code reaches [length] characters.
  final ValueChanged<String>? onComplete;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Splits the cells into groups with a dash between them: `[3, 3]` for
  /// "123-456". The counts must add up to [length].
  final List<int>? groups;

  /// Cell height; cells are square. Defaults to `lg` (40px) for legibility.
  final KumoFieldSize size;
  final String? label;
  final String? labelTooltip;
  final String? description;

  /// Error message below the cells; also turns every cell's ring red.
  final String? error;
  final bool required;
  final bool showOptional;

  /// Accessible name when there is no [label].
  final String? semanticLabel;
  final bool disabled;

  /// Shows a dot in place of each character.
  final bool obscureText;

  /// Accepts letters too (uppercased), with a text keyboard.
  final bool alphanumeric;
  final bool autofocus;
  final EdgeInsets scrollPadding;

  @override
  State<KumoInputOtp> createState() => _KumoInputOtpState();
}

class _KumoInputOtpState extends FormsTextState<KumoInputOtp> {
  @override
  String? get controlledValue => widget.value;
  @override
  TextEditingController? get externalController => widget.controller;
  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleText);
  }

  @override
  void didUpdateWidget(KumoInputOtp oldWidget) {
    super.didUpdateWidget(oldWidget);
    previousController(oldWidget.controller)?.removeListener(_handleText);
    syncWidget(oldWidget.controller, oldWidget.focusNode);
    controller.addListener(_handleText);
  }

  @override
  void dispose() {
    controller.removeListener(_handleText);
    super.dispose();
  }

  void _handleText() {
    final v = controller.value;
    // Cells fill in order, so the caret always sits after the last character.
    if (v.composing.isCollapsed && v.selection != TextSelection.collapsed(offset: v.text.length)) {
      controller.selection = TextSelection.collapsed(offset: v.text.length);
    }
    if (mounted) setState(() {});
  }

  void _handleChanged(String text) {
    widget.onValueChange?.call(text);
    if (text.length == widget.length) widget.onComplete?.call(text);
  }

  List<int> get _groups {
    final g = widget.groups;
    if (g == null || g.isEmpty || g.fold<int>(0, (a, b) => a + b) != widget.length) return [widget.length];
    return g;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final size = widget.size;
    final text = controller.text;
    final chars = text.characters.toList();
    final active = math.min(chars.length, widget.length - 1);
    final style = kumo.code(large: true);
    // Square cells that grow with the text scale instead of clipping it.
    final lineHeight = MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    final extent = math.max(size.height, lineHeight + KumoSpace.s2);

    Widget cell(int i) => SizedBox(
      width: extent,
      child: KumoFieldBox(
        size: size,
        minHeight: extent,
        focused: focused && !widget.disabled && i == active,
        error: widget.error != null,
        disabled: widget.disabled,
        padding: EdgeInsets.zero,
        child: Center(
          child: i < chars.length
              ? Text(widget.obscureText ? '•' : chars[i], style: style, maxLines: 1)
              : focused && !widget.disabled && i == chars.length
              // The real field is invisible, so the next empty cell draws
              // its own caret.
              ? _OtpCaret(key: ValueKey(i), height: lineHeight * 0.8)
              : const SizedBox.shrink(),
        ),
      ),
    );

    final rows = <Widget>[];
    var index = 0;
    final groups = _groups;
    for (var g = 0; g < groups.length; g++) {
      if (g > 0) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: KumoSpace.s1),
            child: KumoIcon(KumoIcons.minus, color: KumoColor.textSubtle),
          ),
        );
      }
      final cells = <Widget>[];
      for (var i = 0; i < groups[g]; i++) {
        cells.add(cell(index++));
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, spacing: KumoSpace.s2, children: cells));
    }

    final field = KumoEditable(
      controller: controller,
      focusNode: focusNode,
      enabled: !widget.disabled,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      obscureText: widget.obscureText,
      keyboardType: widget.alphanumeric ? TextInputType.visiblePassword : TextInputType.number,
      textCapitalization: widget.alphanumeric ? TextCapitalization.characters : TextCapitalization.none,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        if (widget.alphanumeric) ...[
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
          TextInputFormatter.withFunction((_, v) => v.copyWith(text: v.text.toUpperCase())),
        ] else
          FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: widget.length,
      autofillHints: const [AutofillHints.oneTimeCode],
      onChanged: _handleChanged,
      scrollPadding: widget.scrollPadding,
    );

    final cellsRow = Row(mainAxisSize: MainAxisSize.min, children: rows);

    final input = Stack(
      children: [
        IgnorePointer(child: ExcludeSemantics(child: cellsRow)),
        // The real field covers the cells, invisible but tappable, so a tap
        // focuses it and a long press offers Paste.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: FormsFieldSemantics(
              label: widget.label ?? widget.semanticLabel,
              description: widget.description,
              error: widget.error,
              tooltip: widget.labelTooltip,
              required: widget.required,
              child: field,
            ),
          ),
        ),
      ],
    );

    return FormsFieldFrame(
      label: widget.label,
      labelTooltip: widget.labelTooltip,
      description: widget.description,
      error: widget.error,
      required: widget.required,
      showOptional: widget.showOptional,
      onLabelTap: widget.disabled ? null : focusNode.requestFocus,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        // Shrinks the cells rather than overflowing a narrow screen.
        child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: input),
      ),
    );
  }
}

/// The caret in the next empty cell. It blinks like a text caret only while
/// the field has focus (it exists only then), pauses off screen, and holds
/// still under reduced motion. A new cell gets a fresh caret, solid at first.
class _OtpCaret extends StatefulWidget {
  const _OtpCaret({super.key, required this.height});

  final double height;

  @override
  State<_OtpCaret> createState() => _OtpCaretState();
}

class _OtpCaretState extends State<_OtpCaret> {
  Timer? _timer;
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Blinks on a timer like Flutter's own caret, only while on screen and
    // with motion allowed.
    final run = TickerMode.of(context) && !KumoMotion.reduceMotion(context);
    if (run && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() => _visible = !_visible));
    } else if (!run) {
      _timer?.cancel();
      _timer = null;
      _visible = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: _visible ? 1 : 0,
    child: Container(
      width: 1.5,
      height: widget.height,
      decoration: BoxDecoration(color: context.kumo.colors.textDefault, borderRadius: BorderRadius.circular(1)),
    ),
  );
}
