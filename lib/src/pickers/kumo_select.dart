import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../display/kumo_skeleton_line.dart';
import '../forms/src/forms_internal.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../typography/kumo_text.dart';
import 'kumo_select_option.dart';
import 'picker_internals.dart';

/// Builds the trigger's content for the current selection. [selected] holds
/// one option for a single select and every chosen option for a multiple
/// select; it is never empty (the placeholder shows instead).
typedef KumoSelectValueBuilder<T> = Widget Function(BuildContext context, List<KumoSelectOption<T>> selected);

/// Kumo's `Select`: a field-styled trigger that opens a list of options.
///
/// * Wide screens open an anchored list under the trigger, at least as wide
///   as the trigger and scrolled to the current value. Arrow keys move the
///   highlight, Enter or Space picks, typing letters jumps to the matching
///   option, Escape closes, and focus stays on the trigger throughout.
/// * Below 768px ([KumoPresentation.auto]) the list opens in a bottom sheet
///   that follows the finger; the current option is checked.
/// * [KumoSelect.multiple] keeps the list open while options are toggled
///   and summarizes the choice in the trigger.
/// * Lists longer than 100 rows are built lazily, so thousands of options
///   open instantly.
///
/// The widget is controlled: it shows [value] and reports picks through
/// [onValueChange].
///
/// ```dart
/// KumoSelect<String>(
///   label: 'Region',
///   placeholder: 'Choose a region',
///   value: region,
///   onValueChange: (v) => setState(() => region = v),
///   options: const [
///     KumoSelectOption(value: 'enam', label: 'Eastern North America'),
///     KumoSelectOption(value: 'weur', label: 'Western Europe'),
///   ],
/// )
/// ```
class KumoSelect<T> extends StatefulWidget {
  /// A single-choice select.
  const KumoSelect({
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
    this.loading = false,
    this.disabled = false,
    this.presentation = KumoPresentation.auto,
    this.side = KumoSide.bottom,
    this.align = KumoAlign.start,
    this.sideOffset = 4,
    this.maxHeight,
    this.renderValue,
    this.semanticLabel,
    this.sheetTitle,
    this.focusNode,
    this.autofocus = false,
  }) : multiple = false,
       values = const <Never>[],
       onValuesChange = null;

  /// A select that lets the user pick any number of options. The list stays
  /// open while options are toggled.
  ///
  /// ```dart
  /// KumoSelect<String>.multiple(
  ///   label: 'Visible columns',
  ///   values: columns,
  ///   onValuesChange: (v) => setState(() => columns = v),
  ///   options: KumoSelectOption.fromLabels(['Name', 'Route', 'Status', 'Last deploy']),
  /// )
  /// ```
  const KumoSelect.multiple({
    super.key,
    required this.options,
    required this.values,
    this.onValuesChange,
    this.size = KumoFieldSize.base,
    this.label,
    this.description,
    this.error,
    this.labelTooltip,
    this.showOptional = false,
    this.required = false,
    this.placeholder,
    this.loading = false,
    this.disabled = false,
    this.presentation = KumoPresentation.auto,
    this.side = KumoSide.bottom,
    this.align = KumoAlign.start,
    this.sideOffset = 4,
    this.maxHeight,
    this.renderValue,
    this.semanticLabel,
    this.sheetTitle,
    this.focusNode,
    this.autofocus = false,
  }) : multiple = true,
       value = null,
       onValueChange = null;

  /// Options, groups and separators, in display order.
  final List<KumoSelectItem<T>> options;

  /// The chosen value (single select). Null shows [placeholder].
  final T? value;

  /// Called with the picked option's value (single select).
  final ValueChanged<T?>? onValueChange;

  /// True for [KumoSelect.multiple].
  final bool multiple;

  /// The chosen values (multiple select), in the order they were picked.
  final List<T> values;

  /// Called with the next list of values when an option is toggled.
  final ValueChanged<List<T>>? onValuesChange;

  /// Trigger height and text size. Matches [KumoButtonSize] heights.
  final KumoFieldSize size;

  /// Visible label above the trigger. Also the trigger's accessible name.
  final String? label;

  /// Help text under the trigger.
  final String? description;

  /// Error message under the trigger; also turns the ring red.
  final String? error;

  /// Info tooltip next to the label.
  final String? labelTooltip;

