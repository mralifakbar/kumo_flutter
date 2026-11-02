// Parts shared by the controls in this folder. Not exported from the
// package: the public API is the Kumo* widgets that use them.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DeviceGestureSettings;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Kumo's `Fieldset` as the checkbox, radio and switch groups use it: legend,
/// controls, then error and description (Kumo renders both, error first).
class ControlFieldset extends StatelessWidget {
  const ControlFieldset({
    super.key,
    required this.child,
    this.legend,
    this.hideLegend = false,
    this.description,
    this.error,
    this.gap = KumoSpace.s4,
  });

  final Widget child;
  final String? legend;
  final bool hideLegend;
  final String? description;
  final String? error;

  /// `gap-4` for default groups, `gap-2` for card and segmented groups.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final children = <Widget>[
      if (legend != null)
        hideLegend
            ? Semantics(label: legend, child: const SizedBox.shrink())
            : Text(legend!, style: kumo.text(weight: KumoTypography.medium)),
      child,
      if (error != null)
        Semantics(
          liveRegion: true,
          child: Text(error!, style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textDanger)),
        ),
      if (description != null)
        Text(description!, style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle)),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: hideLegend && legend != null ? 0 : gap,
      children: children,
    );
  }
}

/// Label text with Kumo's "(optional)" marker and info tooltip, laid out
/// like Kumo's `Label asContent` (inline, gap-1).
class ControlLabelText extends StatelessWidget {
  const ControlLabelText({
    super.key,
    required this.text,
    this.weight = KumoTypography.normal,
    this.showOptional = false,
    this.tooltip,
  });

  final String text;
  final FontWeight weight;
  final bool showOptional;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final style = kumo.text(weight: weight);
    if (!showOptional && tooltip == null) return Text(text, style: style);
    final strings = context.kumoStrings;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text),
          if (showOptional) TextSpan(text: ' ${strings.optional}', style: kumo.text(color: KumoColor.textSubtle)),
          if (tooltip != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: KumoSpace.s1),
                child: KumoTooltip(
                  content: tooltip!,
                  child: Semantics(
                    label: strings.moreInformation,
                    child: const KumoIcon(KumoIcons.info, color: KumoColor.textSubtle),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A control next to its label. Kumo uses `items-start` with the control
/// nudged down (`mt-0.5`) so a 16px box centers on the first 21px text line.
class ControlRow extends StatelessWidget {
  const ControlRow({
    super.key,
    required this.control,
    required this.label,
    required this.controlFirst,
    this.gap = KumoSpace.s2,
    this.centered = false,
  });

  final Widget control;
  final Widget label;
  final bool controlFirst;
  final double gap;

  /// `items-center` (switches) instead of first-line alignment.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final aligned = centered ? control : Padding(padding: const EdgeInsets.only(top: KumoSpace.s0_5), child: control);
    final text = Flexible(child: label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      spacing: gap,
      children: controlFirst ? [aligned, text] : [text, aligned],
    );
  }
}

/// Label plus optional description stacked with `gap-0.5`, as in Kumo's
/// card items.
class ControlLabelStack extends StatelessWidget {
  const ControlLabelStack({super.key, required this.label, this.description});

  final Widget label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    if (description == null) return label;
    final kumo = context.kumo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: KumoSpace.s0_5,
      children: [
        label,
        Text(description!, style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle)),
      ],
    );
  }
}

/// Spacing between stacked rows in a group. Kumo spaces rows 8px apart. On
/// touch a single-line row is already padded to a 44px hit area, which
/// supplies the separation; rows with a description are about that tall on
/// their own, so they keep the gap.
double controlRowGap(BuildContext context, {bool multiline = false}) =>
    context.kumo.minTapTarget > 0 && !multiline ? 0 : KumoSpace.s2;

