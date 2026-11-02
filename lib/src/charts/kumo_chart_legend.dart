part of 'kumo_charts.dart';

/// The two layouts of [KumoChartLegend].
enum KumoChartLegendSize {
  /// Dot, name and value on one 16px row (`ChartLegend.SmallItem`). For
  /// multi-series legends under or beside a chart.
  small,

  /// Dot and name over a large value with an optional unit
  /// (`ChartLegend.LargeItem`). For single-metric dashboard cards.
  large,
}

/// A legend item for a chart series: Kumo's `ChartLegend.SmallItem` and
/// `ChartLegend.LargeItem`.
///
/// ```dart
/// KumoChartLegend.small(name: 'Requests', color: KumoChartColors.light.categorical(0), value: '1,234')
/// KumoChartLegend.large(name: 'P99', color: KumoChartColors.light.semantic(KumoChartSemanticColor.attention), value: '124', unit: 'ms')
/// const KumoChartLegend.loading()
/// ```
///
/// Give it [onPress] to toggle or isolate a series and [onHoverChange] to
/// highlight one; it then becomes a focusable button that reports its
/// [inactive] state as toggled off. Without callbacks it is plain text.
class KumoChartLegend extends StatelessWidget {
  /// A compact inline item.
  const KumoChartLegend.small({
    super.key,
    required String this.name,
    required Color this.color,
    this.value,
    this.inactive = false,
    this.onPress,
    this.onHoverChange,
    this.semanticLabel,
  })  : size = KumoChartLegendSize.small,
        unit = null,
        loading = false;

  /// A stacked item with a large value.
  const KumoChartLegend.large({
    super.key,
    required String this.name,
    required Color this.color,
    required String this.value,
    this.unit,
    this.inactive = false,
    this.onPress,
    this.onHoverChange,
    this.semanticLabel,
  })  : size = KumoChartLegendSize.large,
        loading = false;

  /// Skeleton placeholders shown while the chart's data loads. Hidden from
  /// screen readers; announce loading on the chart itself.
  const KumoChartLegend.loading({super.key, this.size = KumoChartLegendSize.small})
      : name = null,
        color = null,
        value = null,
        unit = null,
        inactive = false,
        onPress = null,
        onHoverChange = null,
        semanticLabel = null,
        loading = true;

  final KumoChartLegendSize size;

  /// Series name.
  final String? name;

  /// Series color, usually from [KumoChartColors]. Chart colors are a palette
  /// of their own rather than theme tokens, so this takes a [Color].
  final Color? color;

  /// Formatted value, such as `'1,234'`. Optional for small items.
  final String? value;

  /// Unit after the value of a large item, such as `'ms'` or `'%'`.
  final String? unit;

  /// Renders the item at 50% opacity: the series is hidden or faded.
  final bool inactive;

  /// Called when the item is pressed, typically to toggle the series.
  final VoidCallback? onPress;

  /// Called with true when a pointer enters the item and false when it
  /// leaves, to highlight the series in the chart (Kumo's
  /// `onPointerEnter`/`onPointerLeave`).
  final ValueChanged<bool>? onHoverChange;

  /// Overrides the announced label (defaults to name, value and unit).
  final String? semanticLabel;

  /// True for the [KumoChartLegend.loading] placeholder.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return ExcludeSemantics(child: _buildLoading(context));
    final kumo = context.kumo;
    final faded = inactive ? 0.5 : 1.0;
    // Toggling a series eases the item down to half opacity and back, in
    // step with the series fading in the chart.
    final duration = KumoMotion.duration(context, KumoDurations.quick);
    Widget fade(Widget child) =>
        AnimatedOpacity(opacity: faded, duration: duration, curve: KumoCurves.standard, child: child);
    final dot = fade(_ChartDot(color: color!));
    // Tailwind's text-xs pairs 12px with a 16px line.
    const xsHeight = 16 / 12;
    final nameText = fade(Text(
      name!,
      style: kumo.text(size: KumoTextSize.xs, height: xsHeight),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ));
    const numberStyle = [FontFeature.tabularFigures()];

    final Widget content;
    if (size == KumoChartLegendSize.small) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KumoSpace.s4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s2,
          children: [
            dot,
            Flexible(child: nameText),
            if (value != null)
              fade(Text(
                value!,
                style: kumo
                    .text(size: KumoTextSize.xs, weight: KumoTypography.medium, height: xsHeight)
                    .copyWith(fontFeatures: numberStyle),
              )),
          ],
        ),
      );
    } else {
      content = ConstrainedBox(
        // min-w-42 (168px), py-2. Phones drop the minimum so two or three
        // metrics fit on a row.
        constraints: BoxConstraints(minWidth: context.kumoIsNarrow ? 0 : 168),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KumoSpace.s2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s2,
            children: [
              Row(mainAxisSize: MainAxisSize.min, spacing: KumoSpace.s2, children: [dot, Flexible(child: nameText)]),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: KumoSpace.s0_5,
                children: [
                  fade(Text(
                    value!,
                    style: kumo
                        .text(size: KumoTextSize.lg, weight: KumoTypography.medium, height: 1)
                        .copyWith(fontFeatures: numberStyle),
                  )),
                  if (unit != null)
                    fade(Text(unit!, style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle, height: 1))),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final label = semanticLabel ?? [name, value, unit].whereType<String>().join(' ');
    if (onPress == null && onHoverChange == null) {
      return Semantics(label: label, excludeSemantics: true, child: content);
    }
    Widget result = KumoPressable(
      onPress: onPress,
      semanticLabel: label,
      excludeChildSemantics: true,
      toggled: onPress != null ? !inactive : null,
      borderRadius: BorderRadius.circular(KumoRadius.sm),
      scaleOnPress: onPress != null,
      builder: (context, state) => content,
    );
    if (onHoverChange != null) {
      result = MouseRegion(
        onEnter: (_) => onHoverChange!(true),
        onExit: (_) => onHoverChange!(false),
        child: result,
      );
    }
    return result;
  }

  Widget _buildLoading(BuildContext context) {
    final fill = context.kumo.colors.fill;
    final dot = SizedBox.square(
      dimension: 8,
      child: DecoratedBox(decoration: BoxDecoration(color: fill, shape: BoxShape.circle)),
    );
    // Widths follow Kumo's `w-[5ch]` style sizing at 12px (one ch is about 7px).
    if (size == KumoChartLegendSize.small) {
      return SizedBox(
        height: KumoSpace.s4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s2,
          children: [dot, _skeletonBar(35, 12), _skeletonBar(21, 12)],
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: context.kumoIsNarrow ? 0 : 168),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KumoSpace.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s2,
          children: [
            Row(mainAxisSize: MainAxisSize.min, spacing: KumoSpace.s2, children: [dot, _skeletonBar(56, 12)]),
            _skeletonBar(45, 20),
          ],
        ),
      ),
    );
  }
}
