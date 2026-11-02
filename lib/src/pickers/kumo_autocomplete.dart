import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../forms/src/forms_internal.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_strings.dart';
import 'kumo_select_option.dart';
import 'picker_internals.dart';

/// Kumo's `Autocomplete`: a free-text field with a list of suggestions.
///
/// Unlike [KumoCombobox], the value is the text itself: suggestions help
/// the user type, and anything typed is accepted. Picking a suggestion puts
/// its [KumoSelectOption.value] in the field.
///
/// * Typing (or Down arrow) opens the suggestions that match [filter]. The
///   list hides when nothing matches, as Kumo's does, unless
///   [emptyMessage] is set.
/// * Up and Down move the highlight with focus kept in the field; Enter
///   picks the highlighted suggestion, otherwise it submits the text.
/// * Escape closes the list and keeps the text.
///
/// ```dart
/// KumoAutocomplete(
///   label: 'Route pattern',
///   placeholder: 'example.com/*',
///   value: route,
///   onValueChange: (v) => setState(() => route = v),
///   options: KumoSelectOption.fromLabels(['example.com/*', 'api.example.com/*', 'example.com/images/*']),
/// )
/// ```
class KumoAutocomplete extends StatefulWidget {
  const KumoAutocomplete({
    super.key,
    required this.value,
    required this.onValueChange,
    required this.options,
    this.size = KumoFieldSize.base,
    this.label,
    this.description,
    this.error,
    this.labelTooltip,
    this.showOptional = false,
    this.required = false,
    this.placeholder,
    this.disabled = false,
    this.loading = false,
    this.filter,
    this.emptyMessage,
    this.loadingMessage,
    this.onOpenChange,
    this.onSubmitted,
    this.side = KumoSide.bottom,
    this.sideOffset = 4,
    this.maxHeight = 384,
    this.semanticLabel,
    this.keyboardType,
    this.autofillHints,
    this.mono = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The field's text.
  final String value;

  /// Called with the text on every edit and when a suggestion is picked.
  final ValueChanged<String>? onValueChange;

  /// Suggestions, optionally grouped. The option's value is the text it
  /// inserts; its label is what the list shows.
  final List<KumoSelectItem<String>> options;
  final KumoFieldSize size;
  final String? label;
  final String? description;
  final String? error;
  final String? labelTooltip;
  final bool showOptional;
  final bool required;
  final String? placeholder;
  final bool disabled;

  /// Shows a loading row while suggestions are fetched.
  final bool loading;

  /// Which suggestions match the text. Defaults to [kumoContainsFilter].
  final KumoOptionFilter<String>? filter;

  /// Shown when no suggestion matches. Null hides the list instead.
  final String? emptyMessage;

  /// Loading row text. Defaults to [KumoStrings.loading].
  final String? loadingMessage;

  /// Called when the suggestion list opens or closes.
  final ValueChanged<bool>? onOpenChange;

  /// Called when Enter is pressed with no suggestion highlighted.
  final ValueChanged<String>? onSubmitted;
  final KumoSide side;
  final double sideOffset;

  /// Largest list height; Kumo uses 24rem.
  final double maxHeight;

  /// Accessible name when there is no visible [label].
  final String? semanticLabel;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  /// Monospace text, for hostnames, paths and IDs.
  final bool mono;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KumoAutocomplete> createState() => _KumoAutocompleteState();
}

class _KumoAutocompleteState extends State<KumoAutocomplete> {
  late final TextEditingController _text;
  FocusNode? _ownFocus;
  final GlobalKey _fieldKey = GlobalKey();
  final PickerRevealController _reveal = PickerRevealController();
  bool _open = false;
  int _highlight = -1;
  KumoSide _side = KumoSide.bottom;
  double _lastInsets = 0;
  bool _reportedOpen = false;

  PickerModel<String>? _model;
  Object? _modelKey;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'KumoAutocomplete'));

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.value);
    _side = widget.side;
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(KumoAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
    if (widget.value != _text.text) {
      _text.value = TextEditingValue(text: widget.value, selection: TextSelection.collapsed(offset: widget.value.length));
    }
    if (widget.disabled && _open) _open = false;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    _text.dispose();
    _reveal.dispose();
    super.dispose();
  }

  PickerModel<String> get _items {
    final q = _text.text;
    final key = Object.hash(widget.options, q, widget.filter);
    if (_model == null || key != _modelKey) {
      _modelKey = key;
      final filter = widget.filter ?? kumoContainsFilter<String>;
      _model = PickerModel.build(
        widget.options,
        test: q.trim().isEmpty ? null : (o) => filter(o, q),
        separateGroups: true,
      );
    }
    return _model!;
  }

  bool get _visible => _open && (_items.hasOptions || widget.loading || widget.emptyMessage != null);

  void _onFocusChange() {
    if (!mounted) return;
    if (!_focus.hasFocus) _close();
    setState(() {});
  }

  void _openList() {
    if (widget.disabled || _open) return;
    final ctx = _fieldKey.currentContext;
    setState(() {
      _side = ctx == null ? widget.side : pickerSide(ctx, preferred: widget.side, sideOffset: widget.sideOffset);
      _open = true;
      _highlight = -1;
    });
  }

  void _close() {
    if (!_open) return;
    setState(() {
      _open = false;
      _highlight = -1;
    });
  }

  void _onChanged(String text) {
    widget.onValueChange?.call(text);
    setState(() => _highlight = -1);
    _openList();
  }

  void _pick(KumoSelectOption<String> o) {
    if (o.disabled) return;
    _text.value = TextEditingValue(text: o.value, selection: TextSelection.collapsed(offset: o.value.length));
    widget.onValueChange?.call(o.value);
    _close();
  }

  void _move(int to) {
    if (to < 0) return;
    setState(() => _highlight = to);
    _reveal.reveal(to);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (widget.disabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final m = _items;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      final dir = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      if (!_open) _openList();
      _move(m.step(_highlight, dir));
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) &&
        _visible &&
        _highlight >= 0 &&
        _highlight < m.length &&
        m.entries[_highlight].isEnabledOption) {
      _pick(m.entries[_highlight].option!);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _open) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) _close();
    return KeyEventResult.ignored;
  }

  void _reportOpen(bool visible) {
    if (visible == _reportedOpen || widget.onOpenChange == null) return;
    _reportedOpen = visible;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onOpenChange?.call(visible);
    });
  }

  void _onInsetsChanged() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = _fieldKey.currentContext;
      if (!mounted || !_open || ctx == null) return;
      final side = pickerSide(ctx, preferred: widget.side, sideOffset: widget.sideOffset);
      if (side != _side) setState(() => _side = side);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    if (insets != _lastInsets) {
      _lastInsets = insets;
      if (_open) _onInsetsChanged();
    }
    final m = _items;
    final visible = _visible;
    _reportOpen(visible);

    Widget field = KumoFieldBox(
      key: _fieldKey,
      size: widget.size,
      focused: _focus.hasFocus,
      error: widget.error != null,
      disabled: widget.disabled,
      child: KumoEditable(
        controller: _text,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: !widget.disabled,
        size: widget.size.textSize,
        mono: widget.mono,
        placeholder: widget.placeholder,
        semanticLabel: widget.label ?? widget.semanticLabel ?? widget.placeholder,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        onChanged: _onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
    field = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: Semantics(expanded: visible, child: field),
    );

    field = KumoAnchoredOverlay(
      open: visible,
      onDismiss: _close,
      side: _side,
      align: KumoAlign.start,
      sideOffset: widget.sideOffset,
      preferredExtent: 0,
      matchAnchorWidth: true,
      focusPopupWhenUnfocused: false,
      overlayBuilder: (context, placement) => TextFieldTapRegion(
        child: PickerOptionList<String>(
          model: m,
          highlighted: _highlight,
          isSelected: (o) => o.value == widget.value,
          onPick: _pick,
          onHover: (i) => setState(() => _highlight = i),
          reveal: _reveal,
          maxHeight: pickerMaxHeight(context, placement, cap: widget.maxHeight, sideOffset: widget.sideOffset),
          width: placement.anchorRect.width,
          semanticLabel: widget.label ?? widget.semanticLabel,
          leading: [
            if (widget.loading) PickerStatusRow(text: widget.loadingMessage ?? strings.loading, loading: true),
          ],
          trailing: [
            if (!widget.loading && !m.hasOptions && widget.emptyMessage != null)
              PickerStatusRow(text: widget.emptyMessage!),
          ],
        ),
      ),
      child: field,
    );

    final Widget result = FormsFieldFrame(
      label: widget.label,
      description: widget.description,
      error: widget.error,
      labelTooltip: widget.labelTooltip,
      showOptional: widget.showOptional,
      required: widget.required,
      controlLabeled: false,
      controlDescribed: false,
      child: field,
    );
    return PickerWidth(size: widget.size, child: result);
  }
}
