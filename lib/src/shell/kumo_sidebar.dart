import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Kumo's sidebar easing (`cubic-bezier(0.77, 0, 0.175, 1)`), used for the
/// width change, group labels, sub-menus and sliding views.
const Cubic _kSidebarCurve = Cubic(0.77, 0, 0.175, 1);

/// Horizontal padding of the content area when expanded (`px-3.5`).
const double _kContentInset = 14;

/// Horizontal padding of the content area in the icon rail (`px-[11px]`).
const double _kRailInset = 11;

/// Width of a top-level row in the icon rail: 57px rail, minus its 1px
/// border and 11px padding on each side.
const double _kRailItemWidth = 34;

/// Which edge the sidebar sits on. Follows the text direction: [start] is
/// the left edge in left-to-right layouts.
enum KumoSidebarSide { start, end }

/// Sidebar surfaces.
enum KumoSidebarVariant {
  /// Flush with the page edge, separated from content by a 1px border.
  sidebar,

  /// Inset 8px from the edges with rounded corners, a ring and a shadow.
  floating,
}

/// What collapsing does.
enum KumoSidebarCollapseMode {
  /// Shrinks to a 57px rail of icons with tooltips.
  icon,

  /// Slides fully out of view.
  offcanvas,

  /// Never collapses.
  none,
}

/// Row heights for [KumoSidebarMenuButton].
enum KumoSidebarMenuButtonSize {
  /// 34px rows, 13px medium text, 16px icons (`min-h-8.5`).
  base(34, 12, 16, KumoTypography.medium),

  /// 28px rows, 13px regular text, 14px icons (`min-h-7`).
  sm(28, 8, 14, KumoTypography.normal);

  const KumoSidebarMenuButtonSize(this.minHeight, this.paddingX, this.iconSize, this.weight);
  final double minHeight;
  final double paddingX;
  final double iconSize;
  final FontWeight weight;
}

/// State of the nearest [KumoSidebar], read with [KumoSidebar.of]. The
/// equivalent of Kumo's `useSidebar()`.
///
/// ```dart
/// final sidebar = KumoSidebar.of(context);
/// KumoButton(label: sidebar.open ? 'Collapse' : 'Expand', onPress: sidebar.toggle);
/// ```
@immutable
class KumoSidebarData {
  const KumoSidebarData({
    required this.open,
    required this.drawer,
    required this.side,
    required this.collapsible,
    required this.collapse,
    required this.setOpen,
    this.close,
    this.onNavigate,
  });

  /// Expanded (true) or collapsed to the rail (false). Always true in a drawer.
  final bool open;

  /// The sidebar is shown as a drawer over the page (narrow layouts).
  final bool drawer;
  final KumoSidebarSide side;
  final KumoSidebarCollapseMode collapsible;

  /// Collapse progress: 0 fully expanded, 1 fully collapsed. Parts use it to
  /// animate along with the width.
  final Animation<double> collapse;

  /// Expands or collapses the sidebar.
  final ValueChanged<bool> setOpen;

  /// Closes the drawer. Null when the sidebar is not a drawer.
  final VoidCallback? close;

  /// Called after a navigation row is pressed (the drawer closes itself).
  final VoidCallback? onNavigate;

  /// Collapsed to the icon rail or off canvas.
  bool get collapsed => !drawer && !open;

