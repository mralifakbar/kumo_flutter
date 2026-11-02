import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../system/kumo_focus_ring.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// A section in a [KumoTableOfContents]. Items with [children] are Kumo's
/// `TableOfContents.Group`: the label heads a nested list.
///
/// ```dart
/// const KumoTableOfContentsItem(id: 'routes', label: 'Routes', children: [
///   KumoTableOfContentsItem(id: 'custom-domains', label: 'Custom domains'),
/// ])
/// ```
@immutable
class KumoTableOfContentsItem {
  const KumoTableOfContentsItem({
    required this.id,
    required this.label,
    this.children = const [],
    this.selectable = true,
  });

  /// Matches a key in [KumoTableOfContents.anchors].
  final String id;
  final String label;
  final List<KumoTableOfContentsItem> children;

  /// For groups: false makes the label a plain title rather than a link
  /// (Kumo's group without `href`).
  final bool selectable;
}

/// Kumo's `TableOfContents` with the scroll tracking of its
/// `useTableOfContentsActiveId` hook built in.
///
/// Give it the [scrollController] of the page and a [GlobalKey] on each
/// section's heading in [anchors]. The topmost heading in view (below
/// [offset], usually a sticky header's height) is the active item. A tap
/// scrolls to the section with an animation and keeps it active until
/// scrolling settles, even when the section is too short to reach the top.
///
/// ```dart
/// KumoTableOfContents(
///   title: 'On this page',
///   scrollController: scroll,
///   anchors: {'overview': overviewKey, 'routes': routesKey, 'bindings': bindingsKey},
///   items: const [
///     KumoTableOfContentsItem(id: 'overview', label: 'Overview'),
///     KumoTableOfContentsItem(id: 'routes', label: 'Routes'),
///     KumoTableOfContentsItem(id: 'bindings', label: 'Bindings'),
///   ],
/// )
/// ```
///
/// To drive the highlight yourself (Kumo's presentational use), pass
/// [activeId] and [onSelect] and leave the controller out.
class KumoTableOfContents extends StatefulWidget {
  const KumoTableOfContents({
    super.key,
    required this.items,
    this.title,
    this.scrollController,
    this.anchors = const {},
    this.offset = 0,
    this.activeId,
    this.onActiveIdChange,
    this.onSelect,
    this.semanticLabel,
  });

  final List<KumoTableOfContentsItem> items;

  /// Small uppercase heading above the list (Kumo's `TableOfContents.Title`).
  final String? title;

  /// The scroll view holding the sections. Enables tracking and tap-to-scroll.
  final ScrollController? scrollController;

  /// The heading of each section, by item id.
  final Map<String, GlobalKey> anchors;

  /// Distance from the top of the scroll view to the activation line, such
  /// as a sticky header's height. Taps scroll a section to this line too.
  final double offset;

  /// Forces the highlighted item. When null, tracking decides.
  final String? activeId;

  /// Called when tracking changes the active section.
  final ValueChanged<String>? onActiveIdChange;

  /// Called when an item is tapped, after the scroll starts.
  final ValueChanged<String>? onSelect;

  /// Accessible name of the list. Defaults to [KumoStrings.tableOfContents].
  final String? semanticLabel;

  @override
  State<KumoTableOfContents> createState() => _KumoTableOfContentsState();
}

class _KumoTableOfContentsState extends State<KumoTableOfContents> with TickerProviderStateMixin {
  /// How long scrolling must be quiet before a tapped section unpins.
  static const Duration _settle = Duration(milliseconds: 150);

  String? _tracked;
  bool _pinned = false;
  Timer? _unpin;

  // The brand rule of the active item is one indicator that springs along
  // the rail from the previous item, so the eye follows the reading position.
  final GlobalKey _railKey = GlobalKey();
  final Map<String, GlobalKey> _rowKeys = {};
  late final AnimationController _ruleTop;
  late final AnimationController _ruleHeight;
  bool _rulePlaced = false;
  String? _ruleFor;
  ({double top, double height})? _ruleTarget;
  bool _measureScheduled = false;

