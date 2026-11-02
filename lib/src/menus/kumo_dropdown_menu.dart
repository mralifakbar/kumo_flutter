import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_menu_parts.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_field_box.dart' show KumoPresentation;
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

part 'kumo_dropdown_items.dart';

/// Open state and actions handed to a menu or popover trigger builder.
///
/// ```dart
/// KumoDropdownMenu(
///   triggerBuilder: (context, menu) => KumoButton(label: 'Actions', onPress: menu.toggle),
///   items: const [KumoDropdownItem(label: 'Rename')],
/// )
/// ```
@immutable
class KumoDropdownController {
  const KumoDropdownController({required this.isOpen, required this.open, required this.close, required this.toggle});

  /// Whether the menu is showing.
  final bool isOpen;
  final VoidCallback open;
  final VoidCallback close;
  final VoidCallback toggle;
}

/// Builds the trigger of a [KumoDropdownMenu] from its controller.
typedef KumoDropdownTriggerBuilder = Widget Function(BuildContext context, KumoDropdownController menu);

/// Kumo's `DropdownMenu`: a list of actions anchored to a trigger.
///
/// Items are [KumoDropdownItem], [KumoDropdownLinkItem],
/// [KumoDropdownCheckboxItem], [KumoDropdownRadioGroup] with
/// [KumoDropdownRadioItem], [KumoDropdownGroup], [KumoDropdownLabel],
/// [KumoDropdownSeparator] and [KumoDropdownSubmenu].
///
/// ```dart
/// KumoDropdownMenu(
///   triggerBuilder: (context, menu) => KumoButton(label: 'Add', icon: KumoIcons.plus, onPress: menu.toggle),
///   items: [
///     KumoDropdownItem(label: 'Worker', onPress: createWorker),
///     KumoDropdownItem(label: 'KV namespace', onPress: createNamespace),
///   ],
/// )
/// ```
///
/// * Selecting an item runs its `onPress` and closes the menu. Checkbox and
///   radio items stay open (Base UI's default) unless `closeOnPress` is set.
/// * Opens from the trigger with a scale-from-anchor spring and closes along
///   the same path. Focus moves into the menu and returns to the trigger.
/// * Keyboard: Enter, Space or ArrowDown on the trigger open it; Up and Down
///   move between items, Home and End jump; ArrowRight opens a submenu and
///   ArrowLeft or Escape closes it; Escape closes the menu.
/// * Below 768px ([KumoPresentation.auto]) the same items open in a bottom
///   sheet that follows the finger. Submenus push in place with a back row.
class KumoDropdownMenu extends StatefulWidget {
  const KumoDropdownMenu({
    super.key,
    required this.items,
    this.trigger,
    this.triggerBuilder,
    this.open,
    this.onOpenChange,
    this.side = KumoSide.bottom,
    this.align = KumoAlign.center,
    this.sideOffset = 8,
    this.alignOffset = 0,
    this.presentation = KumoPresentation.auto,
    this.disabled = false,
    this.minWidth = 144,
    this.semanticLabel,
    this.sheetTitle,
    this.backLabel,
    this.tapRegionGroupId,
    this.restoreFocus = true,
    this.onNavigateSibling,
    this.animate = true,
  }) : assert((trigger == null) != (triggerBuilder == null), 'Pass either trigger or triggerBuilder');

  /// Menu content, top to bottom.
  final List<Widget> items;

  /// Non-interactive trigger content (an avatar, a label). The menu makes it
  /// pressable. A [KumoButton] without `onPress` renders disabled, so use
  /// [triggerBuilder] for buttons.
  final Widget? trigger;

  /// Builds an interactive trigger that calls `menu.toggle`.
  final KumoDropdownTriggerBuilder? triggerBuilder;

  /// Controls the open state. Leave null to let the menu manage it.
  final bool? open;

  /// Called when the menu asks to open or close (trigger press, item
  /// selection, Escape, outside tap, sheet dismissal).
  final ValueChanged<bool>? onOpenChange;
  final KumoSide side;
  final KumoAlign align;

  /// Gap between trigger and menu. Kumo's default is 8.
  final double sideOffset;
  final double alignOffset;

