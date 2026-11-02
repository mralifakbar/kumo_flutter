import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Tab styles from Kumo's `Tabs`.
enum KumoTabsVariant {
  /// A raised pill on a recessed track. The default.
  segmented,

  /// A 2px brand bar under the active label, over a hairline.
  underline,
}

/// Tab sizes. [base] matches a 36px input, [sm] a 26px one.
enum KumoTabsSize {
  /// 26px track (`h-6.5`), 12px labels.
  sm(26, KumoTextSize.xs, 14),

  /// 36px track (`h-9`), 14px labels.
  base(36, KumoTextSize.base, 16);

  const KumoTabsSize(this.trackHeight, this.textSize, this.iconSize);

  /// Height of the segmented track, and of the underline list.
  final double trackHeight;
  final KumoTextSize textSize;
  final double iconSize;
}

/// One tab of a [KumoTabs] (Kumo's `TabsItem`).
///
/// ```dart
/// const KumoTab(value: 'logs', label: 'Logs', icon: KumoIcons.listBullets)
/// ```
@immutable
class KumoTab {
  const KumoTab({required this.value, required this.label, this.icon, this.disabled = false, this.semanticLabel});

  /// Identifies the tab; [KumoTabs.value] holds the active one.
  final String value;
  final String label;

  /// Optional leading icon, 16px (14px at [KumoTabsSize.sm]).
  final IconData? icon;

  /// Shown dimmed, skipped by arrow keys, cannot be selected.
  final bool disabled;
  final String? semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is KumoTab &&
      other.value == value &&
      other.label == label &&
      other.icon == icon &&
      other.disabled == disabled &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(value, label, icon, disabled, semanticLabel);
}

/// Kumo's `Tabs`: a row of tabs with a moving active indicator.
///
/// The indicator springs from wherever it is to the new tab, so rapid taps
/// never jump. On touch, the segmented pill can be grabbed and dragged
/// across tabs; the release velocity picks where it lands. When tabs do not
/// fit, the row scrolls with faded edges (Kumo's scroll-fade) and, for the
/// segmented variant, chevron buttons at each end.
///
/// Keyboard: Tab reaches the active tab only (roving focus); Left and Right
/// move between tabs, Home and End jump to the ends, Enter or Space selects.
/// Set [activateOnFocus] to select as focus moves.
///
/// ```dart
/// KumoTabs(
///   tabs: const [
///     KumoTab(value: 'overview', label: 'Overview'),
///     KumoTab(value: 'metrics', label: 'Metrics'),
///     KumoTab(value: 'settings', label: 'Settings'),
///   ],
///   value: tab,
///   onValueChange: (v) => setState(() => tab = v),
/// )
/// ```
///
/// Pair with [KumoTabPanels] and a shared [PageController] for panels that
/// swipe with the finger while the indicator follows.
class KumoTabs extends StatefulWidget {
  const KumoTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.onValueChange,
    this.variant = KumoTabsVariant.segmented,
    this.size = KumoTabsSize.base,
    this.activateOnFocus = false,
    this.pageController,
    this.haptic,
    this.semanticLabel,
    this.scrollStartLabel,
    this.scrollEndLabel,
  });

  final List<KumoTab> tabs;

  /// The active tab's [KumoTab.value]. Null, or a value no tab has, shows no
  /// indicator.
  final String? value;

  /// Called with the next value. Null makes every tab read-only.
  final ValueChanged<String>? onValueChange;
  final KumoTabsVariant variant;
  final KumoTabsSize size;

  /// Select a tab as soon as arrow keys focus it. Off by default, like Kumo:
  /// arrows move focus and Enter or Space selects.
  final bool activateOnFocus;

  /// The controller of a [KumoTabPanels] (or any [PageView]) whose pages
  /// match [tabs]. While the pages are dragged, the indicator follows them.
  final PageController? pageController;

  /// Feedback on selection change. Defaults to a selection click for
  /// [KumoTabsVariant.segmented] and none for underline tabs.
  final KumoHaptic? haptic;

  /// Accessible name of the tab list.
  final String? semanticLabel;

  /// Accessible name of the button that scrolls toward the first tab.
  /// Defaults to [KumoStrings.scrollTabsStart].
  final String? scrollStartLabel;

  /// Accessible name of the button that scrolls toward the last tab.
  /// Defaults to [KumoStrings.scrollTabsEnd].
  final String? scrollEndLabel;

  @override
  State<KumoTabs> createState() => _KumoTabsState();
}

