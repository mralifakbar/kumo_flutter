// Building blocks shared by the pickers category. Not exported from the
// package: the names here are internal to lib/src/pickers.
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../feedback/kumo_loader.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_menu_parts.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_select_option.dart';

enum PickerEntryKind { option, groupLabel, separator }

/// One row of a flattened option list.
@immutable
class PickerEntry<T> {
  const PickerEntry.option(KumoSelectOption<T> this.option) : kind = PickerEntryKind.option, label = null;
  const PickerEntry.groupLabel(String this.label) : kind = PickerEntryKind.groupLabel, option = null;
  const PickerEntry.separator() : kind = PickerEntryKind.separator, option = null, label = null;

  final PickerEntryKind kind;
  final KumoSelectOption<T>? option;
  final String? label;

  bool get isOption => kind == PickerEntryKind.option;
  bool get isEnabledOption => option != null && !option!.disabled;
}

/// The rows a picker shows for a set of items, after filtering, plus
/// keyboard navigation over them.
class PickerModel<T> {
  PickerModel._(this.entries);

  /// Flattens [items] into rows. With [test], options that fail it are left
  /// out, groups with no remaining options disappear, and separators never
  /// lead, trail or double up. [separateGroups] draws a hairline between
  /// consecutive groups (Kumo's combobox group style).
  factory PickerModel.build(
    List<KumoSelectItem<T>> items, {
    bool Function(KumoSelectOption<T> option)? test,
    bool separateGroups = false,
  }) {
    final out = <PickerEntry<T>>[];
    void separator() {
      if (out.isNotEmpty && out.last.kind != PickerEntryKind.separator) out.add(PickerEntry<T>.separator());
    }

    for (final item in items) {
      switch (item) {
        case KumoSelectOption<T>():
          if (test == null || test(item)) out.add(PickerEntry<T>.option(item));
        case KumoSelectGroup<T>():
          final matching = test == null ? item.options : item.options.where(test).toList();
          if (matching.isEmpty) continue;
          if (separateGroups) separator();
          out.add(PickerEntry<T>.groupLabel(item.label));
          for (final o in matching) {
            out.add(PickerEntry<T>.option(o));
          }
        case KumoSelectSeparator<T>():
          separator();
      }
    }
    while (out.isNotEmpty && out.last.kind == PickerEntryKind.separator) {
      out.removeLast();
    }
    return PickerModel._(out);
  }

  final List<PickerEntry<T>> entries;

  int get length => entries.length;
  bool get hasOptions => entries.any((e) => e.isOption);

  Iterable<KumoSelectOption<T>> get options sync* {
    for (final e in entries) {
      if (e.option != null) yield e.option!;
    }
  }

  /// Row index of the first option whose value equals [value], or -1.
  int indexOfValue(Object? value) {
    for (var i = 0; i < entries.length; i++) {
      final o = entries[i].option;
      if (o != null && o.value == value) return i;
    }
    return -1;
  }

  int firstEnabled() => _scan(-1, 1, wrap: false);
  int lastEnabled() => _scan(entries.length, -1, wrap: false);

  /// The next enabled option after [from] in [direction] (1 or -1). With
  /// nothing highlighted (-1) it starts at the matching end.
  int step(int from, int direction, {bool wrap = false}) {
    if (from < 0) return direction > 0 ? firstEnabled() : lastEnabled();
    final next = _scan(from, direction, wrap: wrap);
    return next < 0 ? from : next;
  }

  int _scan(int from, int direction, {required bool wrap}) {
    final n = entries.length;
    if (n == 0) return -1;
    var i = from;
    for (var count = 0; count < n; count++) {
      i += direction;
      if (i < 0 || i >= n) {
        if (!wrap) return -1;
        i = (i + n) % n;
      }
      if (entries[i].isEnabledOption) return i;
    }
    return -1;
  }
}

/// Type-to-jump: letters typed in quick succession build a prefix; typing
/// the same letter again cycles through the options that start with it.
class PickerTypeahead {
  static const Duration resetAfter = Duration(milliseconds: 700);

  String _buffer = '';
  DateTime? _last;

  bool get active => _buffer.isNotEmpty && _last != null && clock.now().difference(_last!) <= resetAfter;

  /// The printable character of [event], or null when it is a control key,
  /// a shortcut (Ctrl, Alt, Cmd held), or a space that should activate
  /// instead of search.
  String? characterOf(KeyEvent event) {
    final c = event.character;
    if (c == null || c.isEmpty || c.runes.length != 1) return null;
    if (c.codeUnitAt(0) < 0x20 || c.codeUnitAt(0) == 0x7f) return null;
    final kb = HardwareKeyboard.instance;
    if (kb.isControlPressed || kb.isMetaPressed || kb.isAltPressed) return null;
    if (c == ' ' && !active) return null;
    return c;
  }

