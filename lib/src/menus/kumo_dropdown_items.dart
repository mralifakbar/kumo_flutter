part of 'kumo_dropdown_menu.dart';

/// Wraps every row: hover timing for submenus on pointer devices and a 44px
/// row height in the sheet presentation.
class _ItemShell extends StatelessWidget {
  const _ItemShell({required this.child, this.submenuKey});

  final Widget child;
  final Object? submenuKey;

  @override
  Widget build(BuildContext context) {
    final scope = _MenuScope.maybeOf(context);
    if (scope == null) return child;
    if (scope.host.sheet) {
      return ConstrainedBox(constraints: const BoxConstraints(minHeight: 44), child: child);
    }
    return MouseRegion(
      opaque: false,
      onEnter: (event) {
        if (_isTouch(event)) return;
        final key = submenuKey;
        key != null ? scope.level.hoverSubmenu(key) : scope.level.hoverItem();
      },
      child: child,
    );
  }
}

/// An action in a [KumoDropdownMenu], [KumoContextMenu] or [KumoMenubar].
/// Pressing it runs [onPress] and closes the menu.
///
/// ```dart
/// KumoDropdownItem(label: 'Duplicate', icon: KumoIcons.copy, shortcut: '⌘D', onPress: duplicate)
/// KumoDropdownItem(label: 'Delete Worker', icon: KumoIcons.trash, destructive: true, onPress: delete)
/// ```
class KumoDropdownItem extends StatelessWidget {
  const KumoDropdownItem({
    super.key,
    required this.label,
    this.onPress,
    this.icon,
    this.description,
    this.shortcut,
    this.destructive = false,
    this.disabled = false,
    this.selected = false,
    this.closeOnPress = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPress;
  final IconData? icon;

  /// Second line in subtle text.
  final String? description;

  /// Keyboard shortcut hint at the end of the row, such as `⌘K`. Display
  /// only: register the shortcut itself with `Shortcuts`.
  final String? shortcut;

  /// Kumo's `variant="danger"`: red text for delete and revoke.
  final bool destructive;
  final bool disabled;

  /// Shows a check at the end and announces the row as selected.
  final bool selected;

  /// Set false to keep the menu open after the press.
  final bool closeOnPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scope = _MenuScope.maybeOf(context);
    return _ItemShell(
      child: KumoMenuRow(
        label: label,
        icon: icon,
        description: description,
        shortcut: shortcut,
        destructive: destructive,
        disabled: disabled,
        inset: icon == null && (scope?.inset ?? false),
        selected: selected ? true : null,
        semanticLabel: semanticLabel,
        trailing: selected ? const KumoIcon(KumoIcons.check) : null,
        onPress: disabled
            ? null
            : () {
                onPress?.call();
                if (closeOnPress) scope?.host.close();
              },
      ),
    );
  }
}

/// A menu row that navigates (Kumo's `DropdownMenu.LinkItem`). Announced as
/// a link; [onPress] performs the navigation and the menu closes.
///
/// ```dart
/// KumoDropdownLinkItem(
///   label: 'Developer docs',
///   icon: KumoIcons.arrowSquareOut,
///   onPress: () => launchDocs(),
/// )
/// ```
class KumoDropdownLinkItem extends StatelessWidget {
  const KumoDropdownLinkItem({
    super.key,
    required this.label,
    required this.onPress,
    this.icon,
    this.destructive = false,
    this.disabled = false,
    this.semanticLabel,
  });

  final String label;

  /// Navigate here (push a route, open a URL).
  final VoidCallback? onPress;
  final IconData? icon;
  final bool destructive;
  final bool disabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scope = _MenuScope.maybeOf(context);
    return _ItemShell(
      child: MergeSemantics(
        child: Semantics(
          link: true,
          child: KumoMenuRow(
            label: label,
            icon: icon,
            destructive: destructive,
            disabled: disabled,
            inset: icon == null && (scope?.inset ?? false),
            semanticLabel: semanticLabel,
            onPress: disabled
                ? null
                : () {
                    onPress?.call();
                    scope?.host.close();
                  },
          ),
        ),
      ),
    );
  }
}

/// A row with a check that toggles a setting. The menu stays open after a
/// press, as in Base UI, unless [closeOnPress] is set.
///
/// ```dart
/// KumoDropdownCheckboxItem(
///   label: 'Show line numbers',
///   checked: showLineNumbers,
///   onCheckedChange: (v) => setState(() => showLineNumbers = v),
/// )
/// ```
class KumoDropdownCheckboxItem extends StatelessWidget {
  const KumoDropdownCheckboxItem({
    super.key,
    required this.label,
    required this.checked,
    this.onCheckedChange,
    this.description,
    this.shortcut,
    this.disabled = false,
    this.closeOnPress = false,
  });

  final String label;
  final bool checked;

  /// Called with the next value.
  final ValueChanged<bool>? onCheckedChange;
  final String? description;
  final String? shortcut;
  final bool disabled;
  final bool closeOnPress;