  /// Shows "(optional)" after the label (Kumo's `required={false}`).
  final bool showOptional;

  /// Announces the field as required.
  final bool required;

  /// Text shown while nothing is chosen.
  final String? placeholder;

  /// Shows a skeleton in the trigger and blocks opening, for options that
  /// are still being fetched.
  final bool loading;
  final bool disabled;

  /// Anchored list or bottom sheet. [KumoPresentation.auto] uses a sheet
  /// below 768px.
  final KumoPresentation presentation;

  /// Side of the trigger the list opens on. It flips when there is no room.
  final KumoSide side;
  final KumoAlign align;

  /// Gap between trigger and list.
  final double sideOffset;

  /// Caps the list height. By default the list may use all the room on its
  /// side, as Kumo's does.
  final double? maxHeight;

  /// Custom trigger content for the current selection, such as
  /// "Name, Status and 2 more" or a count badge.
  final KumoSelectValueBuilder<T>? renderValue;

  /// Accessible name when there is no visible [label] (Kumo's `aria-label`).
  final String? semanticLabel;

  /// Heading at the top of the sheet. Defaults to [label].
  final String? sheetTitle;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KumoSelect<T>> createState() => _KumoSelectState<T>();
}

class _KumoSelectState<T> extends State<KumoSelect<T>> {
  FocusNode? _ownFocus;
  bool _open = false;
  bool _sheetOpen = false;
  int _highlight = -1;
  final PickerRevealController _reveal = PickerRevealController();
  final PickerTypeahead _typeahead = PickerTypeahead();
  PickerModel<T>? _model;
  List<KumoSelectItem<T>>? _modelSource;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'KumoSelect'));

  bool get _interactive => !widget.disabled && !widget.loading;

  PickerModel<T> get _items {
    if (_model == null || !identical(_modelSource, widget.options)) {
      _modelSource = widget.options;
      _model = PickerModel.build(widget.options);
    }
    return _model!;
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void didUpdateWidget(KumoSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocusChange);
      _focus.addListener(_onFocusChange);
    }
    if (!_interactive && _open) _open = false;
    if (_highlight >= _items.length) _highlight = _items.lastEnabled();
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _focus.removeListener(_onFocusChange);
    _ownFocus?.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    if (mounted && _focus.hasFocus) setState(() {});
  }

  bool _isSelected(KumoSelectOption<T> o) =>
      widget.multiple ? widget.values.contains(o.value) : o.value == widget.value;

  List<KumoSelectOption<T>> get _selected {
    if (widget.multiple) {
      final byValue = {for (final o in _items.options) o.value: o};
      return [for (final v in widget.values) ?byValue[v]];
    }
    if (widget.value == null) return const [];
    for (final o in _items.options) {
      if (o.value == widget.value) return [o];
    }
    return const [];
  }

  int get _selectedIndex {
    final m = _items;
    if (widget.multiple) {
      for (var i = 0; i < m.length; i++) {
        final o = m.entries[i].option;
        if (o != null && widget.values.contains(o.value)) return i;
      }
      return -1;
    }
    return widget.value == null ? -1 : m.indexOfValue(widget.value);
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openList();
    }
  }

  void _openList() {
    if (!_interactive || _sheetOpen) return;
    _focus.requestFocus();
    if (widget.presentation.usesSheet(context)) {
      unawaited(_openSheet());
      return;
    }
    final start = _selectedIndex;
    setState(() {
      _open = true;
      _highlight = start >= 0 ? start : _items.firstEnabled();
    });
    _reveal.reveal(_highlight, center: true);
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
  }

  void _pick(KumoSelectOption<T> o) {
    if (o.disabled) return;
    if (widget.multiple) {
      final next = List<T>.of(widget.values);
      if (!next.remove(o.value)) next.add(o.value);
      widget.onValuesChange?.call(next);
      return;
    }
    widget.onValueChange?.call(o.value);
    _close();
  }

  void _moveHighlight(int to) {
    if (to < 0) return;
    setState(() => _highlight = to);
    _reveal.reveal(to);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (!_interactive) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final m = _items;
    if (!_open) {
      if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
        _openList();
        return KeyEventResult.handled;
      }
      final char = _typeahead.characterOf(event);
      if (char != null && !widget.multiple && !_sheetOpen) {
        final match = _typeahead.search(m, char, _selectedIndex);
        if (match >= 0) widget.onValueChange?.call(m.entries[match].option!.value);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(m.step(_highlight, 1));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(m.step(_highlight, -1));
    } else if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.pageUp) {
      _moveHighlight(m.firstEnabled());
    } else if (key == LogicalKeyboardKey.end || key == LogicalKeyboardKey.pageDown) {
      _moveHighlight(m.lastEnabled());
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        (key == LogicalKeyboardKey.space && !_typeahead.active)) {
      if (_highlight >= 0 && _highlight < m.length && m.entries[_highlight].isEnabledOption) {
        _pick(m.entries[_highlight].option!);
      }
    } else if (key == LogicalKeyboardKey.escape) {
      _close();
    } else if (key == LogicalKeyboardKey.tab) {
      _close();
      return KeyEventResult.ignored;
    } else {
      final char = _typeahead.characterOf(event);
      if (char == null) return KeyEventResult.ignored;
      _moveHighlight(_typeahead.search(m, char, _highlight));
    }
    return KeyEventResult.handled;
  }

  Future<void> _openSheet() async {
    setState(() => _sheetOpen = true);
    await showKumoSheet<void>(
      context: context,
      semanticLabel: widget.sheetTitle ?? widget.label ?? widget.semanticLabel ?? widget.placeholder,
      builder: (context) => _SelectSheet<T>(
        title: widget.sheetTitle ?? widget.label,
        model: _items,
        multiple: widget.multiple,
        value: widget.value,
        values: widget.values,
        onValueChange: widget.onValueChange,
        onValuesChange: widget.onValuesChange,
      ),
    );
    if (mounted) setState(() => _sheetOpen = false);
  }

  String _summary(List<KumoSelectOption<T>> selected) => selected.map((o) => o.label).join(', ');

  Widget _buildValue(BuildContext context) {
    final kumo = context.kumo;
    final textSize = widget.size.textSize;
    if (widget.loading) {
      // Static: a select can sit loading for a long time, and a trigger that
      // shimmers indefinitely draws the eye away from the rest of the form.
      return const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(width: 96, child: KumoSkeletonLine(widthFactor: 1)),
      );
    }
    final selected = _selected;
    if (selected.isEmpty) {
      return Text(
        widget.placeholder ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: kumo.text(size: textSize, color: KumoColor.textPlaceholder),
      );
    }
    if (widget.renderValue != null) {
      return DefaultTextStyle.merge(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: widget.renderValue!(context, selected),
      );
    }
    return Text(
      _summary(selected),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: kumo.text(size: textSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = _open || _sheetOpen;
    final showFocus =
        _focus.hasFocus && (open || FocusManager.instance.highlightMode == FocusHighlightMode.traditional);
    final selected = _selected;
    final accessibleName = widget.label ?? widget.semanticLabel ?? widget.placeholder;

    Widget trigger = KumoPressable(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onPress: _toggle,
      disabled: widget.disabled,
      loading: widget.loading,
      showFocusRing: false,
      borderRadius: BorderRadius.circular(widget.size.radius),
      semanticLabel: accessibleName,
      semanticValue: widget.loading ? null : (selected.isEmpty ? widget.placeholder : _summary(selected)),
      expanded: open,
      excludeChildSemantics: true,
      builder: (context, state) => KumoFieldBox(
        size: widget.size,
        focused: showFocus,
        error: widget.error != null,
        disabled: widget.disabled,
        hovered: state.hovered,
        trailing: KumoIcon(KumoIcons.caretUpDown, size: pickerIconSize(widget.size), color: KumoColor.textSubtle),
        // The value cross-fades when it changes instead of popping.
        child: AnimatedSwitcher(
          duration: KumoMotion.duration(context, KumoDurations.fast),
          switchInCurve: KumoCurves.enter,
          switchOutCurve: KumoCurves.exit,
          layoutBuilder: (current, previous) =>
              Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
          child: KeyedSubtree(
            key: ValueKey<Object?>(widget.loading ? #loading : (selected.isEmpty ? null : _summary(selected))),
            child: _buildValue(context),
          ),
        ),
      ),
    );
    trigger = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: _onKey, child: trigger);

    final m = _items;
    trigger = KumoAnchoredOverlay(
      open: _open,
      onDismiss: _close,
      side: widget.side,
      align: widget.align,
      sideOffset: widget.sideOffset,
      matchAnchorWidth: true,
      focusPopupWhenUnfocused: false,
      overlayBuilder: (context, placement) => PickerOptionList<T>(
        model: m,
        highlighted: _highlight,
        isSelected: _isSelected,
        onPick: _pick,
        onHover: (i) => setState(() => _highlight = i),
        multiple: widget.multiple,
        reveal: _reveal,
        maxHeight: widget.maxHeight == null || widget.maxHeight! > placement.maxHeight
            ? placement.maxHeight
            : widget.maxHeight,
        width: placement.anchorRect.width,
        semanticLabel: accessibleName,
      ),
      child: trigger,
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
      child: trigger,
    );
    return PickerWidth(size: widget.size, child: result);
  }
}

