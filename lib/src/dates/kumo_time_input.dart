import 'package:clock/clock.dart';
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
import 'kumo_dates_internal.dart';

/// A time of day without a date: what [KumoTimeInput] and [KumoTimePicker]
/// edit. [hour] is 0-23 whatever the display format.
///
/// ```dart
/// const backup = KumoTimeValue(hour: 2, minute: 30);
/// backup.format(); // "2:30 AM"
/// backup.format(use24Hour: true); // "02:30"
/// backup.on(DateTime(2026, 3, 4)); // 2026-03-04 02:30
/// ```
@immutable
class KumoTimeValue implements Comparable<KumoTimeValue> {
  const KumoTimeValue({required this.hour, this.minute = 0, this.second = 0})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60),
      assert(second >= 0 && second < 60);

  /// The time part of [dateTime].
  KumoTimeValue.fromDateTime(DateTime dateTime)
    : hour = dateTime.hour,
      minute = dateTime.minute,
      second = dateTime.second;

  /// The current time from `clock.now()`, so tests can fix it with `withClock`.
  factory KumoTimeValue.now() => KumoTimeValue.fromDateTime(clock.now());

  final int hour;
  final int minute;
  final int second;

  /// 1-12, for 12-hour display.
  int get hour12 => hour % 12 == 0 ? 12 : hour % 12;

  /// Noon and later.
  bool get isPm => hour >= 12;

  /// Seconds since midnight.
  int get inSeconds => hour * 3600 + minute * 60 + second;

  /// This time on the local [day].
  DateTime on(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute, second);

  KumoTimeValue copyWith({int? hour, int? minute, int? second}) =>
      KumoTimeValue(hour: hour ?? this.hour, minute: minute ?? this.minute, second: second ?? this.second);

  /// "9:05 AM", or "09:05" with [use24Hour]; seconds are added with
  /// [showSeconds]. [am] and [pm] come from [KumoTimeLabels].
  String format({bool use24Hour = false, bool showSeconds = false, String am = 'AM', String pm = 'PM'}) {
    final seconds = showSeconds ? ':${kumoTwoDigits(second)}' : '';
    if (use24Hour) return '${kumoTwoDigits(hour)}:${kumoTwoDigits(minute)}$seconds';
    return '$hour12:${kumoTwoDigits(minute)}$seconds ${isPm ? pm : am}';
  }

  @override
  int compareTo(KumoTimeValue other) => inSeconds.compareTo(other.inSeconds);

  @override
  bool operator ==(Object other) =>
      other is KumoTimeValue && other.hour == hour && other.minute == minute && other.second == second;

  @override
  int get hashCode => Object.hash(hour, minute, second);

  @override
  String toString() => 'KumoTimeValue(${format(use24Hour: true, showSeconds: true)})';
}

/// Copy used by [KumoTimeInput] and [KumoTimePicker]. Kumo has no time
/// component, so these are not in [KumoStrings]; pass translations here.
///
/// ```dart
/// const KumoTimeLabels(hour: 'Jam', minute: 'Menit', done: 'Selesai')
/// ```
@immutable
class KumoTimeLabels {
  const KumoTimeLabels({
    this.hour,
    this.minute,
    this.second,
    this.period,
    this.am = 'AM',
    this.pm = 'PM',
    this.done,
  });

  /// Accessible names of the hour, minute and second parts. Default
  /// [KumoStrings.hours], [KumoStrings.minutes] and [KumoStrings.seconds].
  final String? hour;
  final String? minute;
  final String? second;

  /// Accessible name of the AM/PM toggle. Default [KumoStrings.dayPeriod].
  final String? period;
  final String am;
  final String pm;

  /// Closes the time sheet on narrow screens. Default [KumoStrings.done].
  final String? done;

  /// Every label, with unset ones taken from [strings].
  ({String hour, String minute, String second, String period, String am, String pm, String done}) resolve(
    KumoStrings strings,
  ) => (
    hour: hour ?? strings.hours,
    minute: minute ?? strings.minutes,
    second: second ?? strings.seconds,
    period: period ?? strings.dayPeriod,
    am: am,
    pm: pm,
    done: done ?? strings.done,
  );
}

