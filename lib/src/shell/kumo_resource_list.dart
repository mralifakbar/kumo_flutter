import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Meaning of a [KumoResourceListStatus]. Each tone pairs a color with an
/// icon, so status never relies on color alone.
enum KumoResourceListStatusTone {
  /// Gray dot: paused, draft, unknown.
  neutral,

  /// Green check: active, healthy, deployed.
  success,

  /// Amber triangle: degraded, pending, expiring.
  warning,

  /// Red circle: failed, suspended, unreachable.
  danger,

  /// Blue info mark: provisioning, migrating.
  info,
}

/// A status label on a [KumoResourceListItem].
///
/// ```dart
/// const KumoResourceListStatus(label: 'Active', tone: KumoResourceListStatusTone.success)
/// ```
@immutable
class KumoResourceListStatus {
  const KumoResourceListStatus({required this.label, this.tone = KumoResourceListStatusTone.neutral, this.icon});

  final String label;
  final KumoResourceListStatusTone tone;

  /// Replaces the tone's icon.
  final IconData? icon;
}

/// The empty state of a [KumoResourceList]: what is missing and what to do.
///
/// ```dart
/// KumoResourceListEmpty(
///   title: 'No KV namespaces yet',
///   description: 'Create a namespace to store key-value data close to your users.',
///   action: KumoButton(label: 'Create namespace', variant: KumoButtonVariant.primary, onPress: () {}),
/// )
/// ```
class KumoResourceListEmpty extends StatelessWidget {
  const KumoResourceListEmpty({
    super.key,
    this.title = 'No resources yet',
    this.description,
    this.icon = KumoIcons.folder,
    this.action,
  });

  final String title;
  final String? description;
  final IconData icon;

  /// The next step, usually a primary create button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s6, vertical: KumoSpace.s10),
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(c.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: KumoSpace.s2,
        children: [
          KumoIcon(icon, size: 24, color: KumoColor.textSubtle),
          Semantics(
            header: true,
            child: Text(title, textAlign: TextAlign.center, style: kumo.heading()),
          ),
          if (description != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(description!, textAlign: TextAlign.center, style: kumo.text(color: KumoColor.textSubtle)),
            ),
          if (action != null) Padding(padding: const EdgeInsets.only(top: KumoSpace.s2), child: action),
        ],
      ),
    );
  }
}

/// One resource in a [KumoResourceList]: a name, metadata, a status and
/// actions, on a card. Pressing the card opens the resource.
///
/// Below 480px the status and actions move under the name.
///
/// ```dart
/// KumoResourceListItem(
///   title: 'production-kv',
///   metadata: const ['Created 2 days ago', '1,204 keys'],
///   status: const KumoResourceListStatus(label: 'Active', tone: KumoResourceListStatusTone.success),
///   actions: [KumoButton(label: 'View', size: KumoButtonSize.sm, onPress: () {})],
///   onPress: () {},
/// )
/// ```
class KumoResourceListItem extends StatelessWidget {
  const KumoResourceListItem({
    super.key,
    required this.title,
    this.metadata = const [],
    this.status,
    this.actions = const [],
    this.leading,
    this.onPress,
    this.semanticLabel,
    this.mono = false,
  });

  /// Resource name. Truncates to one line.
  final String title;

  /// Short facts shown under the name, joined with a middle dot.
  final List<String> metadata;
  final KumoResourceListStatus? status;

  /// Buttons for the resource. They stay separately reachable from the card.
  final List<Widget> actions;

  /// Icon or avatar before the name.
  final Widget? leading;

  /// Opens the resource.
  final VoidCallback? onPress;

  /// Accessible name of the card. Defaults to the title.
  final String? semanticLabel;

  /// Show the name in monospace (IDs, hostnames).
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final radius = BorderRadius.circular(KumoRadius.lg);

