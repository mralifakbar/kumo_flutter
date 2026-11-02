import 'dart:math' as math;

/// A color in the OKLCH space, the space Kumo defines its tokens in.
///
/// Pure Dart (no Flutter import) so the theme generator in `tool/` can share
/// it. Conversion to sRGB follows CSS Color 4, including its gamut mapping:
/// out-of-gamut colors lose chroma until they fit, the way browsers render
/// Kumo's Tailwind palette on an sRGB display.
///
/// ```dart
/// final brand = Oklch(0.5772, 0.2324, 260);
/// final argb = brand.toArgb(); // 0xFF0051FF
/// ```
class Oklch {
  const Oklch(this.l, this.c, this.h, [this.alpha = 1]);

  /// Lightness, 0 to 1.
  final double l;

  /// Chroma, 0 to about 0.4.
  final double c;

  /// Hue in degrees.
  final double h;

  /// Opacity, 0 to 1.
  final double alpha;

  /// Converts a 32-bit ARGB integer to OKLCH.
  factory Oklch.fromArgb(int argb) {
    double channel(int shift) => _toLinear(((argb >> shift) & 0xFF) / 255);
    final lab = _linearSrgbToOklab(channel(16), channel(8), channel(0));
    final c = math.sqrt(lab[1] * lab[1] + lab[2] * lab[2]);
    var h = math.atan2(lab[2], lab[1]) * 180 / math.pi;
    if (h < 0) h += 360;
    return Oklch(lab[0], c, c < 1e-6 ? 0 : h, ((argb >> 24) & 0xFF) / 255);
  }

  Oklch copyWith({double? l, double? c, double? h, double? alpha}) =>
      Oklch(l ?? this.l, c ?? this.c, h ?? this.h, alpha ?? this.alpha);

  /// `color-mix(in oklch, this, other amount%)`: [amount] is the share of
  /// [other], 0 to 1. Hue takes the shorter arc; an achromatic side (black,
  /// white, greys) has no hue, so the other side's hue is kept.
  Oklch mix(Oklch other, double amount) {
    final t = amount.clamp(0.0, 1.0);
    double hue;
    final selfGrey = c < 1e-4;
    final otherGrey = other.c < 1e-4;
    if (selfGrey && !otherGrey) {
      hue = other.h;
    } else if (otherGrey) {
      hue = h;
    } else {
      var delta = other.h - h;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      hue = (h + delta * t) % 360;
    }
    return Oklch(l + (other.l - l) * t, c + (other.c - c) * t, hue, alpha + (other.alpha - alpha) * t);
  }

  /// 32-bit ARGB, gamut mapped into sRGB.
  int toArgb() {
    final rgb = _gamutMap(this);
    int byte(double v) => (v.clamp(0.0, 1.0) * 255).round();
    final a = byte(alpha);
    return (a << 24) | (byte(rgb[0]) << 16) | (byte(rgb[1]) << 8) | byte(rgb[2]);
  }

  @override
  bool operator ==(Object other) =>
      other is Oklch && other.l == l && other.c == c && other.h == h && other.alpha == alpha;

  @override
  int get hashCode => Object.hash(l, c, h, alpha);

  @override
  String toString() => 'Oklch($l, $c, $h, $alpha)';
}

List<double> _oklchToOklab(double l, double c, double h) {
  final rad = h * math.pi / 180;
  return [l, c * math.cos(rad), c * math.sin(rad)];
}

double _cube(double v) => v * v * v;

List<double> _oklabToLinearSrgb(double l, double a, double b) {
  final l1 = _cube(l + 0.3963377774 * a + 0.2158037573 * b);
  final m1 = _cube(l - 0.1055613458 * a - 0.0638541728 * b);
  final s1 = _cube(l - 0.0894841775 * a - 1.2914855480 * b);
  return [
    4.0767416621 * l1 - 3.3077115913 * m1 + 0.2309699292 * s1,
    -1.2684380046 * l1 + 2.6097574011 * m1 - 0.3413193965 * s1,
    -0.0041960863 * l1 - 0.7034186147 * m1 + 1.7076147010 * s1,
  ];
}

double _cbrt(double v) => v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();

List<double> _linearSrgbToOklab(double r, double g, double b) {
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  ];
}

double _toLinear(double v) => v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _toGamma(double v) {
  final sign = v < 0 ? -1.0 : 1.0;
  final abs = v.abs();
  return abs <= 0.0031308 ? v * 12.92 : sign * (1.055 * math.pow(abs, 1 / 2.4) - 0.055);
}

List<double> _toSrgb(double l, double c, double h) {
  final lab = _oklchToOklab(l, c, h);
  return _oklabToLinearSrgb(lab[0], lab[1], lab[2]).map(_toGamma).toList();
}

bool _inGamut(List<double> rgb) => rgb.every((v) => v >= -1e-4 && v <= 1 + 1e-4);

List<double> _clip(List<double> rgb) => rgb.map((v) => v.clamp(0.0, 1.0)).toList();

double _deltaEok(List<double> rgbA, List<double> rgbB) {
  final a = _linearSrgbToOklab(_toLinear(rgbA[0]), _toLinear(rgbA[1]), _toLinear(rgbA[2]));
  final b = _linearSrgbToOklab(_toLinear(rgbB[0]), _toLinear(rgbB[1]), _toLinear(rgbB[2]));
  final dl = a[0] - b[0], da = a[1] - b[1], db = a[2] - b[2];
  return math.sqrt(dl * dl + da * da + db * db);
}

// CSS Color 4 "binary search gamut mapping with local MINDE".
List<double> _gamutMap(Oklch color) {
  if (color.l >= 1) return [1, 1, 1];
  if (color.l <= 0) return [0, 0, 0];
  final direct = _toSrgb(color.l, color.c, color.h);
  if (_inGamut(direct)) return _clip(direct);

  const jnd = 0.02;
  const epsilon = 0.0001;
  var min = 0.0;
  var max = color.c;
  var minInGamut = true;
  var clipped = _clip(direct);
  if (_deltaEokUnclipped(color, clipped) < jnd) return clipped;

  while (max - min > epsilon) {
    final chroma = (min + max) / 2;
    final current = _toSrgb(color.l, chroma, color.h);
    if (minInGamut && _inGamut(current)) {
      min = chroma;
      continue;
    }
    clipped = _clip(current);
    final e = _deltaEokFrom(color.l, chroma, color.h, clipped);
    if (e < jnd) {
      if (jnd - e < epsilon) return clipped;
      minInGamut = false;
      min = chroma;
    } else {
      max = chroma;
    }
  }
  return clipped;
}

double _deltaEokUnclipped(Oklch color, List<double> clipped) => _deltaEokFrom(color.l, color.c, color.h, clipped);

double _deltaEokFrom(double l, double c, double h, List<double> clipped) {
  final lab = _oklchToOklab(l, c, h);
  final b = _linearSrgbToOklab(_toLinear(clipped[0]), _toLinear(clipped[1]), _toLinear(clipped[2]));
  final dl = lab[0] - b[0], da = lab[1] - b[1], db = lab[2] - b[2];
  return math.sqrt(dl * dl + da * da + db * db);
}

/// Exposed for tests: perceptual distance between two sRGB triples (0 to 1).
double debugDeltaEok(List<double> a, List<double> b) => _deltaEok(a, b);
