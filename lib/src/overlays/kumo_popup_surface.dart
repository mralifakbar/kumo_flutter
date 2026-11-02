import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import 'kumo_anchored_overlay.dart';

/// The floating surface of popovers, tooltips and menus: `bg-kumo-base`, a
/// 1px `kumo-line` outline, a shadow and, optionally, Kumo's soft arrow
/// pointing at the anchor.
///
/// Pass the [placement] from [KumoAnchoredOverlay.overlayBuilder] to draw
/// the arrow; without it the surface is a plain rounded panel.
///
/// ```dart
/// KumoAnchoredOverlay(
///   open: open,
///   overlayBuilder: (context, placement) => KumoPopupSurface(
///     placement: placement,
///     showArrow: true,
///     child: const KumoText('Copied'),
///   ),
///   child: trigger,
/// )
/// ```
class KumoPopupSurface extends StatelessWidget {
  const KumoPopupSurface({
    super.key,
    required this.child,
    this.placement,
    this.showArrow = false,
    this.borderRadius = KumoRadius.lg,
    this.padding = const EdgeInsets.all(KumoSpace.s3),
    this.shadow = KumoShadow.lg,
    this.clip = true,
  });

  final Widget child;
  final KumoPopupPlacement? placement;
  final bool showArrow;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final KumoShadow shadow;

  /// Clip content to the rounded shape (off for content that paints its own
  /// overflow, such as nested menus).
  final bool clip;

  /// Height of the arrow, for overlays that need to add it to their offset.
  static const double arrowHeight = 7;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final radius = BorderRadius.circular(borderRadius);
    Widget content = Padding(padding: padding, child: child);
    if (clip) content = ClipRRect(borderRadius: radius, child: content);
    return CustomPaint(
      painter: _SurfacePainter(
        fill: kumo.colors.base,
        outline: kumo.colors.line,
        radius: borderRadius,
        shadows: shadow.boxShadows,
        placement: showArrow ? placement : null,
      ),
      child: content,
    );
  }
}

class _SurfacePainter extends CustomPainter {
  _SurfacePainter({
    required this.fill,
    required this.outline,
    required this.radius,
    required this.shadows,
    required this.placement,
  }) : super(repaint: placement?.popupRect);

  final Color fill;
  final Color outline;
  final double radius;
  final List<BoxShadow> shadows;
  final KumoPopupPlacement? placement;

  Path _shape(Size size) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final p = placement;
    if (p == null) return body;
    final popup = p.popupRect.value;
    if (popup.isEmpty) return body;
    final along = p.arrowOffset(popup);
    // Arrow drawn pointing up at x = 0, then rotated onto the anchor side.
    final arrow = Path()
      ..moveTo(-10, 0.5)
      ..quadraticBezierTo(-6.5, 0.5, -4.5, -1.6)
      ..lineTo(-1.1, -5.6)
      ..quadraticBezierTo(0, -6.8, 1.1, -5.6)
      ..lineTo(4.5, -1.6)
      ..quadraticBezierTo(6.5, 0.5, 10, 0.5)
      ..close();
    final Matrix4 m;
    switch (p.side) {
      case KumoSide.bottom:
        m = Matrix4.translationValues(along, 0, 0);
      case KumoSide.top:
        m = Matrix4.translationValues(along, size.height, 0)..rotateZ(3.141592653589793);
      case KumoSide.right:
        m = Matrix4.translationValues(0, along, 0)..rotateZ(-3.141592653589793 / 2);
      case KumoSide.left:
        m = Matrix4.translationValues(size.width, along, 0)..rotateZ(3.141592653589793 / 2);
    }
    return Path.combine(PathOperation.union, body, arrow.transform(m.storage));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    for (final s in shadows) {
      final paint = Paint()
        ..color = s.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blurSigma);
      canvas.save();
      canvas.translate(s.offset.dx, s.offset.dy);
      if (s.spreadRadius != 0) {
        final grow = 1 + s.spreadRadius * 2 / size.shortestSide.clamp(1, double.infinity);
        canvas.translate(size.width / 2, size.height / 2);
        canvas.scale(grow, grow);
        canvas.translate(-size.width / 2, -size.height / 2);
      }
      canvas.drawPath(shape, paint);
      canvas.restore();
    }
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      old.fill != fill ||
      old.outline != outline ||
      old.radius != radius ||
      old.shadows != shadows ||
      old.placement != placement;
}