    Widget card(bool hovered) => LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 480;
          final name = Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: mono ? kumo.code(large: true, weight: KumoTypography.medium) : kumo.heading(),
          );
          final meta = metadata.isEmpty
              ? null
              : Text(metadata.join('  ·  '), style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle));
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: KumoSpace.s1,
            children: [name, ?meta],
          );
          final statusPill = status == null ? null : _StatusPill(status: status!);
          final actionRow = actions.isEmpty
              ? null
              : Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: actions);
          final head = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: KumoSpace.s3,
            children: [
              ?leading,
              Expanded(child: info),
              if (!narrow) ?statusPill,
              if (!narrow) ?actionRow,
            ],
          );
          final Widget body = narrow && (statusPill != null || actionRow != null)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: KumoSpace.s3,
                  children: [
                    head,
                    Wrap(
                      spacing: KumoSpace.s2,
                      runSpacing: KumoSpace.s2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [?statusPill, ?actionRow],
                    ),
                  ],
                )
              : head;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s5, vertical: KumoSpace.s4),
            decoration: BoxDecoration(
              color: hovered ? c.tint : c.base,
              borderRadius: radius,
              border: KumoRing.border(c.line),
              boxShadow: KumoShadow.xs.boxShadows,
            ),
            child: body,
          );
        });

    if (onPress == null) {
      return Semantics(container: true, label: semanticLabel, child: card(false));
    }
    return KumoPressable(
      onPress: onPress,
      borderRadius: radius,
      semanticLabel: semanticLabel ?? title,
      mergeChildSemantics: false,
      minTapTargetSize: 0,
      builder: (context, state) => card(state.active),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final KumoResourceListStatus status;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final (Color bg, KumoColor fg, IconData icon) = switch (status.tone) {
      KumoResourceListStatusTone.neutral => (c.tint, KumoColor.textSubtle, KumoIcons.circle),
      KumoResourceListStatusTone.success => (c.successTint, KumoColor.textSuccess, KumoIcons.checkCircle),
      KumoResourceListStatusTone.warning => (c.warningTint, KumoColor.textWarning, KumoIcons.warning),
      KumoResourceListStatusTone.danger => (c.dangerTint, KumoColor.textDanger, KumoIcons.warningCircle),
      KumoResourceListStatusTone.info => (c.infoTint, KumoColor.textInfo, KumoIcons.info),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s0_5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(KumoRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: KumoSpace.s1,
        children: [
          KumoIcon(status.icon ?? icon, size: 12, color: fg),
          Text(status.label, style: kumo.text(size: KumoTextSize.xs, weight: KumoTypography.medium, color: fg)),
        ],
      ),
    );
  }
}

/// Kumo's `ResourceListPage` block: the page for a list of resources (Workers,
/// buckets, namespaces). A title with an icon and description, the list, and
/// an aside for usage notes and links.
///
/// The list shows [KumoResourceListItem] cards, with built-in loading, error
/// and empty states. From 1280px the aside sits beside the list; narrower,
/// [usage] goes above it and [additionalContent] below.
///
/// ```dart
/// KumoResourceList(
///   title: 'KV namespaces',
///   description: 'Store key-value data globally with low-latency access.',
///   icon: KumoIcons.database,
///   loading: loading,
///   error: error,
///   onRetry: reload,
///   empty: const KumoResourceListEmpty(title: 'No KV namespaces yet'),
///   children: [
///     for (final ns in namespaces) KumoResourceListItem(title: ns, onPress: () {}),
///   ],
/// )
/// ```
class KumoResourceList extends StatelessWidget {
  const KumoResourceList({
    super.key,
    this.title,
    this.description,
    this.icon,
    this.iconWidget,
    this.actions = const [],
    this.usage,
    this.additionalContent,
    this.children = const [],
    this.loading = false,
    this.loadingLabel,
    this.error,
    this.onRetry,
    this.retryLabel,
    this.empty,
    this.scrollable = true,
    this.controller,
  });

  /// Page title: 30px semibold, the level 1 heading.
  final String? title;

  /// Shown from 768px up, as in Kumo.
  final String? description;
  final IconData? icon;

  /// Widget in place of [icon].
  final Widget? iconWidget;

  /// Page actions after the title, such as "Create namespace". They wrap
  /// below the title on narrow screens.
  final List<Widget> actions;

  /// Aside content: a quick start or usage snippet.
  final Widget? usage;

  /// More aside content: links, limits, related docs.
  final Widget? additionalContent;

  /// The resources, usually [KumoResourceListItem]s. Give each a [Key] (the
  /// resource ID) and cards that are added or removed grow in or collapse out
  /// while their neighbours slide.
  final List<Widget> children;

  /// Shows placeholder cards in place of [children].
  final bool loading;

  /// Announced while loading. Defaults to [KumoStrings.loading].
  final String? loadingLabel;

  /// Shows an error panel in place of the list. Say what failed.
  final String? error;
  final VoidCallback? onRetry;

  /// Label of the retry button. Defaults to [KumoStrings.retry].
  final String? retryLabel;

  /// Shown when [children] is empty and nothing is loading or failing.
  final Widget? empty;

