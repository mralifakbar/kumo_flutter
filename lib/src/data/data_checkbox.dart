import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';

/// The row-selection checkbox for tables and trees, drawn locally so the
/// data category does not depend on the controls category. Matches Kumo's
/// `Checkbox`: a 16px `rounded-sm` box on `bg-kumo-base` with a hairline
/// ring, filled with `kumo-contrast` when checked or mixed. Not exported.
///
/// The whole [hitArea] is pressable, like Kumo's `Table.CheckCell`, where
/// the cell rather than the 16px box takes the click.
class DataCheckbox extends StatelessWidget {
  const DataCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.semanticLabel,
    this.mixed = false,
    this.disabled = false,
    this.hitArea,
    this.focusNode,
  });

  final bool checked;

  /// Indeterminate: some, not all, rows are selected.
  final bool mixed;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final bool disabled;

  /// Size of the pressable area around the box. Defaults to the box.
  final Size? hitArea;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final on = checked || mixed;
    final interactive = !disabled && onChanged != null;
    return KumoPressable(
      onPress: interactive ? () => onChanged!(mixed ? true : !checked) : null,
      disabled: !interactive,
      semanticLabel: semanticLabel,
      checked: mixed ? null : checked,
      mixed: mixed ? true : null,
      excludeChildSemantics: true,
      scaleOnPress: false,
      focusNode: focusNode,
      borderRadius: BorderRadius.circular(KumoRadius.sm),
      builder: (context, state) {
        Widget box = Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: on ? c.contrast : c.base,
            borderRadius: BorderRadius.circular(KumoRadius.sm),
            border: KumoRing.border(on ? c.contrast : c.hairline),
          ),
          alignment: Alignment.center,
          child: _DataCheckMark(on: on, mixed: mixed, color: c.textInverse),
        );
        if (state.focused) {
          box = DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KumoRadius.sm + 2),
              border: KumoRing.border(c.brand, width: 2),
            ),
            child: box,
          );
        }
        if (disabled) box = Opacity(opacity: 0.5, child: box);
        final area = hitArea;
        if (area == null) return box;
        return SizedBox(width: area.width, height: area.height, child: Center(child: box));
      },
      showFocusRing: false,
    );
  }
}

/// The check or dash inside [DataCheckbox]. It lands with Kumo's small
/// bounce when the box turns on (or switches between check and dash), and
/// disappears at once when it turns off, like the controls checkbox. Reduced
/// motion shows it at rest.
class _DataCheckMark extends StatefulWidget {
  const _DataCheckMark({required this.on, required this.mixed, required this.color});

  final bool on;
  final bool mixed;
  final Color color;

  @override
  State<_DataCheckMark> createState() => _DataCheckMarkState();
}

class _DataCheckMarkState extends State<_DataCheckMark> with SingleTickerProviderStateMixin {
  late final AnimationController _land;

  @override
  void initState() {
    super.initState();
    _land = AnimationController(vsync: this, duration: KumoDurations.quick, value: widget.on ? 1 : 0);
  }

  @override
  void didUpdateWidget(_DataCheckMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    final landed = widget.on && (!oldWidget.on || oldWidget.mixed != widget.mixed);
    if (landed) {
      if (KumoMotion.reduceMotion(context)) {
        _land.value = 1;
      } else {
        _land.forward(from: 0);
      }
    } else if (!widget.on) {
      _land.value = 0;
    }
  }

  @override
  void dispose() {
    _land.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _land,
      builder: (context, child) {
        final t = _land.value;
        if (t == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.6 + 0.4 * KumoCurves.bounce.transform(t), child: child),
        );
      },
      child: KumoIcon(widget.mixed ? KumoIcons.minus : KumoIcons.check, size: 12, dangerouslySetColor: widget.color),
    );
  }
}
