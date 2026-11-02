import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../forms/src/forms_internal.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_calendar.dart';
import 'kumo_dates_internal.dart';

/// How a [KumoDateInput] reads and writes dates.
enum KumoDateInputFormat {
  /// `2026-03-04`. Unambiguous in every locale; the default.
  iso('YYYY-MM-DD', '-'),

  /// `03/04/2026`, month first (United States).
  mdy('MM/DD/YYYY', '/'),

  /// `04/03/2026`, day first.
  dmy('DD/MM/YYYY', '/');

  const KumoDateInputFormat(this.pattern, this.separator);

  /// The pattern shown as the placeholder and in the error message.
  final String pattern;
  final String separator;

  /// [date] written in this format.
  String format(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = kumoTwoDigits(date.month);
    final d = kumoTwoDigits(date.day);
    return switch (this) {
      iso => '$y-$m-$d',
      mdy => '$m/$d/$y',
      dmy => '$d/$m/$y',
    };
  }

  /// The date in [text], or null when it is incomplete or not a real day
  /// (February 30 is rejected, not rolled over).
  DateTime? parse(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final (y, m, d) = switch (this) {
      iso => (digits.substring(0, 4), digits.substring(4, 6), digits.substring(6, 8)),
      mdy => (digits.substring(4, 8), digits.substring(0, 2), digits.substring(2, 4)),
      dmy => (digits.substring(4, 8), digits.substring(2, 4), digits.substring(0, 2)),
    };
    final year = int.parse(y);
    final month = int.parse(m);
    final day = int.parse(d);
    if (month < 1 || month > 12 || day < 1) return null;
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// Digit counts after which a separator goes.
  List<int> get _breaks => this == iso ? const [4, 6] : const [2, 4];
}

/// Typed date entry with validation and a calendar button.
///
/// The field accepts digits only and inserts the separators as you type
/// ([format], ISO by default). A complete, valid, allowed day is reported
/// through [onValueChange]; an impossible or unavailable one shows an
/// inline error, announced to screen readers. The calendar button opens a
/// [KumoCalendar] in a popover, or a bottom sheet below 768px; Alt+Down
/// opens it from the keyboard.
///
/// ```dart
/// KumoDateInput(
///   label: 'Token expires on',
///   value: expiry,
///   minDate: DateTime(2026, 1, 1),
///   onValueChange: (d) => setState(() => expiry = d),
/// )
/// ```
///
/// Controlled: the text follows [value] whenever the field is not being
/// edited. An [error] from the parent wins over the built-in messages.
class KumoDateInput extends StatefulWidget {
  const KumoDateInput({
    super.key,
    this.value,
    this.onValueChange,
    this.format = KumoDateInputFormat.iso,
    this.label,
    this.description,
    this.error,
    this.placeholder,
    this.size = KumoFieldSize.base,
    this.disabled = false,
    this.minDate,
    this.maxDate,
    this.isDateDisabled,
    this.showCalendarButton = true,
    this.presentation = KumoPresentation.auto,
    this.invalidDateMessage,
    this.unavailableDateMessage = 'This date is not available. Pick another day.',
    this.calendarButtonLabel,
    this.autofocus = false,
    this.showOptional = false,
    this.required = false,
    this.semanticLabel,
  });

  final DateTime? value;
  final ValueChanged<DateTime?>? onValueChange;
  final KumoDateInputFormat format;
  final String? label;
  final String? description;

  /// Error from the parent. Replaces the built-in validation messages.
  final String? error;

  /// Defaults to the format's pattern, such as `YYYY-MM-DD`.
  final String? placeholder;
  final KumoFieldSize size;
  final bool disabled;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool Function(DateTime day)? isDateDisabled;
  final bool showCalendarButton;

  /// Popover or bottom sheet for the calendar.
  final KumoPresentation presentation;

  /// Shown for text that is not a real date. Defaults to "Enter a date as
  /// YYYY-MM-DD." with the format's pattern.
  final String? invalidDateMessage;

  /// Shown for a real date outside [minDate]-[maxDate] or rejected by
  /// [isDateDisabled].
  final String unavailableDateMessage;

  /// Accessible name of the calendar button. Default
  /// [KumoStrings.chooseDateFromCalendar].
  final String? calendarButtonLabel;
  final bool autofocus;
  final bool showOptional;
  final bool required;
  final String? semanticLabel;

