import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../feedback/kumo_swap.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../system/kumo_size_reveal.dart';

/// Outcome of a [KumoTimelineItem]. Each status has its own icon shape, so
/// it never relies on color alone.
enum KumoTimelineStatus {
  /// A plain event: a dot.
  neutral(KumoIcons.circleFill, KumoColor.textSubtle, KumoColor.fill),

  /// Finished well: a check on green.
  success(KumoIcons.check, KumoColor.textSuccess, KumoColor.successTint),

  /// Needs attention: a warning triangle on amber.
  warning(KumoIcons.warning, KumoColor.textWarning, KumoColor.warningTint),

  /// Failed: a cross on red.
  danger(KumoIcons.x, KumoColor.textDanger, KumoColor.dangerTint),

  /// Informational: an "i" on blue.
  info(KumoIcons.info, KumoColor.textInfo, KumoColor.infoTint),

  /// Running now: an hourglass with a brand ring. Static; nothing spins.
  active(KumoIcons.hourglassMedium, KumoColor.textLink, KumoColor.base);

  const KumoTimelineStatus(this.icon, this.foreground, this.background);
  final IconData icon;
  final KumoColor foreground;
  final KumoColor background;
}

/// One event in a [KumoTimeline].
///
/// ```dart
/// const KumoTimelineItem(
///   title: 'Deployed to production',
///   time: '2 min ago',
///   description: 'Version 8f2c1a0 of image-resizer',
///   status: KumoTimelineStatus.success,
///   statusLabel: 'Succeeded',
/// )
/// ```
@immutable
class KumoTimelineItem {
  const KumoTimelineItem({
    required this.title,
    this.time,
    this.description,
    this.status = KumoTimelineStatus.neutral,
    this.statusLabel,
    this.icon,
    this.content,
    this.trailing,
    this.onPress,
    this.semanticLabel,
    this.id,
  });

  /// Stable identity of the event. With ids, an event added after the
  /// timeline first shows (a new deployment at the top) slides open and
  /// fades in, and events keep their place as the list grows.
  final Object? id;

  final String title;

  /// When it happened, already formatted ("2 min ago", "Mar 4, 14:02").
  final String? time;
  final String? description;
  final KumoTimelineStatus status;

  /// The status in words ("Failed"), read by screen readers with the item.
  final String? statusLabel;

  /// Replaces the status icon in the marker.
  final IconData? icon;

  /// Extra content under the description (a commit, a log excerpt).
  final Widget? content;

  /// At the end of the title row (a button, a badge).
  final Widget? trailing;

  /// Makes the item pressable (open the deployment).
  final VoidCallback? onPress;

  /// Overrides what screen readers read for the item.
  final String? semanticLabel;
}

/// A vertical list of events, newest first by convention: deployment
/// history, audit logs, the steps of a rollout.
///
/// ```dart
/// KumoTimeline(items: [
///   KumoTimelineItem(title: 'Deploying', time: 'Now', status: KumoTimelineStatus.active, statusLabel: 'In progress'),
///   KumoTimelineItem(title: 'Build finished', time: '1 min ago', status: KumoTimelineStatus.success, statusLabel: 'Succeeded'),
/// ])
/// ```
///
/// Each item is a 24px status marker on a hairline rail, a medium-weight
/// title with its time at the end, and an optional description. Statuses
/// pair a tint with a distinct icon; add [KumoTimelineItem.statusLabel] so
/// the status is read aloud too. For an empty history, show a message in
/// its place: the timeline renders nothing for an empty [items].
class KumoTimeline extends StatefulWidget {
  const KumoTimeline({super.key, required this.items, this.semanticLabel});

  final List<KumoTimelineItem> items;

  /// Names the list for screen readers ("Deployment history").
  final String? semanticLabel;

  @override
  State<KumoTimeline> createState() => _KumoTimelineState();
}

class _KumoTimelineState extends State<KumoTimeline> {
  static const double _marker = 24;