  /// Wrap the page in a vertical scroll view.
  final bool scrollable;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    return ColoredBox(
      color: c.overlay,
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final md = w >= KumoBreakpoints.md;
        final lg = w >= KumoBreakpoints.lg;
        final xl = w >= KumoBreakpoints.xl;
        final padding = lg
            ? const EdgeInsets.symmetric(horizontal: KumoSpace.s10, vertical: 36)
            : EdgeInsets.all(md ? KumoSpace.s8 : KumoSpace.s6);

        final titleRow = Row(
          spacing: KumoSpace.s1_5,
          children: [
            ?(iconWidget ?? (icon == null ? null : KumoIcon(icon!, size: 32, color: KumoColor.textSubtle))),
            if (title != null)
              Flexible(
                child: Semantics(
                  header: true,
                  headingLevel: 1,
                  child: Text(title!, style: kumo.heading(size: KumoHeadingSize.h1)),
                ),
              ),
          ],
        );
        Widget heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1_5,
          children: [
            titleRow,
            if (description != null && md)
              Text(description!, style: kumo.text(size: KumoTextSize.lg, color: KumoColor.textSubtle)),
          ],
        );
        if (actions.isNotEmpty) {
          final bar = Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: actions);
          heading = md
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: KumoSpace.s4,
                  children: [Expanded(child: heading), bar],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: KumoSpace.s4,
                  children: [heading, bar],
                );
        }

        final list = _content(context);
        final hasAside = usage != null || additionalContent != null;
        final Widget body;
        if (xl && hasAside) {
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s8,
            children: [
              Expanded(child: list),
              SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?usage,
                    if (additionalContent != null)
                      Padding(
                        padding: EdgeInsets.only(top: usage != null ? KumoSpace.s6 : 0),
                        child: additionalContent,
                      ),
                  ],
                ),
              ),
            ],
          );
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s6,
            children: [?usage, list, ?additionalContent],
          );
        }

        Widget page = Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: xl ? KumoSpace.s6 : KumoSpace.s4,
            children: [heading, body],
          ),
        );
        page = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: page),
        );
        if (!scrollable) return page;
        return SingleChildScrollView(controller: controller, child: page);
      }),
    );
  }

  Widget _content(BuildContext context) {
    final strings = context.kumoStrings;
    final (String state, Widget child) = _state(context, strings);
    // Loading, error, empty and the list cross-fade, and the space they take
    // eases to its new height, so the page never flashes between states.
    Widget switcher = AnimatedSwitcher(
      duration: KumoMotion.duration(context, KumoDurations.quick),
      switchInCurve: KumoCurves.enter,
      switchOutCurve: KumoCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [
          // The outgoing state keeps its own height and is clipped to the
          // incoming one's while it fades.
          for (final p in previous)
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: IgnorePointer(child: ExcludeSemantics(child: p)),
            ),
          ?current,
        ],
      ),
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
    if (!KumoMotion.reduceMotion(context)) {
      switcher = AnimatedSize(
        duration: KumoDurations.moderate,
        curve: KumoCurves.standard,
        alignment: AlignmentDirectional.topStart,
        child: switcher,
      );
    }
    return switcher;
  }

  (String, Widget) _state(BuildContext context, KumoStrings strings) {
    if (loading) {
      return ('loading', Semantics(
        label: loadingLabel ?? strings.loading,
        liveRegion: true,
        container: true,
        child: const ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s4,
            children: [_PlaceholderCard(widthFactor: 0.4), _PlaceholderCard(widthFactor: 0.3), _PlaceholderCard(widthFactor: 0.5)],
          ),
        ),
      ));
    }
    if (error != null) {
      return ('error', _ErrorPanel(message: error!, onRetry: onRetry, retryLabel: retryLabel ?? strings.retry));
    }
    if (children.isEmpty) return ('empty', empty ?? const KumoResourceListEmpty());
    return ('list', _AnimatedItems(spacing: KumoSpace.s4, children: children));
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    Widget bar(double factor, double height) => FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: factor,
          child: Container(
            height: height,
            decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(KumoRadius.full)),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s5, vertical: KumoSpace.s5),
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s3,
        children: [bar(widthFactor, 12), bar(widthFactor * 1.4, 8)],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry, required this.retryLabel});

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s3),
        decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(KumoRadius.lg)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            const SizedBox(
              height: 21,
              child: Center(child: KumoIcon(KumoIcons.warningCircle, color: KumoColor.textDanger)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KumoSpace.s3,
                children: [
                  Text(message, style: kumo.text(color: KumoColor.textDanger)),
                  if (onRetry != null)
                    KumoButton(
                      label: retryLabel,
                      icon: KumoIcons.arrowClockwise,
                      size: KumoButtonSize.sm,
                      onPress: onRetry,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A column of cards that grow in and collapse out as keyed children are
/// added and removed. Each card's gap belongs to it while it animates, so
/// the neighbours slide without a jump. Without keys on every child it is a
/// plain column.
class _AnimatedItems extends StatefulWidget {
  const _AnimatedItems({required this.children, required this.spacing});

  final List<Widget> children;
  final double spacing;

  @override
  State<_AnimatedItems> createState() => _AnimatedItemsState();
}

class _Item {
  _Item(this.key, this.widget, this.controller)
      : curved = CurvedAnimation(parent: controller, curve: KumoCurves.standard);

  final Key key;
  Widget widget;
  final AnimationController controller;
  final CurvedAnimation curved;
  bool leaving = false;

  void dispose() {
    curved.dispose();
    controller.dispose();
  }

  /// Fully shown and not on its way out.
  bool get settled => !leaving && controller.value == 1 && !controller.isAnimating;
}

class _AnimatedItemsState extends State<_AnimatedItems> with TickerProviderStateMixin {
  List<_Item> _items = [];

  static bool _keyed(List<Widget> children) => children.every((c) => c.key != null) &&
      children.map((c) => c.key).toSet().length == children.length;

  @override
  void initState() {
    super.initState();
    if (_keyed(widget.children)) {
      _items = [for (final c in widget.children) _item(c, shown: true)];
    }
  }

  _Item _item(Widget child, {required bool shown}) {
    final controller = AnimationController(vsync: this, duration: KumoDurations.moderate, value: shown ? 1 : 0);
    final item = _Item(child.key!, child, controller);
    controller.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.dismissed && item.leaving) {
        setState(() => _items.remove(item));
        item.dispose();
      } else if (status == AnimationStatus.completed) {
        // Settled cards take over the gaps animating ones were carrying.
        setState(() {});
      }
    });
    return item;
  }

  @override
  void didUpdateWidget(_AnimatedItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_keyed(widget.children)) {
      for (final item in _items) {
        item.dispose();
      }
      _items = [];
      return;
    }
    final reduce = KumoMotion.reduceMotion(context);
    final byKey = {for (final item in _items) item.key: item};
    final incoming = {for (final c in widget.children) c.key!: c};
    final next = <_Item>[];
    final placed = <Key>{};
    var i = 0;

    void place(Widget child) {
      final existing = byKey[child.key!];
      final _Item item;
      if (existing != null) {
        item = existing..widget = child;
        if (item.leaving) {
          // Back before it finished leaving: turn around from where it is.
          item.leaving = false;
          reduce ? item.controller.value = 1 : item.controller.forward();
        }
      } else {
        item = _item(child, shown: reduce || _items.isEmpty);
        if (!reduce && _items.isNotEmpty) item.controller.forward();
      }
      next.add(item);
      placed.add(child.key!);
    }

    for (final old in _items) {
      if (!incoming.containsKey(old.key)) {
        // Removed: stays where it was while it collapses.
        if (!old.leaving) {
          old.leaving = true;
          if (reduce) {
            old.dispose();
            continue;
          }
          old.controller.reverse();
        }
        next.add(old);
        continue;
      }
      if (placed.contains(old.key)) continue;
      while (i < widget.children.length) {
        final child = widget.children[i++];
        if (placed.contains(child.key!)) continue;
        place(child);
        if (child.key == old.key) break;
      }
    }
    while (i < widget.children.length) {
      final child = widget.children[i++];
      if (!placed.contains(child.key!)) place(child);
    }
    _items = next;
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_keyed(widget.children)) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: widget.spacing, children: widget.children);
    }
    final items = _items;
    final rows = <Widget>[];
    for (var n = 0; n < items.length; n++) {
      final item = items[n];
      final settledBefore = items.take(n).any((e) => e.settled);
      final EdgeInsets gap;
      if (item.settled || settledBefore) {
        gap = EdgeInsets.only(top: settledBefore ? widget.spacing : 0);
      } else if (items.skip(n + 1).any((e) => e.settled)) {
        gap = EdgeInsets.only(bottom: widget.spacing);
      } else {
        gap = EdgeInsets.only(top: n > 0 ? widget.spacing : 0);
      }
      final curved = item.curved;
      rows.add(
        KeyedSubtree(
          key: item.key,
          child: IgnorePointer(
            ignoring: item.leaving,
            child: ExcludeSemantics(
              excluding: item.leaving,
              child: SizeTransition(
                sizeFactor: curved,
                axisAlignment: -1,
                child: FadeTransition(
                  opacity: curved,
                  child: Padding(padding: gap, child: item.widget),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