  /// Collapses an expanded sidebar, expands a collapsed one, closes a drawer.
  void toggle() {
    if (drawer) {
      close?.call();
    } else {
      setOpen(!open);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is KumoSidebarData &&
      other.open == open &&
      other.drawer == drawer &&
      other.side == side &&
      other.collapsible == collapsible &&
      other.collapse == collapse &&
      other.close == close &&
      other.onNavigate == onNavigate;

  @override
  int get hashCode => Object.hash(open, drawer, side, collapsible, collapse, close, onNavigate);
}

class _KumoSidebarScope extends InheritedWidget {
  const _KumoSidebarScope({required this.data, required super.child});

  final KumoSidebarData data;

  @override
  bool updateShouldNotify(_KumoSidebarScope oldWidget) => data != oldWidget.data;
}

/// Places a [KumoSidebar] inside a custom app frame. [KumoAppShell] uses it;
/// reach for it only when building your own shell.
///
/// While a host is above the sidebar, the host owns the open state and the
/// sidebar's own `open` and `onOpenChange` are ignored.
///
/// ```dart
/// KumoSidebarHost(
///   open: expanded,
///   onOpenChange: (v) => setState(() => expanded = v),
///   child: mySidebar,
/// )
/// ```
class KumoSidebarHost extends InheritedWidget {
  const KumoSidebarHost({
    super.key,
    required this.open,
    required this.onOpenChange,
    this.drawer = false,
    this.drawerWidth,
    this.onClose,
    this.onNavigate,
    required super.child,
  });

  /// Expanded state for the persistent sidebar.
  final bool open;
  final ValueChanged<bool> onOpenChange;

  /// Render as a drawer: always expanded, no collapse, no resize handle.
  final bool drawer;

  /// Drawer width; defaults to the sidebar's own width.
  final double? drawerWidth;

  /// Closes the drawer.
  final VoidCallback? onClose;

  /// Called after a navigation row is pressed.
  final VoidCallback? onNavigate;

  static KumoSidebarHost? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<KumoSidebarHost>();

  @override
  bool updateShouldNotify(KumoSidebarHost oldWidget) =>
      open != oldWidget.open ||
      drawer != oldWidget.drawer ||
      drawerWidth != oldWidget.drawerWidth ||
      onOpenChange != oldWidget.onOpenChange ||
      onClose != oldWidget.onClose ||
      onNavigate != oldWidget.onNavigate;
}

/// Kumo's `Sidebar`: app navigation with a header, scrolling groups of
/// rows, nested collapsible sections and a footer.
///
/// Collapsing animates the width over 250ms while the content keeps its
/// expanded size and is clipped, so labels never re-wrap mid-animation.
/// Collapsed, rows show only their icons, group labels turn into dividers
/// and each row shows its label as a tooltip.
///
/// ```dart
/// KumoSidebar(
///   open: expanded,
///   onOpenChange: (v) => setState(() => expanded = v),
///   header: const KumoSidebarHeader(children: [KumoText('Company', bold: true)]),
///   footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
///   child: KumoSidebarContent(children: [
///     KumoSidebarGroup(children: [
///       KumoSidebarMenuButton(icon: KumoIcons.house, label: 'Home', active: true, onPress: () {}),
///       KumoSidebarMenuButton(icon: KumoIcons.globe, label: 'Domains', onPress: () {}),
///     ]),
///   ]),
/// )
/// ```
///
/// Inside a [KumoAppShell] the shell decides between the persistent
/// sidebar, the rail and the drawer, and owns the open state.
class KumoSidebar extends StatefulWidget {
  const KumoSidebar({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.open,
    this.initialOpen = true,
    this.onOpenChange,
    this.onOpenChangeComplete,
    this.side = KumoSidebarSide.start,
    this.variant = KumoSidebarVariant.sidebar,
    this.collapsible = KumoSidebarCollapseMode.icon,
    this.width = KumoSidebar.defaultWidth,
    this.collapsedWidth = KumoSidebar.iconWidth,
    this.minWidth = 200,
    this.maxWidth = 480,
    this.onWidthChange,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  /// Kumo's `--sidebar-width` (16.25rem).
  static const double defaultWidth = 260;

  /// Kumo's `--sidebar-width-icon`.
  static const double iconWidth = 57;

  /// Scrolling body: usually a [KumoSidebarContent] or
  /// [KumoSidebarSlidingViews]. It fills the space between header and footer.
  final Widget child;

  /// Pinned above [child], usually a [KumoSidebarHeader].
  final Widget? header;

  /// Pinned below [child], usually a [KumoSidebarFooter].
  final Widget? footer;

  /// Expanded (true) or collapsed (false). Null keeps the state inside the
  /// sidebar, starting from [initialOpen].
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChange;

  /// Called once the width animation settles, with the new open state.
  final ValueChanged<bool>? onOpenChangeComplete;
  final KumoSidebarSide side;
  final KumoSidebarVariant variant;
  final KumoSidebarCollapseMode collapsible;

  /// Expanded width. With [onWidthChange] set, the user can drag the edge.
  final double width;

  /// Width of the icon rail when [collapsible] is [KumoSidebarCollapseMode.icon].
  final double collapsedWidth;

  /// Narrowest width a resize keeps; dragging past it collapses the sidebar.
  final double minWidth;
  final double maxWidth;

  /// Shows a resize handle on the inner edge (Kumo's `resizable`). Called
  /// with the clamped width while dragging or with arrow keys.
  final ValueChanged<double>? onWidthChange;

  /// Shows [KumoSidebarLoading] in place of [child].
  final bool loading;
  final String? loadingLabel;

  /// Name of the navigation landmark for screen readers. Defaults to
  /// [KumoStrings.navigation].
  final String? semanticLabel;

  /// Collapse and expand duration (Kumo's `animationDuration`).
  final Duration animationDuration;

  /// The nearest sidebar's state.
  static KumoSidebarData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'KumoSidebar.of() called outside a KumoSidebar');
    return data!;
  }

  static KumoSidebarData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KumoSidebarScope>()?.data;

  @override
  State<KumoSidebar> createState() => _KumoSidebarState();
}

class _KumoSidebarState extends State<KumoSidebar> with SingleTickerProviderStateMixin {
  late final AnimationController _collapse;
  late final CurvedAnimation _curved;
  late bool _ownOpen;
  bool _initialized = false;
  bool _resizing = false;
  bool? _pendingComplete;

  KumoSidebarHost? _host;

  bool get _drawer => _host?.drawer ?? false;

  bool get _open {
    if (widget.collapsible == KumoSidebarCollapseMode.none || _drawer) return true;
    return _host?.open ?? widget.open ?? _ownOpen;
  }

  @override
  void initState() {
    super.initState();
    _ownOpen = widget.initialOpen;
    _collapse = AnimationController(vsync: this, duration: widget.animationDuration)
      ..addStatusListener(_onStatus);
    _curved = CurvedAnimation(parent: _collapse, curve: _kSidebarCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _host = KumoSidebarHost.maybeOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(KumoSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _collapse.duration = widget.animationDuration;
    _sync();
  }

  @override
  void dispose() {
    _curved.dispose();
    _collapse.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status.isAnimating || _pendingComplete == null) return;
    final open = _pendingComplete!;
    _pendingComplete = null;
    widget.onOpenChangeComplete?.call(open);
  }

  void _sync() {
    final target = _open ? 0.0 : 1.0;
    if (!_initialized) {
      _initialized = true;
      _collapse.value = target;
      return;
    }
    if (_collapse.value == target && !_collapse.isAnimating) return;
    if (_collapse.isAnimating && (_collapse.status == AnimationStatus.forward) == (target == 1)) return;
    _pendingComplete = _open;
    if (_resizing || KumoMotion.reduceMotion(context) || widget.animationDuration == Duration.zero) {
      _collapse.value = target;
      _onStatus(_collapse.status);
      return;
    }
    if (target == 1) {
      _collapse.forward();
    } else {
      _collapse.reverse();
    }
  }

  void _setOpen(bool value) {
    if (value == _open) return;
    final host = _host;
    if (host != null) {
      host.onOpenChange(value);
      return;
    }
    if (widget.open == null) setState(() => _ownOpen = value);
    widget.onOpenChange?.call(value);
    if (widget.open == null) _sync();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final host = _host;
    final drawer = _drawer;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final data = KumoSidebarData(
      open: _open,
      drawer: drawer,
      side: widget.side,
      collapsible: widget.collapsible,
      collapse: drawer ? kAlwaysDismissedAnimation : _curved,
      setOpen: _setOpen,
      close: drawer ? host?.onClose : null,
      onNavigate: host?.onNavigate,
    );

    final mq = MediaQuery.of(context);
    final floating = widget.variant == KumoSidebarVariant.floating && !drawer;
    final safeTop = floating ? 0.0 : mq.padding.top;
    final safeBottom = floating ? 0.0 : mq.padding.bottom;

    final body = widget.loading ? KumoSidebarLoading(label: widget.loadingLabel) : widget.child;
    Widget panel = Padding(
      padding: EdgeInsets.only(top: safeTop, bottom: safeBottom),
      child: MediaQuery(
        data: mq.removePadding(removeTop: true, removeBottom: true, removeLeft: true, removeRight: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?widget.header, Expanded(child: body), ?widget.footer],
        ),
      ),
    );
    panel = _ArrowKeyNavigation(child: panel);
    // Usable on its own as a page region, so it brings its own text and
    // icon defaults instead of relying on a Scaffold above it.
    panel = DefaultTextStyle(
      style: kumo.text(),
      child: IconTheme(data: IconThemeData(color: c.textDefault, size: 16), child: panel),
    );

    final expandedWidth = drawer ? (host?.drawerWidth ?? widget.width) : widget.width;
    final collapsedWidth = switch (widget.collapsible) {
      KumoSidebarCollapseMode.icon => widget.collapsedWidth,
      KumoSidebarCollapseMode.offcanvas => 0.0,
      KumoSidebarCollapseMode.none => widget.width,
    };

    final startSide = widget.side == KumoSidebarSide.start;
    final showBorder = widget.variant == KumoSidebarVariant.sidebar &&
        !(drawer && host?.drawerWidth != null && host!.drawerWidth! >= mq.size.width);
    final edge = BorderSide(color: c.line);
    final Border? border = !showBorder
        ? null
        : startSide != rtl
            ? Border(right: edge)
            : Border(left: edge);

    final radius = floating ? BorderRadius.circular(KumoRadius.lg) : BorderRadius.zero;
    final resizable = widget.onWidthChange != null && !drawer && widget.collapsible != KumoSidebarCollapseMode.none;

    Widget sized = AnimatedBuilder(
      animation: data.collapse,
      child: panel,
      builder: (context, child) {
        final width = lerpDouble(expandedWidth, collapsedWidth, data.collapse.value)!;
        return SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: radius,
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: expandedWidth,
              maxWidth: expandedWidth,
              child: child,
            ),
          ),
        );
      },
    );