  /// Row index of the match for [character], searching from [from], or -1.
  int search<T>(PickerModel<T> model, String character, int from) {
    final now = clock.now();
    if (_last == null || now.difference(_last!) > resetAfter) _buffer = '';
    _last = now;
    final c = character.toLowerCase();
    final repeat = _buffer.length == 1 && _buffer == c;
    if (!repeat) _buffer += c;
    final n = model.length;
    if (n == 0) return -1;
    final start = (_buffer.length == 1 ? from + 1 : math.max(from, 0)) % n;
    for (var k = 0; k < n; k++) {
      final i = (start + k) % n;
      final o = model.entries[i].option;
      if (o != null && !o.disabled && o.label.toLowerCase().startsWith(_buffer)) return i;
    }
    return -1;
  }
}

/// Asks a [PickerOptionList] to scroll a row into view.
class PickerRevealController extends ChangeNotifier {
  int _index = -1;
  bool _center = false;

  int get index => _index;
  bool get center => _center;

  /// Scrolls row [index] into view; [center] puts it in the middle, the way
  /// a select opens on its current value.
  void reveal(int index, {bool center = false}) {
    if (index < 0) return;
    _index = index;
    _center = center;
    notifyListeners();
  }
}

/// How the option list is framed.
enum PickerListSurface {
  /// Inside a floating [KumoMenuPanel]-styled panel.
  panel,

  /// Bare rows, for a sheet that draws its own surface.
  bare,
}

/// The option list every picker shows: Kumo menu rows with a virtual
/// highlight (the keyboard stays in the field or trigger), a check on
/// selected rows, and group labels and separators.
///
/// Rows are excluded from focus traversal; the owner moves the highlight
/// with the keyboard. Lists longer than [lazyThreshold] rows are built
/// lazily and take [width] (the trigger's width) instead of sizing to their
/// widest row.
class PickerOptionList<T> extends StatefulWidget {
  const PickerOptionList({
    super.key,
    required this.model,
    required this.highlighted,
    required this.isSelected,
    required this.onPick,
    this.onHover,
    this.multiple = false,
    this.reveal,
    this.maxHeight,
    this.width,
    this.semanticLabel,
    this.leading = const [],
    this.trailing = const [],
    this.surface = PickerListSurface.panel,
    this.padding,
    this.showCheck = true,
  });

  static const int lazyThreshold = 100;

  final PickerModel<T> model;
  final int highlighted;
  final bool Function(KumoSelectOption<T> option) isSelected;
  final ValueChanged<KumoSelectOption<T>> onPick;
  final ValueChanged<int>? onHover;
  final bool multiple;
  final PickerRevealController? reveal;
  final double? maxHeight;
  final double? width;
  final String? semanticLabel;

  /// Rows above and below the options: loading and empty states.
  final List<Widget> leading;
  final List<Widget> trailing;
  final PickerListSurface surface;
  final EdgeInsetsGeometry? padding;
  final bool showCheck;

  @override
  State<PickerOptionList<T>> createState() => _PickerOptionListState<T>();
}

class _PickerOptionListState<T> extends State<PickerOptionList<T>> {
  final ScrollController _scroll = ScrollController();
  final Map<int, BuildContext> _rows = {};

  @override
  void initState() {
    super.initState();
    widget.reveal?.addListener(_onReveal);
    if (widget.reveal != null && widget.reveal!.index >= 0) _onReveal();
  }