/// Keyboard navigation inside a group: arrows move between items (Up/Left
/// back, Down/Right forward, Left/Right mirrored in RTL), Home and End jump
/// to the ends. Tab enters and leaves the group at one item, because only the
/// tab stop takes part in traversal.
class RovingFocus {
  final List<FocusNode> nodes = [];

  void sync(int count, String debugLabel) {
    while (nodes.length < count) {
      nodes.add(FocusNode(debugLabel: '$debugLabel ${nodes.length}'));
    }
    while (nodes.length > count) {
      nodes.removeLast().dispose();
    }
  }

  /// Keeps [tabStop] as the only node Tab can reach.
  void setTabStop(int tabStop) {
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].skipTraversal = i != tabStop;
    }
  }

  int get focusedIndex => nodes.indexWhere((n) => n.hasFocus);

  /// Next enabled index from [from] stepping by [delta], wrapping around.
  static int? next(int from, int delta, int count, bool Function(int) enabled) {
    if (count == 0) return null;
    var i = from;
    for (var n = 0; n < count; n++) {
      i = (i + delta) % count;
      if (i < 0) i += count;
      if (enabled(i)) return i;
    }
    return null;
  }

  static int? first(int count, bool Function(int) enabled) {
    for (var i = 0; i < count; i++) {
      if (enabled(i)) return i;
    }
    return null;
  }

  static int? last(int count, bool Function(int) enabled) {
    for (var i = count - 1; i >= 0; i--) {
      if (enabled(i)) return i;
    }
    return null;
  }

  void dispose() {
    for (final n in nodes) {
      n.dispose();
    }
    nodes.clear();
  }
}

/// Wraps a group's items with the arrow, Home and End bindings that drive
/// [RovingFocus]. [onMove] receives the target index.
class RovingFocusKeys extends StatelessWidget {
  const RovingFocusKeys({
    super.key,
    required this.focus,
    required this.count,
    required this.enabled,
    required this.onMove,
    required this.child,
  });

  final RovingFocus focus;
  final int count;
  final bool Function(int index) enabled;
  final ValueChanged<int> onMove;
  final Widget child;

  void _step(BuildContext context, int delta, {bool horizontal = false}) {
    final current = focus.focusedIndex;
    if (current < 0) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final d = horizontal && rtl ? -delta : delta;
    final target = RovingFocus.next(current, d, count, enabled);
    if (target != null) onMove(target);
  }

  void _jump(int? target) {
    if (focus.focusedIndex < 0 || target == null) return;
    onMove(target);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(context, 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(context, -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(context, 1, horizontal: true),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(context, -1, horizontal: true),
        const SingleActivator(LogicalKeyboardKey.home): () => _jump(RovingFocus.first(count, enabled)),
        const SingleActivator(LogicalKeyboardKey.end): () => _jump(RovingFocus.last(count, enabled)),
      },
      child: child,
    );
  }
}

/// The selected fill of a single-choice segmented bar (segmented radio,
/// single toggle group), which slides from the previous segment to the new
/// one instead of jumping.
///
/// [position] runs in segment indices: 2.0 rests on the third segment, 2.5
/// straddles the third and fourth. It is driven by a spring that starts from
/// where the fill is and how fast it moves, so rapid taps retarget it without
/// a jump. [presence] fades the fill in and out when the selection is set or
/// cleared. Under reduced motion both change at once.
class SegmentSelection {
  SegmentSelection({required TickerProvider vsync, required int? selected})
    : _selected = selected,
      position = AnimationController.unbounded(vsync: vsync, value: (selected ?? 0).toDouble()),
      presence = AnimationController(vsync: vsync, duration: KumoDurations.fast, value: selected == null ? 0 : 1);

  final AnimationController position;
  final AnimationController presence;
  int? _selected;

  Listenable get listenable => Listenable.merge([position, presence]);