    sized = Container(
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: radius,
        border: floating ? KumoRing.border(c.line) : null,
        boxShadow: floating ? KumoShadow.lg.boxShadows : null,
      ),
      foregroundDecoration: border == null ? null : BoxDecoration(border: border),
      child: sized,
    );

    if (resizable) {
      sized = Stack(
        children: [
          sized,
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: startSide ? null : 0,
            end: startSide ? 0 : null,
            width: 12,
            child: _ResizeHandle(
              width: widget.width,
              collapsedWidth: collapsedWidth,
              minWidth: widget.minWidth,
              maxWidth: widget.maxWidth,
              open: _open,
              startSide: startSide,
              onWidthChange: widget.onWidthChange!,
              onOpenChange: _setOpen,
              onResizing: (v) => _resizing = v,
            ),
          ),
        ],
      );
    }

    if (floating) sized = Padding(padding: const EdgeInsets.all(KumoSpace.s2), child: sized);

    return _KumoSidebarScope(
      data: data,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.semanticLabel ?? context.kumoStrings.navigation,
        child: sized,
      ),
    );
  }
}

/// Up and Down move focus between rows. Text fields keep their own arrow
/// keys, so a search input in the sidebar still moves its caret.
class _ArrowKeyNavigation extends StatelessWidget {
  const _ArrowKeyNavigation({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
        final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
        if (!down && !up) return KeyEventResult.ignored;
        final focused = FocusManager.instance.primaryFocus;
        final focusedContext = focused?.context;
        if (focused == null || focusedContext == null) return KeyEventResult.ignored;
        if (focusedContext.widget is EditableText ||
            focusedContext.findAncestorWidgetOfExactType<EditableText>() != null) {
          return KeyEventResult.ignored;
        }
        if (down) {
          focused.nextFocus();
        } else {
          focused.previousFocus();
        }
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}

/// Kumo's `Sidebar.Header`: a 58px strip above the content with a bottom
/// border, for the product or account switcher.
///
/// ```dart
/// const KumoSidebarHeader(children: [
///   KumoIcon(KumoIcons.cube, color: KumoColor.brand),
///   Expanded(child: KumoText('Company', bold: true, truncate: true)),
/// ])
/// ```
class KumoSidebarHeader extends StatelessWidget {
  const KumoSidebarHeader({super.key, required this.children, this.padding});

  /// Laid out in a row with 4px gaps.
  final List<Widget> children;

  /// Defaults to 12px on both sides (`px-3`).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(spacing: KumoSpace.s1, children: children),
    );
  }
}

/// Kumo's `Sidebar.Content`: the scrolling middle of the sidebar. Rows fade
/// out under the top and bottom edges while there is more to scroll.
///
/// ```dart
/// KumoSidebarContent(children: [
///   KumoSidebarGroup(label: 'Build', children: [
///     KumoSidebarMenuButton(icon: KumoIcons.code, label: 'Workers', onPress: () {}),
///   ]),
/// ])
/// ```
class KumoSidebarContent extends StatefulWidget {
  const KumoSidebarContent({super.key, required this.children, this.controller});

  /// Usually [KumoSidebarGroup]s. The first group's label hides its divider.
  final List<Widget> children;
  final ScrollController? controller;

  @override
  State<KumoSidebarContent> createState() => _KumoSidebarContentState();
}

class _KumoSidebarContentState extends State<KumoSidebarContent> with SingleTickerProviderStateMixin {
  ScrollController? _own;
  final ValueNotifier<(double, double)> _fade = ValueNotifier((0, 0));
  final GlobalKey _listKey = GlobalKey(debugLabel: 'KumoSidebarContent list');

  // The active-row highlight. At rest each active row paints its own tint;
  // when the active row changes, one tint travels from the old row to the
  // new one and hands over when it lands.
  late final AnimationController _flight;
  final ValueNotifier<int> _flightRects = ValueNotifier(0);
  _ActiveTintState? _active;
  _ActiveTintState? _flyingTo;
  Rect? _from;
  Rect? _to;

  ScrollController get _controller => widget.controller ?? (_own ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(vsync: this, duration: KumoDurations.moderate)..addStatusListener(_onFlightStatus);
  }

  @override
  void dispose() {
    _flight.dispose();
    _flightRects.dispose();
    _own?.dispose();
    _fade.dispose();
    super.dispose();
  }

  Rect? _rectOf(_ActiveTintState target) {
    final list = _listKey.currentContext?.findRenderObject() as RenderBox?;
    final box = target.mounted ? target.context.findRenderObject() as RenderBox? : null;
    if (list == null || box == null || !list.attached || !box.attached || !list.hasSize || !box.hasSize) return null;
    return MatrixUtils.transformRect(box.getTransformTo(list), Offset.zero & box.size);
  }

  /// Where the travelling tint is drawn right now.
  Rect? get _flightRect {
    final from = _from;
    if (_flyingTo == null || from == null) return null;
    final to = _to;
    if (to == null) return from;
    return Rect.lerp(from, to, KumoCurves.standard.transform(_flight.value));
  }

  /// Called while [target] builds, when its row turns active.
  void _activate(_ActiveTintState target) {
    final previous = _active;
    _active = target;
    if (previous == null || previous == target || !previous.mounted || KumoMotion.reduceMotion(context)) {
      _land();
      return;
    }
    final from = _flightRect ?? _rectOf(previous);
    if (from == null) {
      _land();
      return;
    }
    final redirected = _flyingTo;
    _flyingTo = target;
    _from = from;
    _to = null;
    _flight.value = 0;
    // Repaint-only changes are safe while the rows build; the destination is
    // measured once this frame has laid it out.
    _flightRects.value++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (redirected != null && redirected.mounted && redirected != target) redirected.refresh();
      if (!mounted || _flyingTo != target) return;
      final to = _rectOf(target);
      if (to == null) {
        _land();
        return;
      }
      _to = to;
      _flight.forward(from: 0);
    });
  }

  void _deactivate(_ActiveTintState target) {
    if (_active == target) _active = null;
    if (_flyingTo == target) {
      _flyingTo = null;
      _flight.stop();
      _from = _to = null;
      _flightRects.value++;
    }
  }

  void _onFlightStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _land();
  }

  /// Ends any flight; the active row paints its own tint again.
  void _land() {
    final target = _flyingTo;
    if (target == null) return;
    _flyingTo = null;
    _from = _to = null;
    _flight.stop();
    _flightRects.value++;
    if (target.mounted) {
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (target.mounted) target.refresh();
        });
      } else {
        target.refresh();
      }
    }
  }

  bool _onMetrics(ScrollMetrics m) {
    if (m.axis != Axis.vertical) return false;
    const fade = 24.0;
    final top = (m.pixels - m.minScrollExtent).clamp(0.0, fade);
    final bottom = (m.maxScrollExtent - m.pixels).clamp(0.0, fade);
    if (_fade.value != (top, bottom)) _fade.value = (top, bottom);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final data = KumoSidebar.maybeOf(context);
    final collapse = data?.collapse ?? kAlwaysDismissedAnimation;
    final c = context.kumo.colors;

    Widget list = Column(
      key: _listKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.children.length; i++) _GroupPosition(first: i == 0, child: widget.children[i]),
      ],
    );
    list = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CustomSingleChildLayout(
                delegate: _FlightLayout(this),
                child: DecoratedBox(
                  key: const ValueKey('kumo-sidebar-active-flight'),
                  decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(KumoRadius.lg)),
                ),
              ),
            ),
          ),
        ),
        list,
      ],
    );
    list = _ActiveHighlightScope(owner: this, child: list);
    // The rail centers its icons by pulling the content 3px toward the edge
    // (Kumo animates the padding from 14px to 11px).
    list = AnimatedBuilder(
      animation: collapse,
      child: list,
      builder: (context, child) => Transform.translate(
        offset: Offset((_kRailInset - _kContentInset) * collapse.value * _startSign(context), 0),
        child: child,
      ),
    );

    Widget scroll = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _controller,
        padding: const EdgeInsets.symmetric(horizontal: _kContentInset, vertical: KumoSpace.s3),
        child: list,
      ),
    );
    scroll = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(onNotification: (n) => _onMetrics(n.metrics), child: scroll),
    );
    scroll = ValueListenableBuilder<(double, double)>(
      valueListenable: _fade,
      child: scroll,
      builder: (context, fade, child) {
        if (fade.$1 == 0 && fade.$2 == 0) return child!;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) {
            final h = rect.height <= 0 ? 1.0 : rect.height;
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
              stops: [0, (fade.$1 / h).clamp(0.0, 0.5), (1 - fade.$2 / h).clamp(0.5, 1.0), 1],
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
    // The scrollbar stays in the tree when collapsed (hidden, not removed),
    // so expanding and collapsing never remounts the rows and their state.
    final collapsed = data?.collapsed ?? false;
    return RawScrollbar(
      controller: _controller,
      thumbColor: collapsed ? const Color(0x00000000) : c.line,
      thickness: collapsed ? 0 : 4,
      radius: const Radius.circular(KumoRadius.full),
      crossAxisMargin: 1,
      child: scroll,
    );
  }
}

