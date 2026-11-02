import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icons.g.dart';
import '../navigation/kumo_bottom_navigation.dart';
import '../overlays/kumo_scrim.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import 'kumo_sidebar.dart';

/// Which frame [KumoAppShell] is showing.
enum KumoAppShellLayout {
  /// Below 768px: a top bar with a menu button; the sidebar is a drawer.
  narrow,

  /// 768px to 1023px: the sidebar is a collapsed icon rail.
  medium,

  /// 1024px and up: a persistent sidebar.
  wide,
}

/// State of the nearest [KumoAppShell], read with [KumoAppShell.of].
@immutable
class KumoAppShellData {
  const KumoAppShellData({
    required this.layout,
    required this.drawerOpen,
    required this.openDrawer,
    required this.closeDrawer,
    required this.toggleSidebar,
  });

  final KumoAppShellLayout layout;

  /// The navigation drawer is open (narrow layout only).
  final bool drawerOpen;
  final VoidCallback openDrawer;
  final VoidCallback closeDrawer;

  /// Opens the drawer on narrow screens, expands or collapses the sidebar
  /// on wider ones.
  final VoidCallback toggleSidebar;

  @override
  bool operator ==(Object other) =>
      other is KumoAppShellData && other.layout == layout && other.drawerOpen == drawerOpen;

  @override
  int get hashCode => Object.hash(layout, drawerOpen);
}

class _KumoAppShellScope extends InheritedWidget {
  const _KumoAppShellScope({required this.data, required super.child});

  final KumoAppShellData data;

  @override
  bool updateShouldNotify(_KumoAppShellScope oldWidget) => data != oldWidget.data;
}

/// The responsive frame a Kumo app is built on: a [KumoSidebar], a sticky
/// top bar and the page.
///
/// * Wide (1024px and up): the sidebar sits beside the content and collapses
///   to its rail with [KumoSidebarTrigger]. The top bar sticks to the top of
///   the content with a border below it.
/// * Medium (768px to 1023px): the sidebar starts as the icon rail.
/// * Narrow (below 768px): the top bar gets a "Menu" button that opens the
///   sidebar as a drawer from its edge. The drawer follows the finger, opens
///   with a swipe from the screen edge, closes with a flick or a scrim tap,
///   traps focus while open, and closes with Escape or the back gesture. An
///   optional [bottomNavigation] bar sits at the bottom.
///
/// The bars take their share of the safe area, and the body gets the rest,
/// so content never hides under the status bar or home indicator.
///
/// ```dart
/// KumoAppShell(
///   sidebar: KumoSidebar(
///     footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
///     child: KumoSidebarContent(children: [
///       KumoSidebarGroup(children: [
///         KumoSidebarMenuButton(icon: KumoIcons.house, label: 'Home', active: true, onPress: () {}),
///       ]),
///     ]),
///   ),
///   topBar: const KumoText('Workers', variant: KumoTextVariant.heading),
///   body: const WorkersPage(),
/// )
/// ```
class KumoAppShell extends StatefulWidget {
  const KumoAppShell({
    super.key,
    required this.body,
    this.sidebar,
    this.topBar,
    this.bottomNavigation,
    this.sidebarOpen,
    this.initialSidebarOpen = true,
    this.onSidebarOpenChange,
    this.onDrawerOpenChange,
    this.layout,
    this.narrowBreakpoint = KumoBreakpoints.md,
    this.wideBreakpoint = KumoBreakpoints.lg,
    this.bodyPadding = EdgeInsets.zero,
    this.safeAreaBody = true,
    this.drawerWidth,
    this.fullScreenDrawer = false,
    this.closeDrawerOnNavigate = true,
    this.menuLabel,
    this.edgeSwipeWidth = 20,
  });

  /// The page.
  final Widget body;
  final KumoSidebar? sidebar;

  /// Content of the sticky top bar: a title, breadcrumbs, actions. On narrow
  /// screens it sits after the menu button.
  final Widget? topBar;

  /// Bar pinned to the bottom on narrow screens, for a few top destinations.
  /// Usually a [KumoBottomNavigation]; other widgets get a top border and the
  /// bottom safe area from the shell.
  final Widget? bottomNavigation;

  /// Expanded state of the persistent sidebar on wide screens. Null keeps it
  /// inside the shell, starting from [initialSidebarOpen]. Medium screens
  /// always start from the rail.
  final bool? sidebarOpen;
  final bool initialSidebarOpen;
  final ValueChanged<bool>? onSidebarOpenChange;

  /// Called when the drawer opens or closes, by tap, gesture or key.
  final ValueChanged<bool>? onDrawerOpenChange;

  /// Forces a layout instead of choosing one from the width.
  final KumoAppShellLayout? layout;

