import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../feedback/kumo_loader.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_field_box.dart' show KumoPresentation;
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_dropdown_menu.dart';

/// Kumo's `Toolbar`: controls grouped into one compact card, with shared
/// borders between items and only the outer corners rounded.
///
/// Children are [KumoToolbarButton]s, [KumoToolbarGroup]s (buttons with no
/// divider between them) and [KumoToolbarSlot]s (any widget, such as a
/// search field).
///
/// ```dart
/// KumoToolbar(
///   semanticLabel: 'DNS records',
///   children: [
///     KumoToolbarButton(icon: KumoIcons.uploadSimple, label: 'Import', onPress: importRecords),
///     KumoToolbarButton(icon: KumoIcons.downloadSimple, label: 'Export', onPress: exportRecords),
///     KumoToolbarButton(icon: KumoIcons.gearSix, semanticLabel: 'Settings', onPress: openSettings),
///   ],
/// )
/// ```
///
/// * Keyboard: the toolbar is one Tab stop; Left and Right move between
///   buttons (mirrored in RTL), Home and End jump to the ends.
/// * When the items do not fit, buttons and groups at the end move into a
///   "More" menu instead of overflowing; slots always stay. On narrow
///   screens that menu opens as a bottom sheet.
class KumoToolbar extends StatefulWidget {
  const KumoToolbar({
    super.key,
    required this.children,
    this.overflowMenu = true,
    this.semanticLabel,
    this.moreLabel,
    this.presentation = KumoPresentation.auto,
  });

  final List<Widget> children;

  /// Move items that do not fit into a "More" menu. Set false when the
  /// toolbar always has room (it then clips).
  final bool overflowMenu;

  /// Accessible name of the toolbar.
  final String? semanticLabel;

  /// Accessible name of the overflow button. Defaults to [KumoStrings.more].
  final String? moreLabel;

  /// Presentation of the overflow menu.
  final KumoPresentation presentation;

  @override
  State<KumoToolbar> createState() => _KumoToolbarState();
}

/// A quiet button inside a [KumoToolbar] (Kumo's `Toolbar.Button`, and
/// `Toolbar.Link` with [isLink]). Icon-only buttons need [semanticLabel].
///
/// ```dart
/// KumoToolbarButton(icon: KumoIcons.funnelSimple, semanticLabel: 'Filter', onPress: openFilters)
/// KumoToolbarButton(icon: KumoIcons.textB, semanticLabel: 'Bold', toggled: bold, onPress: toggleBold)
/// ```
class KumoToolbarButton extends StatelessWidget {
  const KumoToolbarButton({
    super.key,
    this.label,
    this.icon,
    this.onPress,
    this.disabled = false,
    this.loading = false,
    this.toggled,
    this.isLink = false,
    this.semanticLabel,
    this.tooltip,
  }) : assert(
         label != null || (icon != null && semanticLabel != null),
         'Pass a label, or an icon with a semanticLabel',
       );

  final String? label;
  final IconData? icon;

  /// Null renders the button disabled.
  final VoidCallback? onPress;
  final bool disabled;

  /// Shows a spinner in place of the icon and blocks presses.
  final bool loading;

  /// Pressed state for toggle buttons (bold, word wrap). Null for plain
  /// actions. In the overflow menu a toggle becomes a checkbox row.
  final bool? toggled;

  /// Announce as a link (Kumo's `Toolbar.Link`).
  final bool isLink;
  final String? semanticLabel;

  /// Hover tooltip, useful for icon-only buttons.
  final String? tooltip;

  bool get _inactive => disabled || onPress == null;

  /// The text used for this button in the overflow menu.
  String get _menuLabel => label ?? semanticLabel!;

  @override
  Widget build(BuildContext context) => _ToolbarButtonView(button: this);
}

/// Buttons that read as one unit: no divider between them, one divider
/// around the group. They move into the overflow menu together.
class KumoToolbarGroup extends StatelessWidget {
  const KumoToolbarGroup({super.key, required this.children, this.semanticLabel});

