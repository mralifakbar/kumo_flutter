import 'package:flutter/widgets.dart';

import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';

/// Paints Kumo's keyboard focus ring (`focus-visible:ring-2 ring-kumo-brand`)
/// just outside a control's bounds, so it never shifts layout.
class KumoFocusRingPainter extends CustomPainter {
  const KumoFocusRingPainter({required this.borderRadius, required this.color, this.width = 2, this.offset = 0});

  final BorderRadius borderRadius;
  final Color color;
  final double width;

  /// Gap between the control edge and the ring.
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final inflate = offset + width / 2;
    final rect = (Offset.zero & size).inflate(inflate);
    final r = borderRadius.resolve(TextDirection.ltr);
    Radius grow(Radius radius) =>
        radius == Radius.zero ? Radius.zero : Radius.elliptical(radius.x + inflate, radius.y + inflate);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: grow(r.topLeft),
        topRight: grow(r.topRight),
        bottomLeft: grow(r.bottomLeft),
        bottomRight: grow(r.bottomRight),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(KumoFocusRingPainter old) =>
      old.borderRadius != borderRadius || old.color != color || old.width != width || old.offset != offset;
}

/// Shows the focus ring around [child] while [visible]. For focusable
/// widgets not built on KumoPressable, such as text inputs.
class KumoFocusRing extends StatelessWidget {
  const KumoFocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.color = KumoColor.brand,
    this.width = 2,
    this.offset = 0,
  });

  final bool visible;
  final Widget child;
  final BorderRadius borderRadius;
  final KumoColor color;
  final double width;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    return CustomPaint(
      foregroundPainter: KumoFocusRingPainter(
        borderRadius: borderRadius,
        color: context.kumo.color(color),
        width: width,
        offset: offset,
      ),
      child: child,
    );
  }
}