  /// Anchored menu or bottom sheet. [KumoPresentation.auto] uses a sheet
  /// below 768px.
  final KumoPresentation presentation;
  final bool disabled;

  /// Kumo's `min-w-36`.
  final double minWidth;

  /// Accessible name of the menu, also used for the sheet.
  final String? semanticLabel;

  /// Heading shown at the top of the sheet presentation.
  final String? sheetTitle;

  /// Accessible name of the back row in a sheet submenu. Defaults to
  /// [KumoStrings.back].
  final String? backLabel;

  /// Taps inside other widgets of this [TapRegion] group do not close the
  /// menu. [KumoMenubar] shares one group across its menus.
  final Object? tapRegionGroupId;

  /// Return focus to whatever had it before the menu opened. [KumoMenubar]
  /// turns this off and moves focus itself.
  final bool restoreFocus;

  /// Called with -1 or +1 when Left or Right is pressed on a menu item that
  /// has no submenu to open or close (mirrored in RTL). [KumoMenubar] uses it
  /// to move to the neighboring menu.
  final ValueChanged<int>? onNavigateSibling;

  /// Scale and fade the anchored menu in and out. [KumoMenubar] turns this
  /// off while the pointer or arrow keys move between its open menus, so the
  /// panel swaps in place instead of closing and reopening.
  final bool animate;

  @override
  State<KumoDropdownMenu> createState() => _KumoDropdownMenuState();
}

class _KumoDropdownMenuState extends State<KumoDropdownMenu> implements _MenuHost {
  bool _internalOpen = false;
  bool _focusFirst = false;
  final _MenuLevel _level = _MenuLevel();
  final Object _ownGroup = Object();
  late final ValueNotifier<List<Widget>> _sheetItems = ValueNotifier(widget.items);
  bool _sheetShowing = false;
  BuildContext? _sheetContext;

  bool get _open => widget.open ?? _internalOpen;

  @override
  bool get sheet => false;

  @override
  Object get groupId => widget.tapRegionGroupId ?? _ownGroup;

  @override
  ValueChanged<int>? get onNavigateSibling => widget.onNavigateSibling;

  @override
  void close() => _setOpen(false);

  @override
  void pushSubmenu(String label) {}

  @override
  void didUpdateWidget(KumoDropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == true && widget.open == false) _level.close();
    if (widget.open == true && oldWidget.open != true) _focusFirst = _keyboardMode;
    if (_sheetShowing && !identical(widget.items, oldWidget.items)) {
      // The sheet lives in another route; update it after this build.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sheetItems.value = widget.items;
      });
    }
  }

  @override
  void dispose() {
    _level.dispose();
    _sheetItems.dispose();
    super.dispose();
  }

  static bool get _keyboardMode => FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  void _setOpen(bool value, {bool? focusFirst}) {
    if (value && widget.disabled) return;
    if (value == _open) return;
    if (value) {
      _focusFirst = focusFirst ?? _keyboardMode;
    } else {
      _level.close();
    }
    if (widget.open == null) setState(() => _internalOpen = value);
    widget.onOpenChange?.call(value);
  }

  void _syncSheet() {
    if (!mounted) return;
    final wantSheet = _open && widget.presentation.usesSheet(context);
    if (wantSheet && !_sheetShowing) {
      _sheetShowing = true;
      _sheetItems.value = widget.items;
      final strings = context.kumoStrings;
      showKumoSheet<void>(
        context: context,
        semanticLabel: widget.semanticLabel ?? widget.sheetTitle ?? strings.menu,
        builder: (sheetContext) {
          _sheetContext = sheetContext;
          return _SheetMenu(
            items: _sheetItems,
            title: widget.sheetTitle,
            backLabel: widget.backLabel ?? strings.back,
            semanticLabel: widget.semanticLabel,
            onClose: close,
          );
        },
      ).whenComplete(() {
        _sheetShowing = false;
        _sheetContext = null;
        if (mounted && _open) _setOpen(false);
      });
    } else if (!wantSheet && _sheetShowing) {
      final sheetContext = _sheetContext;
      if (sheetContext != null && sheetContext.mounted) KumoSheetScope.closeFrom(sheetContext);
    }
  }

  KumoDropdownController get _controller => KumoDropdownController(
    isOpen: _open,
    open: () => _setOpen(true),
    close: () => _setOpen(false),
    toggle: () => _setOpen(!_open),
  );

  @override
  Widget build(BuildContext context) {
    final useSheet = widget.presentation.usesSheet(context);
    if ((useSheet && _open != _sheetShowing) || (!useSheet && _sheetShowing)) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _syncSheet());
    }

    Widget trigger =
        widget.triggerBuilder?.call(context, _controller) ??
        KumoPressable(
          onPress: widget.disabled ? null : () => _setOpen(!_open),
          disabled: widget.disabled,
          expanded: _open,
          semanticLabel: widget.semanticLabel,
          borderRadius: BorderRadius.circular(KumoRadius.lg),
          child: widget.trigger,
        );
    trigger = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          if (!_open) _setOpen(true, focusFirst: true);
        },
      },
      child: trigger,
    );

    return KumoAnchoredOverlay(
      open: _open && !useSheet,
      side: widget.side,
      align: widget.align,
      sideOffset: widget.sideOffset,
      alignOffset: widget.alignOffset,
      trapFocus: true,
      restoreFocus: widget.restoreFocus,
      animate: widget.animate,
      tapRegionGroupId: groupId,
      onDismiss: close,
      onClosed: _level.close,
      overlayBuilder: (context, placement) => _MenuPanelContent(
        items: widget.items,
        host: this,
        level: _level,
        rootOpen: _open,
        maxHeight: placement.maxHeight,
        minWidth: widget.minWidth,
        focusFirst: _focusFirst,
        focusPanel: true,
        semanticLabel: widget.semanticLabel,
        onSibling: widget.onNavigateSibling,
      ),
      child: trigger,
    );
  }
}

