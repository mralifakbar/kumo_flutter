import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../forms/src/forms_internal.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_tokens.dart';
import 'picker_internals.dart';

/// Checks one tag before it is added. Return null to accept it, or the
/// message to show (an empty string shows [KumoTagInputLabels.invalidValue]).
/// [accepted] holds the tags already in the field, including ones accepted
/// earlier in the same paste.
typedef KumoTagValidator = String? Function(String value, List<String> accepted);

/// Built-in copy of a [KumoTagInput], for localization (Kumo's
/// `TagInputLabels`). Unset entries use English defaults.
///
/// ```dart
/// KumoTagInputLabels(
///   input: 'Agregar etiqueta',
///   removeValue: (v) => 'Eliminar $v',
///   invalidValue: (v) => '$v no es valido.',
///   maxValuesReached: (n) => 'Maximo de $n etiquetas.',
/// )
/// ```
@immutable
class KumoTagInputLabels {
  const KumoTagInputLabels({this.input, this.removeValue, this.invalidValue, this.maxValuesReached});

  /// Accessible name of the input when there is no label. Default
  /// [KumoStrings.addTag].
  final String? input;

  /// Accessible name of a tag's remove button. Default "Remove" plus the tag.
  final String Function(String value)? removeValue;

  /// Message when a validator rejects a tag without its own message.
  /// Default [KumoStrings.invalidValue].
  final String Function(String value)? invalidValue;

  /// Message when [KumoTagInput.maxValues] is reached. Default
  /// [KumoStrings.maxValuesReached].
  final String Function(int maxValues)? maxValuesReached;
}

/// Kumo's `TagInput`: a field that collects short values as removable tags.
///
/// * Enter or a comma adds what was typed. Pasting text with commas or line
///   breaks adds each part. Leaving the field adds what is left.
/// * Each tag passes through [validateValue]; a rejected tag stays in the
///   input with the message under the field, announced to screen readers.
/// * [maxValues] caps the count; duplicates are skipped unless
///   [allowDuplicates] is set.
/// * Tags are removed with their X button, or with Backspace in the empty
///   input on a hardware keyboard.
///
/// ```dart
/// KumoTagInput(
///   label: 'Allowed origins',
///   placeholder: 'https://example.com',
///   value: origins,
///   onValueChange: (v) => setState(() => origins = v),
///   validateValue: (v, _) => v.startsWith('https://') ? null : 'Origins must start with https://',
/// )
/// ```
class KumoTagInput extends StatefulWidget {
  const KumoTagInput({
    super.key,
    required this.value,
    this.onValueChange,
    this.validateValue,
    this.maxValues,
    this.allowDuplicates = false,
    this.labels = const KumoTagInputLabels(),
    this.label,
    this.labelTooltip,
    this.description,
    this.error,
    this.showOptional = false,
    this.required = false,
    this.placeholder,
    this.disabled = false,
    this.readOnly = false,
    this.mono = false,
    this.keyboardType,
    this.focusNode,
    this.autofocus = false,
  });

  /// The tags, in order.
  final List<String> value;

  /// Called with the next list when tags are added or removed.
  final ValueChanged<List<String>>? onValueChange;
  final KumoTagValidator? validateValue;

  /// Largest number of tags.
  final int? maxValues;

  /// Accept a tag that is already in the list. Off by default: duplicates
  /// are dropped silently, as in Kumo.
  final bool allowDuplicates;
  final KumoTagInputLabels labels;
  final String? label;
  final String? labelTooltip;
  final String? description;

  /// Error from the caller (form validation). Takes the place of the
  /// field's own validation message.
  final String? error;
  final bool showOptional;
  final bool required;
  final String? placeholder;
  final bool disabled;

  /// Shows the tags but blocks adding and removing; the input stays
  /// focusable so the tags can be read and copied.
  final bool readOnly;

  /// Monospace input and tags, for hostnames and IDs.
  final bool mono;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KumoTagInput> createState() => _KumoTagInputState();
}

final RegExp _separators = RegExp(r'[\n,]+');

int _countSeparators(String s) => ','.allMatches(s).length;