class _ActiveHighlightScope extends InheritedWidget {
  const _ActiveHighlightScope({required this.owner, required super.child});

  final _KumoSidebarContentState owner;

  static _KumoSidebarContentState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ActiveHighlightScope>()?.owner;

  @override
  bool updateShouldNotify(_ActiveHighlightScope oldWidget) => false;
}

/// Sizes and places the travelling tint; zero-sized while nothing flies.
class _FlightLayout extends SingleChildLayoutDelegate {
  _FlightLayout(this.owner) : super(relayout: Listenable.merge([owner._flight, owner._flightRects]));

  final _KumoSidebarContentState owner;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final rect = owner._flightRect;
    return rect == null ? const BoxConstraints.tightFor(width: 0, height: 0) : BoxConstraints.tight(rect.size);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) => owner._flightRect?.topLeft ?? Offset.zero;

  @override
  bool shouldRelayout(_FlightLayout oldDelegate) => oldDelegate.owner != owner;
}

/// The tint behind a sidebar row: shown while hovered or focused, and while
/// active unless the travelling tint is still on its way to this row.
class _ActiveTint extends StatefulWidget {
  const _ActiveTint({required this.active, required this.hot, required this.radius, required this.child});

  final bool active;

  /// Hovered, pressed or keyboard-focused.
  final bool hot;
  final BorderRadius radius;
  final Widget child;

  @override
  State<_ActiveTint> createState() => _ActiveTintState();
}

class _ActiveTintState extends State<_ActiveTint> {
  _KumoSidebarContentState? _owner;

  void refresh() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = _ActiveHighlightScope.maybeOf(context);
    if (owner != _owner) {
      _owner?._deactivate(this);
      _owner = owner;
      // The first active row of a fresh sidebar takes the tint in place.
      if (widget.active && owner != null && owner._active == null) owner._active = this;
    }
  }

  @override
  void didUpdateWidget(_ActiveTint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _owner?._activate(this);
  }

  @override
  void dispose() {
    _owner?._deactivate(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = widget.active && _owner?._flyingTo == this;
    final tinted = widget.hot || (widget.active && !waiting);
    return DecoratedBox(
      decoration: BoxDecoration(color: tinted ? context.kumo.colors.tint : null, borderRadius: widget.radius),
      child: widget.child,
    );
  }
}

double _startSign(BuildContext context) => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

class _GroupPosition extends InheritedWidget {
  const _GroupPosition({required this.first, required super.child});

  final bool first;

  static bool isFirst(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupPosition>()?.first ?? true;

  @override
  bool updateShouldNotify(_GroupPosition oldWidget) => first != oldWidget.first;
}

/// Kumo's `Sidebar.Group` with its `Sidebar.GroupLabel` and `Sidebar.Menu`:
/// related rows under an optional label. Collapsed to the rail, the label
/// folds into a divider between icon groups.
///
/// ```dart
/// KumoSidebarGroup(label: 'Protect and connect', children: [
///   KumoSidebarMenuButton(icon: KumoIcons.shieldCheck, label: 'Security', onPress: () {}),
///   KumoSidebarMenuButton(icon: KumoIcons.lock, label: 'Zero Trust', badge: 'Beta', onPress: () {}),
/// ])
/// ```
class KumoSidebarGroup extends StatelessWidget {
  const KumoSidebarGroup({super.key, this.label, required this.children});

  /// Section label, sentence case.
  final String? label;

  /// Rows: [KumoSidebarMenuButton], [KumoSidebarCollapsible] or
  /// [KumoSidebarSeparator].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.px,
      children: [
        if (label != null) _GroupLabel(label!, first: _GroupPosition.isFirst(context)),
        ...children,
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {required this.first});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final collapse = KumoSidebar.maybeOf(context)?.collapse ?? kAlwaysDismissedAnimation;
    final label = Padding(
      padding: EdgeInsets.fromLTRB(KumoSpace.s3, first ? KumoSpace.s2 : KumoSpace.s4, KumoSpace.s3, KumoSpace.s2),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: kumo.text(size: KumoTextSize.sm, weight: KumoTypography.medium, color: KumoColor.textSubtle),
      ),
    );
    return Semantics(
      header: true,
      child: AnimatedBuilder(
        animation: collapse,
        child: label,
        builder: (context, child) {
          final t = collapse.value;
          final margin = first ? 0.0 : KumoSpace.s3 * t;
          final lineColor = first ? const Color(0x00000000) : Color.lerp(const Color(0x00000000), kumo.colors.line, t)!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: margin),
              ClipRect(
                child: Align(alignment: AlignmentDirectional.topStart, heightFactor: 1 - t, child: child),
              ),
              _RailWidth(child: Container(height: 1, color: lineColor)),
              SizedBox(height: margin),
            ],
          );
        },
      ),
    );
  }
}