/// What a menu item needs from the menu it is in.
abstract class _MenuHost {
  bool get sheet;
  Object get groupId;
  ValueChanged<int>? get onNavigateSibling;
  void close();
  void pushSubmenu(String label);
}

const Duration _hoverDelay = Duration(milliseconds: 100);

/// Which submenu of one menu level is open, and hover timing between rows.
class _MenuLevel extends ChangeNotifier {
  Object? _openKey;
  Timer? _timer;
  bool _disposed = false;

  bool isOpen(Object key) => _openKey == key;

  void open(Object key) {
    _cancel();
    if (_openKey == key) return;
    _openKey = key;
    _notify();
  }

  void close([Object? key]) {
    _cancel();
    if (key != null && _openKey != key) return;
    if (_openKey == null) return;
    _openKey = null;
    _notify();
  }

  /// The pointer rests on a submenu trigger: open it after a short delay so a
  /// pointer passing over it on the way elsewhere does not flash it open.
  void hoverSubmenu(Object key) {
    _cancel();
    if (_openKey == key) return;
    _timer = Timer(_hoverDelay, () => open(key));
  }

  /// The pointer rests on a plain row: close the open submenu, a little later
  /// than a submenu opens so a diagonal move toward it survives.
  void hoverItem() {
    _cancel();
    if (_openKey == null) return;
    _timer = Timer(_hoverDelay * 2, close);
  }

  /// The pointer reached the open submenu.
  void keep() => _cancel();

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel();
    super.dispose();
  }
}

class _MenuScope extends InheritedWidget {
  const _MenuScope({
    required this.host,
    required this.level,
    required this.rootOpen,
    required this.inset,
    required super.child,
  });

  final _MenuHost host;
  final _MenuLevel level;
  final bool rootOpen;

  /// Some row at this level has an icon, so rows without one leave its room.
  final bool inset;

  static _MenuScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_MenuScope>();

  @override
  bool updateShouldNotify(_MenuScope old) =>
      host != old.host || level != old.level || rootOpen != old.rootOpen || inset != old.inset;
}

bool _hasIcons(List<Widget> items) {
  for (final w in items) {
    final hasIcon = switch (w) {
      KumoDropdownItem(:final icon) => icon != null,
      KumoDropdownLinkItem(:final icon) => icon != null,
      KumoDropdownRadioItem(:final icon) => icon != null,
      KumoDropdownSubmenu(:final icon) => icon != null,
      KumoDropdownGroup(:final children) => _hasIcons(children),
      KumoDropdownRadioGroup(:final children) => _hasIcons(children),
      _ => false,
    };
    if (hasIcon) return true;
  }
  return false;
}