/// A typed time field, shadcn style: hours and minutes (and optionally
/// seconds) as separate parts in one Kumo field, with an AM/PM toggle in
/// 12-hour mode.
///
/// ```dart
/// KumoTimeInput(
///   label: 'Backup window starts',
///   value: start,
///   onValueChange: (t) => setState(() => start = t),
/// )
/// ```
///
/// * Typing fills a part and moves to the next once it is complete (a "7"
///   in the hour part is already 07). `:` also moves on.
/// * Arrow Up and Down step the focused part, wrapping around; minutes step
///   by [minuteStep]. Left and Right at the edge of a part move between
///   parts; Backspace in an empty part goes back.
/// * Controlled: `onValueChange` fires with a complete time, or null when
///   every part is cleared. The field shows [value] whenever it is not
///   being edited.
///
/// For a field that opens a picker, use [KumoTimePicker].
class KumoTimeInput extends StatefulWidget {
  const KumoTimeInput({
    super.key,
    this.value,
    this.onValueChange,
    this.use24Hour = false,
    this.showSeconds = false,
    this.minuteStep = 1,
    this.label,
    this.description,
    this.error,
    this.size = KumoFieldSize.base,
    this.disabled = false,
    this.labels = const KumoTimeLabels(),
    this.trailing,
    this.autofocus = false,
    this.showOptional = false,
    this.required = false,
    this.semanticLabel,
  }) : assert(minuteStep > 0 && minuteStep <= 30);

  final KumoTimeValue? value;
  final ValueChanged<KumoTimeValue?>? onValueChange;

  /// 00-23 hours instead of 1-12 with AM/PM.
  final bool use24Hour;
  final bool showSeconds;

  /// Minutes the arrow keys step by (5 for a five-minute grid).
  final int minuteStep;
  final String? label;
  final String? description;
  final String? error;
  final KumoFieldSize size;
  final bool disabled;
  final KumoTimeLabels labels;

  /// Content at the end of the field, such as a button that opens a picker.
  final Widget? trailing;
  final bool autofocus;
  final bool showOptional;
  final bool required;

  /// Accessible name of the field when there is no [label].
  final String? semanticLabel;

  @override
  State<KumoTimeInput> createState() => _KumoTimeInputState();
}

class _Part {
  _Part({required this.min, required this.max, required this.step, required this.label});

  final TextEditingController controller = TextEditingController();
  final FocusNode node = FocusNode();
  final int min;
  final int max;
  final int step;
  final String label;

  int? get number => int.tryParse(controller.text);

  /// The largest first digit that can still start a two-digit value; a
  /// higher one completes the part on its own.
  int get maxFirstDigit => max ~/ 10;

  void dispose() {
    controller.dispose();
    node.dispose();
  }
}

class _KumoTimeInputState extends State<KumoTimeInput> {
  late List<_Part> _parts;
  final FocusNode _periodNode = FocusNode(debugLabel: 'KumoTimeInput period');
  bool _pm = false;