  @override
  void didUpdateWidget(PickerOptionList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reveal != widget.reveal) {
      oldWidget.reveal?.removeListener(_onReveal);
      widget.reveal?.addListener(_onReveal);
    }
  }

  @override
  void dispose() {
    widget.reveal?.removeListener(_onReveal);
    _scroll.dispose();
    super.dispose();
  }

  void _onReveal() {
    final r = widget.reveal!;
    final index = r.index;
    final center = r.center;
    SchedulerBinding.instance.addPostFrameCallback((_) => _revealRow(index, center: center, retry: true));
  }

  List<double?> _extents = const [];
  double? _measuredWidth;
  final Map<TextStyle, double> _lineHeights = {};
  Object? _extentKey;

  /// The exact height of row [i] at [width], laid out the way
  /// [KumoMenuRow], [KumoMenuGroupLabel] and [KumoMenuSeparator] lay out.
  ///
  /// The sliver asks for every row's extent on each layout, so the common
  /// path is a width check and a list read; theme lookups happen in build.
  double _extent(BuildContext context, int i, double width) {
    if (width != _measuredWidth) {
      _measuredWidth = width;
      _extentKey = null;
    }
    if (_extentKey == null) {
      _extentKey = _extentInputs;
      _extents = List<double?>.filled(widget.model.length, null);
      _lineHeights.clear();
    }
    final cached = _extents[i];
    if (cached != null) return cached;
    final kumo = _kumo!;
    final scaler = _scaler!;
    final dir = _dir!;
    double measureLine(TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: 'Hg', style: style),
        textDirection: dir,
        textScaler: scaler,
      )..layout();
      final h = tp.height;
      tp.dispose();
      return h;
    }

    double measure(String text, TextStyle style, double maxWidth, {int? maxLines}) {
      // No glyph in Kumo's fonts is wider than 1em, so a string shorter
      // than the width in ems fits on one line without a layout pass.
      final em = scaler.scale(style.fontSize ?? 14);
      if (!text.contains('\n') && text.length * em <= maxWidth) {
        return _lineHeights[style] ??= measureLine(style);
      }
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: dir,
        textScaler: scaler,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '\u2026',
      )..layout(maxWidth: math.max(0, maxWidth));
      final h = tp.height;
      tp.dispose();
      return h;
    }

    final e = widget.model.entries[i];
    double h;
    switch (e.kind) {
      case PickerEntryKind.separator:
        h = KumoSpace.s1 * 2 + 1;
      case PickerEntryKind.groupLabel:
        h =
            KumoSpace.s1_5 * 2 +
            measure(
              e.label!,
              kumo.text(size: KumoTextSize.sm, weight: KumoTypography.semibold),
              width - KumoSpace.s2 * 2,
            );
      case PickerEntryKind.option:
        final o = e.option!;
        var textWidth = width - KumoSpace.s2 * 2;
        if (o.icon != null) textWidth -= 16 + KumoSpace.s2;
        if (widget.showCheck) textWidth -= 16 + KumoSpace.s2;
        var content = measure(o.label, kumo.text(), textWidth, maxLines: 2);
        if (o.description != null) content += measure(o.description!, kumo.text(size: KumoTextSize.sm), textWidth);
        h = math.max(kumo.minTapTarget > 0 ? 40.0 : 32.0, content + KumoSpace.s1_5 * 2);
    }
    return _extents[i] = h;
  }

  double _estimatedExtent(PickerEntry<T> e) {
    final kumo = context.kumo;
    final row = math.max(kumo.minTapTarget > 0 ? 40.0 : 32.0, 33.0);
    return switch (e.kind) {
      PickerEntryKind.option => row + (e.option!.description != null ? 20 : 0),
      PickerEntryKind.groupLabel => 32,
      PickerEntryKind.separator => 9,
    };
  }

  void _revealRow(int index, {required bool center, required bool retry}) {
    if (!mounted || !_scroll.hasClients || index < 0 || index >= widget.model.length) return;
    final row = _rows[index];
    final position = _scroll.position;
    final ro = row != null && row.mounted ? row.findRenderObject() : null;
    if (ro == null || !ro.attached) {
      if (!retry) return;
      // The row is not built yet (a lazy list): jump near it by estimate,
      // then line it up exactly once it exists.
      var offset = 0.0;
      final width = _measuredWidth;
      for (var i = 0; i < index; i++) {
        offset += width != null ? _extent(context, i, width) : _estimatedExtent(widget.model.entries[i]);
      }
      if (center) offset -= position.viewportDimension / 2;
      position.jumpTo(offset.clamp(position.minScrollExtent, position.maxScrollExtent));
      SchedulerBinding.instance.addPostFrameCallback((_) => _revealRow(index, center: center, retry: false));
      return;
    }
    final viewport = RenderAbstractViewport.maybeOf(ro);
    if (viewport == null) return;
    final top = viewport.getOffsetToReveal(ro, 0).offset;
    final bottom = viewport.getOffsetToReveal(ro, 1).offset;
    double? target;
    if (center) {
      target = (top + bottom) / 2;
    } else if (position.pixels > top) {
      target = top;
    } else if (position.pixels < bottom) {
      target = bottom;
    }
    if (target != null) position.jumpTo(target.clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  Widget _buildRow(BuildContext context, int i) {
    final e = widget.model.entries[i];
    final Widget row;
    switch (e.kind) {
      case PickerEntryKind.groupLabel:
        row = KumoMenuGroupLabel(e.label!);
      case PickerEntryKind.separator:
        row = const KumoMenuSeparator();
      case PickerEntryKind.option:
        final o = e.option!;
        final selected = widget.isSelected(o);
        row = MouseRegion(
          onEnter: o.disabled || widget.onHover == null ? null : (_) => widget.onHover!(i),
          child: KumoMenuRow(
            label: o.label,
            description: o.description,
            icon: o.icon,
            highlighted: i == widget.highlighted,
            disabled: o.disabled,
            selected: widget.multiple ? null : selected,
            checked: widget.multiple ? selected : null,
            onPress: () => widget.onPick(o),
            trailing: widget.showCheck
                ? SizedBox(width: 16, child: selected ? const KumoIcon(KumoIcons.check, size: 14) : null)
                : null,
          ),
        );
    }
    return PickerRevealTarget(index: i, rows: _rows, child: row);
  }

  KumoThemeData? _kumo;
  TextScaler? _scaler;
  TextDirection? _dir;
  Object? _extentInputs;

  @override
  Widget build(BuildContext context) {
    _kumo = context.kumo;
    _scaler = MediaQuery.textScalerOf(context);
    _dir = Directionality.of(context);
    final inputs = Object.hash(widget.model, _scaler, _kumo!.minTapTarget, _kumo!.typography, widget.showCheck);
    if (inputs != _extentInputs) {
      _extentInputs = inputs;
      _extentKey = null;
    }
    final model = widget.model;
    final lazy = widget.surface == PickerListSurface.bare || model.length > PickerOptionList.lazyThreshold;
    Widget list;
    if (!lazy) {
      list = KumoMenuPanel(
        maxHeight: widget.maxHeight,
        minWidth: widget.width ?? 144,
        scrollController: _scroll,
        semanticLabel: widget.semanticLabel,
        padding: widget.padding ?? const EdgeInsets.all(KumoSpace.s1_5),
        children: [...widget.leading, for (var i = 0; i < model.length; i++) _buildRow(context, i), ...widget.trailing],
      );
    } else {
      final lead = widget.leading.length;
      final count = lead + model.length + widget.trailing.length;
      // With known row heights the list can jump to any row (open on a value
      // far down, End) without building the rows in between.
      final measured = lead == 0 && widget.trailing.isEmpty;
      list = ListView.builder(
        controller: _scroll,
        shrinkWrap: true,
        padding: widget.padding ?? const EdgeInsets.all(KumoSpace.s1_5),
        itemCount: count,
        itemExtentBuilder: measured ? (i, dims) => i < count ? _extent(context, i, dims.crossAxisExtent) : null : null,
        itemBuilder: (context, i) {
          if (i < lead) return widget.leading[i];
          if (i >= lead + model.length) return widget.trailing[i - lead - model.length];
          final row = _buildRow(context, i - lead);
          if (!measured) return row;
          // Guards against sub-pixel differences between measured and laid
          // out heights.
          return ClipRect(
            child: OverflowBox(alignment: Alignment.topCenter, minHeight: 0, maxHeight: double.infinity, child: row),
          );
        },
      );
      if (widget.surface == PickerListSurface.panel) {
        list = PickerPanelSurface(
          width: widget.width,
          maxHeight: widget.maxHeight,
          semanticLabel: widget.semanticLabel,
          child: list,
        );
      } else {
        list = Semantics(container: true, explicitChildNodes: true, label: widget.semanticLabel, child: list);
      }
    }
    // Rows never take focus: the field or trigger keeps it and drives the
    // highlight, so Tab leaves the picker instead of walking its rows.
    return ExcludeFocus(child: list);
  }
}

/// The [KumoMenuPanel] surface around a lazily built list.
class PickerPanelSurface extends StatelessWidget {
  const PickerPanelSurface({super.key, required this.child, this.width, this.maxHeight, this.semanticLabel});

  final Widget child;
  final double? width;
  final double? maxHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    const radius = BorderRadius.all(Radius.circular(KumoRadius.lg));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        width: width,
        constraints: BoxConstraints(minWidth: 144, maxHeight: maxHeight ?? double.infinity),
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: radius,
          border: KumoRing.border(c.line),
          boxShadow: KumoShadow.lg.boxShadows,
        ),
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}