KumoDropdownSubmenu? _findSubmenu(List<Widget> items, String label) {
  for (final w in items) {
    final found = switch (w) {
      KumoDropdownSubmenu() when w.label == label => w,
      KumoDropdownGroup(:final children) => _findSubmenu(children, label),
      KumoDropdownRadioGroup(:final children) => _findSubmenu(children, label),
      _ => null,
    };
    if (found != null) return found;
  }
  return null;
}

/// One level of an anchored menu: the panel, its keyboard handling and the
/// scope its items read.
class _MenuPanelContent extends StatefulWidget {
  const _MenuPanelContent({
    required this.items,
    required this.host,
    required this.level,
    required this.rootOpen,
    required this.minWidth,
    this.maxHeight,
    this.focusFirst = false,
    this.focusPanel = false,
    this.semanticLabel,
    this.onSibling,
    this.onArrowBack,
  });

  final List<Widget> items;
  final _MenuHost host;
  final _MenuLevel level;
  final bool rootOpen;
  final double minWidth;
  final double? maxHeight;

  /// Opened from the keyboard: focus the first item.
  final bool focusFirst;

  /// Opened by pointer: focus the panel so arrow keys reach it.
  final bool focusPanel;
  final String? semanticLabel;
  final ValueChanged<int>? onSibling;

  /// Submenus: Left (Right in RTL) closes this level.
  final VoidCallback? onArrowBack;

  @override
  State<_MenuPanelContent> createState() => _MenuPanelContentState();
}

class _MenuPanelContentState extends State<_MenuPanelContent> {
  final FocusNode _panel = FocusNode(debugLabel: 'KumoDropdownMenu panel', skipTraversal: true);

