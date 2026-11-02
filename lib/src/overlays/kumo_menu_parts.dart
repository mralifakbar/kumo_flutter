import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// The surface of menus and option lists: `bg-kumo-control`, `rounded-lg`,
/// a 1px ring, `shadow-lg` and 6px of inner padding. Scrolls when its
/// content is taller than the room it was given.
///
/// Used by dropdown menus, select and combobox lists and the command palette.
class KumoMenuPanel extends StatelessWidget {
  const KumoMenuPanel({
    super.key,
    required this.children,
    this.minWidth = 144,
    this.maxHeight,
    this.padding = const EdgeInsets.all(KumoSpace.s1_5),
    this.scrollController,
    this.semanticLabel,
  });

  final List<Widget> children;

  /// Kumo's `min-w-36`.
  final double minWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry padding;
  final ScrollController? scrollController;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    const radius = BorderRadius.all(Radius.circular(KumoRadius.lg));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth, maxHeight: maxHeight ?? double.infinity),
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: radius,
          border: KumoRing.border(c.line),
          boxShadow: KumoShadow.lg.boxShadows,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: KumoMenuKeyboard(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: padding,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Arrow-key movement between the focusable rows inside [child]: Up and Down
/// move, Home and End jump to the ends. Wrap any custom list of
/// [KumoMenuRow]s with it.
class KumoMenuKeyboard extends StatelessWidget {
  const KumoMenuKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        child: Actions(
          actions: {
            _EdgeIntent: CallbackAction<_EdgeIntent>(
              onInvoke: (intent) {
                final scope = FocusManager.instance.primaryFocus?.nearestScope;
                final nodes = scope?.traversalDescendants.where((n) => n.canRequestFocus && !n.skipTraversal).toList();
                if (nodes == null || nodes.isEmpty) return null;
                (intent.last ? nodes.last : nodes.first).requestFocus();
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.home): _EdgeIntent(last: false),
              SingleActivator(LogicalKeyboardKey.end): _EdgeIntent(last: true),
            },
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EdgeIntent extends Intent {
  const _EdgeIntent({required this.last});
  final bool last;
}

/// One row of a menu or option list: `rounded-md px-2 py-1.5`, tinted while
/// hovered or keyboard-highlighted, with optional leading icon, description
/// and trailing content (a check, a shortcut, a submenu caret).
///
/// ```dart
/// KumoMenuRow(label: 'Rename', icon: KumoIcons.pencilSimple, onPress: rename)
/// KumoMenuRow(label: 'Delete', icon: KumoIcons.trash, destructive: true, onPress: delete)
/// ```
class KumoMenuRow extends StatelessWidget {
  const KumoMenuRow({
    super.key,
    required this.label,
    this.onPress,
    this.icon,
    this.leading,
    this.description,
    this.trailing,
    this.shortcut,
    this.selected,
    this.highlighted = false,
    this.disabled = false,
    this.destructive = false,
    this.inset = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.checked,
    this.inMutuallyExclusiveGroup,
    this.expanded,
    this.isLink = false,
    this.onHover,
    this.canRequestFocus = true,
  });

  final String label;
  final VoidCallback? onPress;
  final IconData? icon;

  /// Custom leading widget (an avatar, a checkbox box) in place of [icon].
  final Widget? leading;
  final String? description;
  final Widget? trailing;

  /// Keyboard shortcut hint shown at the end, such as `⌘K`.
  final String? shortcut;

  /// Marks the row as the current option (announced as selected).
  final bool? selected;

  /// Force the highlight (an option list that tracks highlight separately
  /// from focus, such as a combobox driven from its text field).
  final bool highlighted;
  final bool disabled;

  /// Danger text, for delete and revoke.
  final bool destructive;

  /// Leaves room for a leading indicator so labels line up with checkable rows.
  final bool inset;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final bool? checked;
  final bool? inMutuallyExclusiveGroup;
  final bool? expanded;

  /// Announce as a link (navigation items).
  final bool isLink;

  /// Pointer entered (true) or left (false) the row, for lists that move a
  /// highlight with the mouse while focus stays in a text field.
  final ValueChanged<bool>? onHover;

  /// False keeps the row out of focus traversal (option lists driven from a
  /// text field).
  final bool canRequestFocus;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final fg = destructive ? KumoColor.textDanger : KumoColor.textDefault;
    final Widget row = KumoPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      focusNode: focusNode,
      autofocus: autofocus,
      scaleOnPress: false,
      minTapTargetSize: 0,
      borderRadius: BorderRadius.circular(KumoRadius.md),
      semanticLabel: semanticLabel,
      selected: selected,
      checked: checked,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      expanded: expanded,
      isLink: isLink,
      canRequestFocus: canRequestFocus,
      builder: (context, state) {
        final lit = highlighted || state.active || state.focused;
        final lead =
            leading ?? (icon != null ? KumoIcon(icon!, color: destructive ? KumoColor.textDanger : null) : null);
        return Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Container(
            constraints: BoxConstraints(minHeight: kumo.minTapTarget > 0 ? 40 : 32),
            padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1_5),
            decoration: BoxDecoration(
              // Kumo tints destructive rows with danger at 5% instead of the neutral tint.
              color: lit ? (destructive ? c.danger.withValues(alpha: 0.05) : c.tint) : null,
              borderRadius: BorderRadius.circular(KumoRadius.md),
            ),
            child: Row(
              spacing: KumoSpace.s2,
              children: [
                if (lead != null) lead else if (inset) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: kumo.text(color: fg),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
                        ),
                    ],
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut!,
                    style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
                  ),
                ?trailing,
              ],
            ),
          ),
        );
      },
    );
    if (onHover == null) return row;
    return MouseRegion(onEnter: (_) => onHover!(true), onExit: (_) => onHover!(false), child: row);
  }
}

/// A 1px `kumo-hairline` divider between groups of menu rows.
class KumoMenuSeparator extends StatelessWidget {
  const KumoMenuSeparator({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KumoSpace.s1),
    child: SizedBox(height: 1, child: ColoredBox(color: context.kumo.colors.hairline)),
  );
}

/// The heading of a group of menu rows: small semibold subtle text.
class KumoMenuGroupLabel extends StatelessWidget {
  const KumoMenuGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1_5),
      child: Text(
        text,
        style: context.kumo.text(size: KumoTextSize.sm, weight: KumoTypography.semibold, color: KumoColor.textSubtle),
      ),
    ),
  );
}
