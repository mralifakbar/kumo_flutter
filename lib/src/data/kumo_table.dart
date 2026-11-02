import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../feedback/kumo_loader.dart';
import '../feedback/kumo_swap.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'data_checkbox.dart';
import 'data_hover_scope.dart';
import 'data_scroll_fade.dart';

/// How a [KumoTable] lays out its rows.
enum KumoTableLayout {
  /// Columns and rows. Scrolls sideways when the columns do not fit.
  table,

  /// One stacked card per row: the first column as the title, the others
  /// as label and value pairs. Reads better on phones.
  cards,

  /// [cards] below 768px, [table] from there up.
  auto,
}

/// Header styles (Kumo `Table.Header` `variant`).
enum KumoTableHeaderVariant {
  /// Kumo `default`: 14px semibold on `bg-kumo-base`, 12px padding.
  standard,

  /// Kumo `compact`: 12px `text-kumo-strong` on `bg-kumo-elevated`, 8px
  /// vertical padding.
  compact,
}

/// Row padding.
enum KumoTableDensity {
  /// Kumo's `p-3`: 12px around every cell.
  standard,

  /// 8px vertical, 12px horizontal, for long lists.
  compact,
}

/// Horizontal alignment of a column's header and cells.
enum KumoTableAlign { start, center, end }

/// Sort order of a column.
enum KumoTableSortDirection { ascending, descending }

/// Edge a column stays pinned to while the table scrolls sideways (Kumo's
/// `sticky="left"` and `sticky="right"`, flipped in right-to-left layouts).
enum KumoTableColumnPin { start, end }

/// The column a [KumoTable] is sorted by.
///
/// ```dart
/// KumoTableSort('requests', KumoTableSortDirection.descending)
/// ```
@immutable
class KumoTableSort {
  const KumoTableSort(this.columnId, this.direction);

  final String columnId;
  final KumoTableSortDirection direction;

  /// The sort a header press moves to: ascending first, then it flips.
  KumoTableSort toggled(String id) => columnId == id && direction == KumoTableSortDirection.ascending
      ? KumoTableSort(id, KumoTableSortDirection.descending)
      : KumoTableSort(id, KumoTableSortDirection.ascending);

  @override
  bool operator ==(Object other) => other is KumoTableSort && other.columnId == columnId && other.direction == direction;

  @override
  int get hashCode => Object.hash(columnId, direction);

  @override
  String toString() => 'KumoTableSort($columnId, ${direction.name})';
}

/// Width of a [KumoTableColumn]. Widths are fixed or flexible, never
/// measured from content, which is what lets rows build lazily.
@immutable
class KumoTableColumnWidth {
  /// Exactly [width] pixels (a `<col>` width with `layout="fixed"`).
  const KumoTableColumnWidth.fixed(double this.width)
      : flex = 0,
        minWidth = width;

  /// A share of the room left after fixed columns, never narrower than
  /// [minWidth]. When the minimums do not fit, the table scrolls sideways.
  const KumoTableColumnWidth.flex([this.flex = 1, this.minWidth = 120])
      : width = null,
        assert(flex > 0);

  final double? width;
  final int flex;
  final double minWidth;
}

/// One column of a [KumoTable].
///
/// ```dart
/// KumoTableColumn<Worker>(
///   id: 'requests',
///   label: 'Requests',
///   numeric: true,
///   sortable: true,
///   width: const KumoTableColumnWidth.fixed(120),
///   cell: (context, worker) => Text('${worker.requests}'),
/// )
/// ```
@immutable
class KumoTableColumn<T> {
  const KumoTableColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.header,
    this.width = const KumoTableColumnWidth.flex(),
    this.align,
    this.numeric = false,
    this.sortable = false,
    this.pin,
    this.showInCards = true,
  });

  /// Stable id, used by [KumoTableSort].
  final String id;

  /// Header text, sentence case. An empty label (an actions column) still
  /// names the column for screen readers if you pass [header] with a
  /// semantic label.
  final String label;

  /// Builds the cell for a row. Return text or a small widget; cells wrap
  /// rather than clip.
  final Widget Function(BuildContext context, T row) cell;

  /// Custom header content in place of [label].
  final Widget? header;
  final KumoTableColumnWidth width;

  /// Defaults to [KumoTableAlign.end] for [numeric] columns, else start.
  final KumoTableAlign? align;

  /// Numbers: right-aligned (end-aligned in RTL) with tabular figures, so
  /// digits line up down the column.
  final bool numeric;

  /// The header becomes a button that calls [KumoTable.onSortChange].
  final bool sortable;

  /// Keep the column visible while the table scrolls sideways. Pin only
  /// leading columns to [KumoTableColumnPin.start] and trailing ones to
  /// [KumoTableColumnPin.end]. A pinned cell takes the row's height.
  final KumoTableColumnPin? pin;

  /// Include this column in [KumoTableLayout.cards].
  final bool showInCards;

  KumoTableAlign get resolvedAlign => align ?? (numeric ? KumoTableAlign.end : KumoTableAlign.start);
}