  @override
  void initState() {
    super.initState();
    if (widget.focusFirst || widget.focusPanel) {
      // Runs after the focus trap has claimed focus for its scope.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.focusFirst) {
          _focusEdge(last: false);
        } else {
          _panel.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _panel.dispose();
    super.dispose();
  }

  void _focusEdge({required bool last}) {
    final nodes = _panel.traversalDescendants.where((n) => n.canRequestFocus && !n.skipTraversal).toList();
    if (nodes.isEmpty) return;
    (last ? nodes.last : nodes.first).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = widget.onArrowBack;
    final sibling = widget.onSibling;
    return CallbackShortcuts(
      bindings: {
        // Reached only while the panel itself has focus; focused rows handle
        // Up and Down in KumoMenuKeyboard first.
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _focusEdge(last: false),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _focusEdge(last: true),
        if (back != null)
          SingleActivator(rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft): back
        else if (sibling != null) ...{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => sibling(rtl ? 1 : -1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => sibling(rtl ? -1 : 1),
        },
      },
      child: Focus(
        focusNode: _panel,
        child: DefaultTextStyle(
          style: context.kumo.text(),
          child: _MenuScope(
            host: widget.host,
            level: widget.level,
            rootOpen: widget.rootOpen,
            inset: _hasIcons(widget.items),
            child: KumoMenuPanel(
              minWidth: widget.minWidth,
              maxHeight: widget.maxHeight,
              semanticLabel: widget.semanticLabel,
              children: widget.items,
            ),
          ),
        ),
      ),
    );
  }
}

/// The sheet presentation: the same items in a bottom sheet, with submenus
/// pushed in place.
class _SheetMenu extends StatefulWidget {
  const _SheetMenu({
    required this.items,
    required this.onClose,
    required this.backLabel,
    this.title,
    this.semanticLabel,
  });

  final ValueListenable<List<Widget>> items;
  final VoidCallback onClose;
  final String backLabel;
  final String? title;
  final String? semanticLabel;

  @override
  State<_SheetMenu> createState() => _SheetMenuState();
}

class _SheetMenuState extends State<_SheetMenu> implements _MenuHost {
  // Submenus are found again by label on every build so the sheet always
  // shows the latest items (a radio that was just picked).
  final List<String> _path = [];
  final _MenuLevel _level = _MenuLevel();
  bool _forward = true;

  @override
  bool get sheet => true;

  @override
  Object get groupId => this;

  @override
  ValueChanged<int>? get onNavigateSibling => null;

  @override
  void close() => widget.onClose();

  @override
  void pushSubmenu(String label) => setState(() {
    _forward = true;
    _path.add(label);
  });

  void _pop() => setState(() {
    _forward = false;
    if (_path.isNotEmpty) _path.removeLast();
  });

  @override
  void dispose() {
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ValueListenableBuilder<List<Widget>>(
      valueListenable: widget.items,
      builder: (context, items, _) {
        var current = items;
        final resolved = <String>[];
        for (final label in _path) {
          final sub = _findSubmenu(current, label);
          if (sub == null) break;
          current = sub.children;
          resolved.add(label);
        }
        final children = <Widget>[
          if (resolved.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: KumoMenuRow(
                label: resolved.last,
                icon: rtl ? KumoIcons.caretRight : KumoIcons.caretLeft,
                semanticLabel: widget.backLabel,
                onPress: _pop,
              ),
            ),
            const KumoMenuSeparator(),
          ] else if (widget.title != null)
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(KumoSpace.s2, KumoSpace.s1, KumoSpace.s2, KumoSpace.s2),
                child: Text(
                  widget.title!,
                  style: kumo.text(size: KumoTextSize.lg, weight: KumoTypography.semibold),
                ),
              ),
            ),
          ...current,
        ];
        // Sheet routes sit outside the page's DefaultTextStyle; rows and
        // icons take their color from it.
        final list = DefaultTextStyle(
          style: kumo.text(),
          child: _MenuScope(
            host: this,
            level: _level,
            rootOpen: true,
            inset: _hasIcons(current),
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label: widget.semanticLabel,
              child: KumoMenuKeyboard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        );
        final reduce = KumoMotion.reduceMotion(context);
        final direction = (_forward ? 1.0 : -1.0) * (rtl ? -1 : 1);
        final duration = KumoMotion.duration(context, KumoDurations.moderate);
        // The sheet grows or shrinks to the next level with the same timing
        // as the slide, instead of jumping when the old level is removed.
        final switcher = AnimatedSwitcher(
          duration: duration,
          switchInCurve: KumoCurves.enter,
          switchOutCurve: KumoCurves.exit,
          layoutBuilder: (current, previous) =>
              Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
          transitionBuilder: (child, animation) {
            final fade = FadeTransition(opacity: animation, child: child);
            if (reduce) return fade;
            final incoming = child.key == ValueKey(resolved.join('/'));
            final dx = 0.06 * direction * (incoming ? 1 : -1);
            return SlideTransition(
              position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
              child: fade,
            );
          },
          child: KeyedSubtree(
            key: ValueKey(resolved.join('/')),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1),
              child: list,
            ),
          ),
        );
        // Reduced motion swaps levels at once. AnimatedSize must not get a
        // zero duration: it would restart itself during its own layout.
        if (reduce) return switcher;
        return AnimatedSize(
          duration: duration,
          curve: KumoCurves.standard,
          alignment: Alignment.topCenter,
          child: switcher,
        );
      },
    );
  }
}

/// A caret for a menu trigger that turns over while its menu is open, with
/// the popup's timing, so the trigger shows which way the menu went. Reverses
/// from wherever it is when the menu closes mid-flight.
///
/// ```dart
/// KumoDropdownMenu(
///   triggerBuilder: (context, menu) => KumoButton(
///     onPress: menu.toggle,
///     child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
///       const Text('image-resizer'),
///       KumoDropdownCaret(open: menu.isOpen),
///     ]),
///   ),
///   items: const [KumoDropdownItem(label: 'Rename')],
/// )
/// ```
class KumoDropdownCaret extends StatelessWidget {
  const KumoDropdownCaret({super.key, required this.open, this.size = 16, this.icon = KumoIcons.caretDown});

  /// The menu is showing: the caret points up.
  final bool open;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: open ? 0.5 : 0,
      duration: KumoMotion.duration(context, KumoDurations.quick),
      curve: KumoCurves.standard,
      child: KumoIcon(icon, size: size),
    );
  }
}

bool _isTouch(PointerEvent event) => event.kind == PointerDeviceKind.touch;