/// Registers its context under [index] in [rows] so a list can scroll to it.
class PickerRevealTarget extends StatefulWidget {
  const PickerRevealTarget({super.key, required this.index, required this.rows, required this.child});

  final int index;
  final Map<int, BuildContext> rows;
  final Widget child;

  @override
  State<PickerRevealTarget> createState() => _PickerRevealTargetState();
}

class _PickerRevealTargetState extends State<PickerRevealTarget> {
  @override
  void initState() {
    super.initState();
    widget.rows[widget.index] = context;
  }

  @override
  void didUpdateWidget(PickerRevealTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.rows != widget.rows) {
      if (identical(oldWidget.rows[oldWidget.index], context)) oldWidget.rows.remove(oldWidget.index);
      widget.rows[widget.index] = context;
    }
  }

  @override
  void dispose() {
    if (identical(widget.rows[widget.index], context)) widget.rows.remove(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A status row inside an option list: "No results", "Loading".
class PickerStatusRow extends StatelessWidget {
  const PickerStatusRow({super.key, required this.text, this.loading = false});

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s2),
        child: Row(
          spacing: KumoSpace.s2,
          children: [
            if (loading)
              const ExcludeSemantics(
                child: KumoLoader(size: KumoLoaderSize.sm, color: KumoColor.textSubtle),
              ),
            Flexible(
              child: Text(text, style: kumo.text(color: KumoColor.textSubtle)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accepts pointer hits up to [inflate] outside its bounds, so a small
/// control (a chip's remove button) gets a touch-sized target without
/// changing layout. Ancestors must reach it: every widget between the
/// field and the control either covers the area or inflates too.
class PickerHitInflate extends SingleChildRenderObjectWidget {
  const PickerHitInflate({
    super.key,
    required this.inflate,
    this.clampPadding = EdgeInsetsDirectional.zero,
    super.child,
  });

  final EdgeInsets inflate;

  /// Hits outside the bounds are moved inside this inset of the box before
  /// they reach the child, so they land on content rather than padding.
  final EdgeInsetsGeometry clampPadding;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitInflate(inflate, clampPadding.resolve(Directionality.of(context)));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    renderObject as _RenderHitInflate;
    renderObject
      ..inflate = inflate
      ..clampPadding = clampPadding.resolve(Directionality.of(context));
  }
}

class _RenderHitInflate extends RenderProxyBox {
  _RenderHitInflate(this.inflate, this.clampPadding);

  EdgeInsets inflate;
  EdgeInsets clampPadding;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (inflate == EdgeInsets.zero) return super.hitTest(result, position: position);
    if (!inflate.inflateRect(Offset.zero & size).contains(position)) return false;
    final inner = clampPadding.deflateRect(Offset.zero & size);
    final clamped = Offset(
      position.dx.clamp(inner.left, math.max(inner.left, inner.right - 0.01)),
      position.dy.clamp(inner.top, math.max(inner.top, inner.bottom - 0.01)),
    );
    if (hitTestChildren(result, position: clamped) || hitTestSelf(clamped)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// The inflation that brings a [visual]-sized control to the theme's
/// minimum touch target. Zero with a mouse.
EdgeInsets pickerTouchInflate(BuildContext context, Size visual) {
  final min = context.kumo.minTapTarget;
  if (min <= 0) return EdgeInsets.zero;
  final h = math.max(0.0, (min - visual.width) / 2);
  final v = math.max(0.0, (min - visual.height) / 2);
  return EdgeInsets.symmetric(horizontal: h, vertical: v);
}

/// A removable value chip (Kumo's `Combobox.Chip` and the tag input's tag):
/// `h-6 pl-2 pr-[3px] rounded-sm bg-kumo-overlay ring-1 ring-kumo-hairline
/// text-sm`, with an X button.
class PickerChip extends StatelessWidget {
  const PickerChip({
    super.key,
    required this.label,
    required this.removeLabel,
    this.onRemove,
    this.disabled = false,
    this.removeSize = 18,
  });

  final String label;
  final String removeLabel;
  final VoidCallback? onRemove;
  final bool disabled;

  /// Edge of the X button's visual: 18 (`p-1` around a 10px icon) for the
  /// combobox chip, 20 (an `xs` square button) for tags.
  final double removeSize;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final inflate = pickerTouchInflate(context, Size.square(removeSize));
    final remove = PickerHitInflate(
      inflate: inflate,
      child: KumoPressable(
        onPress: disabled ? null : onRemove,
        disabled: disabled,
        minTapTargetSize: 0,
        scaleOnPress: false,
        semanticLabel: removeLabel,
        excludeChildSemantics: true,
        borderRadius: BorderRadius.circular(KumoRadius.md),
        builder: (context, state) => Container(
          width: removeSize,
          height: removeSize,
          decoration: BoxDecoration(
            color: state.active ? c.fillHover : null,
            borderRadius: BorderRadius.circular(KumoRadius.md),
          ),
          alignment: Alignment.center,
          child: const KumoIcon(KumoIcons.x, size: 10),
        ),
      ),
    );
    return PickerHitInflate(
      inflate: inflate,
      clampPadding: const EdgeInsetsDirectional.only(start: KumoSpace.s2, end: 3),
      child: Semantics(
        container: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 24),
          padding: const EdgeInsetsDirectional.only(start: KumoSpace.s2, end: 3),
          decoration: BoxDecoration(
            color: c.overlay,
            borderRadius: BorderRadius.circular(KumoRadius.sm),
            border: KumoRing.border(c.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: KumoSpace.s2_5,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kumo.text(size: KumoTextSize.sm),
                ),
              ),
              remove,
            ],
          ),
        ),
      ),
    );
  }
}

/// Animates chips in and out of a [PickerChipWrap]: a new chip grows from
/// zero width and fades in, a removed one shrinks and fades the way it came
/// while the chips after it slide over. A chip removed and added back while
/// it is leaving turns around from where it is. Chips present on the first
/// build, and every change under reduced motion, appear at once.
///
/// The owner keeps one per field, calls [build] with keyed chips on every
/// build, and [dispose]s it.
class PickerChipMotion {
  PickerChipMotion({required this.vsync, required this.onChanged});

  final TickerProvider vsync;

  /// Rebuilds the owner after a leaving chip is gone.
  final VoidCallback onChanged;

  final Map<Key, ({AnimationController controller, CurvedAnimation curve})> _motions = {};
  final Map<Key, Widget> _leaving = {};
  List<Key> _order = const [];
  final Map<Key, Widget> _last = {};
  bool _first = true;

  ({AnimationController controller, CurvedAnimation curve}) _motionFor(Key key, {required bool entering}) {
    return _motions.putIfAbsent(key, () {
      final controller = AnimationController(vsync: vsync, duration: KumoDurations.quick, value: entering ? 0 : 1);
      final curve = CurvedAnimation(parent: controller, curve: KumoCurves.enter, reverseCurve: KumoCurves.exit);
      controller.addStatusListener((status) {
        if (status == AnimationStatus.dismissed && _leaving.containsKey(key)) {
          _leaving.remove(key);
          _forget(key);
          onChanged();
        }
      });
      return (controller: controller, curve: curve);
    });
  }

  void _forget(Key key) {
    final m = _motions.remove(key);
    m?.curve.dispose();
    m?.controller.dispose();
    _last.remove(key);
  }

  /// [chips] must carry distinct keys.
  List<Widget> build(BuildContext context, List<Widget> chips) {
    final reduce = KumoMotion.reduceMotion(context);
    final keys = [for (final c in chips) c.key!];
    final present = keys.toSet();
    for (final key in _order) {
      if (present.contains(key) || _leaving.containsKey(key)) continue;
      final m = _motions[key];
      if (reduce || m == null) {
        _forget(key);
        continue;
      }
      _leaving[key] = _last[key]!;
      m.controller.reverse();
    }
    for (var i = 0; i < chips.length; i++) {
      final key = keys[i];
      final returning = _leaving.remove(key) != null;
      final m = _motionFor(key, entering: !_first && !reduce);
      if (reduce) {
        m.controller.value = 1;
      } else if (returning || m.controller.value < 1) {
        m.controller.forward();
      }
      _last[key] = chips[i];
    }
    _first = false;

    // Leaving chips keep their place after the chip that came before them.
    final order = List<Key>.of(keys);
    for (var i = 0; i < _order.length; i++) {
      final key = _order[i];
      if (!_leaving.containsKey(key)) continue;
      var at = 0;
      for (var j = i - 1; j >= 0; j--) {
        final before = order.indexOf(_order[j]);
        if (before >= 0) {
          at = before + 1;
          break;
        }
      }
      order.insert(at, key);
    }
    _order = order;

    return [
      for (final key in order)
        _AnimatedChip(
          key: key,
          animation: _motions[key]!.curve,
          leaving: _leaving.containsKey(key),
          child: _last[key]!,
        ),
    ];
  }

  void dispose() {
    for (final m in _motions.values) {
      m.curve.dispose();
      m.controller.dispose();
    }
    _motions.clear();
  }
}

class _AnimatedChip extends AnimatedWidget {
  const _AnimatedChip({super.key, required Animation<double> animation, required this.leaving, required this.child})
    : super(listenable: animation);

  final bool leaving;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value.clamp(0.0, 1.0);
    return PickerChipPresence(
      presence: t,
      child: ExcludeFocus(
        excluding: leaving,
        child: _ChipReveal(factor: t, leaving: leaving, textDirection: Directionality.of(context), child: child),
      ),
    );
  }
}

/// Shows the start [factor] of a chip's width, faded by the same amount. At
/// rest it hit-tests its child without checking its own bounds, so a chip's
/// inflated touch target keeps working; while leaving it takes no hits and
/// drops out of the semantics tree.
class _ChipReveal extends SingleChildRenderObjectWidget {
  const _ChipReveal({required this.factor, required this.leaving, required this.textDirection, super.child});

  final double factor;
  final bool leaving;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderChipReveal(factor: factor, leaving: leaving, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderChipReveal)
      ..factor = factor
      ..leaving = leaving
      ..textDirection = textDirection;
  }
}