  final List<KumoToolbarButton> children;

  /// Accessible name of the group, such as 'Text formatting'.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: semanticLabel,
    child: Row(mainAxisSize: MainAxisSize.min, children: children),
  );
}

/// Any widget inside a [KumoToolbar], such as a search field. Slots never
/// move into the overflow menu.
///
/// ```dart
/// KumoToolbarSlot(flex: 1, minWidth: 160, child: SearchField())
/// ```
class KumoToolbarSlot extends StatelessWidget {
  const KumoToolbarSlot({super.key, required this.child, this.flex = 0, this.minWidth = 160});

  final Widget child;

  /// Share of the free width this slot takes, like `flex-1` in Kumo demos.
  /// Zero sizes it to [child].
  final int flex;

  /// Width a flexible slot keeps before items start moving into the
  /// overflow menu.
  final double minWidth;

  @override
  Widget build(BuildContext context) => child;
}

class _KumoToolbarState extends State<KumoToolbar> {
  final List<FocusNode> _nodes = [];
  late final FocusNode _moreNode = _makeNode('more');
  int _cutoff = 1 << 30;
  FocusNode? _tabStop;

  FocusNode _makeNode(Object label) {
    final node = FocusNode(debugLabel: 'KumoToolbar $label');
    node.addListener(() {
      if (node.hasPrimaryFocus && _tabStop != node) setState(() => _tabStop = node);
    });
    return node;
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    _moreNode.dispose();
    super.dispose();
  }

  static bool _overflowable(Widget w) => w is KumoToolbarButton || w is KumoToolbarGroup;

  bool _hidden(int index) => widget.overflowMenu && index >= _cutoff && _overflowable(widget.children[index]);

  void _onCutoff(int cutoff) {
    if (mounted && cutoff != _cutoff) setState(() => _cutoff = cutoff);
  }

  /// Focusable buttons in visual order, skipping hidden and disabled ones.
  List<FocusNode> _roving(List<(FocusNode, bool)> nodes) => [
    for (final (node, enabled) in nodes)
      if (enabled) node,
  ];

  KeyEventResult _onKey(FocusNode _, KeyEvent event, List<FocusNode> roving) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final focus = FocusManager.instance.primaryFocus;
    // Keys from a slot (a text field moving its caret) are not ours.
    final current = roving.indexWhere((n) => n == focus);
    if (current < 0 || roving.isEmpty) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    int? next;
    if (key == LogicalKeyboardKey.arrowRight) next = (current + (rtl ? -1 : 1)) % roving.length;
    if (key == LogicalKeyboardKey.arrowLeft) next = (current + (rtl ? 1 : -1)) % roving.length;
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = roving.length - 1;
    if (next == null) return KeyEventResult.ignored;
    roving[next].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;

    var nodeCount = 0;
    for (final child in widget.children) {
      if (child is KumoToolbarButton) nodeCount++;
      if (child is KumoToolbarGroup) nodeCount += child.children.length;
    }
    while (_nodes.length < nodeCount) {
      _nodes.add(_makeNode(_nodes.length));
    }
    while (_nodes.length > nodeCount) {
      final removed = _nodes.removeLast();
      if (_tabStop == removed) _tabStop = null;
      removed.dispose();
    }