  /// Widths below this use the narrow layout.
  final double narrowBreakpoint;

  /// Widths from this up use the wide layout.
  final double wideBreakpoint;

  /// Padding around [body], inside the safe area.
  final EdgeInsetsGeometry bodyPadding;

  /// Pad [body] for the safe-area edges that no bar covers. Turn off when the
  /// body is a scroll view that should run under the home indicator and
  /// pads itself from `MediaQuery.padding`.
  final bool safeAreaBody;

  /// Drawer width. Defaults to the sidebar's width, leaving at least 56px of
  /// the page visible.
  final double? drawerWidth;

  /// Drawer covers the whole screen (Kumo's `fullScreenOnMobile`). Put a
  /// [KumoSidebarClose] in the sidebar header so it can be closed from inside.
  final bool fullScreenDrawer;

  /// Close the drawer after a navigation row is pressed.
  final bool closeDrawerOnNavigate;

  /// Visible label of the menu button. Defaults to [KumoStrings.menu].
  final String? menuLabel;

  /// Width of the strip along the drawer edge that starts an edge swipe.
  final double edgeSwipeWidth;

  static KumoAppShellData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'KumoAppShell.of() called outside a KumoAppShell');
    return data!;
  }

  static KumoAppShellData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KumoAppShellScope>()?.data;

  @override
  State<KumoAppShell> createState() => _KumoAppShellState();
}

class _KumoAppShellState extends State<KumoAppShell> with SingleTickerProviderStateMixin {
  late final AnimationController _drawer;
  final GlobalKey _sidebarKey = GlobalKey(debugLabel: 'KumoAppShell sidebar');
  final FocusScopeNode _drawerScope = FocusScopeNode(debugLabel: 'KumoAppShell drawer');
  final FocusNode _menuFocus = FocusNode(debugLabel: 'KumoAppShell menu');

  late bool _ownWideOpen;
  bool _railExpanded = false;
  bool _drawerOpen = false;
  bool _dragging = false;
  double _dragRaw = 0;
  double _drawerExtent = KumoSidebar.defaultWidth;
  KumoAppShellLayout? _lastLayout;
  FocusNode? _restoreFocus;

  @override
  void initState() {
    super.initState();
    _ownWideOpen = widget.initialSidebarOpen;
    _drawer = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _drawer.dispose();
    _drawerScope.dispose();
    _menuFocus.dispose();
    super.dispose();
  }

  bool get _wideOpen => widget.sidebarOpen ?? _ownWideOpen;

  bool get _reduceMotion => KumoMotion.reduceMotion(context);

  /// +1 when a rightward drag opens the drawer.
  double get _openSign {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final start = (widget.sidebar?.side ?? KumoSidebarSide.start) == KumoSidebarSide.start;
    return (start ? 1.0 : -1.0) * (rtl ? -1.0 : 1.0);
  }

  void _setWideOpen(bool value) {
    if (widget.sidebarOpen == null) setState(() => _ownWideOpen = value);
    widget.onSidebarOpenChange?.call(value);
  }

  void _setRailExpanded(bool value) => setState(() => _railExpanded = value);

  void _openDrawer() => _settle(true, velocity: 0);

  void _closeDrawer() => _settle(false, velocity: 0);

  void _toggleSidebar() {
    switch (_lastLayout) {
      case KumoAppShellLayout.narrow:
        _settle(!_drawerOpen, velocity: 0);
      case KumoAppShellLayout.medium:
        _setRailExpanded(!_railExpanded);
      case KumoAppShellLayout.wide || null:
        _setWideOpen(!_wideOpen);
    }
  }