class _RenderChipReveal extends RenderProxyBox {
  _RenderChipReveal({required double factor, required bool leaving, required TextDirection textDirection})
    : _factor = factor,
      _leaving = leaving,
      _textDirection = textDirection;

  double _factor;
  set factor(double v) {
    if (v == _factor) return;
    _factor = v;
    markNeedsLayout();
  }

  bool _leaving;
  set leaving(bool v) {
    if (v == _leaving) return;
    _leaving = v;
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsPaint();
  }

  double get _dx => _textDirection == TextDirection.rtl ? size.width - child!.size.width : 0;

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(Size(c.size.width * _factor, c.size.height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final s = child?.getDryLayout(constraints.loosen()) ?? Size.zero;
    return constraints.constrain(Size(s.width * _factor, s.height));
  }

  @override
  double computeMinIntrinsicWidth(double height) => super.computeMinIntrinsicWidth(height) * _factor;

  @override
  double computeMaxIntrinsicWidth(double height) => super.computeMaxIntrinsicWidth(height) * _factor;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null || _factor <= 0) return;
    void paintChild(PaintingContext context, Offset offset) => context.paintChild(c, offset + Offset(_dx, 0));
    if (_factor >= 1) {
      paintChild(context, offset);
      return;
    }
    final alpha = (_factor * 255).round();
    context.pushOpacity(offset, alpha, (context, offset) {
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, paintChild);
    });
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.translateByDouble(_dx, 0, 0, 1);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_leaving || _factor < 1 || child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(_dx, 0),
      position: position,
      hitTest: (result, transformed) => child!.hitTest(result, position: transformed),
    );
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_leaving) super.visitChildrenForSemantics(visitor);
  }
}

