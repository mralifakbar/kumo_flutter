import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';

/// Kumo's preset responsive layouts. Columns collapse as the width drops
/// below Tailwind's breakpoints (`md` 768, `lg` 1024, `xl` 1280).
enum KumoGridVariant {
  /// `2up`: 1 column, 2 from `md`.
  twoUp,

  /// `side-by-side`: always 2 columns.
  sideBySide,

  /// `2-1`: 1 column, then two thirds and one third from `md`.
  twoOne,

  /// `1-2`: 1 column, then one third and two thirds from `md`.
  oneTwo,

  /// `1-3up`: 1 column, 3 from `lg`.
  oneThreeUp,

  /// `3up`: 1, 2 from `md`, 3 from `lg`.
  threeUp,

  /// `4up`: 1, 2 from `md`, 3 from `lg`, 4 from `xl`.
  fourUp,

  /// `6up`: 2, 3 from `md`, 4 from `lg`, 6 from `xl`.
  sixUp,

  /// `1-2-4up`: 1, 2 from `md`, 4 from `lg`.
  oneTwoFourUp;

  /// Relative column widths at [width].
  List<int> tracksAt(double width) {
    final md = width >= KumoBreakpoints.md;
    List<int> equal(KumoGridColumns c) => List.filled(c.at(width), 1);
    return switch (this) {
      twoUp => equal(const KumoGridColumns(md: 2)),
      sideBySide => const [1, 1],
      twoOne => md ? const [2, 1] : const [1],
      oneTwo => md ? const [1, 2] : const [1],
      oneThreeUp => equal(const KumoGridColumns(lg: 3)),
      threeUp => equal(const KumoGridColumns(md: 2, lg: 3)),
      fourUp => equal(const KumoGridColumns(md: 2, lg: 3, xl: 4)),
      sixUp => equal(const KumoGridColumns(base: 2, md: 3, lg: 4, xl: 6)),
      oneTwoFourUp => equal(const KumoGridColumns(md: 2, lg: 4)),
    };
  }
}

/// Space between grid cells, in both directions.
enum KumoGridGap {
  /// `gap-0`.
  none,

  /// `gap-3`, 12px.
  sm,

  /// `gap-2 md:gap-6 lg:gap-8`: 8px, 24px from `md`, 32px from `lg`. The default.
  base,

  /// `gap-8`, 32px.
  lg;

  /// The gap at [width].
  double at(double width) => switch (this) {
        none => 0,
        sm => KumoSpace.s3,
        base => width >= KumoBreakpoints.lg ? KumoSpace.s8 : (width >= KumoBreakpoints.md ? KumoSpace.s6 : KumoSpace.s2),
        lg => KumoSpace.s8,
      };
}

/// Explicit equal-column counts per breakpoint, for layouts the presets do
/// not cover. Each count applies from its breakpoint up until a larger one
/// overrides it.
///
/// ```dart
/// KumoGrid(columns: const KumoGridColumns(base: 2, md: 3, xl: 5), children: tiles)
/// ```
@immutable
class KumoGridColumns {
  const KumoGridColumns({this.base = 1, this.sm, this.md, this.lg, this.xl})
      : assert(base > 0);

  final int base;

  /// From 640px.
  final int? sm;

  /// From 768px.
  final int? md;

  /// From 1024px.
  final int? lg;

  /// From 1280px.
  final int? xl;

  /// Column count at [width].
  int at(double width) {
    var n = base;
    if (width >= KumoBreakpoints.sm && sm != null) n = sm!;
    if (width >= KumoBreakpoints.md && md != null) n = md!;
    if (width >= KumoBreakpoints.lg && lg != null) n = lg!;
    if (width >= KumoBreakpoints.xl && xl != null) n = xl!;
    return math.max(1, n);
  }

  @override
  bool operator ==(Object other) =>
      other is KumoGridColumns && other.base == base && other.sm == sm && other.md == md && other.lg == lg && other.xl == xl;

  @override
  int get hashCode => Object.hash(base, sm, md, lg, xl);
}

/// Which width the grid's breakpoints read.
enum KumoGridBreakpoints {
  /// The window width, like Tailwind's media queries. The default.
  window,

  /// The grid's own width, for grids inside side panels and cards.
  container,
}

/// Kumo's `Grid`: a responsive column grid with a gap.
///
/// ```dart
/// KumoGrid(
///   variant: KumoGridVariant.threeUp,
///   gap: KumoGridGap.sm,
///   children: const [Text('Workers'), Text('R2'), Text('D1')],
/// )
/// ```
///
/// Cells in a row share the height of the tallest one (CSS grid's
/// `align-items: stretch`), so cards line up. Children fill rows in reading
/// order; in right-to-left layouts the first column is on the right.
class KumoGrid extends StatelessWidget {
  const KumoGrid({
    super.key,
    required this.children,
    this.variant,
    this.columns,
    this.gap = KumoGridGap.base,
    this.mobileDivider = false,
    this.breakpoints = KumoGridBreakpoints.window,
  }) : assert(variant == null || columns == null, 'Pass variant or columns, not both');