/// The content of an empty, loading or error table body: an icon, a title
/// naming the cause, a description and an optional action.
///
/// ```dart
/// KumoTablePlaceholder(
///   icon: KumoIcons.warningCircle,
///   title: 'Could not load Workers',
///   description: 'The API did not respond. Check your connection and retry.',
///   action: KumoButton(label: 'Retry', onPress: reload),
/// )
/// ```
class KumoTablePlaceholder extends StatelessWidget {
  const KumoTablePlaceholder({
    super.key,
    required this.title,
    this.icon,
    this.description,
    this.action,
    this.iconColor = KumoColor.textSubtle,
  });

  final String title;
  final IconData? icon;
  final String? description;
  final Widget? action;
  final KumoColor iconColor;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[KumoIcon(icon!, size: 24, color: iconColor), const SizedBox(height: KumoSpace.s3)],
          Text(title, textAlign: TextAlign.center, style: kumo.text(weight: KumoTypography.medium)),
          if (description != null) ...[
            const SizedBox(height: KumoSpace.s1),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
            ),
          ],
          if (action != null) ...[const SizedBox(height: KumoSpace.s4), action!],
        ],
      ),
    );
  }
}

/// Kumo's `Table`: rows of data under a header, with sorting, selection,
/// pinned columns and a card layout for phones.
///
/// ```dart
/// KumoTable<Worker>(
///   rows: workers,
///   rowId: (w) => w.name,
///   columns: [
///     KumoTableColumn(id: 'name', label: 'Name', cell: (context, w) => Text(w.name)),
///     KumoTableColumn(
///       id: 'requests',
///       label: 'Requests',
///       numeric: true,
///       sortable: true,
///       cell: (context, w) => Text('${w.requests}'),
///     ),
///   ],
///   sort: sort,
///   onSortChange: (next) => setState(() => sort = next),
///   selected: selected,
///   onSelectionChange: (ids) => setState(() => selected = ids),
/// )
/// ```
///
/// * Controlled: the table never sorts or selects by itself. It reports
///   header presses through [onSortChange] and checkbox presses through
///   [onSelectionChange]; you pass back the sorted [rows] and the new
///   [selected] set.
/// * Given a bounded height, rows build lazily, so thousands of rows are
///   fine, and the header stays put above them ([stickyHeader]). Inside an
///   unbounded parent (a scrolling page) every row is built.
/// * When the columns' minimum widths exceed the room, the table scrolls
///   sideways; the cut-off edge fades to show there is more.
/// * Rows are striped like Kumo's (`even:bg-kumo-elevated`); selected rows
///   take `bg-kumo-tint`.
/// * Pass [empty], [error] or [loading] for the body's other states.
class KumoTable<T> extends StatefulWidget {
  const KumoTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowId,
    this.layout = KumoTableLayout.table,
    this.headerVariant = KumoTableHeaderVariant.standard,
    this.density = KumoTableDensity.standard,
    this.striped = true,
    this.stickyHeader = true,
    this.sort,
    this.onSortChange,
    this.selected,
    this.onSelectionChange,
    this.rowLabel,
    this.onRowPress,
    this.loading = false,
    this.error,
    this.empty,
    this.footer,
    this.semanticLabel,
    this.controller,
  }) : assert(selected == null || rowId != null, 'Selection needs rowId');

  final List<KumoTableColumn<T>> columns;
  final List<T> rows;

  /// A stable id per row, for selection and keys.
  final Object Function(T row)? rowId;
  final KumoTableLayout layout;
  final KumoTableHeaderVariant headerVariant;
  final KumoTableDensity density;

  /// Tint every other row with `bg-kumo-elevated`.
  final bool striped;

  /// With a bounded height, keep the header above the scrolling rows. It is
  /// separated from them by a border (Kumo rule: sticky elements get one).
  final bool stickyHeader;

  /// The current sort, shown by the header's arrow. Null shows none.
  final KumoTableSort? sort;

  /// Called with the next sort when a sortable header is pressed.
  final ValueChanged<KumoTableSort>? onSortChange;

  /// Selected row ids. Non-null adds a checkbox column (Kumo's
  /// `Table.CheckHead` and `Table.CheckCell`).
  final Set<Object>? selected;
  final ValueChanged<Set<Object>>? onSelectionChange;

  /// A short name for a row, used by screen readers for the row and its
  /// checkbox ("Select image-resizer").
  final String Function(T row)? rowLabel;

  /// Makes rows pressable (open a detail view). Rows show the tint on
  /// hover and from the moment a finger lands.
  final ValueChanged<T>? onRowPress;

  /// Shows a loader in the body in place of the rows.
  final bool loading;

  /// Shown in the body in place of the rows, usually a [KumoTablePlaceholder].
  final Widget? error;

  /// Shown when [rows] is empty. Defaults to a placeholder reading
  /// [KumoStrings.noResults].
  final Widget? empty;

  /// Below the last row (Kumo `Table.Footer`), for totals or pagination.
  final Widget? footer;

  /// Names the table for screen readers.
  final String? semanticLabel;

  /// Vertical scroll controller for the lazy rows.
  final ScrollController? controller;

  @override
  State<KumoTable<T>> createState() => _KumoTableState<T>();
}

