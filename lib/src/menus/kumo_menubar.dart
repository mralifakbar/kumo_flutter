import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_field_box.dart' show KumoPresentation;
import '../system/kumo_pressable.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_dropdown_menu.dart';

/// One menu of a [KumoMenubar]: its trigger and its items (the same item
/// widgets as [KumoDropdownMenu]).
///
/// ```dart
/// KumoMenubarMenu(
///   label: 'Deploy',
///   items: [
///     KumoDropdownItem(label: 'Deploy to production', onPress: deploy),
///     KumoDropdownItem(label: 'Roll back', onPress: rollBack),
///   ],
/// )
/// ```
@immutable
class KumoMenubarMenu {
  const KumoMenubarMenu({required this.label, required this.items, this.icon, this.disabled = false});

  /// Trigger text. With [icon], the trigger shows only the icon and [label]
  /// becomes its tooltip and accessible name (Kumo's icon `MenuBar`).
  final String label;
  final List<Widget> items;
  final IconData? icon;
  final bool disabled;
}

/// A horizontal bar of menus, in Kumo's `MenuBar` look: a recessed track
/// where the open menu's trigger is raised onto the base surface.
///
/// ```dart
/// KumoMenubar(
///   menus: [
///     KumoMenubarMenu(label: 'File', items: [KumoDropdownItem(label: 'New Worker', onPress: create)]),
///     KumoMenubarMenu(label: 'View', items: [KumoDropdownCheckboxItem(label: 'Logs', checked: logs, onCheckedChange: setLogs)]),
///   ],
/// )
/// ```
///
/// * Press a trigger to open its menu. While one menu is open, hovering
///   another trigger switches to it.
/// * Keyboard: Left and Right move between triggers (one Tab stop for the
///   whole bar); Enter, Space or Down open the focused menu; inside an open
///   menu, Left and Right move to the neighboring menu; Escape closes it and
///   focus returns to its trigger.
/// * Below 768px ([KumoPresentation.auto]) menus open as bottom sheets. The
///   bar scrolls sideways if its triggers do not fit.
class KumoMenubar extends StatefulWidget {
  const KumoMenubar({super.key, required this.menus, this.presentation = KumoPresentation.auto, this.semanticLabel});

  final List<KumoMenubarMenu> menus;
  final KumoPresentation presentation;

  /// Accessible name of the bar, such as 'Worker editor'.
  final String? semanticLabel;

  @override
  State<KumoMenubar> createState() => _KumoMenubarState();
}

class _KumoMenubarState extends State<KumoMenubar> {
  final Object _group = Object();
  final List<FocusNode> _nodes = [];
  int? _openIndex;
  int _tabStop = 0;

  // True after the open menu moved to another trigger, until a menu opens
  // from closed or closes. The outgoing and incoming panels then swap in
  // place instead of one shrinking away while the other grows in.
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(KumoMenubar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
    final open = _openIndex;
    if (open != null && (open >= widget.menus.length || widget.menus[open].disabled)) _openIndex = null;
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    while (_nodes.length < widget.menus.length) {
      final index = _nodes.length;
      final node = FocusNode(debugLabel: 'KumoMenubar trigger $index');
      node.addListener(() {
        if (node.hasPrimaryFocus && _tabStop != index) setState(() => _tabStop = index);
      });
      _nodes.add(node);
    }
    while (_nodes.length > widget.menus.length) {
      _nodes.removeLast().dispose();
    }
    _tabStop = _tabStop.clamp(0, math.max(0, widget.menus.length - 1));
  }

  List<int> get _enabled => [
    for (var i = 0; i < widget.menus.length; i++)
      if (!widget.menus[i].disabled) i,
  ];

  int? _neighbor(int from, int delta) {
    final enabled = _enabled;
    if (enabled.isEmpty) return null;
    var pos = enabled.indexOf(from);
    if (pos < 0) pos = 0;
    return enabled[(pos + delta) % enabled.length];
  }

  void _setOpen(int index, bool open) {
    setState(() {
      _switching = open && _openIndex != null && _openIndex != index;
      if (open) {
        _openIndex = index;
        _tabStop = index;
      } else if (_openIndex == index) {
        _openIndex = null;
        _refocus(index);
      }
    });
  }