  String? get _active => widget.activeId ?? _tracked;

  @override
  void initState() {
    super.initState();
    _ruleTop = AnimationController.unbounded(vsync: this);
    _ruleHeight = AnimationController.unbounded(vsync: this);
    widget.scrollController?.addListener(_onScroll);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recompute();
    });
  }

  @override
  void didUpdateWidget(KumoTableOfContents oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _unpin?.cancel();
    _ruleTop.dispose();
    _ruleHeight.dispose();
    super.dispose();
  }

  void _scheduleRule() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (mounted) _placeRule();
    });
  }

  /// Moves the rule to the active row: a spring when the active item
  /// changed, an instant move for layout changes and the first placement.
  void _placeRule() {
    final id = _active;
    final rail = _railKey.currentContext?.findRenderObject();
    final row = id == null ? null : _rowKeys[id]?.currentContext?.findRenderObject();
    if (rail is! RenderBox || row is! RenderBox || !rail.hasSize || !row.hasSize) {
      if (_rulePlaced) setState(() => _rulePlaced = false);
      _ruleFor = null;
      _ruleTarget = null;
      return;
    }
    final target = (top: row.localToGlobal(Offset.zero, ancestor: rail).dy, height: row.size.height);
    if (target == _ruleTarget && _ruleFor == id) return;
    final changed = _ruleFor != id;
    final moving = _ruleTop.isAnimating || _ruleHeight.isAnimating;
    _ruleFor = id;
    _ruleTarget = target;
    if (_rulePlaced && (changed || moving) && !KumoMotion.reduceMotion(context)) {
      KumoMotion.springTo(_ruleTop, target.top, velocity: _ruleTop.velocity);
      KumoMotion.springTo(_ruleHeight, target.height, velocity: _ruleHeight.velocity);
      return;
    }
    _ruleTop.value = target.top;
    _ruleHeight.value = target.height;
    if (!_rulePlaced) setState(() => _rulePlaced = true);
  }

  List<String> get _order {
    final ids = <String>[];
    void walk(List<KumoTableOfContentsItem> items) {
      for (final item in items) {
        ids.add(item.id);
        walk(item.children);
      }
    }

    walk(widget.items);
    return ids;
  }

  void _onScroll() {
    if (_pinned) {
      _armUnpin();
      return;
    }
    _recompute();
  }

  void _armUnpin() {
    _unpin?.cancel();
    _unpin = Timer(_settle, () => _pinned = false);
  }

  RenderBox? _viewport() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return null;
    final ctx = controller.position.context.notificationContext;
    final box = ctx?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  void _recompute() {
    final viewport = _viewport();
    if (viewport == null) return;
    final top = viewport.localToGlobal(Offset.zero).dy + widget.offset;
    final bottom = viewport.localToGlobal(Offset(0, viewport.size.height)).dy;
    for (final id in _order) {
      final box = widget.anchors[id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height > top && y < bottom) {
        _setTracked(id);
        return;
      }
    }
    // Inside a long section with no heading in view: keep the last one.
  }

  void _setTracked(String id) {
    if (id == _tracked) return;
    setState(() => _tracked = id);
    if (widget.activeId == null) widget.onActiveIdChange?.call(id);
  }

  void _select(String id) {
    _pinned = true;
    _armUnpin();
    if (id != _tracked) {
      setState(() => _tracked = id);
      if (widget.activeId == null) widget.onActiveIdChange?.call(id);
    }
    _scrollTo(id);
    widget.onSelect?.call(id);
  }

  void _scrollTo(String id) {
    final controller = widget.scrollController;
    final box = widget.anchors[id]?.currentContext?.findRenderObject();
    if (controller == null || !controller.hasClients || box == null) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final position = controller.position;
    final target = (viewport.getOffsetToReveal(box, 0).offset - widget.offset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final duration = KumoMotion.duration(context, KumoDurations.slow);
    if (duration == Duration.zero) {
      position.jumpTo(target);
    } else {
      position.animateTo(target, duration: duration, curve: KumoCurves.standard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final touch = kumo.minTapTarget > 0;
    final children = <Widget>[
      if (widget.title != null)
        Padding(
          padding: const EdgeInsets.only(bottom: KumoSpace.s3),
          child: Semantics(
            header: true,
            child: Text(
              widget.title!.toUpperCase(),
              style: kumo.text(size: KumoTextSize.xs, weight: KumoTypography.semibold, color: KumoColor.textSubtle),
            ),
          ),
        ),
      _list(context, widget.items, nested: false, touch: touch),
    ];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel ?? context.kumoStrings.tableOfContents,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _list(BuildContext context, List<KumoTableOfContentsItem> items, {required bool nested, required bool touch}) {
    final c = context.kumo.colors;
    final rows = <Widget>[];
    for (final item in items) {
      if (item.children.isEmpty) {
        rows.add(_row(context, item, nested: nested, touch: touch));
        continue;
      }
      rows.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: touch ? 0 : KumoSpace.s2,
          children: [
            item.selectable
                ? _row(context, item, nested: nested, touch: touch)
                : _groupTitle(context, item, touch: touch),
            _list(context, item.children, nested: true, touch: touch),
          ],
        ),
      );
    }
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: touch ? 0 : KumoSpace.s2,
      children: rows,
    );
    if (nested) return column;
    // `border-l-2 border-kumo-hairline`. Hovered items draw a 2px rule on top
    // of it (Kumo's `-ml-0.5`); the active item's brand rule is one indicator
    // that moves between items.
    _scheduleRule();
    return Stack(
      key: _railKey,
      children: [
        PositionedDirectional(start: 0, top: 0, bottom: 0, width: 2, child: ColoredBox(color: c.hairline)),
        column,
        if (_rulePlaced)
          AnimatedBuilder(
            animation: Listenable.merge([_ruleTop, _ruleHeight]),
            builder: (context, _) => PositionedDirectional(
              key: const ValueKey('kumo-toc-indicator'),
              start: 0,
              width: 2,
              top: _ruleTop.value,
              height: _ruleHeight.value.clamp(0.0, double.infinity),
              child: IgnorePointer(child: ColoredBox(color: c.brand)),
            ),
          ),
      ],
    );
  }

  Widget _groupTitle(BuildContext context, KumoTableOfContentsItem item, {required bool touch}) {
    final kumo = context.kumo;
    return Container(
      constraints: BoxConstraints(minHeight: touch ? 44 : 24),
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsetsDirectional.only(start: KumoSpace.s4, top: KumoSpace.s0_5, bottom: KumoSpace.s0_5),
      child: Text(
        item.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: kumo.text(
          size: KumoTextSize.sm,
          weight: KumoTypography.medium,
          color: KumoColor.textSubtle,
          height: 20 / 13,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, KumoTableOfContentsItem item, {required bool nested, required bool touch}) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final active = item.id == _active;
    final row = KumoPressable(
      onPress: () => _select(item.id),
      isLink: true,
      selected: active,
      scaleOnPress: false,
      showFocusRing: false,
      minTapTargetSize: 0,
      builder: (context, state) {
        final emphasized = active || state.active;
        final rule = !active && state.active ? c.line : const Color(0x00000000);
        return KumoFocusRing(
          visible: state.focused,
          borderRadius: BorderRadius.circular(KumoRadius.sm),
          child: Container(
            constraints: BoxConstraints(minHeight: touch ? 44 : 24),
            alignment: AlignmentDirectional.centerStart,
            decoration: BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: rule, width: 2)),
            ),
            padding: EdgeInsetsDirectional.only(
              start: nested ? KumoSpace.step(7) : KumoSpace.s4,
              top: KumoSpace.s0_5,
              bottom: KumoSpace.s0_5,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kumo.text(
                size: KumoTextSize.sm,
                weight: emphasized ? KumoTypography.medium : KumoTypography.normal,
                color: emphasized ? KumoColor.textDefault : KumoColor.textSubtle,
                height: 20 / 13,
              ),
            ),
          ),
        );
      },
    );
    return KeyedSubtree(key: _rowKeys.putIfAbsent(item.id, GlobalKey.new), child: row);
  }
}