/// Shrinks its child from the full row width to the rail item width as the
/// sidebar collapses, aligned to the start edge.
class _RailWidth extends StatelessWidget {
  const _RailWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final collapse = KumoSidebar.maybeOf(context)?.collapse ?? kAlwaysDismissedAnimation;
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: collapse,
        child: child,
        builder: (context, child) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: lerpDouble(constraints.maxWidth, math.min(constraints.maxWidth, _kRailItemWidth), collapse.value),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SubDepth extends InheritedWidget {
  const _SubDepth({required this.depth, required super.child});

  final int depth;

  static int of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_SubDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(_SubDepth oldWidget) => depth != oldWidget.depth;
}

/// Kumo's `Sidebar.MenuButton`: a navigation row with an icon, a label, an
/// optional badge and an active state.
///
/// Collapsed to the rail the row shows only its icon and shows [tooltip]
/// (the label by default) on hover, keyboard focus or long press. In a
/// drawer, pressing a row closes the drawer.
///
/// ```dart
/// KumoSidebarMenuButton(
///   icon: KumoIcons.house,
///   label: 'Account home',
///   active: route == '/',
///   onPress: () => go('/'),
/// )
/// ```
class KumoSidebarMenuButton extends StatelessWidget {
  const KumoSidebarMenuButton({
    super.key,
    required this.label,
    this.icon,
    this.iconWidget,
    this.active = false,
    this.size = KumoSidebarMenuButtonSize.base,
    this.onPress,
    this.badge,
    this.trailing,
    this.tooltip,
    this.disabled = false,
    this.isLink = false,
    this.semanticLabel,
    this.focusNode,
  });

  final String label;
  final IconData? icon;

  /// Leading widget in place of [icon] (an avatar, a colored mark).
  final Widget? iconWidget;

  /// The current page. Shown with a tint and announced as selected.
  final bool active;
  final KumoSidebarMenuButtonSize size;
  final VoidCallback? onPress;

  /// Short pill after the label, such as "Beta" or "New".
  final String? badge;

  /// Widget at the end of the row (a count, a shortcut).
  final Widget? trailing;

  /// Text shown when collapsed. Defaults to [label].
  final String? tooltip;
  final bool disabled;

  /// Announce as a link (Kumo renders `href` rows as anchors).
  final bool isLink;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return _SidebarRow(
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      active: active,
      size: size,
      onPress: onPress,
      badge: badge,
      trailing: trailing,
      tooltip: tooltip,
      disabled: disabled,
      isLink: isLink,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      rail: _SubDepth.of(context) == 0,
      navigates: true,
    );
  }
}

/// Kumo's `Sidebar.MenuSubButton`: a row inside a [KumoSidebarMenuSub] or
/// [KumoSidebarCollapsible]. Sub rows have no icon; the indent and the
/// guide line show the hierarchy.
///
/// ```dart
/// KumoSidebarMenuSubButton(label: 'Durable Objects', onPress: () {})
/// ```
class KumoSidebarMenuSubButton extends StatelessWidget {
  const KumoSidebarMenuSubButton({
    super.key,
    required this.label,
    this.active = false,
    this.onPress,
    this.badge,
    this.trailing,
    this.disabled = false,
    this.isLink = false,
    this.semanticLabel,
    this.focusNode,
  });

  final String label;
  final bool active;
  final VoidCallback? onPress;
  final String? badge;
  final Widget? trailing;
  final bool disabled;
  final bool isLink;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return _SidebarRow(
      label: label,
      active: active,
      size: KumoSidebarMenuButtonSize.base,
      onPress: onPress,
      badge: badge,
      trailing: trailing,
      disabled: disabled,
      isLink: isLink,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      rail: false,
      navigates: true,
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.label,
    required this.size,
    required this.rail,
    required this.navigates,
    this.icon,
    this.iconWidget,
    this.active = false,
    this.onPress,
    this.badge,
    this.trailing,
    this.trailingBuilder,
    this.tooltip,
    this.disabled = false,
    this.isLink = false,
    this.semanticLabel,
    this.focusNode,
    this.expanded,
  });

  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final bool active;
  final KumoSidebarMenuButtonSize size;
  final VoidCallback? onPress;
  final String? badge;
  final Widget? trailing;

  /// Trailing content that reacts to hover (the collapsible chevron).
  final Widget Function(bool hovered)? trailingBuilder;
  final String? tooltip;
  final bool disabled;
  final bool isLink;
  final String? semanticLabel;
  final FocusNode? focusNode;

  /// Top-level rows shrink to the rail; sub rows are hidden when collapsed.
  final bool rail;

  /// Pressing closes the drawer.
  final bool navigates;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final data = KumoSidebar.maybeOf(context);
    final collapse = rail ? (data?.collapse ?? kAlwaysDismissedAnimation) : kAlwaysDismissedAnimation;
    final collapsed = rail && (data?.collapsed ?? false);
    final rowHeight = math.max(size.minHeight, kumo.minTapTarget);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(KumoRadius.lg);

    void press() {
      onPress?.call();
      if (navigates) data?.onNavigate?.call();
    }

    Widget content(KumoPressState state) {
      final fg = state.focused ? c.textStrong : c.textDefault;
      final style = kumo.text(size: KumoTextSize.sm, weight: size.weight, color: KumoColor.textDefault).copyWith(color: fg);
      final leading =
          iconWidget ?? (icon == null ? null : KumoIcon(icon!, size: size.iconSize, dangerouslySetColor: fg.withValues(alpha: 0.4)));
      final trail = trailingBuilder?.call(state.active) ?? trailing;
      return Row(
        spacing: leading == null ? 0 : KumoSpace.s3,
        children: [
          ?leading,
          Expanded(
            child: Row(
              spacing: KumoSpace.s2,
              children: [
                Flexible(
                  child: Text(label, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                ),
                if (badge != null) KumoSidebarMenuBadge(badge!),
                if (trail != null) ...[const Spacer(), trail],
              ],
            ),
          ),
        ],
      );
    }

    Widget tile(double full) {
      Widget pressable = KumoPressable(
        onPress: disabled ? null : press,
        disabled: disabled,
        selected: navigates ? active : null,
        expanded: expanded,
        isLink: isLink,
        semanticLabel: semanticLabel,
        excludeChildSemantics: semanticLabel != null,
        borderRadius: radius,
        focusRingOffset: -2,
        minTapTargetSize: 0,
        focusNode: focusNode,
        builder: (context, state) {
          Widget row = Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: size.paddingX),
            child: content(state),
          );
          if (rail) {
            // Kumo nudges the row 3px toward the edge so the icon centers in
            // the rail.
            row = AnimatedBuilder(
              animation: collapse,
              child: row,
              builder: (context, child) => Transform.translate(
                offset: Offset(-3 * collapse.value * (rtl ? -1 : 1), 0),
                child: child,
              ),
            );
          }
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: rowHeight),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Opacity(
                opacity: disabled ? 0.5 : 1,
                child: _ActiveTint(
                  active: active,
                  hot: state.active || state.focused,
                  radius: radius,
                  child: ClipRRect(
                    borderRadius: radius,
                    // The row keeps its expanded width while the tile
                    // narrows, so labels are clipped instead of re-wrapping.
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerStart,
                      fit: OverflowBoxFit.deferToChild,
                      minWidth: full,
                      maxWidth: full,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: size.minHeight),
                        child: Align(alignment: AlignmentDirectional.centerStart, heightFactor: 1, child: row),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      if (rail) {
        pressable = KumoTooltip(
          content: tooltip ?? label,
          disabled: !collapsed,
          side: (data?.side ?? KumoSidebarSide.start) == KumoSidebarSide.start
              ? (rtl ? KumoSide.left : KumoSide.right)
              : (rtl ? KumoSide.right : KumoSide.left),
          child: pressable,
        );
      }
      return pressable;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final child = tile(full);
        if (!rail) return child;
        // The pressable itself narrows to the rail tile, so its hit area,
        // focus ring and tooltip anchor all match the 34px icon square.
        return AnimatedBuilder(
          animation: collapse,
          child: child,
          builder: (context, child) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: lerpDouble(full, math.min(full, _kRailItemWidth), collapse.value),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Kumo's `Sidebar.MenuBadge`: a small dashed pill after a row label, for
/// states such as "Beta". Text, never color alone, carries the meaning.
///
/// ```dart
/// const KumoSidebarMenuBadge('Beta')
/// ```
class KumoSidebarMenuBadge extends StatelessWidget {
  const KumoSidebarMenuBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return CustomPaint(
      painter: _DashedPillPainter(color: kumo.colors.line),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s1_5, vertical: KumoSpace.s0_5 + 1),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: kumo
              .text(size: KumoTextSize.xs, weight: KumoTypography.medium, color: KumoColor.textStrong)
              .copyWith(fontSize: 11, height: 1),
        ),
      ),
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(size.height / 2));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 3, metric.length)), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter oldDelegate) => oldDelegate.color != color;
}