  void _refocus(int index) {
    // Menus here do not restore focus themselves (switching menus would
    // fight over it), so hand it back to the trigger.
    final focus = FocusManager.instance.primaryFocus;
    final inBar = focus != null && _nodes.contains(focus);
    if (inBar || FocusManager.instance.highlightMode != FocusHighlightMode.traditional) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && index < _nodes.length) _nodes[index].requestFocus();
    });
  }

  void _moveFocus(int delta) {
    final current = _nodes.indexWhere((n) => n.hasPrimaryFocus);
    final next = _neighbor(current < 0 ? _tabStop : current, delta);
    if (next == null) return;
    setState(() => _tabStop = next);
    _nodes[next].requestFocus();
  }

  void _switchTo(int from, int delta) {
    final next = _neighbor(from, delta);
    if (next == null || next == from) return;
    setState(() {
      _switching = true;
      _openIndex = next;
      _tabStop = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final height = math.max(36.0, kumo.minTapTarget);

    final triggers = <Widget>[for (var i = 0; i < widget.menus.length; i++) _buildMenu(context, i, height)];

    Widget bar = Container(
      padding: const EdgeInsetsDirectional.only(start: KumoSpace.px),
      decoration: BoxDecoration(
        color: c.recessed,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(c.line),
        boxShadow: KumoShadow.xs.boxShadows,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: triggers),
    );

    bar = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        // Only while a trigger has focus; open menus handle their own keys.
        if (!_nodes.any((n) => n.hasPrimaryFocus)) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowLeft) {
          _moveFocus(rtl ? 1 : -1);
        } else if (key == LogicalKeyboardKey.arrowRight) {
          _moveFocus(rtl ? -1 : 1);
        } else if (key == LogicalKeyboardKey.home) {
          _focusEdge(last: false);
        } else if (key == LogicalKeyboardKey.end) {
          _focusEdge(last: true);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: bar,
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, child: bar),
    );
  }

  void _focusEdge({required bool last}) {
    final enabled = _enabled;
    if (enabled.isEmpty) return;
    final index = last ? enabled.last : enabled.first;
    setState(() => _tabStop = index);
    _nodes[index].requestFocus();
  }

  Widget _buildMenu(BuildContext context, int index, double height) {
    final menu = widget.menus[index];
    final open = _openIndex == index;
    return KumoDropdownMenu(
      key: ValueKey(index),
      open: open,
      onOpenChange: (value) => _setOpen(index, value),
      items: menu.items,
      side: KumoSide.bottom,
      align: KumoAlign.start,
      sideOffset: 6,
      presentation: widget.presentation,
      semanticLabel: menu.label,
      sheetTitle: menu.label,
      disabled: menu.disabled,
      tapRegionGroupId: _group,
      restoreFocus: false,
      animate: !_switching,
      onNavigateSibling: (delta) => _switchTo(index, delta),
      triggerBuilder: (context, controller) => _MenubarTrigger(
        menu: menu,
        open: open,
        height: height,
        focusNode: _nodes[index],
        tabStop: _tabStop == index,
        onPress: controller.toggle,
        onHover: () {
          final current = _openIndex;
          if (current != null && current != index && !menu.disabled) {
            setState(() {
              _switching = true;
              _openIndex = _tabStop = index;
            });
          }
        },
      ),
    );
  }
}

class _MenubarTrigger extends StatelessWidget {
  const _MenubarTrigger({
    required this.menu,
    required this.open,
    required this.height,
    required this.focusNode,
    required this.tabStop,
    required this.onPress,
    required this.onHover,
  });

  final KumoMenubarMenu menu;
  final bool open;
  final double height;
  final FocusNode focusNode;
  final bool tabStop;
  final VoidCallback onPress;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final iconOnly = menu.icon != null;
    // Roving focus: one trigger is the Tab stop, arrows reach the rest.
    focusNode.skipTraversal = !tabStop;
    final radius = BorderRadius.circular(KumoRadius.md);
    Widget trigger = KumoPressable(
      focusNode: focusNode,
      onPress: menu.disabled ? null : onPress,
      disabled: menu.disabled,
      expanded: open,
      minTapTargetSize: 0,
      borderRadius: radius,
      semanticLabel: iconOnly ? menu.label : null,
      excludeChildSemantics: iconOnly,
      builder: (context, state) => Opacity(
        opacity: menu.disabled ? 0.5 : 1,
        child: Container(
          height: height,
          width: iconOnly ? math.max(44.0, height) : null,
          padding: iconOnly ? null : const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: open ? c.base : (state.active ? c.tint : null),
            borderRadius: radius,
            boxShadow: open ? KumoShadow.xs.boxShadows : null,
          ),
          child: iconOnly
              ? KumoIcon(menu.icon!, size: 18)
              : Text(menu.label, maxLines: 1, style: kumo.text(weight: KumoTypography.medium)),
        ),
      ),
    );
    // Always wrapped, so opening never rebuilds the trigger and drops focus.
    if (iconOnly) trigger = KumoTooltip(content: menu.label, disabled: open, child: trigger);
    return MouseRegion(
      opaque: false,
      onEnter: (event) {
        if (event.kind != PointerDeviceKind.touch) onHover();
      },
      child: trigger,
    );
  }
}