/// Lays chips out in wrapping lines and gives the last child (the text
/// input) the rest of the last line, or a fresh line when less than
/// [fillMinWidth] is left. Its own size includes [padding] so taps in the
/// field's padding still reach inflated chip targets.
class PickerChipWrap extends MultiChildRenderObjectWidget {
  const PickerChipWrap({
    super.key,
    required super.children,
    this.spacing = KumoSpace.s1_5,
    this.runSpacing = KumoSpace.s1_5,
    this.padding = EdgeInsets.zero,
    this.fillMinWidth = 100,
    this.hasFill = true,
  });

  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry padding;
  final double fillMinWidth;

  /// Whether the last child fills the rest of its line.
  final bool hasFill;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final dir = Directionality.of(context);
    return _RenderChipWrap(
      textDirection: dir,
      spacing: spacing,
      runSpacing: runSpacing,
      padding: padding.resolve(dir),
      fillMinWidth: fillMinWidth,
      hasFill: hasFill,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    renderObject as _RenderChipWrap;
    final dir = Directionality.of(context);
    renderObject
      ..textDirection = dir
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..padding = padding.resolve(dir)
      ..fillMinWidth = fillMinWidth
      ..hasFill = hasFill;
  }
}

class _ChipWrapParentData extends ContainerBoxParentData<RenderBox> {
  /// 1 for a chip at rest, toward 0 while it enters or leaves.
  double presence = 1;
}

