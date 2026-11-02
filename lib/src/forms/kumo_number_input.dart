import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icons.g.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import 'src/forms_internal.dart';

/// A numeric field with stepper buttons, in Kumo's input style. Kumo has no
/// number input of its own; this follows shadcn's feature set with Kumo's
/// field chrome and compact ghost buttons.
///
/// * Type a number, or step it with the minus and plus buttons, ArrowUp and
///   ArrowDown, or PageUp and PageDown (and Shift+Arrow) for [largeStep].
/// * Holding a stepper steps once, then repeats after [repeatDelay] every
///   [repeatInterval] until the finger lifts or a bound is reached.
/// * While typing, only numbers inside [min] and [max] are reported. Text
///   that is not a number, or is out of range, shows the error ring; on blur
///   or submit it is clamped, or reverted to the last valid value.
/// * Clearing the field reports null.
///
/// ```dart
/// KumoNumberInput(
///   label: 'Max retries',
///   value: retries,
///   min: 0,
///   max: 10,
///   onValueChange: (v) => setState(() => retries = v),
/// )
/// KumoNumberInput(
///   label: 'Sample rate',
///   value: rate,
///   min: 0,
///   max: 1,
///   step: 0.05,
///   fractionDigits: 2,
///   onValueChange: (v) => setState(() => rate = v),
/// )
/// ```
class KumoNumberInput extends StatefulWidget {
  const KumoNumberInput({
    super.key,
    this.value,
    this.onValueChange,
    this.min,
    this.max,
    this.step = 1,
    this.largeStep,
    this.fractionDigits,
    this.format,
    this.parse,
    this.size = KumoFieldSize.base,
    this.label,
    this.labelTooltip,
    this.description,
    this.error,
    this.required = false,
    this.showOptional = false,
    this.placeholder,
    this.semanticLabel,
    this.disabled = false,
    this.readOnly = false,
    this.showSteppers = true,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.inputFormatters,
    this.onSubmitted,
    this.repeatDelay = const Duration(milliseconds: 400),
    this.repeatInterval = const Duration(milliseconds: 60),
    this.scrollPadding = formsScrollPadding,
  }) : assert(step > 0),
       assert(min == null || max == null || min <= max);

  /// The number, or null when the field is empty.
  final double? value;

  /// Called with the next number, or null when the field is cleared.
  final ValueChanged<double?>? onValueChange;
  final double? min;
  final double? max;

  /// Amount added or removed by a stepper press or an arrow key.
  final double step;

  /// Amount for PageUp, PageDown and Shift+Arrow. Defaults to ten steps.
  final double? largeStep;

  /// Fixed decimals for display, and rounding of committed values. Null
  /// shows integers without decimals and other numbers as they are.
  final int? fractionDigits;

  /// Custom display text, such as thousands separators. Pair with [parse].
  final String Function(double value)? format;

  /// Reads typed text back into a number; return null for invalid text.
  final double? Function(String text)? parse;
  final KumoFieldSize size;
  final String? label;
  final String? labelTooltip;
  final String? description;

  /// Error message below the field. Also marks it invalid.
  final String? error;
  final bool required;
  final bool showOptional;
  final String? placeholder;

  /// Accessible name when there is no [label].
  final String? semanticLabel;
  final bool disabled;
  final bool readOnly;

  /// Shows the minus and plus buttons at the end of the field.
  final bool showSteppers;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;

  /// Replaces the default filter (digits, one decimal point, a leading minus
  /// when negatives are allowed). Needed with a custom [format].
  final List<TextInputFormatter>? inputFormatters;

  /// Called with the committed number when the keyboard's action key is pressed.
  final ValueChanged<double?>? onSubmitted;

  /// Hold time before a held stepper starts repeating.
  final Duration repeatDelay;

  /// Time between repeated steps while a stepper is held.
  final Duration repeatInterval;
  final EdgeInsets scrollPadding;

  @override
  State<KumoNumberInput> createState() => _KumoNumberInputState();
}

class _KumoNumberInputState extends FormsTextState<KumoNumberInput> with SingleTickerProviderStateMixin {
  /// 0 to 1 after a step: the new number rises (or drops) the last few
  /// pixels into place, so a stepper press visibly lands.
  late final AnimationController _nudge;
  double _nudgeDirection = 1;
  Timer? _repeat;
  bool _holdStepped = false;
  bool _invalid = false;

