part of 'kumo_flow_diagram.dart';

// A port of Kumo's flow-layout.ts and connectors.tsx. Everything here is pure:
// sizes in, positions, edges and connector paths out.

sealed class _FlowTree {
  const _FlowTree();
}

final class _FlowTreeNode extends _FlowTree {
  const _FlowTreeNode(this.index);

  /// Position of the node's widget in the diagram's flattened child list.
  final int index;
}

final class _FlowTreeList extends _FlowTree {
  const _FlowTreeList(this.children);
  final List<_FlowTree> children;
}

final class _FlowTreeParallel extends _FlowTree {
  const _FlowTreeParallel(this.children, {this.alignEnd = false});
  final List<_FlowTree> children;
  final bool alignEnd;
}

/// Kumo's `columnGap`: space between consecutive steps on the main axis.
const double _kColumnGap = 64;

/// Kumo's `rowGap`: space between parallel branches.
const double _kRowGap = 16;

/// Entry points of a subtree: the nodes an incoming edge connects to.
List<int> _entryIds(_FlowTree node) => switch (node) {
  _FlowTreeNode(:final index) => [index],
  _FlowTreeParallel(:final children) => [for (final c in children) ..._entryIds(c)],
  _FlowTreeList(:final children) => children.isEmpty ? const [] : _entryIds(children.first),
};

/// Exit points of a subtree: the nodes an outgoing edge starts from.
List<int> _exitIds(_FlowTree node) => switch (node) {
  _FlowTreeNode(:final index) => [index],
  _FlowTreeParallel(:final children) => [for (final c in children) ..._exitIds(c)],
  _FlowTreeList(:final children) => children.isEmpty ? const [] : _exitIds(children.last),
};

/// Kumo's `computeEdges`. Adjacent nodes connect; a node next to a parallel
/// group connects to every branch; two adjacent parallel groups do not
/// connect; a list connects outward through its first and last node only.
List<(int, int)> _computeEdges(_FlowTree tree) {
  final edges = <(int, int)>[];
  void collect(_FlowTree node) {
    switch (node) {
      case _FlowTreeNode():
        return;
      case _FlowTreeParallel(:final children):
        children.forEach(collect);
      case _FlowTreeList(:final children):
        children.forEach(collect);
        for (var i = 0; i < children.length - 1; i++) {
          final current = children[i];
          final next = children[i + 1];
          if (current is _FlowTreeParallel && next is _FlowTreeParallel) continue;
          for (final from in _exitIds(current)) {
            for (final to in _entryIds(next)) {
              edges.add((from, to));
            }
          }
        }
    }
  }

  collect(tree);
  return edges;
}

/// Kumo's `computePositions`: top-left corner of every node, in left-to-right
/// content coordinates (RTL mirroring happens later, in one place).
///
/// Horizontal flows put list items left to right and branches top to bottom;
/// vertical flows swap both.
Map<int, Offset> _computePositions(
  _FlowTree tree,
  List<Size> sizes, {
  required bool vertical,
  required bool alignCenter,
  double columnGap = _kColumnGap,
  double rowGap = _kRowGap,
}) {
  Size layout(_FlowTree node, double originX, double originY, Map<int, Offset> out) {
    switch (node) {
      case _FlowTreeNode(:final index):
        out[index] = Offset(originX, originY);
        return sizes[index];

      case _FlowTreeList(:final children):
        if (vertical) {
          if (alignCenter) {
            final measured = [for (final c in children) layout(c, 0, 0, {})];
            final columnWidth = measured.fold<double>(0, (m, s) => math.max(m, s.width));
            var cursorY = originY;
            for (var i = 0; i < children.length; i++) {
              layout(children[i], originX + (columnWidth - measured[i].width) / 2, cursorY, out);
              cursorY += measured[i].height;
              if (i < children.length - 1) cursorY += columnGap;
            }
            return Size(columnWidth, cursorY - originY);
          }
          var cursorY = originY;
          var totalWidth = 0.0;
          for (var i = 0; i < children.length; i++) {
            final s = layout(children[i], originX, cursorY, out);
            cursorY += s.height;
            if (i < children.length - 1) cursorY += columnGap;
            totalWidth = math.max(totalWidth, s.width);
          }
          return Size(totalWidth, cursorY - originY);
        }
        if (alignCenter) {
          final measured = [for (final c in children) layout(c, 0, 0, {})];
          final rowHeight = measured.fold<double>(0, (m, s) => math.max(m, s.height));
          var cursorX = originX;
          for (var i = 0; i < children.length; i++) {
            layout(children[i], cursorX, originY + (rowHeight - measured[i].height) / 2, out);
            cursorX += measured[i].width;
            if (i < children.length - 1) cursorX += columnGap;
          }
          return Size(cursorX - originX, rowHeight);
        }
        var cursorX = originX;
        var totalHeight = 0.0;
        for (var i = 0; i < children.length; i++) {
          final s = layout(children[i], cursorX, originY, out);
          cursorX += s.width;
          if (i < children.length - 1) cursorX += columnGap;
          totalHeight = math.max(totalHeight, s.height);
        }
        return Size(cursorX - originX, totalHeight);

      case _FlowTreeParallel(:final children, :final alignEnd):
        if (vertical) {
          if (alignEnd) {
            final measured = [for (final c in children) layout(c, 0, 0, {})];
            final maxHeight = measured.fold<double>(0, (m, s) => math.max(m, s.height));
            var cursorX = originX;
            for (var i = 0; i < children.length; i++) {
              layout(children[i], cursorX, originY + maxHeight - measured[i].height, out);
              cursorX += measured[i].width;
              if (i < children.length - 1) cursorX += rowGap;
            }
            return Size(cursorX - originX, maxHeight);
          }
          var cursorX = originX;
          var maxHeight = 0.0;
          for (var i = 0; i < children.length; i++) {
            final s = layout(children[i], cursorX, originY, out);
            maxHeight = math.max(maxHeight, s.height);
            cursorX += s.width;
            if (i < children.length - 1) cursorX += rowGap;
          }
          return Size(cursorX - originX, maxHeight);
        }
        if (alignEnd) {
          final measured = [for (final c in children) layout(c, 0, 0, {})];
          final maxWidth = measured.fold<double>(0, (m, s) => math.max(m, s.width));
          var cursorY = originY;
          for (var i = 0; i < children.length; i++) {
            layout(children[i], originX + maxWidth - measured[i].width, cursorY, out);
            cursorY += measured[i].height;
            if (i < children.length - 1) cursorY += rowGap;
          }
          return Size(maxWidth, cursorY - originY);
        }
        var cursorY = originY;
        var maxWidth = 0.0;
        for (var i = 0; i < children.length; i++) {
          final s = layout(children[i], originX, cursorY, out);
          maxWidth = math.max(maxWidth, s.width);
          cursorY += s.height;
          if (i < children.length - 1) cursorY += rowGap;
        }
        return Size(maxWidth, cursorY - originY);
    }
  }

  final positions = <int, Offset>{};
  layout(tree, 0, 0, positions);
  return positions;
}

