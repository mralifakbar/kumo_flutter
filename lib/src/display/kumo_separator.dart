import 'package:flutter/widgets.dart';

import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Direction a [KumoSeparator] runs.
enum KumoSeparatorOrientation { horizontal, vertical }

/// A 1px hairline between groups of content, the `h-px bg-kumo-hairline`
/// divider Kumo uses between menu groups and card sections.
///
/// ```dart
/// const KumoSeparator()
/// const KumoSeparator(label: 'or continue with')
/// const IntrinsicHeight(child: Row(children: [Text('Workers'), KumoSeparator.vertical(), Text('Pages')]))
/// ```
///
/// Horizontal separators fill the available width. Vertical separators fill
/// the height their parent gives them: wrap the row in [IntrinsicHeight] or
/// pass [length]. The line is decorative and hidden from screen readers; a
/// [label] is read as text.
class KumoSeparator extends StatelessWidget {
  const KumoSeparator({
    super.key,
    this.orientation = KumoSeparatorOrientation.horizontal,
    this.label,
    this.length,
    this.color = KumoColor.hairline,
    this.thickness = 1,
  });

  /// A vertical separator.
  const KumoSeparator.vertical({super.key, this.length, this.color = KumoColor.hairline, this.thickness = 1})
    : orientation = KumoSeparatorOrientation.vertical,
      label = null;

  final KumoSeparatorOrientation orientation;

  /// Short text centered in a horizontal separator, such as "or". 12px subtle.
  final String? label;

  /// Fixed extent along the line. Null fills the parent.
  final double? length;

  /// Line color token. [KumoColor.line] gives a stronger divider.
  final KumoColor color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final lineColor = kumo.color(color);
    final vertical = orientation == KumoSeparatorOrientation.vertical;

    // A childless Container fills bounded constraints and collapses to zero
    // in unbounded ones, which also keeps it working under IntrinsicHeight.
    Widget line({double? extent}) => vertical
        ? Container(width: thickness, height: extent, color: lineColor)
        : Container(height: thickness, width: extent, color: lineColor);

    if (label == null || vertical) {
      return ExcludeSemantics(child: line(extent: length));
    }

    final row = LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(child: ExcludeSemantics(child: line())),
          ConstrainedBox(
            // A long label wraps instead of pushing the lines off screen.
            constraints: BoxConstraints(
              maxWidth: constraints.hasBoundedWidth ? constraints.maxWidth * 0.7 : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
              child: Text(
                label!,
                textAlign: TextAlign.center,
                style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle, height: 4 / 3),
              ),
            ),
          ),
          Expanded(child: ExcludeSemantics(child: line())),
        ],
      ),
    );
    return length == null ? row : SizedBox(width: length, child: row);
  }
}