/// Kumo's `Sidebar.MenuSub`: an indented list with a guide line, for rows
/// below a parent. [KumoSidebarCollapsible] wraps its children in one.
///
/// ```dart
/// const KumoSidebarMenuSub(children: [
///   KumoSidebarMenuSubButton(label: 'Overview', active: true),
///   KumoSidebarMenuSubButton(label: 'Settings'),
/// ])
/// ```
class KumoSidebarMenuSub extends StatelessWidget {
  const KumoSidebarMenuSub({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final depth = _SubDepth.of(context);
    return _SubDepth(
      depth: depth + 1,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.px, children: children),
          ),
          PositionedDirectional(
            start: 19,
            top: 1,
            bottom: 1,
            width: 1,
            child: ColoredBox(color: c.line),
          ),
        ],
      ),
    );
  }
}

/// Kumo's `Sidebar.Collapsible` with its trigger, content and chevron: a row
/// that expands to show sub rows.
///
/// The content keeps its size and is revealed by a clip as it opens. While
/// the sidebar is collapsed to the rail the content is hidden; pressing the
/// icon expands the sidebar and opens the section. Tabbing onto the row
/// opens it, and it closes again when focus leaves unless it was opened on
/// purpose or holds the active row.
///
/// ```dart
/// KumoSidebarCollapsible(
///   icon: KumoIcons.code,
///   label: 'Compute',
///   initialOpen: true,
///   children: [
///     KumoSidebarMenuSubButton(label: 'Workers', active: true, onPress: () {}),
///     KumoSidebarMenuSubButton(label: 'Containers', badge: 'Beta', onPress: () {}),
///   ],
/// )
/// ```
///
/// Nest a collapsible inside the children for a second level.
class KumoSidebarCollapsible extends StatefulWidget {
  const KumoSidebarCollapsible({
    super.key,
    required this.label,
    required this.children,
    this.icon,
    this.badge,
    this.open,
    this.initialOpen = false,
    this.onOpenChange,
    this.onOpenChangeComplete,
    this.autoScrollOnOpen = false,
    this.semanticLabel,
  });

  final String label;

  /// Sub rows, usually [KumoSidebarMenuSubButton]s.
  final List<Widget> children;

  /// Icon of a top-level trigger. Nested triggers have none.
  final IconData? icon;
  final String? badge;

  /// Controlled open state. Null keeps it inside, starting at [initialOpen].
  final bool? open;
  final bool initialOpen;
  final ValueChanged<bool>? onOpenChange;

  /// Called once the content finishes showing or hiding, including when the
  /// sidebar collapses or expands an open section.
  final ValueChanged<bool>? onOpenChangeComplete;

  /// Scroll the revealed rows into view after opening, for sections near
  /// the bottom of a long sidebar.
  final bool autoScrollOnOpen;
  final String? semanticLabel;

  @override
  State<KumoSidebarCollapsible> createState() => _KumoSidebarCollapsibleState();
}

class _KumoSidebarCollapsibleState extends State<KumoSidebarCollapsible> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  late final CurvedAnimation _curved;
  late bool _ownOpen;
  bool _keyboardOpened = false;
  bool _initialized = false;
  bool? _pendingComplete;
  final GlobalKey _contentKey = GlobalKey();

  bool get _open => widget.open ?? _ownOpen;

  @override
  void initState() {
    super.initState();
    _ownOpen = widget.initialOpen;
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
      ..addStatusListener(_onStatus);
    _curved = CurvedAnimation(parent: _reveal, curve: _kSidebarCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KumoSidebarCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _curved.dispose();
    _reveal.dispose();
    super.dispose();
  }

  bool get _shown {
    final data = KumoSidebar.maybeOf(context);
    return _open && !(data?.collapsed ?? false);
  }

  void _onStatus(AnimationStatus status) {
    if (status.isAnimating || _pendingComplete == null) return;
    final shown = _pendingComplete!;
    _pendingComplete = null;
    widget.onOpenChangeComplete?.call(shown);
    if (shown && widget.autoScrollOnOpen) _scrollIntoView();
  }

  void _scrollIntoView() {
    final ctx = _contentKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: KumoMotion.duration(context, KumoDurations.moderate),
      curve: KumoCurves.standard,
    );
  }

  void _sync() {
    final target = _shown ? 1.0 : 0.0;
    if (!_initialized) {
      _initialized = true;
      _reveal.value = target;
      return;
    }
    if (_reveal.value == target && !_reveal.isAnimating) return;
    _pendingComplete = target == 1;
    if (KumoMotion.reduceMotion(context)) {
      _reveal.value = target;
      _onStatus(_reveal.status);
    } else {
      _reveal.animateTo(target);
    }
  }

  void _setOpen(bool value) {
    if (value == _open) return;
    if (widget.open == null) {
      setState(() => _ownOpen = value);
      // Start on this frame rather than the next, so the press answers at once.
      _sync();
    }
    widget.onOpenChange?.call(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  void _toggle() {
    _keyboardOpened = false;
    final data = KumoSidebar.maybeOf(context);
    if (data != null && data.collapsed) {
      data.setOpen(true);
      _setOpen(true);
      return;
    }
    _setOpen(!_open);
  }

  void _onFocusChange(bool focused) {
    final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (focused && !_open && keyboard) {
      _keyboardOpened = true;
      _setOpen(true);
    } else if (!focused && _keyboardOpened && !_containsActive(widget.children)) {
      _keyboardOpened = false;
      _setOpen(false);
    }
  }

  static bool _containsActive(List<Widget> children) {
    for (final child in children) {
      if (child is KumoSidebarMenuSubButton && child.active) return true;
      if (child is KumoSidebarMenuButton && child.active) return true;
      if (child is KumoSidebarCollapsible && _containsActive(child.children)) return true;
      if (child is KumoSidebarMenuSub && _containsActive(child.children)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final depth = _SubDepth.of(context);
    final open = _open;
    final trigger = _SidebarRow(
      label: widget.label,
      icon: depth == 0 ? widget.icon : null,
      size: KumoSidebarMenuButtonSize.base,
      rail: depth == 0,
      navigates: false,
      badge: widget.badge,
      expanded: open,
      semanticLabel: widget.semanticLabel,
      onPress: _toggle,
      trailingBuilder: (hovered) => _Chevron(progress: _curved, hovered: hovered),
    );

    final content = AnimatedBuilder(
      animation: _curved,
      child: KeyedSubtree(key: _contentKey, child: KumoSidebarMenuSub(children: widget.children)),
      builder: (context, child) {
        final value = _curved.value;
        final hidden = value == 0;
        return ExcludeFocus(
          excluding: !_shown,
          child: ExcludeSemantics(
            excluding: hidden,
            child: IgnorePointer(
              ignoring: !_shown,
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  heightFactor: value,
                  child: Offstage(offstage: hidden, child: child),
                ),
              ),
            ),
          ),
        );
      },
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _onFocusChange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.px,
        children: [trigger, content],
      ),
    );
  }
}