  void select(BuildContext context, int? next) {
    if (next == _selected) return;
    _selected = next;
    final reduce = KumoMotion.reduceMotion(context);
    if (next == null) {
      if (reduce) {
        presence.value = 0;
      } else {
        presence.reverse();
      }
      return;
    }
    if (reduce || presence.value == 0) {
      position.value = next.toDouble();
    } else {
      KumoMotion.springTo(position, next.toDouble(), velocity: position.velocity);
    }
    if (reduce) {
      presence.value = 1;
    } else {
      presence.forward();
    }
  }

  /// The part of segment [index] the fill covers, as start and end fractions
  /// of its width (in reading order), or null when it covers none of it.
  ({double start, double end})? slice(int index) {
    if (presence.value == 0) return null;
    final p = position.value;
    final start = math.max(index - 0.5, p - 0.5);
    final end = math.min(index + 0.5, p + 0.5);
    if (end - start <= 1e-6) return null;
    return (start: start - (index - 0.5), end: end - (index - 0.5));
  }

  /// How much of segment [index] is under the fill, 0 to 1, faded with it.
  double coverage(int index) {
    final s = slice(index);
    return s == null ? 0 : (s.end - s.start) * presence.value;
  }

  void dispose() {
    position.dispose();
    presence.dispose();
  }
}

/// Presses a small control (a checkbox box, a radio circle) in a little while
/// it is held, with a spring that starts from where it is, so the control
/// answers the finger on pointer-down even though the whole row is the hit
/// area. Static under reduced motion.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.pressed, required this.child, this.scale = 0.9});

  final bool pressed;
  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void didUpdateWidget(PressScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressed == widget.pressed) return;
    final target = widget.pressed ? widget.scale : 1.0;
    if (KumoMotion.reduceMotion(context)) {
      _scale.value = 1;
    } else {
      KumoMotion.springTo(_scale, target, spring: KumoSprings.press, velocity: _scale.velocity);
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

/// Geometry of one segment in a joined bar (segmented radio, toggle group).
@immutable
class SegmentPosition {
  const SegmentPosition({
    required this.index,
    required this.count,
    this.previousSelected = false,
    this.nextSelected = false,
  });

  final int index;
  final int count;
  final bool previousSelected;
  final bool nextSelected;

  bool get first => index == 0;
  bool get last => index == count - 1;

  @override
  bool operator ==(Object other) =>
      other is SegmentPosition &&
      other.index == index &&
      other.count == count &&
      other.previousSelected == previousSelected &&
      other.nextSelected == nextSelected;

  @override
  int get hashCode => Object.hash(index, count, previousSelected, nextSelected);
}

/// The outer surface of Kumo's segmented control: `rounded-lg bg-kumo-control
/// shadow-xs ring ring-kumo-line`. [touchPad] grows the hit area of every
/// segment above and below the visual bar on touch, without changing it.
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    super.key,
    required this.children,
    this.radius = KumoRadius.lg,
    this.error = false,
    this.touchPad = 0,
    this.background = true,
  });

  final List<Widget> children;
  final double radius;
  final bool error;
  final double touchPad;

  /// False draws no surface (ghost toggle groups).
  final bool background;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final row = IntrinsicHeight(
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
    if (!background && !error) return row;
    return Stack(
      children: [
        Positioned.fill(
          top: touchPad,
          bottom: touchPad,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background ? c.control : null,
              borderRadius: BorderRadius.circular(radius),
              border: KumoRing.border(error ? c.danger : c.line),
              boxShadow: background ? KumoShadow.xs.boxShadows : null,
            ),
          ),
        ),
        row,
      ],
    );
  }
}

/// The 1px seam between two segments (`border-r border-kumo-line/60`).
/// Hidden next to a selected segment, whose fill covers it; between two
/// selected segments it shows as a faint inverse line so they stay apart.
/// With a [selection], it hides while the sliding fill passes over it.
class SegmentDivider extends StatelessWidget {
  const SegmentDivider({
    super.key,
    required this.beforeSelected,
    required this.afterSelected,
    this.touchPad = 0,
    this.selection,
    this.index = 0,
  });