class _KumoTabsState extends State<KumoTabs> with TickerProviderStateMixin {
  static const double _fadeWidth = 48;

  final GlobalKey _stackKey = GlobalKey();
  final List<GlobalKey> _keys = [];
  final List<FocusNode> _nodes = [];
  final ScrollController _scroll = ScrollController();
  late final AnimationController _x;
  late final AnimationController _w;
  late final AnimationController _press;
  List<Rect>? _rects;
  bool _measureScheduled = false;
  bool _indicatorPlaced = false;
  double? _xTarget;
  double? _wTarget;
  double? _page;

  // Drag of the segmented pill.
  bool _dragging = false;
  double _dragStartCenter = 0;
  double _dragStartGlobal = 0;
  int? _preview;

  bool _canScrollStart = false;
  bool _canScrollEnd = false;

  bool get _segmented => widget.variant == KumoTabsVariant.segmented;
  int get _active => widget.value == null ? -1 : widget.tabs.indexWhere((t) => t.value == widget.value);
  bool _enabled(int i) => widget.onValueChange != null && !widget.tabs[i].disabled;
  KumoHaptic get _haptic => widget.haptic ?? (_segmented ? KumoHaptic.selection : KumoHaptic.none);

  @override
  void initState() {
    super.initState();
    _x = AnimationController.unbounded(vsync: this);
    _w = AnimationController.unbounded(vsync: this);
    _press = AnimationController.unbounded(vsync: this, value: 1);
    _scroll.addListener(_updateOverflow);
    widget.pageController?.addListener(_onPage);
    _syncTabs();
  }