/// The collapsible's caret. It turns with the same animation that reveals
/// the rows, so the two stay in step and reverse together mid-flight.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.progress, required this.hovered});

  /// 0 closed, 1 open.
  final Animation<double> progress;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RotationTransition(
      turns: progress.drive(Tween<double>(begin: 0, end: rtl ? -0.25 : 0.25)),
      child: Opacity(
        opacity: hovered ? 1 : 0.4,
        child: KumoIcon(rtl ? KumoIcons.caretLeft : KumoIcons.caretRight, size: 12),
      ),
    );
  }
}

/// Kumo's `Sidebar.Separator`: a divider between sections.
///
/// ```dart
/// const KumoSidebarSeparator()
/// ```
class KumoSidebarSeparator extends StatelessWidget {
  const KumoSidebarSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KumoSpace.s3),
      child: _RailWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2),
          child: Container(height: 1, color: context.kumo.colors.line),
        ),
      ),
    );
  }
}

/// Kumo's `Sidebar.Footer`: a 48px strip pinned below the content with a
/// top border, usually holding [KumoSidebarTrigger].
///
/// ```dart
/// const KumoSidebarFooter(children: [KumoSidebarTrigger()])
/// ```
class KumoSidebarFooter extends StatelessWidget {
  const KumoSidebarFooter({super.key, required this.children});

  /// Laid out in a row with 16px gaps.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final collapse = KumoSidebar.maybeOf(context)?.collapse ?? kAlwaysDismissedAnimation;
    final sign = _startSign(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s4),
      decoration: BoxDecoration(color: c.base, border: Border(top: BorderSide(color: c.line))),
      child: AnimatedBuilder(
        animation: collapse,
        builder: (context, child) => Transform.translate(
          // Padding goes from 16px to Kumo's 11px rail inset.
          offset: Offset((_kRailInset - KumoSpace.s4) * collapse.value * sign, 0),
          child: child,
        ),
        child: Row(spacing: KumoSpace.s4, children: children),
      ),
    );
  }
}

/// Kumo's `Sidebar.Trigger`: the 34px button that collapses and expands the
/// sidebar. Its panel icon's divider slides with the sidebar. In a drawer
/// it closes the drawer.
///
/// ```dart
/// const KumoSidebarTrigger()
/// ```
class KumoSidebarTrigger extends StatelessWidget {
  const KumoSidebarTrigger({super.key, this.onPress, this.collapseLabel, this.expandLabel});

  /// Called before the sidebar toggles.
  final VoidCallback? onPress;

  /// Accessible name while expanded. Defaults to "Collapse sidebar".
  final String? collapseLabel;

