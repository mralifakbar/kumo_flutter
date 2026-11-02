import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../forms/src/forms_internal.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import 'kumo_select_option.dart';
import 'picker_internals.dart';

/// Where the text input sits in a [KumoCombobox.multiple] field.
enum KumoComboboxInputSide {
  /// Inline after the chips (Kumo's default).
  right,

  /// Above the chips.
  top,
}

/// Kumo's `Combobox`: a text field that filters a list of options as you
/// type.
///
/// * Typing opens the list and narrows it with [filter] (a case-insensitive
///   substring match by default). The first match is highlighted, so Enter
///   picks it; arrow keys move the highlight while focus stays in the field.
/// * With no matches the list says "No results" ([KumoStrings.noResults]).
///   [loading] shows a loading row while results are fetched; pair it with
///   [onInputValueChange] and a pass-through [filter] for server search.
/// * [KumoCombobox.multiple] shows chosen options as chips with remove
///   buttons; Backspace in the empty input removes the last chip.
/// * The list opens below the field, or above it when the on-screen
///   keyboard leaves too little room.
///
/// ```dart
/// KumoCombobox<String>(
///   label: 'Database',
///   placeholder: 'Search databases',
///   value: database,
///   onValueChange: (v) => setState(() => database = v),
///   options: const [
///     KumoSelectOption(value: 'd1', label: 'D1'),
///     KumoSelectOption(value: 'hyperdrive', label: 'Hyperdrive'),
///   ],
/// )
/// ```
class KumoCombobox<T> extends StatefulWidget {
  /// A single-choice combobox. The field shows the chosen option's label.
  const KumoCombobox({
    super.key,
    required this.options,
    this.value,
    this.onValueChange,
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
    this.onInputValueChange,
    this.side = KumoSide.bottom,
    this.sideOffset = 4,
    this.maxHeight = 384,
    this.semanticLabel,
    this.clearLabel,
    this.showOptionsLabel,
    this.focusNode,
    this.autofocus = false,
  })  : multiple = false,
        values = const <Never>[],
        onValuesChange = null,
        inputSide = KumoComboboxInputSide.right,
        removeLabel = null;

  /// A combobox that collects several options as chips.
  ///
  /// ```dart
  /// KumoCombobox<String>.multiple(
  ///   label: 'Allowed bots',
  ///   values: bots,
  ///   onValuesChange: (v) => setState(() => bots = v),
  ///   options: KumoSelectOption.fromLabels(['Googlebot', 'Bingbot', 'Applebot']),
  /// )
  /// ```
  const KumoCombobox.multiple({
    super.key,
    required this.options,
    required this.values,
    this.onValuesChange,
    this.inputSide = KumoComboboxInputSide.right,
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
    this.onInputValueChange,
    this.side = KumoSide.bottom,
    this.sideOffset = 4,
    this.maxHeight = 384,
    this.semanticLabel,
    this.removeLabel,
    this.focusNode,
    this.autofocus = false,
  })  : multiple = true,
        value = null,
        onValueChange = null,
        clearLabel = null,
        showOptionsLabel = null;

  /// Options, groups and separators. Groups are divided by a hairline, as
  /// in Kumo's combobox.
  final List<KumoSelectItem<T>> options;

  /// The chosen value (single).
  final T? value;
  final ValueChanged<T?>? onValueChange;

  /// True for [KumoCombobox.multiple].
  final bool multiple;

  /// The chosen values (multiple), shown as chips in this order.
  final List<T> values;
  final ValueChanged<List<T>>? onValuesChange;

  /// Input placement relative to the chips (multiple only).
  final KumoComboboxInputSide inputSide;
  final KumoFieldSize size;
  final String? label;
  final String? description;
  final String? error;
  final String? labelTooltip;
  final bool showOptional;
  final bool required;

  /// Input placeholder.
  final String? placeholder;
  final bool disabled;

  /// Shows a loading row in the list, for results being fetched.
  final bool loading;

  /// Decides which options match the typed text. Defaults to
  /// [kumoContainsFilter]. Pass `(option, query) => true` when the options
  /// are already filtered by a server.
  final KumoOptionFilter<T>? filter;

