import 'dart:math' as math;
import 'dart:ui' show Color;

import 'kumo_oklch.dart';

/// Color math Kumo components need at runtime.
abstract final class KumoColorUtils {
  /// CSS `color-mix(in oklch, color, other amount%)`. Kumo uses it for button
  /// emphasis gradients: `mix(brand, white, 0.3)` is the primary button's top.
  static Color mix(Color color, Color other, double amount) {
    final a = Oklch.fromArgb(color.toARGB32());
    final b = Oklch.fromArgb(other.toARGB32());
    return Color(a.mix(b, amount).toArgb());
  }

  /// Mixes toward white.
  static Color lighten(Color color, double amount) => mix(color, const Color(0xFFFFFFFF), amount);

  /// Mixes toward black.
  static Color darken(Color color, double amount) => mix(color, const Color(0xFF000000), amount);

  /// WCAG 2 relative luminance.
  static double luminance(Color color) {
    double channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
  }

  /// WCAG 2 contrast ratio between two opaque colors, 1 to 21.
  static double contrastRatio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Composites a translucent [top] over an opaque [bottom].
  static Color over(Color top, Color bottom) => Color.alphaBlend(top, bottom);
}