  @override
  Widget build(BuildContext context) {
    final scope = _MenuScope.maybeOf(context);
    final off = disabled || onCheckedChange == null;
    return _ItemShell(
      child: KumoMenuRow(
        label: label,
        description: description,
        shortcut: shortcut,
        disabled: disabled,
        checked: checked,
        leading: SizedBox(
          width: 16,
          child: Center(child: _MenuCheck(checked: checked, size: 12)),
        ),
        onPress: off
            ? null
            : () {
                onCheckedChange!(!checked);
                if (closeOnPress) scope?.host.close();
              },
      ),
    );
  }
}

class _RadioScope extends InheritedWidget {
  const _RadioScope({required this.value, required this.onSelect, required super.child});

  final Object? value;
  final ValueChanged<Object?>? onSelect;

  static _RadioScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_RadioScope>();

  @override
  bool updateShouldNotify(_RadioScope old) => value != old.value || onSelect != old.onSelect;
}

/// The check of a checkbox or radio row. It lands with Kumo's small bounce
/// when the row becomes checked and fades out when it is cleared, reversing
/// from wherever it is if the value flips back mid-flight. Rows that open
/// checked show it at rest.
class _MenuCheck extends StatefulWidget {
  const _MenuCheck({required this.checked, this.size = 16});

  final bool checked;
  final double size;

  @override
  State<_MenuCheck> createState() => _MenuCheckState();
}

class _MenuCheckState extends State<_MenuCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _t;

  @override
  void initState() {
    super.initState();
    // Unbounded so the bounce curve can overshoot past 1.
    _t = AnimationController.unbounded(vsync: this, value: widget.checked ? 1 : 0)..duration = KumoDurations.moderate;
  }

  @override
  void didUpdateWidget(_MenuCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked == oldWidget.checked) return;
    final target = widget.checked ? 1.0 : 0.0;
    if (KumoMotion.reduceMotion(context)) {
      _t.value = target;
    } else if (widget.checked) {
      _t.animateTo(target, curve: KumoCurves.bounce);
    } else {
      _t.animateTo(target, duration: KumoDurations.fast, curve: KumoCurves.exit);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = _t.value;
          if (t <= 0) return const SizedBox.shrink();
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
          );
        },
        child: KumoIcon(KumoIcons.check, size: widget.size),
      ),
    );
  }
}

/// A set of mutually exclusive [KumoDropdownRadioItem]s. The group owns the
/// value; items only report presses.
///
/// ```dart
/// KumoDropdownRadioGroup<String>(
///   value: region,
///   onValueChange: (v) => setState(() => region = v),
///   children: const [
///     KumoDropdownRadioItem(value: 'wnam', label: 'Western North America'),
///     KumoDropdownRadioItem(value: 'weur', label: 'Western Europe'),
///   ],
/// )
/// ```
class KumoDropdownRadioGroup<T> extends StatelessWidget {
  const KumoDropdownRadioGroup({
    super.key,
    required this.value,
    required this.children,
    this.onValueChange,
    this.label,
  });

  /// The selected value, or null for none.
  final T? value;
  final List<Widget> children;
  final ValueChanged<T>? onValueChange;

  /// Accessible name of the group (a visible heading goes in a
  /// [KumoDropdownLabel] or [KumoDropdownGroup]).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final change = onValueChange;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: _RadioScope(
        value: value,
        onSelect: change == null ? null : (v) => change(v as T),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// One option of a [KumoDropdownRadioGroup]. The selected option shows a
/// check at the end. The menu stays open after a press unless
/// [closeOnPress] is set.
class KumoDropdownRadioItem<T> extends StatelessWidget {
  const KumoDropdownRadioItem({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.description,
    this.disabled = false,
    this.closeOnPress = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? description;
  final bool disabled;
  final bool closeOnPress;

  @override
  Widget build(BuildContext context) {
    final scope = _MenuScope.maybeOf(context);
    final radio = _RadioScope.maybeOf(context);
    final checked = radio != null && radio.value == value;
    final select = radio?.onSelect;
    return _ItemShell(
      child: KumoMenuRow(
        label: label,
        icon: icon,
        description: description,
        disabled: disabled,
        inset: icon == null && (scope?.inset ?? false),
        checked: checked,
        inMutuallyExclusiveGroup: true,
        // Always present so the check can leave the old option and land on
        // the new one while the menu stays open.
        trailing: _MenuCheck(checked: checked),
        onPress: disabled || select == null
            ? null
            : () {
                select(value);
                if (closeOnPress) scope?.host.close();
              },
      ),
    );
  }
}

/// Groups related rows, with an optional [label] heading.
///
/// ```dart
/// KumoDropdownGroup(
///   label: 'Display',
///   children: [
///     KumoDropdownCheckboxItem(label: 'Word wrap', checked: wrap, onCheckedChange: setWrap),
///   ],
/// )
/// ```
class KumoDropdownGroup extends StatelessWidget {
  const KumoDropdownGroup({super.key, required this.children, this.label});

  final List<Widget> children;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [if (label != null) KumoDropdownLabel(label!), ...children],
      ),
    );
  }
}