  final bool beforeSelected;
  final bool afterSelected;
  final double touchPad;
  final SegmentSelection? selection;

  /// Index of the segment after this seam, for [selection].
  final int index;

  @override
  Widget build(BuildContext context) {
    final selection = this.selection;
    if (selection == null) return _seam(context, beforeSelected ? 1 : 0, afterSelected ? 1 : 0);
    return AnimatedBuilder(
      animation: selection.listenable,
      builder: (context, _) {
        // The fill is one segment wide, so it covers the seam whenever it
        // sits anywhere between the two segments; the seam shows again the
        // moment the fill's edge passes it.
        final p = selection.position.value;
        final covered = p >= index - 1 && p <= index ? selection.presence.value : 0.0;
        return _seam(context, covered, 0);
      },
    );
  }

  Widget _seam(BuildContext context, double before, double after) {
    final c = context.kumo.colors;
    Color? color;
    final bothSelected = before >= 1 && after >= 1;
    if (bothSelected) {
      color = c.textInverse.withValues(alpha: 0.25);
    } else {
      final hidden = math.max(before, after).clamp(0.0, 1.0);
      if (hidden < 1) color = c.line.withValues(alpha: c.line.a * 0.6 * (1 - hidden));
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: touchPad),
      child: SizedBox(
        width: 1,
        child: color == null
            ? null
            : bothSelected
                ? ColoredBox(color: c.contrast, child: ColoredBox(color: color))
                : ColoredBox(color: color),
      ),
    );
  }
}

/// One segment's visual: content with its selected or hover fill. The fill
/// extends 1px past the segment over the bar's ring and the neighboring
/// seams (Kumo's `before:-inset-y-px before:-right-px`), with 9px outer
/// corners so it stays concentric with the 8px bar plus its ring.
///
/// With a [selection], the fill is the part of the sliding [SegmentSelection]
/// fill that lies over this segment, and [builder] gets how much of the
/// segment it covers (0 to 1) to blend the label from the default to the
/// inverse color, so a label is readable at every point of the slide.
class SegmentSurface extends StatelessWidget {
  const SegmentSurface({
    super.key,
    required this.position,
    required this.state,
    required this.selected,
    required this.height,
    required this.padding,
    this.child,
    this.selection,
    this.builder,
    this.radius = KumoRadius.lg,
    this.touchPad = 0,
    this.minWidth = 0,
  }) : assert(child != null || (selection != null && builder != null));