/// Tells [PickerChipWrap] how present a chip is while it enters or leaves,
/// so the gap before it opens and closes with it and the chips after it
/// slide instead of jumping by the gap when it goes.
class PickerChipPresence extends ParentDataWidget<_ChipWrapParentData> {
  const PickerChipPresence({super.key, required this.presence, required super.child});

  final double presence;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _ChipWrapParentData;
    if (data.presence == presence) return;
    data.presence = presence;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => PickerChipWrap;
}

class _RenderChipWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ChipWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ChipWrapParentData> {
  _RenderChipWrap({
    required TextDirection textDirection,
    required double spacing,
    required double runSpacing,
    required EdgeInsets padding,
    required double fillMinWidth,
    required bool hasFill,
  }) : _textDirection = textDirection,
       _spacing = spacing,
       _runSpacing = runSpacing,
       _padding = padding,
       _fillMinWidth = fillMinWidth,
       _hasFill = hasFill;

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double v) {
    if (v == _spacing) return;
    _spacing = v;
    markNeedsLayout();
  }

  double _runSpacing;
  set runSpacing(double v) {
    if (v == _runSpacing) return;
    _runSpacing = v;
    markNeedsLayout();
  }

  EdgeInsets _padding;
  set padding(EdgeInsets v) {
    if (v == _padding) return;
    _padding = v;
    markNeedsLayout();
  }

  double _fillMinWidth;
  set fillMinWidth(double v) {
    if (v == _fillMinWidth) return;
    _fillMinWidth = v;
    markNeedsLayout();
  }

  bool _hasFill;
  set hasFill(bool v) {
    if (v == _hasFill) return;
    _hasFill = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ChipWrapParentData) child.parentData = _ChipWrapParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var w = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      w = math.max(w, child.getMinIntrinsicWidth(double.infinity));
    }
    return w + _padding.horizontal;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var w = 0.0;
    var count = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      w += child.getMaxIntrinsicWidth(double.infinity);
      count++;
    }
    return w + math.max(0, count - 1) * _spacing + _padding.horizontal;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _layout(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final maxW = constraints.hasBoundedWidth
        ? math.max(0.0, constraints.maxWidth - _padding.horizontal)
        : double.infinity;
    final children = <RenderBox>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      children.add(child);
    }
    final sizes = <Size>[];
    final xs = <double>[];
    final lines = <int>[];
    var line = 0;
    var x = 0.0;
    // The most present chip on the line so far. The gap before a chip scales
    // with its own presence and with this, so a chip entering or leaving at
    // the start of a line takes the gap after it along.
    var linePresence = 0.0;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final presence = (child.parentData! as _ChipWrapParentData).presence.clamp(0.0, 1.0);
      final isFill = _hasFill && i == children.length - 1;
      Size s;
      double gap() => x > 0 ? _spacing * presence * math.min(1.0, linePresence) : 0;
      if (isFill) {
        var remaining = maxW.isFinite ? maxW - x - gap() : _fillMinWidth;
        if (x > 0 && remaining < _fillMinWidth) {
          line++;
          x = 0;
          linePresence = 0;
          remaining = maxW.isFinite ? maxW : _fillMinWidth;
        }
        final c = BoxConstraints.tightFor(width: math.max(0.0, remaining));
        s = dry ? child.getDryLayout(c) : (child..layout(c, parentUsesSize: true)).size;
      } else {
        final c = BoxConstraints(maxWidth: maxW);
        s = dry ? child.getDryLayout(c) : (child..layout(c, parentUsesSize: true)).size;
        if (x > 0 && maxW.isFinite && x + gap() + s.width > maxW) {
          line++;
          x = 0;
          linePresence = 0;
        }
      }
      x += gap();
      linePresence = math.max(linePresence, presence);
      xs.add(x);
      lines.add(line);
      sizes.add(s);
      x += s.width;
    }
    final lineCount = children.isEmpty ? 0 : line + 1;
    final heights = List<double>.filled(lineCount, 0);
    var widest = 0.0;
    for (var i = 0; i < children.length; i++) {
      heights[lines[i]] = math.max(heights[lines[i]], sizes[i].height);
      widest = math.max(widest, xs[i] + sizes[i].width);
    }
    final tops = List<double>.filled(lineCount, 0);
    var y = 0.0;
    for (var l = 0; l < lineCount; l++) {
      tops[l] = y;
      y += heights[l] + (l < lineCount - 1 ? _runSpacing : 0);
    }
    final contentW = maxW.isFinite ? maxW : widest;
    if (!dry) {
      final rtl = _textDirection == TextDirection.rtl;
      for (var i = 0; i < children.length; i++) {
        final pd = children[i].parentData! as _ChipWrapParentData;
        final dy = tops[lines[i]] + (heights[lines[i]] - sizes[i].height) / 2;
        final dx = rtl ? contentW - xs[i] - sizes[i].width : xs[i];
        pd.offset = Offset(_padding.left + dx, _padding.top + dy);
      }
    }
    return constraints.constrain(Size(contentW + _padding.horizontal, y + _padding.vertical));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  // Chips first, in order: their inflated remove targets may reach into
  // the input's area, and the X should win there.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final pd = child.parentData! as _ChipWrapParentData;
      final hit = result.addWithPaintOffset(
        offset: pd.offset,
        position: position,
        hitTest: (result, transformed) => child!.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// Default width for a picker placed where width is unbounded (a Row):
/// Kumo's input widths per size (`KUMO_INPUT_STYLING`).
double pickerDefaultWidth(KumoFieldSize size) => switch (size) {
  KumoFieldSize.xs => 160,
  KumoFieldSize.sm => 200,
  KumoFieldSize.base => 280,
  KumoFieldSize.lg => 320,
};

/// Gives [child] Kumo's default field width when the parent leaves width
/// unbounded, and fills the parent otherwise.
class PickerWidth extends StatelessWidget {
  const PickerWidth({super.key, required this.size, required this.child});

  final KumoFieldSize size;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.hasBoundedWidth ? child : SizedBox(width: pickerDefaultWidth(size), child: child),
  );
}