/// A group heading: `px-2 py-1.5 text-base font-semibold`, inset to line up
/// with rows that have icons.
class KumoDropdownLabel extends StatelessWidget {
  const KumoDropdownLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final inset = _MenuScope.maybeOf(context)?.inset ?? false;
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: KumoSpace.s2 + (inset ? 24 : 0),
          end: KumoSpace.s2,
          top: KumoSpace.s1_5,
          bottom: KumoSpace.s1_5,
        ),
        child: Text(text, style: context.kumo.text(weight: KumoTypography.semibold)),
      ),
    );
  }
}

/// A hairline between groups of rows.
class KumoDropdownSeparator extends StatelessWidget {
  const KumoDropdownSeparator({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(child: KumoMenuSeparator());
}

/// A row that opens a nested menu: to the side on hover, tap or ArrowRight
/// in the anchored menu, and pushed in place (with a back row) in the sheet.
/// ArrowLeft and Escape close it and return focus to this row.
///
/// ```dart
/// KumoDropdownSubmenu(
///   label: 'Move to zone',
///   icon: KumoIcons.globe,
///   children: [
///     KumoDropdownItem(label: 'example.com', onPress: () => move('example.com')),
///     KumoDropdownItem(label: 'example.dev', onPress: () => move('example.dev')),
///   ],
/// )
/// ```
class KumoDropdownSubmenu extends StatefulWidget {
  const KumoDropdownSubmenu({
    super.key,
    required this.label,
    required this.children,
    this.icon,
    this.disabled = false,
    this.minWidth = 144,
  });

  /// Row text. Also identifies the submenu in the sheet, so keep it unique
  /// within its menu.
  final String label;
  final List<Widget> children;
  final IconData? icon;
  final bool disabled;
  final double minWidth;

  @override
  State<KumoDropdownSubmenu> createState() => _KumoDropdownSubmenuState();
}

class _KumoDropdownSubmenuState extends State<KumoDropdownSubmenu> {
  final FocusNode _row = FocusNode(debugLabel: 'KumoDropdownSubmenu trigger');
  final FocusNode _panel = FocusNode(
    debugLabel: 'KumoDropdownSubmenu panel',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final _MenuLevel _childLevel = _MenuLevel();
  bool _focusFirst = false;

  @override
  void dispose() {
    _row.dispose();
    _panel.dispose();
    _childLevel.dispose();
    super.dispose();
  }

  void _open(_MenuScope scope, {required bool keyboard}) {
    if (widget.disabled) return;
    _focusFirst = keyboard;
    scope.level.open(this);
  }

  void _close(_MenuScope scope) {
    final hadFocus = _panel.hasFocus;
    _childLevel.close();
    scope.level.close(this);
    if (hadFocus) _row.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _MenuScope.maybeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final caret = KumoIcon(rtl ? KumoIcons.caretLeft : KumoIcons.caretRight);
    final inset = widget.icon == null && (scope?.inset ?? false);
    if (scope == null || scope.host.sheet) {
      return _ItemShell(
        child: KumoMenuRow(
          label: widget.label,
          icon: widget.icon,
          inset: inset,
          disabled: widget.disabled,
          trailing: caret,
          onPress: widget.disabled || scope == null ? null : () => scope.host.pushSubmenu(widget.label),
        ),
      );
    }
    return ListenableBuilder(
      listenable: scope.level,
      builder: (context, _) {
        final open = scope.rootOpen && scope.level.isOpen(this);
        final row = CallbackShortcuts(
          bindings: {
            SingleActivator(rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight): () =>
                _open(scope, keyboard: true),
          },
          child: KumoMenuRow(
            label: widget.label,
            icon: widget.icon,
            inset: inset,
            disabled: widget.disabled,
            focusNode: _row,
            highlighted: open,
            expanded: open,
            trailing: caret,
            onPress: widget.disabled
                ? null
                : () => open
                      ? _close(scope)
                      : _open(scope, keyboard: FocusManager.instance.highlightMode == FocusHighlightMode.traditional),
          ),
        );
        return KumoAnchoredOverlay(
          open: open,
          side: rtl ? KumoSide.left : KumoSide.right,
          align: KumoAlign.start,
          // Kumo's submenu offsets: overlap the parent a little and cancel
          // the popup padding so the first row lines up with this one.
          sideOffset: 2,
          alignOffset: -KumoSpace.s1_5,
          preferredExtent: 160,
          tapRegionGroupId: scope.host.groupId,
          // Hover-opened submenus must not take focus from the parent menu.
          focusPopupWhenUnfocused: false,
          onDismiss: () => _close(scope),
          onClosed: _childLevel.close,
          overlayBuilder: (context, placement) => MouseRegion(
            onEnter: (_) => scope.level.keep(),
            child: Focus(
              focusNode: _panel,
              child: _MenuPanelContent(
                items: widget.children,
                host: scope.host,
                level: _childLevel,
                rootOpen: scope.rootOpen,
                minWidth: widget.minWidth,
                maxHeight: placement.maxHeight,
                focusFirst: _focusFirst,
                semanticLabel: widget.label,
                onArrowBack: () => _close(scope),
              ),
            ),
          ),
          child: _ItemShell(submenuKey: this, child: row),
        );
      },
    );
  }
}
