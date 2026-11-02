import 'package:flutter/widgets.dart';

import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';

/// Renders an icon: a [KumoIcons] glyph or any other [IconData].
///
/// Icons are decorative by default and hidden from screen readers. Give an
/// icon a [semanticLabel] only when it carries meaning on its own (a status
/// icon with no text next to it).
///
/// Size defaults to 16px, the size Kumo pairs with 14px text. The color
/// follows the surrounding text unless [color] is set.
///
/// ```dart
/// const KumoIcon(KumoIcons.gear)
/// const KumoIcon(KumoIcons.warningCircle, color: KumoColor.textDanger, semanticLabel: 'Error')
/// ```
class KumoIcon extends StatelessWidget {
  const KumoIcon(
    this.icon, {
    super.key,
    this.size = 16,
    this.color,
    this.dangerouslySetColor,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final KumoColor? color;
  final Color? dangerouslySetColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = dangerouslySetColor ??
        (color != null ? context.kumo.color(color!) : DefaultTextStyle.of(context).style.color) ??
        context.kumo.colors.textDefault;
    final glyph = Icon(icon, size: size, color: resolved, semanticLabel: semanticLabel);
    return semanticLabel == null ? ExcludeSemantics(child: glyph) : glyph;
  }
}