    final ordered = <(FocusNode, bool)>[];
    final views = <Widget>[];
    final overflow = <Widget>[];
    var n = 0;
    for (var i = 0; i < widget.children.length; i++) {
      final child = widget.children[i];
      final hidden = _hidden(i);
      Widget view;
      var flex = 0;
      var minWidth = 0.0;
      switch (child) {
        case KumoToolbarButton():
          final node = _nodes[n++];
          if (!hidden) ordered.add((node, !child._inactive && !child.loading));
          view = _ToolbarButtonView(button: child, focusNode: node);
        case KumoToolbarGroup():
          final buttons = <Widget>[];
          for (final b in child.children) {
            final node = _nodes[n++];
            if (!hidden) ordered.add((node, !b._inactive && !b.loading));
            buttons.add(_ToolbarButtonView(button: b, focusNode: node));
          }
          view = Semantics(
            container: true,
            explicitChildNodes: true,
            label: child.semanticLabel,
            child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
          );
        case KumoToolbarSlot():
          flex = child.flex;
          minWidth = child.minWidth;
          view = child.child;
        default:
          view = child;
      }
      if (hidden) {
        if (child is KumoToolbarGroup && overflow.isNotEmpty) overflow.add(const KumoDropdownSeparator());
        overflow.addAll(_menuItems(child));
        if (child is KumoToolbarGroup && i < widget.children.length - 1) overflow.add(const KumoDropdownSeparator());
      }
      views.add(
        _ToolbarEntry(
          flex: flex,
          minWidth: minWidth,
          overflowable: _overflowable(child),
          child: ExcludeFocus(
            excluding: hidden,
            child: ExcludeSemantics(excluding: hidden, child: view),
          ),
        ),
      );
    }
    while (overflow.isNotEmpty && overflow.last is KumoDropdownSeparator) {
      overflow.removeLast();
    }

    final showMore = overflow.isNotEmpty;
    if (showMore) ordered.add((_moreNode, true));
    final roving = _roving(ordered);
    final stop = roving.contains(_tabStop) ? _tabStop : (roving.isEmpty ? null : roving.first);
    for (final (node, _) in ordered) {
      node.skipTraversal = node != stop;
    }
    _moreNode.skipTraversal = _moreNode != stop;

    final moreLabel = widget.moreLabel ?? strings.more;
    final more = _ToolbarEntry(
      overflowable: false,
      child: ExcludeFocus(
        excluding: !showMore,
        child: ExcludeSemantics(
          excluding: !showMore,
          child: KumoDropdownMenu(
            items: overflow,
            align: KumoAlign.end,
            presentation: widget.presentation,
            semanticLabel: moreLabel,
            triggerBuilder: (context, menu) => _ToolbarButtonView(
              button: KumoToolbarButton(icon: KumoIcons.dotsThree, semanticLabel: moreLabel, onPress: menu.toggle),
              focusNode: _moreNode,
              expanded: menu.isOpen,
            ),
          ),
        ),
      ),
    );

    const radius = BorderRadius.all(Radius.circular(KumoRadius.lg));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) => _onKey(node, event, roving),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: radius,
            border: KumoRing.border(c.line),
            boxShadow: KumoShadow.xs.boxShadows,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: _ToolbarLayout(
              textDirection: Directionality.of(context),
              divider: c.line,
              overflowMenu: widget.overflowMenu,
              onCutoff: _onCutoff,
              children: [...views, more],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _menuItems(Widget child) {
    Widget item(KumoToolbarButton b) {
      final off = b._inactive || b.loading;
      if (b.toggled != null) {
        return KumoDropdownCheckboxItem(
          label: b._menuLabel,
          checked: b.toggled!,
          disabled: off,
          onCheckedChange: off ? null : (_) => b.onPress!(),
        );
      }
      if (b.isLink) return KumoDropdownLinkItem(label: b._menuLabel, icon: b.icon, disabled: off, onPress: b.onPress);
      return KumoDropdownItem(label: b._menuLabel, icon: b.icon, disabled: off, onPress: b.onPress);
    }

    return switch (child) {
      KumoToolbarButton() => [item(child)],
      KumoToolbarGroup(:final children) => [for (final b in children) item(b)],
      _ => const [],
    };
  }
}

class _ToolbarButtonView extends StatelessWidget {
  const _ToolbarButtonView({required this.button, this.focusNode, this.expanded});