class _KumoTableState<T> extends State<KumoTable<T>> with SingleTickerProviderStateMixin {
  final ScrollController _horizontal = ScrollController();

  /// Fades the rows back in after the sort changes, so a re-sorted list
  /// reads as new content instead of a flash. Rows never animate their
  /// layout: a table can hold thousands of them.
  late final AnimationController _reorder;
  late final Animation<double> _rowOpacity;

  @override
  void initState() {
    super.initState();
    _reorder = AnimationController(vsync: this, duration: KumoDurations.quick, value: 1);
    _rowOpacity = _reorder.drive(Tween<double>(begin: 0.2, end: 1).chain(CurveTween(curve: KumoCurves.enter)));
  }

  @override
  void didUpdateWidget(KumoTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final resorted = oldWidget.sort != widget.sort && widget.rows.isNotEmpty;
    // Loading, error, empty and rows swap by fading the new body in.
    final swapped = _bodyKind(oldWidget) != _bodyKind(widget);
    if ((resorted || swapped) && !KumoMotion.reduceMotion(context)) _reorder.forward(from: 0);
  }

  static int _bodyKind(KumoTable<Object?> table) {
    if (table.loading) return 0;
    if (table.error != null) return 1;
    return table.rows.isEmpty ? 2 : 3;
  }