  @override
  void didUpdateWidget(KumoTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTabs();
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController?.removeListener(_onPage);
      widget.pageController?.addListener(_onPage);
      _page = null;
    }
    if (oldWidget.value != widget.value) {
      if (!_dragging && _page == null) _moveIndicator(animate: true);
      _scheduleRevealActive();
    }
    if (!listEquals(oldWidget.tabs, widget.tabs) ||
        oldWidget.size != widget.size ||
        oldWidget.variant != widget.variant) {
      _scheduleMeasure();
    }
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onPage);
    _scroll.dispose();
    _x.dispose();
    _w.dispose();
    _press.dispose();
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncTabs() {
    while (_nodes.length < widget.tabs.length) {
      _nodes.add(FocusNode(debugLabel: 'KumoTab ${_nodes.length}'));
      _keys.add(GlobalKey());
    }
    while (_nodes.length > widget.tabs.length) {
      _nodes.removeLast().dispose();
      _keys.removeLast();
    }
    // Roving focus: only one tab sits in the Tab order.
    final rover = _active >= 0 ? _active : _firstEnabled();
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != rover;
    }
  }

  int _firstEnabled() {
    for (var i = 0; i < widget.tabs.length; i++) {
      if (!widget.tabs[i].disabled) return i;
    }
    return 0;
  }

  bool get _reduceMotion => KumoMotion.reduceMotion(context);

  void _select(int i) {
    if (!_enabled(i)) return;
    final tab = widget.tabs[i];
    if (tab.value != widget.value) {
      kumoHaptic(_haptic);
      widget.onValueChange!(tab.value);
    }
    _reveal(i);
  }

  // Measurement ------------------------------------------------------------

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (mounted) _measure();
    });
  }

  void _measure() {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;
    final rects = <Rect>[];
    for (final key in _keys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      rects.add(box.localToGlobal(Offset.zero, ancestor: stackBox) & box.size);
    }
    final first = _rects == null;
    if (!listEquals(rects, _rects)) {
      setState(() => _rects = rects);
      // Layout changes (resize, text scale, new labels) move the indicator
      // without animating; only selection changes animate.
      if (!_dragging && _page == null) _moveIndicator(animate: false);
      if (first) _reveal(_active, animate: false);
    }
    _updateOverflow();
  }

  Rect? _rectAt(int i) {
    final rects = _rects;
    if (rects == null || i < 0 || i >= rects.length) return null;
    return rects[i];
  }

  void _moveIndicator({required bool animate, double velocity = 0}) {
    final rect = _rectAt(_active);
    if (rect == null) return;
    _springTo(rect.left, rect.width, animate: animate, velocity: velocity);
  }

  void _springTo(double x, double width, {required bool animate, double velocity = 0}) {
    if (!_indicatorPlaced || !animate || _reduceMotion) {
      _indicatorPlaced = true;
      _xTarget = x;
      _wTarget = width;
      _x.value = x;
      _w.value = width;
      return;
    }
    if (_xTarget != x || !_x.isAnimating && _x.value != x) {
      _xTarget = x;
      KumoMotion.springTo(_x, x, velocity: velocity != 0 ? velocity : _x.velocity);
    }
    if (_wTarget != width || !_w.isAnimating && _w.value != width) {
      _wTarget = width;
      KumoMotion.springTo(_w, width, velocity: _w.velocity);
    }
  }

  void _setIndicator(double x, double width) {
    _indicatorPlaced = true;
    _xTarget = null;
    _wTarget = null;
    _x.value = x;
    _w.value = width;
  }

  // Page tracking ------------------------------------------------------------

  void _onPage() {
    final controller = widget.pageController;
    final rects = _rects;
    if (controller == null || rects == null || rects.isEmpty) return;
    if (!controller.hasClients || controller.positions.length != 1) return;
    final position = controller.position;
    if (!position.hasContentDimensions) return;
    final page = controller.page;
    if (page == null) return;
    final atRest = (page - page.roundToDouble()).abs() < 0.001;
    if (atRest) {
      if (_page != null) {
        _page = null;
        _moveIndicator(animate: true);
      }
      return;
    }
    _page = page;
    if (_dragging) return;
    final lower = page.floor().clamp(0, rects.length - 1);
    final upper = page.ceil().clamp(0, rects.length - 1);
    final t = (page - page.floor()).clamp(0.0, 1.0);
    final rect = Rect.lerp(rects[lower], rects[upper], t)!;
    _setIndicator(rect.left, rect.width);
  }

  // Scrolling ----------------------------------------------------------------

  void _updateOverflow() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (!p.hasContentDimensions) return;
    final start = p.pixels > 1;
    final end = p.maxScrollExtent - p.pixels > 1;
    if (start != _canScrollStart || end != _canScrollEnd) {
      setState(() {
        _canScrollStart = start;
        _canScrollEnd = end;
      });
    }
  }

  void _scheduleRevealActive() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(_active);
    });
  }

  /// Scrolls the tab at [i] into view, clear of the edge fades (Kumo's
  /// `scroll-px` equal to the fade width).
  void _reveal(int i, {bool animate = true}) {
    final rect = _rectAt(i);
    if (rect == null || !_scroll.hasClients) return;
    final p = _scroll.position;
    if (!p.hasContentDimensions || p.maxScrollExtent <= 0) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final contentWidth = stackBox.size.width;
    final start = rtl ? contentWidth - rect.right : rect.left;
    final end = start + rect.width;
    final viewport = p.viewportDimension;
    final pad = math.min(_fadeWidth, math.max(0.0, (viewport - rect.width) / 2));
    var target = p.pixels;
    if (start - pad < p.pixels) {
      target = start - pad;
    } else if (end + pad > p.pixels + viewport) {
      target = end + pad - viewport;
    }
    target = target.clamp(0.0, p.maxScrollExtent);
    if ((target - p.pixels).abs() < 0.5) return;
    final duration = animate ? KumoMotion.duration(context, KumoDurations.moderate) : Duration.zero;
    if (duration == Duration.zero) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: duration, curve: KumoCurves.standard);
    }
  }

  void _scrollBy(bool towardStart) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final viewport = p.viewportDimension;
    // Kumo scrolls by the width of the tabs that fit in the viewport.
    var distance = 0.0;
    for (final r in _rects ?? const <Rect>[]) {
      if (distance + r.width > viewport) break;
      distance += r.width;
    }
    if (distance == 0) distance = math.max(80, viewport * 0.8);
    final target = (p.pixels + (towardStart ? -distance : distance)).clamp(0.0, p.maxScrollExtent);
    final duration = KumoMotion.duration(context, KumoDurations.slow);
    if (duration == Duration.zero) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: duration, curve: KumoCurves.standard);
    }
  }

  // Keyboard -----------------------------------------------------------------

  int? _step(int from, int delta) {
    final n = widget.tabs.length;
    for (var k = 1; k <= n; k++) {
      final i = ((from + delta * k) % n + n) % n;
      if (!widget.tabs[i].disabled) return i;
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final focused = _nodes.indexWhere((n) => n.hasFocus);
    if (focused < 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    int? target;
    if (key == LogicalKeyboardKey.arrowRight) {
      target = _step(focused, rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      target = _step(focused, rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      target = _step(-1, 1);
    } else if (key == LogicalKeyboardKey.end) {
      target = _step(widget.tabs.length, -1);
    } else {
      return KeyEventResult.ignored;
    }
    if (target != null) {
      _nodes[target].requestFocus();
      if (widget.activateOnFocus) {
        _select(target);
      } else {
        _reveal(target);
      }
    }
    return KeyEventResult.handled;
  }

  // Dragging the segmented pill ---------------------------------------------

  double _centerOf(int i) => _rects![i].center.dx;

  Rect _rectForCenter(double c) {
    final rects = _rects!;
    if (c <= rects.first.center.dx) {
      return Rect.fromCenter(
        center: Offset(c, rects.first.center.dy),
        width: rects.first.width,
        height: rects.first.height,
      );
    }
    if (c >= rects.last.center.dx) {
      return Rect.fromCenter(
        center: Offset(c, rects.last.center.dy),
        width: rects.last.width,
        height: rects.last.height,
      );
    }
    for (var i = 0; i < rects.length - 1; i++) {
      final a = rects[i].center.dx;
      final b = rects[i + 1].center.dx;
      if (c >= a && c <= b) {
        final t = b == a ? 0.0 : (c - a) / (b - a);
        final width = rects[i].width + (rects[i + 1].width - rects[i].width) * t;
        return Rect.fromCenter(center: Offset(c, rects[i].center.dy), width: width, height: rects[i].height);
      }
    }
    return rects.last;
  }

  int? _nearestEnabled(double c) {
    int? best;
    var bestDistance = double.infinity;
    for (var i = 0; i < widget.tabs.length; i++) {
      if (!_enabled(i)) continue;
      final d = (_centerOf(i) - c).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }

  void _onDragStart(DragStartDetails details) {
    if (_rects == null || _active < 0) return;
    _dragging = true;
    _dragStartGlobal = details.globalPosition.dx;
    _dragStartCenter = _x.value + _w.value / 2;
    _x.stop();
    _w.stop();
    _pressTo(0.97);
    setState(() => _preview = _active);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final rects = _rects!;
    final min = rects.first.center.dx;
    final max = rects.last.center.dx;
    var c = _dragStartCenter + details.globalPosition.dx - _dragStartGlobal;
    final span = rects.last.right - rects.first.left;
    if (c < min) c = min + KumoMotion.rubberband(c - min, span);
    if (c > max) c = max + KumoMotion.rubberband(c - max, span);
    final rect = _rectForCenter(c);
    _setIndicator(rect.left, rect.width);
    final preview = _nearestEnabled(c);
    if (preview != _preview) {
      kumoHaptic(KumoHaptic.selection);
      setState(() => _preview = preview);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final center = _x.value + _w.value / 2;
    final target = _nearestEnabled(center + KumoMotion.project(velocity)) ?? _active;
    _dragging = false;
    setState(() => _preview = null);
    _pressTo(1);
    final rect = _rectAt(target);
    if (rect != null) {
      _indicatorPlaced = true;
      _springTo(rect.left, rect.width, animate: true, velocity: velocity);
    }
    if (target != _active) {
      // The preview already clicked while crossing tabs; commit quietly.
      final tab = widget.tabs[target];
      widget.onValueChange?.call(tab.value);
      _reveal(target);
    }
    // A controlled parent may keep the old value; settle on whatever is active.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dragging) _moveIndicator(animate: true);
    });
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    setState(() => _preview = null);
    _pressTo(1);
    _moveIndicator(animate: true);
  }

  void _pressTo(double scale) {
    if (_reduceMotion) {
      _press.value = 1;
      return;
    }
    KumoMotion.springTo(_press, scale, spring: KumoSprings.press, velocity: _press.velocity);
  }

  // Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) return const SizedBox.shrink();
    _scheduleMeasure();
    final kumo = context.kumo;
    final c = kumo.colors;
    final size = widget.size;
    final sm = size == KumoTabsSize.sm;
    final textScaler = MediaQuery.textScalerOf(context);
    final lineHeight = textScaler.scale(size.textSize.fontSize) * KumoTypography.bodyHeight;
    final minTap = kumo.minTapTarget;
    final active = _active;
    final lit = _preview ?? active;

    // Segmented: the pill is the track minus `my-0.5` (2px) on each side.
    // Underline: a label box, `pb-2` (8px) below it, then the hairline.
    final visualHeight = _segmented
        ? math.max(size.trackHeight - 4, lineHeight)
        : math.max(size.trackHeight - 8, lineHeight);
    final trackHeight = _segmented ? visualHeight + 4 : visualHeight + 8;
    final rowHeight = math.max(trackHeight, minTap);
    final tabRadius = _segmented ? (sm ? KumoRadius.sm : KumoRadius.md) : KumoRadius.sm;
    final indicatorRadius = sm ? KumoRadius.sm : KumoRadius.md;

    final children = <Widget>[];
    for (var i = 0; i < widget.tabs.length; i++) {
      final tab = widget.tabs[i];
      final enabled = _enabled(i);
      final isActive = i == active;
      Widget item = KumoPressable(
        focusNode: _nodes[i],
        onPress: enabled ? () => _select(i) : null,
        onPressIn: isActive && _segmented ? () => _pressTo(0.97) : null,
        onPressOut: isActive && _segmented
            ? () {
                if (!_dragging) _pressTo(1);
              }
            : null,
        // A read-only bar (no onValueChange) reports its tabs as disabled:
        // Flutter requires an enabled tab to have a tap action.
        disabled: tab.disabled || widget.onValueChange == null,
        isButton: false,
        selected: isActive,
        scaleOnPress: false,
        showFocusRing: false,
        minTapTargetSize: 0,
        semanticLabel: tab.semanticLabel,
        haptic: KumoHaptic.none,
        builder: (context, state) {
          final highlighted = i == lit || state.active;
          final fg = highlighted ? KumoColor.textDefault : KumoColor.textSubtle;
          final style = kumo.text(size: size.textSize, weight: KumoTypography.medium, color: fg);
          final label = Row(
            mainAxisSize: MainAxisSize.min,
            spacing: sm ? KumoSpace.s1 : KumoSpace.s1_5,
            children: [
              if (tab.icon != null) KumoIcon(tab.icon!, size: size.iconSize, color: fg),
              Text(tab.label, style: style, maxLines: 1, softWrap: false),
            ],
          );
          Widget visual = Container(
            key: _keys[i],
            height: visualHeight,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: _segmented ? (sm ? KumoSpace.s2 : KumoSpace.s2_5) : (sm ? KumoSpace.s1_5 : KumoSpace.s2),
            ),
            decoration: BoxDecoration(
              color: !_segmented && state.active ? c.tint : null,
              borderRadius: BorderRadius.circular(tabRadius),
            ),
            child: label,
          );
          visual = KumoFocusRing(
            visible: state.focused,
            borderRadius: BorderRadius.circular(tabRadius),
            offset: _segmented ? -2 : 0,
            child: visual,
          );
          if (tab.disabled) visual = Opacity(opacity: 0.5, child: visual);
          return Semantics(
            role: SemanticsRole.tab,
            child: SizedBox(
              height: rowHeight,
              child: Padding(
                padding: EdgeInsets.only(bottom: _segmented ? 0 : KumoSpace.s2),
                child: Center(widthFactor: 1, child: visual),
              ),
            ),
          );
        },
      );
      if (isActive && _segmented && enabled) {
        item = RawGestureDetector(
          excludeFromSemantics: true,
          gestures: {
            HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer(
                supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.stylus},
              ),
              (r) => r
                ..onStart = _onDragStart
                ..onUpdate = _onDragUpdate
                ..onEnd = _onDragEnd
                ..onCancel = _onDragCancel,
            ),
          },
          child: item,
        );
      }
      children.add(item);
    }

    Widget row = Row(mainAxisSize: MainAxisSize.min, spacing: _segmented ? 0 : KumoSpace.s4, children: children);
    // The tab bar node sits inside the scroll view: Flutter requires its
    // direct children to be tabs, so the scroll and overflow nodes stay out.
    row = Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.tabBar,
      label: widget.semanticLabel,
      child: row,
    );
    row = NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _scheduleMeasure();
        return true;
      },
      child: SizeChangedLayoutNotifier(child: row),
    );

    final rect = _rectAt(active);
    Widget? indicator;
    if (rect != null && (_indicatorPlaced || _dragging)) {
      final radius = BorderRadius.circular(indicatorRadius);
      indicator = AnimatedBuilder(
        animation: Listenable.merge([_x, _w, _press]),
        builder: (context, _) {
          final Widget paint = _segmented
              ? Transform.scale(
                  scale: _press.value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.base,
                      borderRadius: radius,
                      border: KumoRing.border(c.line),
                      boxShadow: KumoShadow.sm.boxShadows,
                    ),
                  ),
                )
              : ColoredBox(color: c.brand);
          return Positioned(
            key: const ValueKey('kumo-tabs-indicator'),
            left: _x.value,
            width: math.max(0, _w.value),
            top: _segmented ? rect.top : null,
            height: _segmented ? rect.height : 2,
            bottom: _segmented ? null : 0,
            child: IgnorePointer(child: ExcludeSemantics(child: paint)),
          );
        },
      );
    }

    Widget content = Stack(key: _stackKey, clipBehavior: Clip.none, children: [?indicator, row]);

    content = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: _onKey, child: content);

    content = ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, dragDevices: {...PointerDeviceKind.values}, overscroll: false),
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.symmetric(horizontal: _segmented ? KumoSpace.s0_5 : 0),
        child: content,
      ),
    );

    content = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateOverflow();
        });
        return false;
      },
      child: content,
    );

    final rtl = Directionality.of(context) == TextDirection.rtl;
    {
      // Always masked (opaque when nothing overflows) so the scroll view
      // keeps its place in the tree and its offset.
      content = AnimatedBuilder(
        animation: _scroll,
        child: content,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            final p = _scroll.hasClients && _scroll.position.hasContentDimensions ? _scroll.position : null;
            final startFade = p == null ? 0.0 : p.pixels.clamp(0.0, _fadeWidth);
            final endFade = p == null ? 0.0 : (p.maxScrollExtent - p.pixels).clamp(0.0, _fadeWidth);
            final w = math.max(1.0, bounds.width);
            final left = (rtl ? endFade : startFade) / w;
            final right = (rtl ? startFade : endFade) / w;
            final a = left.clamp(0.0, 0.5);
            final b = (1 - right).clamp(0.5, 1.0);
            return LinearGradient(
              colors: const [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
              stops: [0, a, b, 1],
            ).createShader(bounds);
          },
          child: child,
        ),
      );
    }

    final trackTop = (rowHeight - trackHeight) / 2;
    final stackChildren = <Widget>[
      if (_segmented)
        Positioned(
          key: const ValueKey('track'),
          left: 0,
          right: 0,
          top: trackTop,
          height: trackHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.recessed,
              borderRadius: BorderRadius.circular(sm ? KumoRadius.md : KumoRadius.lg),
              border: KumoRing.border(c.hairline.withValues(alpha: c.hairline.a * 0.7)),
            ),
          ),
        ),
      KeyedSubtree(key: const ValueKey('list'), child: content),
      if (_segmented) ...[
        _overflowControl(start: true, visible: _canScrollStart, top: trackTop, height: trackHeight),
        _overflowControl(start: false, visible: _canScrollEnd, top: trackTop, height: trackHeight),
      ],
    ];

    // One tree shape for both variants, so switching variant keeps the
    // scroll view (and its controller) in place.
    // Underline tabs span the available width so the hairline does too.
    final result = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: _segmented ? null : Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: _segmented ? 0 : 1),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          widthFactor: _segmented ? 1 : null,
          heightFactor: 1,
          child: Stack(children: stackChildren),
        ),
      ),
    );
    return result;
  }

  Widget _overflowControl({required bool start, required bool visible, required double top, required double height}) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final sm = widget.size == KumoTabsSize.sm;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final pointsLeft = start != rtl;
    final radius = BorderRadius.circular(sm ? KumoRadius.md : KumoRadius.lg);
    final innerRadius = BorderRadius.circular(sm ? KumoRadius.sm : KumoRadius.md);
    return PositionedDirectional(
      key: ValueKey(start ? 'start' : 'end'),
      start: start ? 0 : null,
      end: start ? null : 0,
      top: top,
      height: height,
      width: sm ? 32 : 40,
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: KumoMotion.duration(context, KumoDurations.quick),
            curve: KumoCurves.standard,
            child: KumoPressable(
              onPress: () => _scrollBy(start),
              semanticLabel: start
                  ? widget.scrollStartLabel ?? context.kumoStrings.scrollTabsStart
                  : widget.scrollEndLabel ?? context.kumoStrings.scrollTabsEnd,
              excludeChildSemantics: true,
              scaleOnPress: false,
              showFocusRing: false,
              minTapTargetSize: 0,
              canRequestFocus: visible,
              builder: (context, state) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: pointsLeft ? Alignment.centerLeft : Alignment.centerRight,
                    end: pointsLeft ? Alignment.centerRight : Alignment.centerLeft,
                    colors: [c.recessed, c.recessed.withValues(alpha: 0.95), c.recessed.withValues(alpha: 0)],
                  ),
                ),
                child: Align(
                  alignment: start ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: start ? 4 : 0, end: start ? 0 : 4),
                    child: KumoFocusRing(
                      visible: state.focused,
                      borderRadius: innerRadius,
                      child: SizedBox.square(
                        dimension: sm ? 20 : 24,
                        child: Center(
                          child: KumoIcon(
                            pointsLeft ? KumoIcons.caretLeft : KumoIcons.caretRight,
                            size: 14,
                            color: state.active ? KumoColor.textDefault : KumoColor.textSubtle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One page of a [KumoTabPanels], matched to a [KumoTab] by [value].
@immutable
class KumoTabPanel {
  const KumoTabPanel({required this.value, required this.child});

  final String value;
  final Widget child;
}

/// The content pages of a [KumoTabs], one per tab, that swipe horizontally
/// with the finger on touch. The page follows the finger 1:1; on release the
/// fling velocity picks the page. Mouse users switch with the tabs.
///
/// Give it a bounded height (inside `Expanded` or a `SizedBox`). Share a
/// [PageController] with [KumoTabs.pageController] so the indicator tracks
/// the swipe:
///
/// ```dart
/// Column(children: [
///   KumoTabs(tabs: tabs, value: tab, onValueChange: setTab, pageController: pages),
///   Expanded(
///     child: KumoTabPanels(
///       controller: pages,
///       value: tab,
///       onValueChange: setTab,
///       panels: const [
///         KumoTabPanel(value: 'overview', child: Text('Overview')),
///         KumoTabPanel(value: 'logs', child: Text('Logs')),
///       ],
///     ),
///   ),
/// ])
/// ```
class KumoTabPanels extends StatefulWidget {
  const KumoTabPanels({
    super.key,
    required this.panels,
    required this.value,
    required this.onValueChange,
    this.controller,
    this.swipeable = true,
  });

  final List<KumoTabPanel> panels;

  /// The visible panel's value; matches [KumoTabs.value].
  final String? value;

  /// Called when a swipe settles on another panel.
  final ValueChanged<String>? onValueChange;

  /// Shared with [KumoTabs.pageController]. Created internally when null.
  final PageController? controller;

  /// Set false to switch panels only through the tabs.
  final bool swipeable;

  @override
  State<KumoTabPanels> createState() => _KumoTabPanelsState();
}

class _KumoTabPanelsState extends State<KumoTabPanels> {
  PageController? _own;
  bool _programmatic = false;
  String? _swipedTo;

  PageController get _controller => widget.controller ?? (_own ??= PageController(initialPage: _index));

  int get _index => math.max(0, widget.panels.indexWhere((p) => p.value == widget.value));

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if ((_controller.page ?? 0).round() != _index) _controller.jumpToPage(_index);
    });
  }

  @override
  void didUpdateWidget(KumoTabPanels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // A value that came from the finger is already where the page is going.
      if (widget.value == _swipedTo) {
        _swipedTo = null;
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback((_) => _goTo(_index));
    }
  }

  Future<void> _goTo(int index) async {
    if (!mounted || !_controller.hasClients) return;
    final current = _controller.page;
    if (current != null && (current - index).abs() < 0.001) return;
    final duration = KumoMotion.duration(context, KumoDurations.slow);
    if (duration == Duration.zero) {
      _controller.jumpToPage(index);
      return;
    }
    _programmatic = true;
    try {
      await _controller.animateToPage(index, duration: duration, curve: KumoCurves.standard);
    } finally {
      _programmatic = false;
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: widget.swipeable ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
      onPageChanged: (i) {
        // Pages crossed while animating to a tapped tab are not selections.
        if (_programmatic) return;
        final value = widget.panels[i].value;
        if (value != widget.value) {
          _swipedTo = value;
          widget.onValueChange?.call(value);
        }
      },
      children: [
        for (final p in widget.panels) Semantics(role: SemanticsRole.tabPanel, container: true, child: p.child),
      ],
    );
  }
}