  /// False during the first build: events already there do not animate in.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _shown = true);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineEntry(
              key: items[i].id == null ? null : ValueKey<Object>(items[i].id!),
              animateIn: _shown && items[i].id != null,
              child: _item(context, items[i], last: i == items.length - 1),
            ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, KumoTimelineItem item, {required bool last}) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final status = item.status;
    final glyph = item.icon ?? status.icon;

    // A status change (running to succeeded) eases the marker's tint and
    // cross-fades its icon instead of flashing.
    final duration = KumoMotion.duration(context, KumoDurations.quick);
    final Widget marker = AnimatedContainer(
      duration: duration,
      curve: KumoCurves.standard,
      width: _marker,
      height: _marker,
      decoration: BoxDecoration(
        color: kumo.color(status.background),
        shape: BoxShape.circle,
        border: Border.all(
          color: status == KumoTimelineStatus.active ? c.brand : c.brand.withValues(alpha: 0),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: KumoSwap(
        duration: KumoDurations.quick,
        child: KumoIcon(
          glyph,
          key: ValueKey((glyph, status)),
          size: status == KumoTimelineStatus.neutral && item.icon == null ? 8 : 14,
          color: status.foreground,
          semanticLabel: item.statusLabel,
        ),
      ),
    );

    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: KumoSpace.s2,
      children: [
        Expanded(
          child: Text(item.title, style: kumo.text(weight: KumoTypography.medium)),
        ),
        if (item.time != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              item.time!,
              style: kumo
                  .text(size: KumoTextSize.xs, color: KumoColor.textSubtle)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ?item.trailing,
      ],
    );

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleRow,
        if (item.description != null)
          Padding(
            padding: const EdgeInsets.only(top: KumoSpace.s0_5),
            child: Text(
              item.description!,
              style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
            ),
          ),
        if (item.content != null)
          Padding(
            padding: const EdgeInsets.only(top: KumoSpace.s2),
            child: item.content,
          ),
      ],
    );

    // Title line (21px) centered on the 24px marker.
    body = Padding(padding: const EdgeInsets.only(top: 1.5), child: body);
    if (item.onPress != null) {
      final content = body;
      body = KumoPressable(
        onPress: item.onPress,
        semanticLabel: item.semanticLabel,
        scaleOnPress: false,
        borderRadius: BorderRadius.circular(KumoRadius.md),
        builder: (context, state) => Container(
          decoration: BoxDecoration(
            color: state.active ? c.tint : null,
            borderRadius: BorderRadius.circular(KumoRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2),
          child: content,
        ),
      );
    }

    final Widget row = Stack(
      children: [
        Padding(
          // A pressable body pads its own 8px so its hover tint has room.
          padding: EdgeInsetsDirectional.only(
            start: _marker + (item.onPress != null ? KumoSpace.s1 : KumoSpace.s3),
            bottom: last ? 0 : KumoSpace.s6,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _marker),
            child: body,
          ),
        ),
        if (!last)
          PositionedDirectional(
            start: _marker / 2 - 0.5,
            top: _marker + KumoSpace.s1,
            bottom: KumoSpace.s1,
            width: 1,
            child: ColoredBox(color: c.line),
          ),
        PositionedDirectional(start: 0, top: 0, child: marker),
      ],
    );

    if (item.onPress != null) return row;
    return MergeSemantics(
      child: Semantics(label: item.semanticLabel, child: row),
    );
  }
}

/// Slides a newly added event open and fades it in, so the events below
/// move down instead of jumping. Reduced motion shows it at once.
class _TimelineEntry extends StatefulWidget {
  const _TimelineEntry({super.key, required this.animateIn, required this.child});

  final bool animateIn;
  final Widget child;

  @override
  State<_TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends State<_TimelineEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final CurvedAnimation _curve;

  /// Fixed for the entry's life, so finishing the entrance never rebuilds
  /// the event's content from scratch.
  late final bool _wrap;

  @override
  void initState() {
    super.initState();
    _wrap = widget.animateIn;
    _enter = AnimationController(vsync: this, duration: KumoDurations.moderate, value: widget.animateIn ? 0 : 1);
    _curve = CurvedAnimation(parent: _enter, curve: KumoCurves.standard);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.isDismissed) {
      if (KumoMotion.reduceMotion(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_wrap) return widget.child;
    return KumoSizeReveal(
      sizeFactor: _curve,
      child: FadeTransition(opacity: _curve, child: widget.child),
    );
  }
}