  /// Accessible name while collapsed. Defaults to "Expand sidebar".
  final String? expandLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final data = KumoSidebar.maybeOf(context);
    final strings = context.kumoStrings;
    final open = data?.open ?? true;
    final label = data?.drawer ?? false
        ? strings.closeSidebar
        : open
            ? (collapseLabel ?? context.kumoStrings.collapseSidebar)
            : (expandLabel ?? context.kumoStrings.expandSidebar);
    final collapse = data?.collapse ?? kAlwaysDismissedAnimation;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return KumoPressable(
      onPress: () {
        onPress?.call();
        data?.toggle();
      },
      semanticLabel: label,
      excludeChildSemantics: true,
      expanded: open,
      borderRadius: BorderRadius.circular(KumoRadius.lg),
      focusRingOffset: -2,
      builder: (context, state) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: state.active ? c.tint : null,
          borderRadius: BorderRadius.circular(KumoRadius.lg),
        ),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: collapse,
          builder: (context, _) => CustomPaint(
            size: const Size.square(18),
            painter: _PanelIconPainter(
              progress: collapse.value,
              color: state.active ? c.textDefault : c.textSubtle,
              mirror: rtl != ((data?.side ?? KumoSidebarSide.start) == KumoSidebarSide.end),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kumo's `Sidebar.PanelIcon`, drawn from the same 24-unit path.
class _PanelIconPainter extends CustomPainter {
  const _PanelIconPainter({required this.progress, required this.color, required this.mirror});

  final double progress;
  final Color color;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.save();
    if (mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.scale(s);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawRRect(
      RRect.fromLTRBR(2.75, 3.75, 21.25, 20.25, const Radius.circular(2.97)),
      paint,
    );
    final dx = lerpDouble(1, 10.5, progress)!;
    canvas.drawLine(Offset(6.25 + dx, 7.25), Offset(6.25 + dx, 16.75), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PanelIconPainter old) => old.progress != progress || old.color != color || old.mirror != mirror;
}

/// Kumo's `Sidebar.Close`: an X button that closes the sidebar drawer. It
/// renders nothing when the sidebar is not a drawer.
///
/// ```dart
/// const KumoSidebarHeader(children: [Expanded(child: KumoText('Navigation')), KumoSidebarClose()])
/// ```
class KumoSidebarClose extends StatelessWidget {
  const KumoSidebarClose({super.key, this.semanticLabel});

  /// Defaults to [KumoStrings.closeSidebar].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final data = KumoSidebar.maybeOf(context);
    if (data == null || !data.drawer) return const SizedBox.shrink();
    return KumoButton(
      variant: KumoButtonVariant.ghost,
      shape: KumoButtonShape.square,
      size: KumoButtonSize.sm,
      semanticLabel: semanticLabel ?? context.kumoStrings.closeSidebar,
      iconWidget: const KumoIcon(KumoIcons.x, size: 18),
      onPress: data.close,
    );
  }
}

/// Kumo's `Sidebar.Loading`: nav-shaped placeholder rows shown while routes
/// or permissions load. They stay still (no shimmer) and are announced as
/// loading. Collapsed, only the icon squares remain.
///
/// ```dart
/// KumoSidebar(loading: true, child: const SizedBox())
/// ```
class KumoSidebarLoading extends StatelessWidget {
  const KumoSidebarLoading({super.key, this.label});

  /// Announced to screen readers. Defaults to [KumoStrings.loading].
  final String? label;

  static const List<List<double>> _groups = [
    [112, 160, 96],
    [96, 144, 128],
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final collapse = KumoSidebar.maybeOf(context)?.collapse ?? kAlwaysDismissedAnimation;
    Widget bar(double width, double height, double radius) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(radius)),
        );
    Widget fading(Widget child) => AnimatedBuilder(
          animation: collapse,
          child: child,
          builder: (context, child) => Opacity(opacity: 1 - collapse.value, child: child),
        );
    return Semantics(
      label: label ?? context.kumoStrings.loading,
      liveRegion: true,
      container: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s4,
            children: [
              for (final group in _groups)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: KumoSpace.s0_5,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: KumoSpace.s2, bottom: KumoSpace.s1),
                      child: fading(bar(64, 8, KumoRadius.full)),
                    ),
                    for (final width in group)
                      Container(
                        constraints: const BoxConstraints(minHeight: 34),
                        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
                        child: Row(
                          spacing: KumoSpace.s3,
                          children: [bar(18, 18, KumoRadius.md), fading(bar(width, 10, KumoRadius.full))],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One navigation surface inside [KumoSidebarSlidingViews].
class KumoSidebarSlidingView extends StatelessWidget {
  const KumoSidebarSlidingView({super.key, required this.value, required this.child});

  /// Key that [KumoSidebarSlidingViews.activeKey] selects.
  final String value;

  /// Usually a [KumoSidebarContent].
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Kumo's `Sidebar.SlidingViews`: switches between navigation surfaces
/// (account and zone, say) by sliding them sideways. Views to the right of
/// the active one wait off the end edge; inactive views are hidden from
/// screen readers, focus and taps.
///
/// ```dart
/// KumoSidebarSlidingViews(
///   activeKey: surface,
///   children: [
///     KumoSidebarSlidingView(value: 'account', child: KumoSidebarContent(children: accountNav)),
///     KumoSidebarSlidingView(value: 'zone', child: KumoSidebarContent(children: zoneNav)),
///   ],
/// )
/// ```
class KumoSidebarSlidingViews extends StatefulWidget {
  const KumoSidebarSlidingViews({super.key, required this.activeKey, required this.children});

  final String activeKey;
  final List<KumoSidebarSlidingView> children;

  @override
  State<KumoSidebarSlidingViews> createState() => _KumoSidebarSlidingViewsState();
}

class _KumoSidebarSlidingViewsState extends State<KumoSidebarSlidingViews> with SingleTickerProviderStateMixin {
  late final AnimationController _position;

  int get _activeIndex => math.max(0, widget.children.indexWhere((v) => v.value == widget.activeKey));

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(vsync: this, value: _activeIndex.toDouble());
  }

  @override
  void didUpdateWidget(KumoSidebarSlidingViews oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _activeIndex.toDouble();
    if (_position.value == target) return;
    if (KumoMotion.reduceMotion(context)) {
      _position.value = target;
    } else {
      _position.animateTo(target, duration: const Duration(milliseconds: 250), curve: _kSidebarCurve);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final sign = _startSign(context);
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _position,
          builder: (context, _) {
            final pos = _position.value;
            return Stack(
              children: [
                for (var i = 0; i < widget.children.length; i++)
                  Positioned.fill(
                    child: _SlidingViewSlot(
                      offset: (i - pos) * constraints.maxWidth * sign,
                      active: i == active,
                      visible: (i - pos).abs() < 1,
                      child: widget.children[i],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SlidingViewSlot extends StatelessWidget {
  const _SlidingViewSlot({required this.offset, required this.active, required this.visible, required this.child});

  final double offset;
  final bool active;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      child: TickerMode(
        enabled: visible,
        child: ExcludeFocus(
          excluding: !active,
          child: ExcludeSemantics(
            excluding: !active,
            child: IgnorePointer(
              ignoring: !active,
              child: Transform.translate(offset: Offset(offset, 0), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.width,
    required this.collapsedWidth,
    required this.minWidth,
    required this.maxWidth,
    required this.open,
    required this.startSide,
    required this.onWidthChange,
    required this.onOpenChange,
    required this.onResizing,
  });

  final double width;
  final double collapsedWidth;
  final double minWidth;
  final double maxWidth;
  final bool open;
  final bool startSide;
  final ValueChanged<double> onWidthChange;
  final ValueChanged<bool> onOpenChange;
  final ValueChanged<bool> onResizing;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  static const double _step = 10;
  final FocusNode _focus = FocusNode(debugLabel: 'KumoSidebar resize');
  bool _hovered = false;
  bool _dragging = false;
  bool _focused = false;
  double _startWidth = 0;
  double _dragged = 0;
  bool _wasCollapsed = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _sign {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return (widget.startSide ? 1 : -1) * (rtl ? -1 : 1);
  }

  double _clamp(double w) => w.clamp(widget.minWidth, widget.maxWidth);

  static String _describe(bool open, double width) => open ? '${width.round()} px' : 'Collapsed';

  void _start(DragStartDetails _) {
    widget.onResizing(true);
    setState(() => _dragging = true);
    _wasCollapsed = !widget.open;
    _startWidth = widget.open ? widget.width : widget.collapsedWidth;
    _dragged = 0;
  }

  void _update(DragUpdateDetails d) {
    _dragged += d.delta.dx * _sign;
    final raw = _startWidth + _dragged;
    if (_wasCollapsed) {
      if (raw >= widget.minWidth) {
        _wasCollapsed = false;
        widget.onOpenChange(true);
        widget.onWidthChange(_clamp(raw));
      }
      return;
    }
    if (raw < widget.minWidth) {
      _wasCollapsed = true;
      widget.onOpenChange(false);
      return;
    }
    widget.onWidthChange(_clamp(raw));
  }

  void _end([DragEndDetails? _]) {
    widget.onResizing(false);
    setState(() => _dragging = false);
  }

  void _grow() {
    if (!widget.open) {
      widget.onOpenChange(true);
      widget.onWidthChange(widget.minWidth);
    } else {
      widget.onWidthChange(math.min(widget.width + _step, widget.maxWidth));
    }
  }

  void _shrink() {
    final next = widget.width - _step;
    if (next < widget.minWidth) {
      widget.onOpenChange(false);
    } else {
      widget.onWidthChange(next);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rightGrows = _sign > 0;
    if (key == LogicalKeyboardKey.arrowRight) {
      rightGrows ? _grow() : _shrink();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      rightGrows ? _shrink() : _grow();
    } else if (key == LogicalKeyboardKey.home) {
      widget.onOpenChange(false);
    } else if (key == LogicalKeyboardKey.end) {
      widget.onOpenChange(true);
      widget.onWidthChange(widget.maxWidth);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final show = _hovered || _dragging || _focused;
    return Semantics(
      label: 'Resize sidebar',
      slider: true,
      value: _describe(widget.open, widget.width),
      increasedValue: _describe(true, widget.open ? math.min(widget.width + _step, widget.maxWidth) : widget.minWidth),
      decreasedValue: _describe(widget.width - _step >= widget.minWidth, widget.width - _step),
      onIncrease: _grow,
      onDecrease: _shrink,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        onFocusChange: (v) => setState(
          () => _focused = v && FocusManager.instance.highlightMode == FocusHighlightMode.traditional,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _start,
            onHorizontalDragUpdate: _update,
            onHorizontalDragEnd: _end,
            onHorizontalDragCancel: _end,
            child: Align(
              alignment: widget.startSide ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Container(width: 2, color: show ? c.hairline : const Color(0x00000000)),
            ),
          ),
        ),
      ),
    );
  }
}