/// The option list in a bottom sheet. It keeps its own copy of a multiple
/// selection while open, since the route does not rebuild with the parent.
class _SelectSheet<T> extends StatefulWidget {
  const _SelectSheet({
    required this.title,
    required this.model,
    required this.multiple,
    required this.value,
    required this.values,
    required this.onValueChange,
    required this.onValuesChange,
  });

  final String? title;
  final PickerModel<T> model;
  final bool multiple;
  final T? value;
  final List<T> values;
  final ValueChanged<T?>? onValueChange;
  final ValueChanged<List<T>>? onValuesChange;

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
  late final List<T> _values = List<T>.of(widget.values);
  final PickerRevealController _reveal = PickerRevealController();
  final PickerTypeahead _typeahead = PickerTypeahead();
  int _highlight = -1;
  bool _keyboard = false;

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    var start = -1;
    for (var i = 0; i < m.length && start < 0; i++) {
      final o = m.entries[i].option;
      if (o == null) continue;
      if (widget.multiple ? _values.contains(o.value) : o.value == widget.value) start = i;
    }
    _highlight = start >= 0 ? start : m.firstEnabled();
    if (start >= 0) _reveal.reveal(start, center: true);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  bool _isSelected(KumoSelectOption<T> o) => widget.multiple ? _values.contains(o.value) : o.value == widget.value;