  @override
  State<KumoDateInput> createState() => _KumoDateInputState();
}

class _KumoDateInputState extends State<KumoDateInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'KumoDateInput');
  String? _error;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value == null ? '' : widget.format.format(widget.value!);
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(KumoDateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = !kumoSameDay(oldWidget.value, widget.value) || (oldWidget.value == null) != (widget.value == null);
    if ((changed || oldWidget.format != widget.format) && !_focus.hasFocus) _syncText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncText() {
    final v = widget.value;
    final text = v == null ? '' : widget.format.format(v);
    if (_controller.text != text) _controller.text = text;
    _error = null;
  }

  void _onFocus() {
    if (!_focus.hasFocus) _validate(committed: true);
    setState(() {});
  }

  bool _allowed(DateTime d) {
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && d.isBefore(kumoDay(min))) return false;
    if (max != null && d.isAfter(kumoDay(max))) return false;
    return !(widget.isDateDisabled?.call(d) ?? false);
  }

  /// Checks the text. While typing ([committed] false) an incomplete date is
  /// fine; on blur or submit it is an error.
  void _validate({required bool committed}) {
    final text = _controller.text;
    String? error;
    if (text.isEmpty) {
      if (widget.value != null) widget.onValueChange?.call(null);
    } else {
      final date = widget.format.parse(text);
      final complete = text.length == widget.format.pattern.length;
      if (date == null) {
        if (complete || committed) error = widget.invalidDateMessage ?? 'Enter a date as ${widget.format.pattern}.';
      } else if (!_allowed(date)) {
        error = widget.unavailableDateMessage;
      } else if (!kumoSameDay(date, widget.value)) {
        widget.onValueChange?.call(date);
      }
    }
    if (error != _error) setState(() => _error = error);
  }

  void _pickFromCalendar(DateTime? day) {
    setState(() => _open = false);
    if (day == null) return;
    _controller.text = widget.format.format(day);
    _error = null;
    widget.onValueChange?.call(day);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowDown &&
        HardwareKeyboard.instance.isAltPressed &&
        widget.showCalendarButton &&
        !widget.disabled) {
      setState(() => _open = true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final error = widget.error ?? _error;
    final iconSize = widget.size.textSize == KumoTextSize.xs ? 14.0 : 16.0;
    final button = widget.showCalendarButton
        ? KumoPressable(
            onPress: widget.disabled ? null : () => setState(() => _open = !_open),
            disabled: widget.disabled,
            semanticLabel: widget.calendarButtonLabel ?? context.kumoStrings.chooseDateFromCalendar,
            expanded: _open,
            excludeChildSemantics: true,
            minTapTargetSize: kumo.minTapTarget > 0 ? 36 : 0,
            borderRadius: BorderRadius.circular(KumoRadius.sm),
            builder: (context, state) => Container(
              padding: const EdgeInsets.all(KumoSpace.s1),
              decoration: BoxDecoration(
                color: state.active ? kumo.colors.tint : null,
                borderRadius: BorderRadius.circular(KumoRadius.sm),
              ),
              child: KumoIcon(KumoIcons.calendarBlank, size: iconSize, color: KumoColor.textSubtle),
            ),
          )
        : null;

    Widget field = KumoFieldBox(
      size: widget.size,
      focused: _focus.hasFocus || _open,
      error: error != null,
      disabled: widget.disabled,
      padding: EdgeInsetsDirectional.only(
        start: widget.size.paddingX,
        end: button == null ? widget.size.paddingX : KumoSpace.s1,
      ),
      trailing: button,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: KumoEditable(
          controller: _controller,
          focusNode: _focus,
          size: widget.size.textSize,
          placeholder: widget.placeholder ?? widget.format.pattern,
          enabled: !widget.disabled,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.datetime,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [_DateTextFormatter(widget.format)],
          semanticLabel: widget.label == null ? (widget.semanticLabel ?? widget.format.pattern) : null,
          onChanged: (_) => _validate(committed: false),
          onSubmitted: (_) => _validate(committed: true),
        ),
      ),
    );

    if (widget.showCalendarButton) {
      field = KumoDatesPanelHost(
        open: _open && !widget.disabled,
        onOpenChange: (v) => setState(() => _open = v),
        presentation: widget.presentation,
        sheetLabel: widget.label ?? widget.calendarButtonLabel ?? context.kumoStrings.chooseDateFromCalendar,
        popoverPadding: const EdgeInsets.all(KumoSpace.s3),
        panelBuilder: (context, inSheet) {
          final calendar = KumoCalendar.single(
            value: widget.value,
            minDate: widget.minDate,
            maxDate: widget.maxDate,
            isDateDisabled: widget.isDateDisabled,
            autofocus: true,
            onValueChange: _pickFromCalendar,
          );
          if (!inSheet) return calendar;
          return Padding(
            padding: const EdgeInsets.fromLTRB(KumoSpace.s4, KumoSpace.s2, KumoSpace.s4, KumoSpace.s4),
            child: Center(child: calendar),
          );
        },
        child: field,
      );
    }

    return FormsFieldFrame(
      label: widget.label,
      description: widget.description,
      error: error,
      showOptional: widget.showOptional,
      required: widget.required,
      controlLabeled: false,
      controlDescribed: false,
      child: field,
    );
  }
}

/// Keeps only digits and writes the format's separators between them.
class _DateTextFormatter extends TextInputFormatter {
  _DateTextFormatter(this.format);

  final KumoDateInputFormat format;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    // Deleting a separator deletes the digit before it, so Backspace never
    // gets stuck behind a separator that is put straight back.
    final deleting = newValue.text.length < oldValue.text.length;
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    if (deleting && digits == oldDigits && digits.isNotEmpty) digits = digits.substring(0, digits.length - 1);
    final buffer = StringBuffer();
    final breaks = format._breaks;
    for (var i = 0; i < digits.length; i++) {
      if (breaks.contains(i)) buffer.write(format.separator);
      buffer.write(digits[i]);
    }
    // A separator appears as soon as the part before it is complete.
    if (!deleting && breaks.contains(digits.length)) buffer.write(format.separator);
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