  /// Empty state text. Defaults to [KumoStrings.noResults].
  final String? emptyMessage;

  /// Loading row text. Defaults to [KumoStrings.loading].
  final String? loadingMessage;

  /// Called with the text as the user types (Base UI's
  /// `onInputValueChange`), for fetching options.
  final ValueChanged<String>? onInputValueChange;
  final KumoSide side;
  final double sideOffset;

  /// Largest list height. Kumo caps the combobox list at 24rem.
  final double maxHeight;

  /// Accessible name when there is no visible [label].
  final String? semanticLabel;

  /// Accessible name of the clear button. Defaults to [KumoStrings.clear].
  final String? clearLabel;

  /// Accessible name of the caret button that toggles the list. Default
  /// [KumoStrings.showOptions].
  final String? showOptionsLabel;

  /// Accessible name of a chip's remove button, given the chip label.
  /// Defaults to [KumoStrings.removeItem].
  final String Function(String label)? removeLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KumoCombobox<T>> createState() => _KumoComboboxState<T>();
}

class _KumoComboboxState<T> extends State<KumoCombobox<T>> with TickerProviderStateMixin {
  late final TextEditingController _text;
  late final PickerChipMotion _chipMotion;
  FocusNode? _ownFocus;
  final GlobalKey _fieldKey = GlobalKey();
  final PickerRevealController _reveal = PickerRevealController();
  bool _open = false;
  bool _dirty = false;
  int _highlight = -1;
  KumoSide _side = KumoSide.bottom;
  double _lastInsets = 0;