  void _pick(KumoSelectOption<T> o) {
    if (o.disabled) return;
    kumoHaptic(KumoHaptic.selection);
    if (widget.multiple) {
      setState(() {
        if (!_values.remove(o.value)) _values.add(o.value);
      });
      widget.onValuesChange?.call(List<T>.of(_values));
      return;
    }
    widget.onValueChange?.call(o.value);
    KumoSheetScope.closeFrom(context);
  }

  void _move(int to) {
    if (to < 0) return;
    setState(() {
      _keyboard = true;
      _highlight = to;
    });
    _reveal.reveal(to);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final m = widget.model;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(_keyboard ? m.step(_highlight, 1) : _highlight);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(_keyboard ? m.step(_highlight, -1) : _highlight);
    } else if (key == LogicalKeyboardKey.home) {
      _move(m.firstEnabled());
    } else if (key == LogicalKeyboardKey.end) {
      _move(m.lastEnabled());
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        (key == LogicalKeyboardKey.space && !_typeahead.active)) {
      if (_highlight >= 0 && m.entries[_highlight].isEnabledOption) _pick(m.entries[_highlight].option!);
    } else {
      final char = _typeahead.characterOf(event);
      if (char == null) return KeyEventResult.ignored;
      _move(_typeahead.search(m, char, _highlight));
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(KumoSpace.s4, KumoSpace.s1, KumoSpace.s4, KumoSpace.s2),
            child: KumoText(widget.title!, variant: KumoTextVariant.heading, headingLevel: 2),
          ),
        Flexible(
          child: Focus(
            autofocus: true,
            onKeyEvent: _onKey,
            child: PickerOptionList<T>(
              model: widget.model,
              highlighted: _keyboard ? _highlight : -1,
              isSelected: _isSelected,
              onPick: _pick,
              multiple: widget.multiple,
              reveal: _reveal,
              surface: PickerListSurface.bare,
              semanticLabel: widget.title,
              padding: const EdgeInsets.fromLTRB(KumoSpace.s2, 0, KumoSpace.s2, KumoSpace.s2),
            ),
          ),
        ),
      ],
    );
  }
}