  @override
  String? get controlledValue => null;
  @override
  TextEditingController? get externalController => null;
  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    _nudge = AnimationController(vsync: this, duration: KumoDurations.quick, value: 1);
    controller.text = _format(widget.value);
  }

  @override
  void didUpdateWidget(KumoNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncWidget(null, oldWidget.focusNode);
    // Text that already reads as the new value stays as typed ("1." for 1),
    // so the caret and partial input survive the round trip.
    if (_parse(controller.text) != widget.value) {
      writeValue(_format(widget.value));
      _invalid = false;
    }
    if (widget.disabled || widget.readOnly) _stopRepeat();
  }

  @override
  void dispose() {
    _stopRepeat();
    _nudge.dispose();
    super.dispose();
  }

  @override
  void onFocusChanged(bool hasFocus) {
    if (!hasFocus) _commit();
  }

  bool get _allowNegative => widget.min == null || widget.min! < 0;
  bool get _allowDecimal => widget.fractionDigits != 0;
  bool get _editable => !widget.disabled && !widget.readOnly;

  String _format(double? v) {
    if (v == null) return '';
    if (widget.format != null) return widget.format!(v);
    if (widget.fractionDigits != null) return v.toStringAsFixed(widget.fractionDigits!);
    if (v == v.truncateToDouble() && v.abs() < 1e15) return v.toInt().toString();
    return v.toString();
  }

  double? _parse(String text) {
    if (widget.parse != null) return widget.parse!(text);
    final t = text.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null || v.isNaN || v.isInfinite ? null : v;
  }

  bool _inRange(double v) => (widget.min == null || v >= widget.min!) && (widget.max == null || v <= widget.max!);

  double _clamp(double v) {
    var r = v;
    if (widget.min != null) r = math.max(r, widget.min!);
    if (widget.max != null) r = math.min(r, widget.max!);
    return r;
  }

  static int _decimalsOf(double v) {
    final s = v.toString();
    if (s.contains('e')) return 10;
    final dot = s.indexOf('.');
    if (dot < 0) return 0;
    final frac = s.substring(dot + 1);
    return frac == '0' ? 0 : frac.length;
  }

  // Float steps drift (0.1 + 0.2); round to the precision in play.
  double _round(double v) {
    final digits = widget.fractionDigits ?? math.max(_decimalsOf(widget.step), _decimalsOf(widget.min ?? 0));
    return double.parse(v.toStringAsFixed(digits.clamp(0, 15)));
  }

  void _emit(double? v) {
    if (v != widget.value) widget.onValueChange?.call(v);
  }

  bool _isPartial(String t) => t == '-' || t == '.' || t == '-.';

  void _handleChanged(String text) {
    final t = text.trim();
    if (t.isEmpty) {
      setState(() => _invalid = false);
      _emit(null);
      return;
    }
    final v = _parse(t);
    final invalid = v == null ? !_isPartial(t) : !_inRange(v);
    if (invalid != _invalid) setState(() => _invalid = invalid);
    if (v != null && _inRange(v)) _emit(v);
  }

  double? _commit() {
    final t = controller.text.trim();
    double? result;
    if (t.isEmpty) {
      result = null;
    } else {
      final v = _parse(t);
      result = v == null ? widget.value : _round(_clamp(v));
    }
    _emit(result);
    final text = _format(result);
    if (text != controller.text) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    if (_invalid && mounted) setState(() => _invalid = false);
    return result;
  }

  /// Steps by [delta]. Returns false when nothing changed (a bound was hit).
  bool _step(double delta, {bool nudge = true}) {
    if (!_editable) return false;
    final current = _parse(controller.text) ?? widget.value;
    final double next;
    if (current == null) {
      next = _clamp(delta > 0 ? (widget.min ?? 0) : (widget.max ?? 0));
    } else {
      next = _round(_clamp(current + delta));
    }
    if (current != null && next == current) return false;
    final text = _format(next);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (_invalid) setState(() => _invalid = false);
    _emit(next);
    if (nudge && !KumoMotion.reduceMotion(context)) {
      _nudgeDirection = delta > 0 ? 1 : -1;
      _nudge.forward(from: 0);
    }
    return true;
  }

  void _startRepeat(double delta) {
    _stopRepeat();
    _holdStepped = true;
    if (!_step(delta)) return;
    _repeat = Timer(widget.repeatDelay, () {
      _repeat = Timer.periodic(widget.repeatInterval, (_) {
        // Repeats come faster than the nudge; the number just counts.
        if (!mounted || !_step(delta, nudge: false)) _stopRepeat();
      });
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  void _releaseHold() {
    _stopRepeat();
    // A tap reports release, then press, in the same event. Clear the flag
    // after that, so a later keyboard or screen reader press still steps.
    scheduleMicrotask(() => _holdStepped = false);
  }

  void _pressStepper(double delta) {
    if (_holdStepped) {
      _holdStepped = false;
      return;
    }
    _step(delta);
  }

  // Rejects an edit that would not read as a (partial) number, instead of
  // dropping characters from it.
  TextInputFormatter _numberFilter() {
    final pattern = RegExp('^${_allowNegative ? '-?' : ''}[0-9]*${_allowDecimal ? r'(\.[0-9]*)?' : ''}\$');
    return TextInputFormatter.withFunction(
      (oldValue, newValue) => pattern.hasMatch(newValue.text) ? newValue : oldValue,
    );
  }

  double get _large => widget.largeStep ?? widget.step * 10;

  bool get _canDecrement {
    final v = _parse(controller.text) ?? widget.value;
    return _editable && (v == null || widget.min == null || v > widget.min!);
  }

  bool get _canIncrement {
    final v = _parse(controller.text) ?? widget.value;
    return _editable && (v == null || widget.max == null || v < widget.max!);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final size = widget.size;
    final current = _parse(controller.text) ?? widget.value ?? 0;
    final adjustable = _editable && controller.text.isNotEmpty;

    Widget editable = KumoEditable(
      controller: controller,
      focusNode: focusNode,
      placeholder: widget.placeholder,
      size: size.textSize,
      enabled: !widget.disabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.numberWithOptions(signed: _allowNegative, decimal: _allowDecimal),
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      inputFormatters: widget.inputFormatters ?? (widget.parse != null ? null : [_numberFilter()]),
      onChanged: _handleChanged,
      onSubmitted: (_) => widget.onSubmitted?.call(_commit()),
      scrollPadding: widget.scrollPadding,
    );

    editable = AnimatedBuilder(
      animation: _nudge,
      builder: (context, child) {
        // Same widgets at rest and in motion, so the field is never rebuilt.
        final t = KumoCurves.enter.transform(_nudge.value);
        return Transform.translate(
          offset: Offset(0, _nudgeDirection * 4 * (1 - t)),
          child: Opacity(opacity: 0.4 + 0.6 * t, child: child),
        );
      },
      child: editable,
    );

    editable = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(widget.step),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(-widget.step),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () => _step(_large),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () => _step(-_large),
        const SingleActivator(LogicalKeyboardKey.pageUp): () => _step(_large),
        const SingleActivator(LogicalKeyboardKey.pageDown): () => _step(-_large),
      },
      // Adjust actions need a current value to announce against, so an empty
      // field offers only the stepper buttons.
      child: Semantics(
        increasedValue: adjustable && _canIncrement ? _format(_round(_clamp(current + widget.step))) : null,
        decreasedValue: adjustable && _canDecrement ? _format(_round(_clamp(current - widget.step))) : null,
        onIncrease: adjustable && _canIncrement ? () => _step(widget.step) : null,
        onDecrease: adjustable && _canDecrement ? () => _step(-widget.step) : null,
        child: editable,
      ),
    );

    final steppers = widget.showSteppers
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormsCompactButton(
                icon: KumoIcons.minus,
                semanticLabel: strings.decrement,
                fieldSize: size,
                disabled: !_canDecrement,
                canRequestFocus: false,
                onPressIn: () => _startRepeat(-widget.step),
                onPressOut: _releaseHold,
                onPress: () => _pressStepper(-widget.step),
              ),
              FormsCompactButton(
                icon: KumoIcons.plus,
                semanticLabel: strings.increment,
                fieldSize: size,
                disabled: !_canIncrement,
                canRequestFocus: false,
                onPressIn: () => _startRepeat(widget.step),
                onPressOut: _releaseHold,
                onPress: () => _pressStepper(widget.step),
              ),
            ],
          )
        : null;

    // No tap-to-focus wrapper here: a second tap recognizer above the
    // steppers would hold their press back until the gesture arena settles.
    final box = KumoFieldBox(
      size: size,
      focused: focused && !widget.readOnly,
      error: widget.error != null || _invalid,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      // Steppers sit flush with the end edge, like an input group addon.
      padding: EdgeInsetsDirectional.only(start: size.paddingX, end: steppers == null ? size.paddingX : 2),
      trailing: steppers,
      child: FormsFieldSemantics(
        label: widget.label ?? widget.semanticLabel,
        description: widget.description,
        error: widget.error,
        tooltip: widget.labelTooltip,
        required: widget.required,
        child: editable,
      ),
    );

    return FormsFieldFrame(
      label: widget.label,
      labelTooltip: widget.labelTooltip,
      description: widget.description,
      error: widget.error,
      required: widget.required,
      showOptional: widget.showOptional,
      onLabelTap: widget.disabled ? null : focusNode.requestFocus,
      child: box,
    );
  }
}