  final SegmentPosition position;
  final KumoPressState state;
  final bool selected;
  final Widget? child;
  final SegmentSelection? selection;
  final Widget Function(BuildContext context, double selected)? builder;
  final double height;
  final EdgeInsetsDirectional padding;
  final double radius;
  final double touchPad;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final selection = this.selection;
    if (selection == null) return _surface(context, selected ? (start: 0.0, end: 1.0) : null, 1, child!);
    return AnimatedBuilder(
      animation: selection.listenable,
      builder: (context, _) {
        final slice = selection.slice(position.index);
        return _surface(
          context,
          slice,
          selection.presence.value,
          builder!(context, selection.coverage(position.index)),
        );
      },
    );
  }

  Widget _surface(BuildContext context, ({double start, double end})? slice, double opacity, Widget content) {
    final c = context.kumo.colors;
    const edge = 1e-3;
    final full = slice != null && slice.start <= edge && slice.end >= 1 - edge;
    final hover = state.active && !state.disabled && !full;
    final outer = Radius.circular(radius + 1);
    final inner = BorderRadiusDirectional.only(
      topStart: position.first ? Radius.circular(radius) : Radius.zero,
      bottomStart: position.first ? Radius.circular(radius) : Radius.zero,
      topEnd: position.last ? Radius.circular(radius) : Radius.zero,
      bottomEnd: position.last ? Radius.circular(radius) : Radius.zero,
    );
    BorderRadiusDirectional fillRadius({required bool atStart, required bool atEnd}) => BorderRadiusDirectional.only(
      topStart: position.first && atStart ? outer : Radius.zero,
      bottomStart: position.first && atStart ? outer : Radius.zero,
      topEnd: position.last && atEnd ? outer : Radius.zero,
      bottomEnd: position.last && atEnd ? outer : Radius.zero,
    );
    Widget? fill;
    if (slice != null) {
      final atStart = slice.start <= edge;
      final atEnd = slice.end >= 1 - edge;
      // A fill that reaches the segment's edge covers the seam beside it,
      // except toward a selected neighbor in a multiple-choice bar.
      final extendStart = atStart && !(selected && position.previousSelected) ? 1.0 : 0.0;
      final extendEnd = atEnd && !(selected && position.nextSelected) ? 1.0 : 0.0;
      fill = LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                top: -1,
                bottom: -1,
                start: slice.start * w - extendStart,
                end: (1 - slice.end) * w - extendEnd,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: c.contrast, borderRadius: fillRadius(atStart: atStart, atEnd: atEnd)),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: touchPad),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (hover)
            PositionedDirectional(
              top: -1,
              bottom: -1,
              start: -1,
              end: -1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.contrast.withValues(alpha: 0.07),
                  borderRadius: fillRadius(atStart: true, atEnd: true),
                ),
              ),
            ),
          if (fill != null) Positioned.fill(child: fill),
          KumoFocusRing(
            visible: state.focused,
            borderRadius: inner.resolve(Directionality.of(context)),
            offset: -2,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height, minWidth: math.max(minWidth, 0)),
              child: Padding(padding: padding, child: Center(widthFactor: 1, child: content)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card items joined into one shared card (`rounded-lg ring ring-kumo-line`),
/// divided by `border-kumo-line` seams: a column, or a two-column grid when
/// [horizontal].
class JoinedCards extends StatelessWidget {
  const JoinedCards({super.key, required this.children, required this.horizontal});

  final List<Widget> children;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final seam = ColoredBox(color: c.line);
    Widget content;
    if (!horizontal) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: 1, child: seam),
            children[i],
          ],
        ],
      );
    } else {
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += 2) {
        if (i > 0) rows.add(SizedBox(height: 1, child: seam));
        final hasPair = i + 1 < children.length;
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              // A lone last item keeps its column; only a pair gets the seam.
              if (hasPair) SizedBox(width: 1, child: seam),
              Expanded(child: hasPair ? children[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ));
      }
      content = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(c.line),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(KumoRadius.lg), child: content),
    );
  }
}

/// Scrolls [child] sideways when it is wider than the space it gets, so a
/// segmented bar that must not wrap never overflows a phone screen. In an
/// unbounded row (a toolbar) it lays out as is.
class OverflowScroll extends StatelessWidget {
  const OverflowScroll({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(1),
    this.clipBehavior = Clip.hardEdge,
  });

  final Widget child;

  /// Room for rings drawn outside the child, which a scroll view would clip.
  final EdgeInsets padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return Padding(padding: padding, child: child);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: padding,
          clipBehavior: clipBehavior,
          child: child,
        );
      },
    );
  }
}

/// Lowers the touch slop for the drag recognizer that [build] returns. The
/// default 18px slop is as long as a switch's whole travel, so the thumb
/// would sit still under a moving finger. [build] receives a `restore`
/// function that gives the recognizer's content the original gesture
/// settings back, so nested recognizers keep their usual slop.
Widget withDragSlop(
  BuildContext context, {
  required double slop,
  required Widget Function(Widget Function(Widget child) restore) build,
}) {
  final media = MediaQuery.maybeOf(context);
  if (media == null) return build((child) => child);
  return MediaQuery(
    data: media.copyWith(gestureSettings: DeviceGestureSettings(touchSlop: slop)),
    child: build((child) => MediaQuery(data: media, child: child)),
  );
}
