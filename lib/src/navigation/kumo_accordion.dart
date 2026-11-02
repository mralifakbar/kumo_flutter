import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'kumo_collapsible.dart';

/// Whether a [KumoAccordion] keeps one item open or several.
enum KumoAccordionType {
  /// Opening an item closes the others.
  single,

  /// Items open and close independently.
  multiple,
}

/// One section of a [KumoAccordion].
///
/// ```dart
/// const KumoAccordionItem(
///   value: 'routes',
///   title: 'Which routes run this Worker?',
///   child: KumoText('Routes on example.com/api/* and the workers.dev subdomain.'),
/// )
/// ```
@immutable
class KumoAccordionItem {
  const KumoAccordionItem({
    required this.value,
    required this.title,
    required this.child,
    this.description,
    this.icon,
    this.disabled = false,
  });

  /// Identifies the item in [KumoAccordion.value].
  final String value;
  final String title;

  /// Panel content, shown in subtle 14px text unless it sets its own style.
  final Widget child;

  /// A second line under the title.
  final String? description;

  /// Leading icon, 16px.
  final IconData? icon;
  final bool disabled;
}

/// A stack of collapsible sections separated by hairlines. Shaped after
/// shadcn's accordion and drawn with Kumo tokens; each panel opens with
/// [KumoCollapsiblePanel], so content keeps its size while the height
/// animates.
///
/// Controlled: [value] holds the open items, [onValueChange] receives the
/// next set.
///
/// Keyboard: Tab moves between headers; Up and Down move too, Home and End
/// jump to the first and last; Enter or Space toggles.
///
/// ```dart
/// KumoAccordion(
///   value: open,
///   onValueChange: (v) => setState(() => open = v),
///   items: const [
///     KumoAccordionItem(value: 'cache', title: 'Cache rules', child: KumoText('3 rules')),
///     KumoAccordionItem(value: 'waf', title: 'WAF custom rules', child: KumoText('1 rule')),
///   ],
/// )
/// ```
class KumoAccordion extends StatefulWidget {
  const KumoAccordion({
    super.key,
    required this.items,
    required this.value,
    required this.onValueChange,
    this.type = KumoAccordionType.single,
    this.collapsible = true,
    this.keepMounted = false,
  });

  final List<KumoAccordionItem> items;

  /// Values of the open items.
  final Set<String> value;
  final ValueChanged<Set<String>>? onValueChange;
  final KumoAccordionType type;

  /// For [KumoAccordionType.single]: whether the open item can be closed,
  /// leaving none open.
  final bool collapsible;

  /// Keep closed panels' widgets alive.
  final bool keepMounted;

  @override
  State<KumoAccordion> createState() => _KumoAccordionState();
}

class _KumoAccordionState extends State<KumoAccordion> {
  final List<FocusNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(KumoAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    while (_nodes.length < widget.items.length) {
      _nodes.add(FocusNode(debugLabel: 'KumoAccordion ${_nodes.length}'));
    }
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _toggle(String value) {
    final open = widget.value.contains(value);
    final Set<String> next;
    if (widget.type == KumoAccordionType.single) {
      if (open && !widget.collapsible) return;
      next = open ? <String>{} : {value};
    } else {
      next = {...widget.value};
      open ? next.remove(value) : next.add(value);
    }
    widget.onValueChange?.call(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final focused = _nodes.indexWhere((n) => n.hasFocus);
    if (focused < 0) return KeyEventResult.ignored;
    final enabled = [
      for (var i = 0; i < widget.items.length; i++)
        if (!widget.items[i].disabled) i,
    ];
    if (enabled.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    int? target;
    final pos = enabled.indexOf(focused);
    if (key == LogicalKeyboardKey.arrowDown) {
      target = enabled[(pos + 1) % enabled.length];
    } else if (key == LogicalKeyboardKey.arrowUp) {
      target = enabled[(pos - 1 + enabled.length) % enabled.length];
    } else if (key == LogicalKeyboardKey.home) {
      target = enabled.first;
    } else if (key == LogicalKeyboardKey.end) {
      target = enabled.last;
    } else {
      return KeyEventResult.ignored;
    }
    _nodes[target].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final items = widget.items;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == items.length - 1 ? null : Border(bottom: BorderSide(color: c.hairline)),
              ),
              child: _AccordionSection(
                item: items[i],
                open: widget.value.contains(items[i].value),
                focusNode: _nodes[i],
                keepMounted: widget.keepMounted,
                onToggle: widget.onValueChange == null ? null : () => _toggle(items[i].value),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.item,
    required this.open,
    required this.focusNode,
    required this.keepMounted,
    required this.onToggle,
  });

  final KumoAccordionItem item;
  final bool open;
  final FocusNode focusNode;
  final bool keepMounted;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final disabled = item.disabled || onToggle == null;
    final header = KumoPressable(
      onPress: disabled ? null : onToggle,
      disabled: item.disabled,
      focusNode: focusNode,
      expanded: open,
      scaleOnPress: false,
      showFocusRing: false,
      builder: (context, state) {
        final fg = state.active ? KumoColor.textStrong : KumoColor.textDefault;
        Widget row = Padding(
          padding: const EdgeInsets.symmetric(vertical: KumoSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s2,
            children: [
              if (item.icon != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.5),
                  child: KumoIcon(item.icon!, color: KumoColor.textSubtle),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: kumo.text(weight: KumoTypography.medium, color: fg),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2.5),
                child: KumoDisclosureCaret(
                  open: open,
                  color: state.active ? KumoColor.textDefault : KumoColor.textSubtle,
                ),
              ),
            ],
          ),
        );
        row = KumoFocusRing(visible: state.focused, borderRadius: BorderRadius.circular(KumoRadius.sm), child: row);
        return Semantics(
          header: true,
          child: Opacity(opacity: item.disabled ? 0.5 : 1, child: row),
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        KumoCollapsiblePanel(
          open: open,
          keepMounted: keepMounted,
          child: Padding(
            padding: EdgeInsetsDirectional.only(bottom: KumoSpace.s4, start: item.icon != null ? KumoSpace.s6 : 0),
            child: DefaultTextStyle.merge(
              style: kumo.text(color: KumoColor.textSubtle),
              child: item.child,
            ),
          ),
        ),
      ],
    );
  }
}