  final List<Widget> children;

  /// Preset layout. With neither [variant] nor [columns], items stack in a
  /// single column (a Kumo `Grid` without a variant).
  final KumoGridVariant? variant;

  /// Explicit per-breakpoint column counts.
  final KumoGridColumns? columns;
  final KumoGridGap gap;

  /// With [KumoGridVariant.fourUp], separate stacked items with a hairline
  /// and 32px of space while the grid is a single column.
  final bool mobileDivider;
  final KumoGridBreakpoints breakpoints;

  @override
  Widget build(BuildContext context) {
    Widget build(double width) {
      final tracks = variant?.tracksAt(width) ?? List.filled(columns?.at(width) ?? 1, 1);
      final spacing = gap.at(width);
      var items = children;
      if (mobileDivider && variant == KumoGridVariant.fourUp && tracks.length == 1) {
        final line = context.kumo.colors.hairline;
        items = [
          for (var i = 0; i < children.length; i++)
            i == children.length - 1
                ? children[i]
                : DecoratedBox(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: line))),
                    child: Padding(padding: const EdgeInsets.only(bottom: KumoSpace.s8), child: children[i]),
                  ),
        ];
      }
      return _GridLayout(tracks: tracks, gap: spacing, textDirection: Directionality.of(context), children: items);
    }

    if (breakpoints == KumoGridBreakpoints.container) {
      return LayoutBuilder(builder: (context, constraints) => build(constraints.maxWidth));
    }
    return build(MediaQuery.sizeOf(context).width);
  }
}

class _GridLayout extends MultiChildRenderObjectWidget {
  const _GridLayout({required this.tracks, required this.gap, required this.textDirection, required super.children});

  final List<int> tracks;
  final double gap;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGrid(tracks: tracks, gap: gap, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderGrid renderObject) {
    renderObject
      ..tracks = tracks
      ..gap = gap
      ..textDirection = textDirection;
  }
}

class _GridParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderGrid extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _GridParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _GridParentData> {
  _RenderGrid({required List<int> tracks, required double gap, required TextDirection textDirection})
      : _tracks = tracks,
        _gap = gap,
        _textDirection = textDirection;

  List<int> _tracks;
  set tracks(List<int> value) {
    if (listEquals(value, _tracks)) return;
    _tracks = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GridParentData) child.parentData = _GridParentData();
  }

  List<double> _trackWidths(double width) {
    final total = _tracks.fold<int>(0, (a, b) => a + b);
    final free = math.max(0.0, width - _gap * (_tracks.length - 1));
    return [for (final t in _tracks) free * t / total];
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

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
    final widths = _trackWidths(width);
    final n = _tracks.length;
    final kids = _children;
    var y = 0.0;
    for (var start = 0; start < kids.length; start += n) {
      final row = kids.sublist(start, math.min(start + n, kids.length));
      var rowHeight = 0.0;
      for (var i = 0; i < row.length; i++) {
        final c = BoxConstraints(minWidth: widths[i], maxWidth: widths[i]);
        final h = dry ? row[i].getDryLayout(c).height : (row[i]..layout(c, parentUsesSize: true)).size.height;
        rowHeight = math.max(rowHeight, h);
      }
      var x = 0.0;
      for (var i = 0; i < row.length; i++) {
        if (!dry) {
          // Second pass: stretch every cell to the row's height.
          if (row[i].size.height != rowHeight) {
            row[i].layout(BoxConstraints.tightFor(width: widths[i], height: rowHeight), parentUsesSize: true);
          }
          final dx = _textDirection == TextDirection.rtl ? width - x - widths[i] : x;
          (row[i].parentData! as _GridParentData).offset = Offset(dx, y);
        }
        x += widths[i] + _gap;
      }
      y += rowHeight;
      if (start + n < kids.length) y += _gap;
    }
    return constraints.constrain(Size(width, y));
  }

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    var widest = 0.0;
    for (final c in _children) {
      widest = math.max(widest, c.getMaxIntrinsicWidth(double.infinity));
    }
    return widest * _tracks.length + _gap * (_tracks.length - 1);
  }

  double _intrinsicHeight(double width, double Function(RenderBox child, double width) measure) {
    final widths = _trackWidths(width);
    final n = _tracks.length;
    final kids = _children;
    var y = 0.0;
    for (var start = 0; start < kids.length; start += n) {
      var rowHeight = 0.0;
      for (var i = 0; start + i < kids.length && i < n; i++) {
        rowHeight = math.max(rowHeight, measure(kids[start + i], widths[i]));
      }
      y += rowHeight + (start + n < kids.length ? _gap : 0);
    }
    return y;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);
}
