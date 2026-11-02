import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';

/// Wraps a horizontal scroll view and fades its start or end edge while
/// content is hidden past that edge, so a cut-off table or long code line
/// reads as "scrolls sideways" on phones where no scrollbar is visible.
/// A thin scrollbar shows while scrolling. Not exported.
class DataScrollFade extends StatefulWidget {
  const DataScrollFade({
    super.key,
    required this.controller,
    required this.color,
    required this.child,
    this.width = KumoSpace.s6,
    this.top = 0,
  });

  final ScrollController controller;

  /// The surface behind the content; the fade blends into it.
  final Color color;

  /// A horizontal scroll view driven by [controller].
  final Widget child;

  /// Width of the fade (24px, the width of Kumo's sticky-column fade).
  final double width;

  /// Distance from the top where the fade starts (below a header row).
  final double top;

  @override
  State<DataScrollFade> createState() => _DataScrollFadeState();
}

class _DataScrollFadeState extends State<DataScrollFade> {
  bool _before = false;
  bool _after = false;

  bool _onMetrics(ScrollMetrics m) {
    if (m.axis != Axis.horizontal) return false;
    final before = m.extentBefore > 0.5;
    final after = m.extentAfter > 0.5;
    if (before == _before && after == _after) return false;
    void apply() {
      if (!mounted) return;
      setState(() {
        _before = before;
        _after = after;
      });
    }

    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => apply());
      binding.scheduleFrame();
    } else {
      apply();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final transparent = widget.color.withValues(alpha: 0);
    Widget fade(bool start) => PositionedDirectional(
      start: start ? 0 : null,
      end: start ? null : 0,
      top: widget.top,
      bottom: 0,
      width: widget.width,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: start ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
              end: start ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              colors: [widget.color, transparent],
            ),
          ),
        ),
      ),
    );
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
        child: Stack(
          children: [
            RawScrollbar(
              controller: widget.controller,
              thickness: 4,
              radius: const Radius.circular(KumoRadius.full),
              thumbColor: context.kumo.colors.textSubtle.withValues(alpha: 0.4),
              padding: const EdgeInsets.only(bottom: 1),
              notificationPredicate: (n) => n.depth == 0 && n.metrics.axis == Axis.horizontal,
              child: widget.child,
            ),
            if (_before) fade(true),
            if (_after) fade(false),
          ],
        ),
      ),
    );
  }
}