  final KumoToolbarButton button;
  final FocusNode? focusNode;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final height = math.max(36.0, kumo.minTapTarget);
    final iconOnly = button.label == null;
    final off = button._inactive;
    final toggled = button.toggled ?? false;
    Widget result = KumoPressable(
      focusNode: focusNode,
      onPress: off ? null : button.onPress,
      disabled: off,
      loading: button.loading,
      toggled: button.toggled,
      expanded: expanded,
      isLink: button.isLink,
      minTapTargetSize: 0,
      semanticLabel: button.semanticLabel,
      excludeChildSemantics: iconOnly,
      builder: (context, state) {
        final fg = toggled ? KumoColor.textStrong : KumoColor.textDefault;
        final Color? background = toggled ? (state.active ? c.fillHover : c.fill) : (state.active ? c.tint : null);
        final lead = button.loading
            ? KumoLoader(dimension: 14, color: fg)
            : (button.icon != null ? KumoIcon(button.icon!, color: fg) : null);
        return Opacity(
          opacity: off ? 0.5 : 1,
          child: Container(
            height: height,
            width: iconOnly ? height : null,
            color: background,
            alignment: Alignment.center,
            padding: iconOnly
                ? null
                : EdgeInsetsDirectional.only(start: lead != null ? KumoSpace.s2_5 : KumoSpace.s3, end: KumoSpace.s3),
            child: iconOnly
                ? lead
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: KumoSpace.s1_5,
                    children: [
                      ?lead,
                      Text(
                        button.label!,
                        maxLines: 1,
                        style: kumo.text(weight: KumoTypography.medium, color: fg),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
    if (button.tooltip != null) result = KumoTooltip(content: button.tooltip!, child: result);
    return result;
  }
}

class _ToolbarParentData extends ContainerBoxParentData<RenderBox> {
  int flex = 0;
  double minWidth = 0;
  bool overflowable = false;
  bool visible = true;
}

class _ToolbarEntry extends ParentDataWidget<_ToolbarParentData> {
  const _ToolbarEntry({required this.overflowable, required super.child, this.flex = 0, this.minWidth = 0});

  final int flex;
  final double minWidth;
  final bool overflowable;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _ToolbarParentData;
    if (data.flex == flex && data.minWidth == minWidth && data.overflowable == overflowable) return;
    data
      ..flex = flex
      ..minWidth = minWidth
      ..overflowable = overflowable;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _ToolbarLayout;
}

/// Lays out toolbar items in a row with 1px dividers. When they do not fit,
/// overflowable items are dropped from the end and the last child (the
/// "More" button) is shown in their place.
class _ToolbarLayout extends MultiChildRenderObjectWidget {
  const _ToolbarLayout({
    required this.textDirection,
    required this.divider,
    required this.overflowMenu,
    required this.onCutoff,
    required super.children,
  });

  final TextDirection textDirection;
  final Color divider;
  final bool overflowMenu;
  final ValueChanged<int> onCutoff;

  @override
  _RenderToolbar createRenderObject(BuildContext context) =>
      _RenderToolbar(textDirection: textDirection, divider: divider, overflowMenu: overflowMenu, onCutoff: onCutoff);

  @override
  void updateRenderObject(BuildContext context, _RenderToolbar renderObject) {
    renderObject
      ..textDirection = textDirection
      ..divider = divider
      ..overflowMenu = overflowMenu
      ..onCutoff = onCutoff;
  }
}

class _Plan {
  _Plan(this.widths, this.heights, this.visible, this.cutoff, this.moreSize);

  final List<double> widths;
  final List<double> heights;
  final List<bool> visible;
  final int cutoff;
  final Size moreSize;

  bool get showMore => visible.contains(false);
}

class _RenderToolbar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ToolbarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ToolbarParentData> {
  _RenderToolbar({
    required TextDirection textDirection,
    required Color divider,
    required bool overflowMenu,
    required this.onCutoff,
  }) : _textDirection = textDirection,
       _divider = divider,
       _overflowMenu = overflowMenu;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Color _divider;
  set divider(Color value) {
    if (value == _divider) return;
    _divider = value;
    markNeedsPaint();
  }

  bool _overflowMenu;
  set overflowMenu(bool value) {
    if (value == _overflowMenu) return;
    _overflowMenu = value;
    markNeedsLayout();
  }

  ValueChanged<int> onCutoff;
  int? _reportedCutoff;
  final List<double> _dividerXs = [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ToolbarParentData) child.parentData = _ToolbarParentData();
  }

  _Plan _plan(BoxConstraints constraints, ChildLayouter layoutChild) {
    final children = getChildrenAsList();
    final items = children.sublist(0, children.length - 1);
    final more = children.last;
    final loose = BoxConstraints(maxHeight: constraints.maxHeight);
    final widths = <double>[];
    final heights = <double>[];
    for (final child in items) {
      final data = child.parentData! as _ToolbarParentData;
      if (data.flex > 0) {
        final size = layoutChild(child, BoxConstraints.tightFor(width: data.minWidth).enforce(loose));
        widths.add(data.minWidth);
        heights.add(size.height);
      } else {
        final size = layoutChild(child, loose);
        widths.add(size.width);
        heights.add(size.height);
      }
    }
    final moreSize = layoutChild(more, loose);
    final visible = List<bool>.filled(items.length, true);
    double total() {
      var sum = 0.0;
      var count = 0;
      for (var i = 0; i < items.length; i++) {
        if (!visible[i]) continue;
        sum += widths[i];
        count++;
      }
      return sum + math.max(0, count - 1);
    }

    var cutoff = items.length;
    final maxWidth = constraints.maxWidth;
    if (_overflowMenu && maxWidth.isFinite && total() > maxWidth + 0.5) {
      for (var i = items.length - 1; i >= 0; i--) {
        if (!(items[i].parentData! as _ToolbarParentData).overflowable) continue;
        visible[i] = false;
        cutoff = i;
        if (total() + 1 + moreSize.width <= maxWidth + 0.5) break;
      }
    }
    return _Plan(widths, heights, visible, cutoff, moreSize);
  }

  Size _sizeFor(BoxConstraints constraints, _Plan plan, {List<double>? finalWidths}) {
    final items = plan.widths.length;
    var height = constraints.minHeight;
    var width = 0.0;
    var count = 0;
    var hasFlex = false;
    final children = getChildrenAsList();
    for (var i = 0; i < items; i++) {
      if (!plan.visible[i]) continue;
      height = math.max(height, plan.heights[i]);
      width += finalWidths?[i] ?? plan.widths[i];
      count++;
      if ((children[i].parentData! as _ToolbarParentData).flex > 0) hasFlex = true;
    }
    if (plan.showMore) {
      height = math.max(height, plan.moreSize.height);
      width += plan.moreSize.width;
      count++;
    }
    width += math.max(0, count - 1);
    if (hasFlex && constraints.maxWidth.isFinite) width = math.max(width, constraints.maxWidth);
    return constraints.constrain(Size(width, height));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (firstChild == null) return constraints.smallest;
    return _sizeFor(constraints, _plan(constraints, ChildLayoutHelper.dryLayoutChild));
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    _dividerXs.clear();
    if (firstChild == null) {
      size = constraints.smallest;
      return;
    }
    final plan = _plan(constraints, ChildLayoutHelper.layoutChild);
    final children = getChildrenAsList();
    final items = children.sublist(0, children.length - 1);
    final more = children.last;

    // Free width goes to flexible slots.
    final widths = [...plan.widths];
    var flexTotal = 0;
    for (var i = 0; i < items.length; i++) {
      final data = items[i].parentData! as _ToolbarParentData;
      data.visible = plan.visible[i];
      if (data.visible) flexTotal += data.flex;
    }
    final natural = _sizeFor(constraints, plan, finalWidths: widths);
    if (flexTotal > 0) {
      var used = 0.0;
      var count = 0;
      for (var i = 0; i < items.length; i++) {
        if (!plan.visible[i]) continue;
        used += widths[i];
        count++;
      }
      if (plan.showMore) {
        used += plan.moreSize.width;
        count++;
      }
      used += math.max(0, count - 1);
      final free = math.max(0.0, natural.width - used);
      for (var i = 0; i < items.length; i++) {
        final data = items[i].parentData! as _ToolbarParentData;
        if (plan.visible[i] && data.flex > 0) widths[i] += free * data.flex / flexTotal;
      }
    }
    final height = natural.height;

    final rtl = _textDirection == TextDirection.rtl;
    var x = 0.0;
    var first = true;
    void place(RenderBox child, double width) {
      if (!first) {
        _dividerXs.add(rtl ? natural.width - x - 1 : x);
        x += 1;
      }
      first = false;
      child.layout(BoxConstraints.tight(Size(width, height)), parentUsesSize: true);
      final data = child.parentData! as _ToolbarParentData;
      data.offset = Offset(rtl ? natural.width - x - width : x, 0);
      x += width;
    }

    for (var i = 0; i < items.length; i++) {
      if (plan.visible[i]) place(items[i], widths[i]);
    }
    final moreData = more.parentData! as _ToolbarParentData;
    moreData.visible = plan.showMore;
    if (plan.showMore) place(more, plan.moreSize.width);
    size = natural;

    if (_reportedCutoff != plan.cutoff) {
      _reportedCutoff = plan.cutoff;
      final cutoff = plan.cutoff;
      // The widget tree (focus, semantics, menu items) follows next frame.
      SchedulerBinding.instance.addPostFrameCallback((_) => onCutoff(cutoff));
    }
  }

  bool _isVisible(RenderBox child) => (child.parentData! as _ToolbarParentData).visible;

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _ToolbarParentData;
      if (data.visible) context.paintChild(child, data.offset + offset);
      child = data.nextSibling;
    }
    final paint = Paint()..color = _divider;
    for (final x in _dividerXs) {
      context.canvas.drawRect(Rect.fromLTWH(offset.dx + x, offset.dy, 1, size.height), paint);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final data = child.parentData! as _ToolbarParentData;
      if (data.visible) {
        final hit = result.addWithPaintOffset(
          offset: data.offset,
          position: position,
          hitTest: (result, transformed) => child!.hitTest(result, position: transformed),
        );
        if (hit) return true;
      }
      child = data.previousSibling;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren((child) {
      if (_isVisible(child as RenderBox)) visitor(child);
    });
  }

  @override
  double computeMinIntrinsicHeight(double width) => _maxChild((c) => c.getMinIntrinsicHeight(double.infinity));

  @override
  double computeMaxIntrinsicHeight(double width) => _maxChild((c) => c.getMaxIntrinsicHeight(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) {
    final children = getChildrenAsList();
    var sum = 0.0;
    for (final c in children.sublist(0, children.length - 1)) {
      final data = c.parentData! as _ToolbarParentData;
      sum += data.flex > 0 ? data.minWidth : c.getMaxIntrinsicWidth(height);
    }
    return sum + math.max(0, children.length - 2);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (!_overflowMenu) return computeMaxIntrinsicWidth(height);
    final children = getChildrenAsList();
    var sum = children.last.getMaxIntrinsicWidth(height);
    for (final c in children.sublist(0, children.length - 1)) {
      final data = c.parentData! as _ToolbarParentData;
      if (data.overflowable) continue;
      sum += (data.flex > 0 ? data.minWidth : c.getMaxIntrinsicWidth(height)) + 1;
    }
    return sum;
  }

  double _maxChild(double Function(RenderBox) measure) {
    var result = 0.0;
    var child = firstChild;
    while (child != null) {
      result = math.max(result, measure(child));
      child = childAfter(child);
    }
    return result;
  }
}