  void _setDrawerOpen(bool open) {
    if (open == _drawerOpen) return;
    setState(() => _drawerOpen = open);
    widget.onDrawerOpenChange?.call(open);
    if (open) {
      final current = FocusManager.instance.primaryFocus;
      _restoreFocus = current != null && current != FocusManager.instance.rootScope ? current : _menuFocus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_drawerOpen) return;
        _drawerScope.requestFocus();
        // Land on the first row, like Kumo's drawer.
        _drawerScope.nextFocus();
      });
    } else {
      final restore = _restoreFocus;
      _restoreFocus = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (restore != null && restore.context != null && restore.canRequestFocus) restore.requestFocus();
      });
    }
  }

  /// Snaps the drawer open or closed with a spring that keeps the finger's
  /// velocity (in drawer widths per second).
  void _settle(bool open, {required double velocity, bool fromGesture = false}) {
    if (fromGesture && open != _drawerOpen) kumoHaptic(KumoHaptic.light);
    _setDrawerOpen(open);
    final target = open ? 1.0 : 0.0;
    if (_reduceMotion) {
      _drawer.value = target;
      return;
    }
    KumoMotion.springTo(_drawer, target, spring: KumoSprings.sheet, velocity: velocity);
  }

  double _visual(double raw) {
    if (raw <= 0) return 0;
    if (raw <= 1) return raw;
    final over = (raw - 1) * _drawerExtent;
    return 1 + KumoMotion.rubberband(over, _drawerExtent) / _drawerExtent;
  }

  void _dragStart(DragStartDetails _) {
    _drawer.stop();
    _dragging = true;
    _dragRaw = _drawer.value.clamp(0.0, 1.0);
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _dragRaw += d.delta.dx * _openSign / _drawerExtent;
    _drawer.value = _visual(_dragRaw);
  }

  void _dragEnd(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = d.velocity.pixelsPerSecond.dx * _openSign;
    final projected = _drawer.value + KumoMotion.project(velocity) / _drawerExtent;
    // A clear flick decides by direction; otherwise where the drawer would
    // come to rest does, so a small drag springs back.
    final open = velocity.abs() > 400 ? velocity > 0 : projected >= 0.5;
    _settle(open, velocity: velocity / _drawerExtent, fromGesture: true);
  }

  void _dragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _settle(_drawerOpen, velocity: 0);
  }

  KumoAppShellLayout _layoutFor(double width) {
    if (widget.layout != null) return widget.layout!;
    if (widget.sidebar == null) {
      return width < widget.narrowBreakpoint ? KumoAppShellLayout.narrow : KumoAppShellLayout.wide;
    }
    if (width < widget.narrowBreakpoint) return KumoAppShellLayout.narrow;
    if (width < widget.wideBreakpoint) return KumoAppShellLayout.medium;
    return KumoAppShellLayout.wide;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _layoutFor(constraints.maxWidth);
        if (_lastLayout != layout) {
          final leftNarrow = _lastLayout == KumoAppShellLayout.narrow;
          _lastLayout = layout;
          _railExpanded = false;
          if (leftNarrow && (_drawerOpen || _drawer.value != 0)) {
            _drawer.value = 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _setDrawerOpen(false);
            });
          }
        }
        final data = KumoAppShellData(
          layout: layout,
          drawerOpen: _drawerOpen && layout == KumoAppShellLayout.narrow,
          openDrawer: _openDrawer,
          closeDrawer: _closeDrawer,
          toggleSidebar: _toggleSidebar,
        );
        final frame = layout == KumoAppShellLayout.narrow
            ? _buildNarrow(context, constraints)
            : _buildPersistent(context, layout);
        // The shell is a page: it sets up its own text and icon defaults so a
        // route with no Scaffold above it never falls back to Material's
        // debug text style (the yellow double underline).
        final kumo = context.kumo;
        return _KumoAppShellScope(
          data: data,
          child: DefaultTextStyle(
            style: kumo.text(),
            child: IconTheme(
              data: IconThemeData(color: kumo.colors.textDefault, size: 16),
              child: ColoredBox(color: kumo.colors.canvas, child: frame),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, {required bool top, required bool bottom}) {
    // Text fields in the page need a Material ancestor for their selection
    // toolbar and ink; a transparent one paints nothing.
    Widget body = Material(
      type: MaterialType.transparency,
      textStyle: context.kumo.text(),
      child: Padding(padding: widget.bodyPadding, child: widget.body),
    );
    if (widget.safeAreaBody) {
      body = SafeArea(top: !top, bottom: !bottom, child: body);
    }
    return MediaQuery.removePadding(context: context, removeTop: top, removeBottom: bottom, child: body);
  }

  Widget _buildPersistent(BuildContext context, KumoAppShellLayout layout) {
    final sidebar = widget.sidebar;
    final hasTop = widget.topBar != null;
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTop) _ShellTopBar(child: widget.topBar),
        Expanded(child: _body(context, top: hasTop, bottom: false)),
      ],
    );
    if (sidebar == null) return main;
    final open = layout == KumoAppShellLayout.wide ? _wideOpen : _railExpanded;
    final rail = KumoSidebarHost(
      open: open,
      onOpenChange: layout == KumoAppShellLayout.wide ? _setWideOpen : _setRailExpanded,
      child: KeyedSubtree(key: _sidebarKey, child: sidebar),
    );
    final start = sidebar.side == KumoSidebarSide.start;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sidebarOnLeft = start != rtl;
    final content = MediaQuery.removePadding(
      context: context,
      removeLeft: sidebarOnLeft,
      removeRight: !sidebarOnLeft,
      child: main,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: start ? [rail, Expanded(child: content)] : [Expanded(child: content), rail],
    );
  }

  Widget _buildNarrow(BuildContext context, BoxConstraints constraints) {
    final sidebar = widget.sidebar;
    final strings = context.kumoStrings;
    final hasBottom = widget.bottomNavigation != null;
    final maxWidth = constraints.maxWidth;
    final drawerWidth = widget.fullScreenDrawer
        ? maxWidth
        : math.min(widget.drawerWidth ?? sidebar?.width ?? KumoSidebar.defaultWidth, math.max(0.0, maxWidth - 56));
    _drawerExtent = math.max(1, drawerWidth);
    final open = _drawerOpen;

    Widget main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShellTopBar(
          leading: sidebar == null
              ? null
              : KumoButton(
                  variant: KumoButtonVariant.ghost,
                  size: KumoButtonSize.sm,
                  icon: KumoIcons.list,
                  label: widget.menuLabel ?? strings.menu,
                  focusNode: _menuFocus,
                  onPress: _openDrawer,
                ),
          child: widget.topBar,
        ),
        Expanded(child: _body(context, top: true, bottom: hasBottom)),
        if (hasBottom)
          // KumoBottomNavigation draws its own top border and safe-area
          // padding; anything else gets the shell's.
          widget.bottomNavigation is KumoBottomNavigation
              ? widget.bottomNavigation!
              : _ShellBottomBar(child: widget.bottomNavigation!),
      ],
    );
    if (sidebar == null) return main;
    main = ExcludeFocus(excluding: open, child: main);

    final start = sidebar.side == KumoSidebarSide.start;
    final panel = KumoSidebarHost(
      open: true,
      drawer: true,
      drawerWidth: drawerWidth,
      onOpenChange: (_) {},
      onClose: _closeDrawer,
      onNavigate: widget.closeDrawerOnNavigate ? _closeDrawer : null,
      child: SizedBox(
        width: drawerWidth,
        child: KeyedSubtree(key: _sidebarKey, child: sidebar),
      ),
    );

    final layer = AnimatedBuilder(
      animation: _drawer,
      child: panel,
      builder: (context, child) {
        final value = _drawer.value;
        final hidden = value <= 0 && !_dragging && !open;
        final over = value > 1 ? (value - 1) * drawerWidth : 0.0;
        final shift = value < 1 ? (1 - value) * drawerWidth : 0.0;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final towardEdge = (start ? -1.0 : 1.0) * (rtl ? -1.0 : 1.0);
        final c = context.kumo.colors;
        return Offstage(
          offstage: hidden,
          child: Stack(
            fit: StackFit.expand,
            children: [
              KumoScrim(
                opacity: widget.fullScreenDrawer ? 0 : value.clamp(0.0, 1.0),
                onPress: _closeDrawer,
                semanticLabel: strings.closeSidebar,
              ),
              // Past fully open the drawer stretches from its edge instead
              // of pulling away from it.
              if (over > 0)
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  start: start ? 0 : null,
                  end: start ? null : 0,
                  width: over,
                  child: ColoredBox(color: c.base),
                ),
              Align(
                alignment: start ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                child: Transform.translate(offset: Offset((shift - over) * towardEdge, 0), child: child),
              ),
            ],
          ),
        );
      },
    );

    // Only an open drawer listens for drags across the screen; a closed one
    // opens from the edge strip, so horizontal scrolling in the page keeps
    // working.
    final drawerLayer = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: open ? _dragStart : null,
      onHorizontalDragUpdate: open ? _dragUpdate : null,
      onHorizontalDragEnd: open ? _dragEnd : null,
      onHorizontalDragCancel: open ? _dragCancel : null,
      child: ExcludeFocus(
        excluding: !open,
        child: FocusScope(
          node: _drawerScope,
          child: CallbackShortcuts(
            bindings: {const SingleActivator(LogicalKeyboardKey.escape): _closeDrawer},
            child: layer,
          ),
        ),
      ),
    );

    final safe = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final edgeOnLeft = start != rtl;
    final edgeWidth = widget.edgeSwipeWidth + (edgeOnLeft ? safe.left : safe.right);

    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _drawerOpen) _closeDrawer();
      },
      child: Stack(
        children: [
          Positioned.fill(child: main),
          if (!open)
            Positioned(
              top: 0,
              bottom: 0,
              left: edgeOnLeft ? 0 : null,
              right: edgeOnLeft ? null : 0,
              width: edgeWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _dragStart,
                onHorizontalDragUpdate: _dragUpdate,
                onHorizontalDragEnd: _dragEnd,
                onHorizontalDragCancel: _dragCancel,
              ),
            ),
          Positioned.fill(child: open ? BlockSemantics(child: drawerLayer) : drawerLayer),
        ],
      ),
    );
  }
}

/// The sticky bar above the page, separated from it by a border.
class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({this.leading, this.child});

  final Widget? leading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        color: c.base,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s1),
          child: Row(
            spacing: KumoSpace.s2,
            children: [
              ?leading,
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.base,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