class _KumoTagInputState extends State<KumoTagInput> with TickerProviderStateMixin {
  final TextEditingController _text = TextEditingController();
  late final PickerChipMotion _chipMotion;
  FocusNode? _ownFocus;
  String? _message;
  String _lastText = '';

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'KumoTagInput'));

  @override
  void initState() {
    super.initState();
    _chipMotion = PickerChipMotion(vsync: this, onChanged: () {
      if (mounted) setState(() {});
    });
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(KumoTagInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _chipMotion.dispose();
    _focus.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    if (!_focus.hasFocus && !widget.readOnly && !widget.disabled && _text.text.trim().isNotEmpty) _commit(_text.text);
    setState(() {});
  }

  void _setText(String text) {
    _lastText = text;
    _text.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  void _emit(List<String> next) {
    if (next.length != widget.value.length) widget.onValueChange?.call(next);
  }

  /// Adds every tag in [raw]; stops at the first rejected one and leaves it
  /// and the rest in the input. Returns whether everything was added.
  bool _commit(String raw) {
    final entries = raw.split(_separators).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final next = List<String>.of(widget.value);
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (!widget.allowDuplicates && next.contains(entry)) continue;
      String? problem;
      final max = widget.maxValues;
      if (max != null && next.length >= max) {
        problem = widget.labels.maxValuesReached?.call(max) ?? context.kumoStrings.maxValuesReached(max);
      } else {
        final verdict = widget.validateValue?.call(entry, List.unmodifiable(next));
        if (verdict != null) {
          problem = verdict.isNotEmpty ? verdict : (widget.labels.invalidValue?.call(entry) ?? context.kumoStrings.invalidValue(entry));
        }
      }
      if (problem != null) {
        _setText(entries.sublist(i).join(', '));
        setState(() => _message = problem);
        _emit(next);
        return false;
      }
      next.add(entry);
    }
    _emit(next);
    _setText('');
    setState(() => _message = null);
    return true;
  }

  void _onChanged(String text) {
    // Commit when the edit added a separator (a typed comma, a paste with
    // commas or line breaks), not when editing text that already had one.
    final added = _countSeparators(text) > _countSeparators(_lastText);
    _lastText = text;
    if (_message != null) setState(() => _message = null);
    if (added && !widget.readOnly) _commit(text);
  }

  void _removeAt(int index) {
    if (widget.readOnly || widget.disabled) return;
    widget.onValueChange?.call(List<String>.of(widget.value)..removeAt(index));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (widget.readOnly || widget.disabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final empty = _text.text.isEmpty;
    if (key == LogicalKeyboardKey.backspace && empty && widget.value.isNotEmpty) {
      _removeAt(widget.value.length - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_text.text.trim().isNotEmpty) _commit(_text.text);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab && _text.text.trim().isNotEmpty) {
      // A rejected tag keeps focus so it can be fixed; an accepted one lets
      // Tab move on.
      return _commit(_text.text) ? KeyEventResult.ignored : KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final error = widget.error ?? _message;
    final locked = widget.disabled || widget.readOnly;

    // Keyed by the tag (and which repeat of it), not its index, so removing
    // one tag animates that tag out instead of re-labelling the rest.
    final seen = <String, int>{};
    final chips = [
      for (var i = 0; i < widget.value.length; i++)
        PickerChip(
          key: ValueKey<(String, int)>((widget.value[i], seen.update(widget.value[i], (n) => n + 1, ifAbsent: () => 0))),
          label: widget.value[i],
          removeSize: 20,
          disabled: locked,
          removeLabel: widget.labels.removeValue?.call(widget.value[i]) ?? strings.removeItem(widget.value[i]),
          onRemove: () => _removeAt(i),
        ),
    ];

    final input = Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s1, vertical: KumoSpace.s0_5),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: KumoEditable(
          controller: _text,
          focusNode: _focus,
          autofocus: widget.autofocus,
          enabled: !widget.disabled,
          readOnly: widget.readOnly,
          mono: widget.mono,
          placeholder: widget.placeholder,
          semanticLabel: widget.labels.input ?? widget.label ?? context.kumoStrings.addTag,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: widget.keyboardType ?? TextInputType.text,
          textInputAction: TextInputAction.done,
          // A multi-line editor keeps pasted line breaks (single-line fields
          // strip them) so they can split tags; they become commas here.
          maxLines: null,
          inputFormatters: [
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(text: newValue.text.replaceAll(RegExp(r'\r?\n|\r'), ',')),
            ),
          ],
          onChanged: _onChanged,
          onSubmitted: (v) {
            if (!widget.readOnly && v.trim().isNotEmpty) _commit(v);
          },
          onEditingComplete: () {},
        ),
      ),
    );

    Widget field = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.disabled ? null : _focus.requestFocus,
      child: KumoFieldBox(
        focused: _focus.hasFocus,
        error: error != null,
        disabled: widget.disabled,
        readOnly: widget.readOnly,
        multiline: true,
        padding: EdgeInsets.zero,
        child: PickerChipWrap(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1_5),
          spacing: KumoSpace.s2,
          runSpacing: KumoSpace.s1_5,
          fillMinWidth: 128,
          children: [..._chipMotion.build(context, chips), input],
        ),
      ),
    );

    field = FormsFieldFrame(
      label: widget.label,
      description: widget.description,
      error: error,
      labelTooltip: widget.labelTooltip,
      showOptional: widget.showOptional,
      required: widget.required,
      controlLabeled: false,
      controlDescribed: false,
      child: field,
    );
    return PickerWidth(size: KumoFieldSize.base, child: field);
  }
}