  bool get _focused => _parts.any((p) => p.node.hasFocus) || _periodNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _parts = _makeParts();
    _periodNode.addListener(_onFocusChange);
    _syncFromValue();
  }

  List<_Part> _makeParts() {
    final labels = widget.labels.resolve(context.kumoStrings);
    final parts = [
      widget.use24Hour
          ? _Part(min: 0, max: 23, step: 1, label: labels.hour)
          : _Part(min: 1, max: 12, step: 1, label: labels.hour),
      _Part(min: 0, max: 59, step: widget.minuteStep, label: labels.minute),
      if (widget.showSeconds) _Part(min: 0, max: 59, step: 1, label: labels.second),
    ];
    for (final p in parts) {
      p.node.addListener(() {
        if (p.node.hasFocus) {
          p.controller.selection = TextSelection(baseOffset: 0, extentOffset: p.controller.text.length);
        } else {
          _normalize(p);
        }
        _onFocusChange();
      });
    }
    return parts;
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {});
    if (!_focused) _syncFromValue();
  }

  @override
  void didUpdateWidget(KumoTimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.use24Hour != widget.use24Hour ||
        oldWidget.showSeconds != widget.showSeconds ||
        oldWidget.minuteStep != widget.minuteStep) {
      final old = _parts;
      _parts = _makeParts();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final p in old) {
          p.dispose();
        }
      });
      _syncFromValue();
    } else if (oldWidget.value != widget.value && !_focused) {
      _syncFromValue();
    }
  }

  @override
  void dispose() {
    for (final p in _parts) {
      p.dispose();
    }
    _periodNode.dispose();
    super.dispose();
  }

  void _syncFromValue() {
    final v = widget.value;
    if (v == null) {
      for (final p in _parts) {
        p.controller.text = '';
      }
      return;
    }
    _parts[0].controller.text = kumoTwoDigits(widget.use24Hour ? v.hour : v.hour12);
    _parts[1].controller.text = kumoTwoDigits(v.minute);
    if (widget.showSeconds) _parts[2].controller.text = kumoTwoDigits(v.second);
    _pm = v.isPm;
  }

  void _normalize(_Part p) {
    final n = p.number;
    if (n == null) {
      p.controller.text = '';
      return;
    }
    // "0" in a 12-hour part means 12, as on a clock face.
    final fixed = !widget.use24Hour && identical(p, _parts[0]) && n == 0 ? 12 : n.clamp(p.min, p.max);
    p.controller.text = kumoTwoDigits(fixed);
  }

  void _emit() {
    if (_parts.every((p) => p.controller.text.isEmpty)) {
      if (widget.value != null) widget.onValueChange?.call(null);
      return;
    }
    final numbers = [for (final p in _parts) p.number];
    if (numbers.any((n) => n == null)) return;
    for (var i = 0; i < _parts.length; i++) {
      if (numbers[i]! < _parts[i].min || numbers[i]! > _parts[i].max) {
        if (!(i == 0 && !widget.use24Hour && numbers[i] == 0)) return;
      }
    }
    var hour = numbers[0]!;
    if (!widget.use24Hour) hour = (hour % 12) + (_pm ? 12 : 0);
    final next = KumoTimeValue(hour: hour, minute: numbers[1]!, second: widget.showSeconds ? numbers[2]! : 0);
    if (next != widget.value) widget.onValueChange?.call(next);
  }

  void _focusPart(int index) {
    if (index < 0) return;
    if (index < _parts.length) {
      _parts[index].node.requestFocus();
    } else if (!widget.use24Hour) {
      _periodNode.requestFocus();
    }
  }

  void _onChanged(int index, String text) {
    final p = _parts[index];
    _emit();
    final n = int.tryParse(text);
    if (n == null) return;
    final complete = text.length >= 2 || n > p.maxFirstDigit;
    if (complete) {
      if (text.length < 2) {
        p.controller.text = kumoTwoDigits(n);
        _emit();
      }
      _focusPart(index + 1);
    }
  }

  void _step(_Part p, int direction) {
    final span = p.max - p.min + 1;
    final current = p.number;
    int next;
    if (current == null) {
      next = direction > 0 ? p.min : p.max - (p.max - p.min) % p.step;
    } else {
      // Snap to the step grid first, so 07 with a 5-minute step goes to 10.
      final base = current - p.min;
      final snapped = direction > 0 ? (base ~/ p.step + 1) * p.step : ((base + p.step - 1) ~/ p.step - 1) * p.step;
      next = p.min + (snapped % span + span) % span;
    }
    p.controller.text = kumoTwoDigits(next);
    p.controller.selection = TextSelection(baseOffset: 0, extentOffset: p.controller.text.length);
    _emit();
  }

  KeyEventResult _onPartKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final p = _parts[index];
    final key = event.logicalKey;
    final sel = p.controller.selection;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (key == LogicalKeyboardKey.arrowUp) {
      _step(p, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _step(p, -1);
      return KeyEventResult.handled;
    }
    final back = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    final forward = rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
    if (key == back && sel.start <= 0 && index > 0) {
      _focusPart(index - 1);
      return KeyEventResult.handled;
    }
    if (key == forward && sel.end >= p.controller.text.length) {
      if (index + 1 < _parts.length || !widget.use24Hour) {
        _focusPart(index + 1);
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.backspace && p.controller.text.isEmpty && index > 0) {
      _focusPart(index - 1);
      return KeyEventResult.handled;
    }
    if (event.character == ':' || event.character == '.') {
      _focusPart(index + 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _togglePeriod([bool? pm]) {
    setState(() => _pm = pm ?? !_pm);
    _emit();
  }

  KeyEventResult _onPeriodKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final char = event.character?.toLowerCase();
    final labels = widget.labels.resolve(context.kumoStrings);
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      _togglePeriod();
      return KeyEventResult.handled;
    }
    if (char != null && char.isNotEmpty) {
      if (labels.am.toLowerCase().startsWith(char)) {
        _togglePeriod(false);
        return KeyEventResult.handled;
      }
      if (labels.pm.toLowerCase().startsWith(char)) {
        _togglePeriod(true);
        return KeyEventResult.handled;
      }
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    if (key == back || key == LogicalKeyboardKey.backspace) {
      _focusPart(_parts.length - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final textSize = widget.size.textSize;
    final style = kumo.text(size: textSize).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final painter = TextPainter(
      text: TextSpan(text: '00', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    // EditableText keeps room for the caret after the text, which pulls
    // centered digits left; the start inset balances it.
    const caretRoom = 1.5;
    final partWidth = painter.width + caretRoom * 2 + 2;
    painter.dispose();
    final iconSize = textSize == KumoTextSize.xs ? 14.0 : 16.0;

    Widget separator() => ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.px),
        child: Text(':', style: style.copyWith(color: kumo.colors.textSubtle)),
      ),
    );

    final children = <Widget>[];
    for (var i = 0; i < _parts.length; i++) {
      if (i > 0) children.add(separator());
      final p = _parts[i];
      children.add(
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, e) => _onPartKey(i, e),
          child: SizedBox(
            width: partWidth,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: caretRoom * 2),
              child: KumoEditable(
                controller: p.controller,
                focusNode: p.node,
                size: textSize,
                placeholder: '--',
                enabled: !widget.disabled,
                autofocus: widget.autofocus && i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: i == _parts.length - 1 && widget.use24Hour
                    ? TextInputAction.done
                    : TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                semanticLabel: p.label,
                onChanged: (t) => _onChanged(i, t),
                onSubmitted: (_) => _focusPart(i + 1),
              ),
            ),
          ),
        ),
      );
    }
    if (!widget.use24Hour) {
      final labels = widget.labels.resolve(context.kumoStrings);
      children.add(const SizedBox(width: KumoSpace.s1));
      children.add(
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onPeriodKey,
          child: KumoPressable(
            focusNode: _periodNode,
            onPress: widget.disabled ? null : _togglePeriod,
            disabled: widget.disabled,
            minTapTargetSize: kumo.minTapTarget > 0 ? 36 : 0,
            showFocusRing: false,
            semanticLabel: labels.period,
            semanticValue: _pm ? labels.pm : labels.am,
            excludeChildSemantics: true,
            borderRadius: BorderRadius.circular(KumoRadius.sm),
            builder: (context, state) => Container(
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s1, vertical: KumoSpace.s0_5),
              decoration: BoxDecoration(
                color: state.focused || _periodNode.hasFocus
                    ? kumo.colors.brand.withValues(alpha: 0.24)
                    : (state.active ? kumo.colors.tint : null),
                borderRadius: BorderRadius.circular(KumoRadius.sm),
              ),
              child: Text(
                _pm ? labels.pm : labels.am,
                style: style.copyWith(
                  color: widget.value == null && _parts.every((p) => p.controller.text.isEmpty)
                      ? kumo.colors.textPlaceholder
                      : kumo.colors.textDefault,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Widget field = Semantics(
      container: true,
      label: widget.label == null ? widget.semanticLabel : null,
      child: KumoFieldBox(
        size: widget.size,
        focused: _focused,
        error: widget.error != null,
        disabled: widget.disabled,
        leading: KumoIcon(KumoIcons.clock, size: iconSize, color: KumoColor.textSubtle),
        trailing: widget.trailing,
        child: Row(children: [...children, const Spacer()]),
      ),
    );
    return FormsFieldFrame(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      showOptional: widget.showOptional,
      required: widget.required,
      controlLabeled: false,
      controlDescribed: false,
      child: field,
    );
  }
}