  @override
  void dispose() {
    _reorder.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  bool get _selectable => widget.selected != null;

  Object _id(T row) => widget.rowId?.call(row) ?? row as Object;

  bool _isSelected(T row) => widget.selected?.contains(_id(row)) ?? false;

  void _toggleRow(T row, bool value) {
    final next = {...?widget.selected};
    value ? next.add(_id(row)) : next.remove(_id(row));
    widget.onSelectionChange?.call(next);
  }

  void _toggleAll(bool value) {
    final next = {...?widget.selected};
    for (final row in widget.rows) {
      value ? next.add(_id(row)) : next.remove(_id(row));
    }
    widget.onSelectionChange?.call(next);
  }

  Widget? _bodyState(BuildContext context) {
    final state = _bodyStateContent(context);
    return state == null ? null : FadeTransition(opacity: _rowOpacity, child: state);
  }

  Widget? _bodyStateContent(BuildContext context) {
    final strings = context.kumoStrings;
    if (widget.loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: KumoSpace.s10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KumoLoader(semanticLabel: strings.loading),
            const SizedBox(height: KumoSpace.s3),
            ExcludeSemantics(
              child: Text(strings.loading, style: context.kumo.text(color: KumoColor.textSubtle)),
            ),
          ],
        ),
      );
    }
    if (widget.error != null) return widget.error;
    if (widget.rows.isEmpty) {
      return widget.empty ?? KumoTablePlaceholder(icon: KumoIcons.tray, title: strings.noResults);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cards = switch (widget.layout) {
      KumoTableLayout.cards => true,
      KumoTableLayout.auto => context.kumoIsNarrow,
      KumoTableLayout.table => false,
    };
    final result = cards ? _buildCards(context) : _buildTable(context);
    return Semantics(container: true, label: widget.semanticLabel, explicitChildNodes: true, child: result);
  }

  Widget _buildTable(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = widget.columns;
        final checkWidth = math.max(40.0, kumo.minTapTarget);
        final lead = _selectable ? checkWidth : 0.0;
        var minTotal = lead;
        var fixedTotal = lead;
        var flexTotal = 0;
        var flexMin = 0.0;
        for (final col in columns) {
          minTotal += col.width.minWidth;
          if (col.width.width != null) {
            fixedTotal += col.width.width!;
          } else {
            flexTotal += col.width.flex;
            flexMin += col.width.minWidth;
          }
        }
        final available = constraints.hasBoundedWidth ? constraints.maxWidth : minTotal;
        final tableWidth = math.max(available, minTotal);
        final extra = math.max(0.0, tableWidth - fixedTotal - flexMin);
        final widths = <double>[
          if (_selectable) checkWidth,
          for (final col in columns)
            col.width.width ?? col.width.minWidth + (flexTotal == 0 ? 0 : extra * col.width.flex / flexTotal),
        ];
        final anyStartPin = columns.any((col) => col.pin == KumoTableColumnPin.start);
        final pins = <KumoTableColumnPin?>[
          if (_selectable) anyStartPin ? KumoTableColumnPin.start : null,
          for (final col in columns) col.pin,
        ];
        final scrolls = tableWidth > available + 0.5;
        final controller = scrolls ? _horizontal : null;
        final bounded = constraints.hasBoundedHeight;

        final header = _header(context, widths, pins, controller, checkWidth);
        final state = _bodyState(context);
        final footer = widget.footer == null
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.fill))),
                child: widget.footer,
              );

        Widget rowAt(int i) => _row(context, i, widths, pins, controller, checkWidth);

        Widget grid;
        if (state != null) {
          // States are not table content; keep them at the viewport's width.
          final head = scrolls ? _scroll(SizedBox(width: tableWidth, child: header), c.base) : header;
          grid = Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [head, if (bounded) Expanded(child: _fill(state)) else state, ?footer],
          );
          return grid;
        }

        if (bounded) {
          final sticky = widget.stickyHeader;
          final extraItems = (sticky ? 0 : 1) + (footer != null ? 1 : 0);
          final list = ListView.builder(
            controller: widget.controller,
            padding: EdgeInsets.zero,
            itemCount: widget.rows.length + extraItems,
            itemBuilder: (context, i) {
              if (!sticky && i == 0) return header;
              final index = sticky ? i : i - 1;
              if (index >= widget.rows.length) return footer!;
              return rowAt(index);
            },
          );
          grid = sticky
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, Expanded(child: list)])
              : list;
          grid = SizedBox(width: tableWidth, height: constraints.maxHeight, child: grid);
        } else {
          grid = SizedBox(
            width: tableWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, for (var i = 0; i < widget.rows.length; i++) rowAt(i), ?footer],
            ),
          );
        }
        return scrolls ? _scroll(grid, c.base) : grid;
      },
    );
  }

  /// Centers a body state in the room left, scrolling if large text makes
  /// it taller than that.
  Widget _fill(Widget state) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: state),
          ),
        ),
      );

  Widget _scroll(Widget child, Color fade) => DataScrollFade(
        controller: _horizontal,
        color: fade,
        child: SingleChildScrollView(controller: _horizontal, scrollDirection: Axis.horizontal, child: child),
      );

  EdgeInsets _cellPadding({required bool header}) {
    final compact = header
        ? widget.headerVariant == KumoTableHeaderVariant.compact
        : widget.density == KumoTableDensity.compact;
    return EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: compact ? KumoSpace.s2 : KumoSpace.s3);
  }

  static AlignmentDirectional _alignment(KumoTableAlign align) => switch (align) {
        KumoTableAlign.start => AlignmentDirectional.centerStart,
        KumoTableAlign.center => AlignmentDirectional.center,
        KumoTableAlign.end => AlignmentDirectional.centerEnd,
      };

  Widget _header(
    BuildContext context,
    List<double> widths,
    List<KumoTableColumnPin?> pins,
    ScrollController? controller,
    double checkWidth,
  ) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final compact = widget.headerVariant == KumoTableHeaderVariant.compact;
    final background = compact ? c.elevated : c.base;
    final style = compact
        ? kumo.text(size: KumoTextSize.xs, weight: KumoTypography.semibold, color: KumoColor.textStrong)
        : kumo.text(weight: KumoTypography.semibold);
    final padding = _cellPadding(header: true);

    final cells = <Widget>[];
    if (_selectable) {
      final ids = widget.rows.map(_id);
      final count = ids.where(widget.selected!.contains).length;
      final all = widget.rows.isNotEmpty && count == widget.rows.length;
      cells.add(Center(
        child: DataCheckbox(
          checked: all,
          mixed: count > 0 && !all,
          disabled: widget.rows.isEmpty,
          semanticLabel: strings.selectAll,
          hitArea: Size(checkWidth, math.max(40, kumo.minTapTarget)),
          onChanged: widget.onSelectionChange == null ? null : (_) => _toggleAll(!all),
        ),
      ));
    }
    for (final col in widget.columns) {
      final align = col.resolvedAlign;
      final sorted = widget.sort?.columnId == col.id ? widget.sort!.direction : null;
      Widget label = col.header ?? Text(col.label, style: style);
      if (col.sortable) {
        final icon = _SortIndicator(
          direction: sorted,
          color: compact ? KumoColor.textStrong : KumoColor.textDefault,
        );
        final next = (widget.sort ?? KumoTableSort(col.id, KumoTableSortDirection.descending)).toggled(col.id);
        label = Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1,
          children: align == KumoTableAlign.end
              ? [icon, Flexible(child: label)]
              : [Flexible(child: label), icon],
        );
        cells.add(KumoPressable(
          onPress: widget.onSortChange == null ? null : () => widget.onSortChange!(next),
          semanticLabel: col.label,
          // aria-sort, read as the button's value.
          semanticValue: switch (sorted) {
            KumoTableSortDirection.ascending => context.kumoStrings.sortedAscending,
            KumoTableSortDirection.descending => context.kumoStrings.sortedDescending,
            null => null,
          },
          semanticHint: next.direction == KumoTableSortDirection.ascending ? strings.sortAscending : strings.sortDescending,
          excludeChildSemantics: true,
          scaleOnPress: false,
          minTapTargetSize: 0,
          focusRingOffset: -2,
          builder: (context, state) => Container(
            color: state.active ? c.tint : null,
            padding: padding,
            alignment: _alignment(align),
            child: label,
          ),
        ));
      } else {
        cells.add(Semantics(
          header: true,
          child: Padding(padding: padding, child: Align(alignment: _alignment(align), heightFactor: 1, child: label)),
        ));
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: background, border: Border(bottom: BorderSide(color: c.fill))),
      child: _TableRowLayout(
        widths: widths,
        pins: pins,
        controller: controller,
        background: background,
        textDirection: Directionality.of(context),
        minHeight: widget.columns.any((col) => col.sortable) ? kumo.minTapTarget : 0,
        children: cells,
      ),
    );
  }

  Color _rowColor(BuildContext context, int index, {required bool selected, required bool active}) {
    final c = context.kumo.colors;
    if (selected || active) return c.tint;
    return widget.striped && index.isOdd ? c.elevated : c.base;
  }

  Widget _cell(BuildContext context, KumoTableColumn<T> col, T row, EdgeInsets padding) {
    var style = context.kumo.text();
    if (col.numeric) style = style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final align = col.resolvedAlign;
    return Padding(
      padding: padding,
      child: Align(
        alignment: _alignment(align),
        heightFactor: 1,
        child: DefaultTextStyle(
          style: style,
          textAlign: switch (align) {
            KumoTableAlign.start => TextAlign.start,
            KumoTableAlign.center => TextAlign.center,
            KumoTableAlign.end => TextAlign.end,
          },
          child: Builder(builder: (context) => col.cell(context, row)),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    int index,
    List<double> widths,
    List<KumoTableColumnPin?> pins,
    ScrollController? controller,
    double checkWidth,
  ) {
    final row = widget.rows[index];
    final selected = _isSelected(row);
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final name = widget.rowLabel?.call(row);
    final padding = _cellPadding(header: false);

    final cells = [
      if (_selectable)
        Center(
          child: DataCheckbox(
            checked: selected,
            semanticLabel: name == null ? strings.selectRow : '${strings.select} $name',
            hitArea: Size(checkWidth, math.max(40, kumo.minTapTarget)),
            onChanged: widget.onSelectionChange == null ? null : (v) => _toggleRow(row, v),
          ),
        ),
      for (final col in widget.columns) _cell(context, col, row, padding),
    ];

    Widget build(bool active, {bool tint = true}) {
      // Selection eases its tint in and out; hover and press show the tint
      // at once, on top of whatever the resting color is doing.
      return _RowTint(
        color: _rowColor(context, index, selected: selected, active: false),
        builder: (context, resting) {
          final background = active && tint ? kumo.colors.tint : resting;
          return ColoredBox(
            color: background,
            child: DataHoverScope(
              active: active,
              child: _TableRowLayout(
                widths: widths,
                pins: pins,
                controller: controller,
                background: background,
                textDirection: Directionality.of(context),
                minHeight: widget.onRowPress != null ? context.kumo.minTapTarget : 0,
                children: cells,
              ),
            ),
          );
        },
      );
    }

    final key = ValueKey<Object>(_id(row));
    if (widget.onRowPress == null) {
      return Semantics(
        key: key,
        container: true,
        selected: _selectable ? selected : null,
        label: name,
        child: FadeTransition(
          opacity: _rowOpacity,
          child: _HoverRow(builder: (hovered) => build(hovered, tint: false)),
        ),
      );
    }
    return FadeTransition(
      key: key,
      opacity: _rowOpacity,
      child: KumoPressable(
        onPress: () => widget.onRowPress!(row),
        semanticLabel: name,
        selected: _selectable ? selected : null,
        mergeChildSemantics: false,
        scaleOnPress: false,
        minTapTargetSize: 0,
        focusRingOffset: -2,
        builder: (context, state) => build(state.active || state.focused),
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final state = _bodyState(context);
    final visible = [for (final col in widget.columns) if (col.showInCards) col];

    Widget card(int index) {
      final row = widget.rows[index];
      final selected = _isSelected(row);
      final name = widget.rowLabel?.call(row);
      final title = visible.isEmpty ? null : visible.first;
      Widget body(bool active) {
        final radius = BorderRadius.circular(KumoRadius.lg);
        return _RowTint(
          color: selected ? c.tint : c.base,
          builder: (context, resting) => Container(
          decoration: BoxDecoration(
            color: active ? c.tint : resting,
            borderRadius: radius,
            border: KumoRing.border(c.line),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(KumoSpace.s4, KumoSpace.s3, KumoSpace.s4, KumoSpace.s3),
          child: DataHoverScope(
            active: active,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s3,
              children: [
                if (_selectable)
                  DataCheckbox(
                    checked: selected,
                    semanticLabel: name == null ? strings.selectRow : '${strings.select} $name',
                    hitArea: const Size(24, 22),
                    onChanged: widget.onSelectionChange == null ? null : (v) => _toggleRow(row, v),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: KumoSpace.s1_5,
                    children: [
                      if (title != null)
                        DefaultTextStyle(
                          style: kumo.text(weight: KumoTypography.medium),
                          child: Builder(builder: (context) => title.cell(context, row)),
                        ),
                      for (final col in visible.skip(1))
                        // Centered, so a label stays level with a cell
                        // taller than its text (a switch with a 44px target).
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: KumoSpace.s3,
                          children: [
                            if (col.label.isNotEmpty)
                              Text(col.label, style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle)),
                            Expanded(
                              child: Align(
                                alignment: col.label.isEmpty ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                                child: DefaultTextStyle(
                                  style: col.numeric
                                      ? kumo.text().copyWith(fontFeatures: const [FontFeature.tabularFigures()])
                                      : kumo.text(),
                                  textAlign: col.label.isEmpty ? TextAlign.start : TextAlign.end,
                                  child: Builder(builder: (context) => col.cell(context, row)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      }

      final key = ValueKey<Object>(_id(row));
      final Widget item = widget.onRowPress == null
          ? Semantics(key: key, container: true, selected: _selectable ? selected : null, label: name, child: body(false))
          : KumoPressable(
              key: key,
              onPress: () => widget.onRowPress!(row),
              semanticLabel: name,
              selected: _selectable ? selected : null,
              mergeChildSemantics: false,
              borderRadius: BorderRadius.circular(KumoRadius.lg),
              builder: (context, s) => body(s.active),
            );
      return FadeTransition(
        key: key,
        opacity: _rowOpacity,
        child: Padding(padding: const EdgeInsets.only(bottom: KumoSpace.s2), child: item),
      );
    }

    Widget? selectAll;
    if (_selectable && widget.rows.isNotEmpty) {
      final count = widget.rows.map(_id).where(widget.selected!.contains).length;
      final all = count == widget.rows.length;
      selectAll = Padding(
        padding: const EdgeInsetsDirectional.only(start: KumoSpace.s4, bottom: KumoSpace.s2),
        child: Row(
          spacing: KumoSpace.s3,
          children: [
            DataCheckbox(
              checked: all,
              mixed: count > 0 && !all,
              semanticLabel: strings.selectAll,
              hitArea: const Size(24, 32),
              onChanged: widget.onSelectionChange == null ? null : (_) => _toggleAll(!all),
            ),
            ExcludeSemantics(child: Text(strings.selectAll, style: kumo.text(color: KumoColor.textSubtle))),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (state != null) {
          return constraints.hasBoundedHeight ? _fill(state) : state;
        }
        final count = widget.rows.length + (selectAll != null ? 1 : 0) + (widget.footer != null ? 1 : 0);
        Widget item(int i) {
          if (selectAll != null) {
            if (i == 0) return selectAll;
            i -= 1;
          }
          if (i >= widget.rows.length) return widget.footer!;
          return card(i);
        }

        if (constraints.hasBoundedHeight) {
          return ListView.builder(
            controller: widget.controller,
            padding: EdgeInsets.zero,
            itemCount: count,
            itemBuilder: (context, i) => item(i),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (var i = 0; i < count; i++) item(i)],
        );
      },
    );
  }
}

/// A sortable header's indicator. Unsorted shows Kumo's up-down caret; a
/// sorted column shows one arrow that turns over when the direction flips,
/// from wherever it is if the header is pressed again mid-turn.
class _SortIndicator extends StatelessWidget {
  const _SortIndicator({required this.direction, required this.color});

  final KumoTableSortDirection? direction;
  final KumoColor color;

  @override
  Widget build(BuildContext context) {
    final d = direction;
    final Widget child = d == null
        ? const KumoIcon(KumoIcons.caretUpDown, key: ValueKey('unsorted'), size: 14, color: KumoColor.textSubtle)
        : AnimatedRotation(
            key: const ValueKey('sorted'),
            turns: d == KumoTableSortDirection.ascending ? 0 : 0.5,
            duration: KumoMotion.duration(context, KumoDurations.moderate),
            curve: KumoCurves.standard,
            child: KumoIcon(KumoIcons.arrowUp, size: 14, color: color),
          );
    return SizedBox.square(dimension: 14, child: KumoSwap(child: child));
  }
}

/// Eases a row's resting background (stripe or selection tint) to [color]
/// from wherever it is, so selecting a row reads as a state change.
class _RowTint extends StatelessWidget {
  const _RowTint({required this.color, required this.builder});

  final Color color;
  final Widget Function(BuildContext context, Color color) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: KumoMotion.duration(context, KumoDurations.fast),
        curve: KumoCurves.standard,
        builder: (context, value, _) => builder(context, value ?? color),
      );
}

/// Hover tracking for rows that are not pressable, so a
/// [KumoInlineCopyText] in the row can still reveal its icon. The row keeps
/// its stripe; only descendants see the hover.
class _HoverRow extends StatefulWidget {
  const _HoverRow({required this.builder});

  final Widget Function(bool active) builder;

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (f) => setState(() => _focused = f),
          child: widget.builder(_hovered || _focused),
        ),
      );
}

/// Lays out one row's cells at fixed widths, stretches them to the tallest
/// cell, and paints pinned cells last, shifted by the horizontal scroll
/// offset so they stay at the viewport's edge (CSS `position: sticky`). A
/// scroll only repaints; it never relayouts.
class _TableRowLayout extends MultiChildRenderObjectWidget {
  const _TableRowLayout({
    required this.widths,
    required this.pins,
    required this.controller,
    required this.background,
    required this.textDirection,
    required super.children,
    this.minHeight = 0,
  });

  /// Touch rows and sortable headers stay at least 44px tall.
  final double minHeight;
  final List<double> widths;
  final List<KumoTableColumnPin?> pins;
  final ScrollController? controller;
  final Color background;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTableRow(
        widths: widths,
        pins: pins,
        controller: controller,
        background: background,
        textDirection: textDirection,
        minHeight: minHeight,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderTableRow renderObject) {
    renderObject
      ..minHeight = minHeight
      ..widths = widths
      ..pins = pins
      ..controller = controller
      ..background = background
      ..textDirection = textDirection;
  }
}

class _RowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTableRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _RowParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _RowParentData> {
  _RenderTableRow({
    required List<double> widths,
    required List<KumoTableColumnPin?> pins,
    required ScrollController? controller,
    required Color background,
    required TextDirection textDirection,
    required double minHeight,
  })  : _minHeight = minHeight,
        _widths = widths,
        _pins = pins,
        _controller = controller,
        _background = background,
        _textDirection = textDirection;

  double _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  List<double> _widths;
  set widths(List<double> value) {
    if (listEquals(value, _widths)) return;
    _widths = value;
    markNeedsLayout();
  }

  List<KumoTableColumnPin?> _pins;
  set pins(List<KumoTableColumnPin?> value) {
    if (listEquals(value, _pins)) return;
    _pins = value;
    markNeedsPaint();
  }

  ScrollController? _controller;
  set controller(ScrollController? value) {
    if (value == _controller) return;
    if (attached) _controller?.removeListener(markNeedsPaint);
    _controller = value;
    if (attached) _controller?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Color _background;
  set background(Color value) {
    if (value == _background) return;
    _background = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _controller?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowParentData) child.parentData = _RowParentData();
  }

  List<RenderBox> get _children {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  double get _total => _widths.fold(0.0, (a, b) => a + b);

  @override
  void performLayout() {
    final kids = _children;
    var height = _minHeight;
    for (var i = 0; i < kids.length; i++) {
      final w = i < _widths.length ? _widths[i] : 0.0;
      kids[i].layout(BoxConstraints.tightFor(width: w), parentUsesSize: true);
      height = math.max(height, kids[i].size.height);
    }
    var x = 0.0;
    final total = _total;
    for (var i = 0; i < kids.length; i++) {
      final w = i < _widths.length ? _widths[i] : 0.0;
      if (kids[i].size.height != height) {
        kids[i].layout(BoxConstraints.tightFor(width: w, height: height), parentUsesSize: true);
      }
      final dx = _textDirection == TextDirection.rtl ? total - x - w : x;
      (kids[i].parentData! as _RowParentData).offset = Offset(dx, 0);
      x += w;
    }
    size = constraints.constrain(Size(total, height));
  }

  @override
  double computeMinIntrinsicWidth(double height) => _total;

  @override
  double computeMaxIntrinsicWidth(double height) => _total;

  @override
  double computeMinIntrinsicHeight(double width) {
    var h = 0.0;
    final kids = _children;
    for (var i = 0; i < kids.length && i < _widths.length; i++) {
      h = math.max(h, kids[i].getMinIntrinsicHeight(_widths[i]));
    }
    return h;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    var h = 0.0;
    final kids = _children;
    for (var i = 0; i < kids.length && i < _widths.length; i++) {
      h = math.max(h, kids[i].getMaxIntrinsicHeight(_widths[i]));
    }
    return h;
  }

  /// Horizontal shift for a cell pinned to [pin] at the current scroll.
  double _shift(KumoTableColumnPin? pin) {
    final c = _controller;
    if (pin == null || c == null || !c.hasClients || !c.position.hasContentDimensions) return 0;
    final offset = c.offset.clamp(0.0, c.position.maxScrollExtent);
    final max = c.position.maxScrollExtent;
    final ltr = _textDirection == TextDirection.ltr;
    return switch (pin) {
      KumoTableColumnPin.start => ltr ? offset : -offset,
      KumoTableColumnPin.end => ltr ? offset - max : max - offset,
    };
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final kids = _children;
    for (var i = 0; i < kids.length; i++) {
      if (i < _pins.length && _pins[i] != null) continue;
      context.paintChild(kids[i], offset + (kids[i].parentData! as _RowParentData).offset);
    }
    final ltr = _textDirection == TextDirection.ltr;
    for (final pin in KumoTableColumnPin.values) {
      final shift = _shift(pin);
      Rect? group;
      for (var i = 0; i < kids.length && i < _pins.length; i++) {
        if (_pins[i] != pin) continue;
        final at = offset + (kids[i].parentData! as _RowParentData).offset + Offset(shift, 0);
        final rect = at & kids[i].size;
        group = group == null ? rect : group.expandToInclude(rect);
        context.canvas.drawRect(rect, Paint()..color = _background);
        context.paintChild(kids[i], at);
      }
      if (group == null || shift == 0) continue;
      // Kumo's 24px fade on the pinned cell's inner edge, shown only while
      // content is scrolled beneath it.
      final innerOnRight = (pin == KumoTableColumnPin.start) == ltr;
      final fade = innerOnRight
          ? Rect.fromLTWH(group.right, group.top, KumoSpace.s6, group.height)
          : Rect.fromLTWH(group.left - KumoSpace.s6, group.top, KumoSpace.s6, group.height);
      context.canvas.drawRect(
        fade,
        Paint()
          ..shader = LinearGradient(
            begin: innerOnRight ? Alignment.centerLeft : Alignment.centerRight,
            end: innerOnRight ? Alignment.centerRight : Alignment.centerLeft,
            colors: [_background, _background.withValues(alpha: 0)],
          ).createShader(fade),
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final kids = _children;
    // Pinned cells paint on top, so they are hit first.
    for (var i = kids.length - 1; i >= 0; i--) {
      final pinned = i < _pins.length && _pins[i] != null;
      if (!pinned) continue;
      final at = (kids[i].parentData! as _RowParentData).offset + Offset(_shift(_pins[i]), 0);
      final hit = result.addWithPaintOffset(
        offset: at,
        position: position,
        hitTest: (result, transformed) => kids[i].hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    for (var i = kids.length - 1; i >= 0; i--) {
      final pinned = i < _pins.length && _pins[i] != null;
      if (pinned) continue;
      final at = (kids[i].parentData! as _RowParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: at,
        position: position,
        hitTest: (result, transformed) => kids[i].hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final i = _children.indexOf(child);
    final pinned = i >= 0 && i < _pins.length && _pins[i] != null;
    final at = (child.parentData! as _RowParentData).offset + Offset(pinned ? _shift(_pins[i]) : 0, 0);
    transform.translateByDouble(at.dx, at.dy, 0, 1);
  }
}