/// Kumo's `computeDiagramRect`: the far corner of the furthest node.
Size _computeDiagramSize(Map<int, Offset> positions, List<Size> sizes) {
  var width = 0.0;
  var height = 0.0;
  positions.forEach((i, p) {
    width = math.max(width, p.dx + sizes[i].width);
    height = math.max(height, p.dy + sizes[i].height);
  });
  return Size(width, height);
}

/// Kumo's connector constants (`createRoundedPath` defaults).
const double _kCornerRadius = 8;
const double _kMidOffset = 32;
const double _kArrowheadOffset = 8;

/// Below this cross-axis distance a connector is drawn straight.
const double _kFlatThreshold = 2;

/// A connector path plus where its arrowhead sits.
class _ConnectorPath {
  const _ConnectorPath(this.path, this.tip, this.direction);
  final Path path;

  /// End of the stroked line; the arrowhead starts here.
  final Offset tip;

  /// Unit direction of the final segment.
  final Offset direction;
}

/// Kumo's `createRoundedPath` with `single: true`, the only mode the Flow
/// connectors use: out along the main axis, one rounded elbow, across, a
/// second elbow, and in to the target, stopping short for the arrowhead.
_ConnectorPath _roundedPath(Offset a, Offset b, {required bool vertical}) {
  final x1 = a.dx, y1 = a.dy, x2 = b.dx, y2 = b.dy;
  final path = Path()..moveTo(x1, y1);
  late Offset previous;
  late Offset end;

  if (!vertical) {
    if ((y2 - y1).abs() <= _kFlatThreshold) {
      previous = Offset(x1, y1);
      end = Offset(x2 - _kArrowheadOffset, y2);
      path.lineTo(end.dx, end.dy);
    } else {
      final r = math.min(_kCornerRadius, ((y2 - y1) / 2).abs());
      final vx = x2 - _kMidOffset;
      final h = x2 > x1 ? 1.0 : -1.0;
      final v = y2 > y1 ? 1.0 : -1.0;
      path
        ..lineTo(vx - h * r, y1)
        ..quadraticBezierTo(vx, y1, vx, y1 + v * r)
        ..lineTo(vx, y2 - v * r)
        ..quadraticBezierTo(vx, y2, vx + h * r, y2);
      previous = Offset(vx + h * r, y2);
      end = Offset(x2 - h * _kArrowheadOffset, y2);
      path.lineTo(end.dx, end.dy);
    }
  } else {
    if ((x2 - x1).abs() <= _kFlatThreshold) {
      previous = Offset(x1, y1);
      end = Offset(x2, y2 - _kArrowheadOffset);
      path.lineTo(end.dx, end.dy);
    } else {
      final r = math.min(_kCornerRadius, ((x2 - x1) / 2).abs());
      final hy = y2 - _kMidOffset;
      final h = x2 > x1 ? 1.0 : -1.0;
      final v = y2 > y1 ? 1.0 : -1.0;
      path
        ..lineTo(x1, hy - r)
        ..quadraticBezierTo(x1, hy, x1 + h * r, hy)
        ..lineTo(x2 - h * r, hy)
        ..quadraticBezierTo(x2, hy, x2, hy + r);
      previous = Offset(x2, hy + r);
      end = Offset(x2, y2 - v * _kArrowheadOffset);
      path.lineTo(end.dx, end.dy);
    }
  }

  var direction = end - previous;
  if (direction.distance == 0) direction = vertical ? const Offset(0, 1) : const Offset(1, 0);
  return _ConnectorPath(path, end, direction / direction.distance);
}

/// Kumo's arrowhead marker (8x8, `refX=0 refY=4`), pointing along +x with
/// its base at the origin.
final Path _arrowhead = Path()
  ..moveTo(0, 1.5 - 4)
  ..quadraticBezierTo(0, 0 - 4, 1.5, 0 - 4)
  ..quadraticBezierTo(3.5, 1 - 4, 5.8, 3.2 - 4)
  ..quadraticBezierTo(6.5, 4 - 4, 5.8, 4.8 - 4)
  ..quadraticBezierTo(3.5, 7 - 4, 1.5, 8 - 4)
  ..quadraticBezierTo(0, 8 - 4, 0, 6.5 - 4)
  ..close();