  PickerModel<T>? _model;
  Object? _modelKey;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'KumoCombobox'));

  @override
  void initState() {
    super.initState();
    _chipMotion = PickerChipMotion(vsync: this, onChanged: () {
      if (mounted) setState(() {});
    });
    _text = TextEditingController(text: _labelOf(widget.value));
    _side = widget.side;
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(KumoCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
    if (!widget.multiple && !_dirty && oldWidget.value != widget.value) _setText(_labelOf(widget.value));
    if (widget.disabled && _open) _open = false;
  }

  @override
  void dispose() {
    _chipMotion.dispose();
    _focus.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    _text.dispose();
    _reveal.dispose();
    super.dispose();
  }

  Map<T, String>? _labels;
  List<KumoSelectItem<T>>? _labelsSource;

  String? _lookup(T value) {
    if (_labels == null || !identical(_labelsSource, widget.options)) {
      _labelsSource = widget.options;
      _labels = {for (final o in PickerModel.build(widget.options).options) o.value: o.label};
    }
    return _labels![value];
  }

  String _labelOf(T? value) => value == null ? '' : _lookup(value) ?? '';

  void _setText(String text) {
    _text.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  String get _query => _dirty ? _text.text : '';

  PickerModel<T> get _items {
    final key = Object.hash(widget.options, _query, widget.filter);
    if (_model == null || key != _modelKey) {
      _modelKey = key;
      final q = _query;
      final filter = widget.filter ?? kumoContainsFilter<T>;
      _model = PickerModel.build(
        widget.options,
        test: q.trim().isEmpty ? null : (o) => filter(o, q),
        separateGroups: true,
      );
    }
    return _model!;
  }

  bool _isSelected(KumoSelectOption<T> o) => widget.multiple ? widget.values.contains(o.value) : o.value == widget.value;

  void _onFocusChange() {
    if (!mounted) return;
    if (!_focus.hasFocus) _close(revert: true);
    setState(() {});
  }

  int _initialHighlight() {
    final m = _items;
    if (_query.trim().isNotEmpty) return m.firstEnabled();
    if (!widget.multiple && widget.value != null) return m.indexOfValue(widget.value);
    return -1;
  }

  void _openList() {
    if (widget.disabled || _open) return;
    final ctx = _fieldKey.currentContext;
    setState(() {
      _side = ctx == null ? widget.side : pickerSide(ctx, preferred: widget.side, sideOffset: widget.sideOffset);
      _open = true;
      _highlight = _initialHighlight();
    });
    if (_highlight >= 0) _reveal.reveal(_highlight, center: true);
  }

  void _close({bool revert = false}) {
    if (revert) {
      _dirty = false;
      if (widget.multiple) {
        if (_text.text.isNotEmpty) _setText('');
      } else {
        final label = _labelOf(widget.value);
        if (_text.text != label) _setText(label);
      }
    }
    if (!_open) return;
    setState(() => _open = false);
  }

  void _onChanged(String text) {
    widget.onInputValueChange?.call(text);
    setState(() {
      _dirty = true;
      _model = null;
    });
    if (!_open) {
      _openList();
    } else {
      setState(() => _highlight = _initialHighlight());
      if (_highlight >= 0) _reveal.reveal(_highlight);
    }
  }

  void _pick(KumoSelectOption<T> o) {
    if (o.disabled) return;
    if (widget.multiple) {
      final next = List<T>.of(widget.values);
      if (!next.remove(o.value)) next.add(o.value);
      widget.onValuesChange?.call(next);
      _dirty = false;
      if (_text.text.isNotEmpty) {
        _setText('');
        widget.onInputValueChange?.call('');
      }
      _model = null;
      setState(() => _highlight = _items.indexOfValue(o.value));
      if (!_focus.hasFocus) _focus.requestFocus();
      return;
    }
    widget.onValueChange?.call(o.value);
    _dirty = false;
    _setText(o.label);
    _close();
  }

  void _clear() {
    widget.onValueChange?.call(null);
    _dirty = false;
    _setText('');
    widget.onInputValueChange?.call('');
    _focus.requestFocus();
  }

  void _removeAt(int index) {
    final next = List<T>.of(widget.values)..removeAt(index);
    widget.onValuesChange?.call(next);
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
      if (!_open) {
        _openList();
        if (_highlight < 0) _move(dir > 0 ? m.firstEnabled() : m.lastEnabled());
      } else {
        _move(m.step(_highlight, dir));
      }
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) && _open) {
      if (_highlight >= 0 && _highlight < m.length && m.entries[_highlight].isEnabledOption) {
        _pick(m.entries[_highlight].option!);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.escape && _open) {
      _close(revert: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace && widget.multiple && _text.text.isEmpty && widget.values.isNotEmpty) {
      _removeAt(widget.values.length - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) _close(revert: true);
    return KeyEventResult.ignored;
  }

  void _onInsetsChanged() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = _fieldKey.currentContext;
      if (!mounted || !_open || ctx == null) return;
      final side = pickerSide(ctx, preferred: widget.side, sideOffset: widget.sideOffset);
      if (side != _side) setState(() => _side = side);
    });
  }

  Widget _editable(BuildContext context, {EdgeInsetsGeometry padding = EdgeInsets.zero}) {
    final strings = context.kumoStrings;
    // Inline after chips, the placeholder would read as another chip.
    final hasChips = widget.multiple && widget.values.isNotEmpty && widget.inputSide == KumoComboboxInputSide.right;
    return Padding(
      padding: padding,
      child: KumoEditable(
        controller: _text,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: !widget.disabled,
        size: widget.size.textSize,
        placeholder: hasChips ? null : widget.placeholder,
        semanticLabel: widget.label ?? widget.semanticLabel ?? widget.placeholder ?? strings.search,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onChanged: _onChanged,
        onTap: _openList,
        onEditingComplete: () {},
      ),
    );
  }

  Widget _chip(BuildContext context, int index) {
    final strings = context.kumoStrings;
    final v = widget.values[index];
    final label = _lookup(v) ?? '$v';
    return PickerChip(
      key: ValueKey<Object?>(v),
      label: label,
      removeLabel: widget.removeLabel?.call(label) ?? strings.removeItem(label),
      disabled: widget.disabled,
      onRemove: () => _removeAt(index),
    );
  }

  Widget _buildField(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final focused = _focus.hasFocus;
    final iconSize = pickerIconSize(widget.size);

    if (widget.multiple) {
      final chips = _chipMotion.build(context, [for (var i = 0; i < widget.values.length; i++) _chip(context, i)]);
      const inputPadding = EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1);
      final Widget content;
      if (widget.inputSide == KumoComboboxInputSide.top) {
        content = Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s1_5, vertical: KumoSpace.s1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s1,
            children: [
              _editable(context, padding: inputPadding),
              if (chips.isNotEmpty) PickerChipWrap(hasFill: false, children: chips),
            ],
          ),
        );
      } else {
        content = PickerChipWrap(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s1_5, vertical: KumoSpace.s1),
          children: [...chips, _editable(context, padding: inputPadding)],
        );
      }
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.disabled
            ? null
            : () {
                _focus.requestFocus();
                _openList();
              },
        child: KumoFieldBox(
          key: _fieldKey,
          size: widget.size,
          focused: focused,
          error: widget.error != null,
          disabled: widget.disabled,
          multiline: true,
          padding: EdgeInsets.zero,
          child: content,
        ),
      );
    }

    final showClear = widget.value != null && !widget.disabled;
    // Both buttons are as tall as the field so their touch targets cover it.
    Widget iconButton({required IconData icon, required String label, required VoidCallback onPress}) {
      final visual = Size(iconSize + KumoSpace.s2, widget.size.height);
      return PickerHitInflate(
        inflate: pickerTouchInflate(context, visual),
        child: KumoPressable(
          onPress: onPress,
          minTapTargetSize: 0,
          scaleOnPress: false,
          semanticLabel: label,
          excludeChildSemantics: true,
          borderRadius: BorderRadius.circular(KumoRadius.sm),
          builder: (context, state) => SizedBox.fromSize(
            size: visual,
            child: Center(
              child: KumoIcon(icon, size: iconSize, color: state.active ? KumoColor.textDefault : KumoColor.textSubtle),
            ),
          ),
        ),
      );
    }

    return KumoFieldBox(
      key: _fieldKey,
      size: widget.size,
      focused: focused,
      error: widget.error != null,
      disabled: widget.disabled,
      padding: EdgeInsetsDirectional.only(start: widget.size.paddingX, end: KumoSpace.s1),
      trailing: widget.disabled
          ? KumoIcon(KumoIcons.caretUpDown, size: iconSize, color: KumoColor.textSubtle)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showClear) iconButton(icon: KumoIcons.x, label: widget.clearLabel ?? strings.clear, onPress: _clear),
                iconButton(
                  icon: KumoIcons.caretUpDown,
                  label: widget.showOptionsLabel ?? strings.showOptions,
                  onPress: () {
                    _focus.requestFocus();
                    _open ? _close() : _openList();
                  },
                ),
              ],
            ),
      child: DefaultTextStyle.merge(style: kumo.text(size: widget.size.textSize), child: _editable(context)),
    );
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
    if (_highlight >= m.length) _highlight = m.firstEnabled();

    Widget field = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: Semantics(expanded: _open, child: _buildField(context)),
    );

    field = KumoAnchoredOverlay(
      open: _open,
      onDismiss: () => _close(revert: true),
      side: _side,
      align: KumoAlign.start,
      sideOffset: widget.sideOffset,
      preferredExtent: 0,
      matchAnchorWidth: true,
      focusPopupWhenUnfocused: false,
      overlayBuilder: (context, placement) => TextFieldTapRegion(
        child: PickerOptionList<T>(
          model: m,
          highlighted: _highlight,
          isSelected: _isSelected,
          onPick: _pick,
          onHover: (i) => setState(() => _highlight = i),
          multiple: widget.multiple,
          reveal: _reveal,
          maxHeight: pickerMaxHeight(context, placement, cap: widget.maxHeight, sideOffset: widget.sideOffset),
          width: placement.anchorRect.width,
          semanticLabel: widget.label ?? widget.semanticLabel,
          leading: [
            if (widget.loading) PickerStatusRow(text: widget.loadingMessage ?? strings.loading, loading: true),
          ],
          trailing: [
            if (!widget.loading && !m.hasOptions) PickerStatusRow(text: widget.emptyMessage ?? strings.noResults),
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