/// Caret icon size per field size (`CaretUpDownIcon` sizes in Kumo).
double pickerIconSize(KumoFieldSize size) => switch (size) {
  KumoFieldSize.xs => 12,
  KumoFieldSize.sm => 14,
  KumoFieldSize.base => 16,
  KumoFieldSize.lg => 18,
};

/// Room for a popup under and above [anchor], with the on-screen keyboard
/// taken off the bottom. [KumoAnchoredOverlay] measures against the whole
/// screen, so a field near the bottom of a phone would open its list under
/// the keyboard without this.
({double below, double above, Rect? rect}) pickerRoom(BuildContext anchor, {double sideOffset = 4}) {
  final box = anchor.findRenderObject();
  final media = MediaQuery.maybeOf(anchor);
  if (box is! RenderBox || !box.hasSize || !box.attached || media == null) {
    return (below: double.infinity, above: 0, rect: null);
  }
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final bottomLimit = media.size.height - math.max(media.viewInsets.bottom, media.viewPadding.bottom) - 8;
  final topLimit = media.viewPadding.top + 8;
  return (below: bottomLimit - rect.bottom - sideOffset, above: rect.top - sideOffset - topLimit, rect: rect);
}

/// The side to open on: [preferred] unless it has under [wanted] of room
/// and the other side has more.
KumoSide pickerSide(
  BuildContext anchor, {
  KumoSide preferred = KumoSide.bottom,
  double wanted = 200,
  double sideOffset = 4,
}) {
  final room = pickerRoom(anchor, sideOffset: sideOffset);
  if (room.rect == null) return preferred;
  if (preferred == KumoSide.bottom && room.below < wanted && room.above > room.below) return KumoSide.top;
  if (preferred == KumoSide.top && room.above < wanted && room.below > room.above) return KumoSide.bottom;
  return preferred;
}

/// The list height for [placement], clipped to the room above the keyboard.
double pickerMaxHeight(
  BuildContext context,
  KumoPopupPlacement placement, {
  double cap = double.infinity,
  double sideOffset = 4,
}) {
  var h = math.min(placement.maxHeight, cap);
  final media = MediaQuery.maybeOf(context);
  if (media != null && placement.side == KumoSide.bottom) {
    final limit = media.size.height - math.max(media.viewInsets.bottom, media.viewPadding.bottom) - 8;
    h = math.min(h, limit - placement.anchorRect.bottom - sideOffset);
  }
  return math.max(h, 48);
}
