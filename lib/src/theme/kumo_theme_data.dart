import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'generated/kumo_colors.g.dart';
import 'kumo_tokens.dart';
import 'kumo_typography.dart';

/// Kumo's built-in themes. A theme recolors a few surface tokens on top of the
/// light and dark modes; it does not change components.
enum KumoThemeVariant {
  /// The default Kumo theme.
  kumo,

  /// Cloudflare's FedRAMP environment theme: slate canvas and base surfaces.
  fedramp,
}

/// How large interactive targets are.
enum KumoTapTargetSize {
  /// Pads small controls so their hit area is at least 44x44. The default on
  /// touch platforms (iOS, Android, Fuchsia).
  padded,

  /// Hit area matches the visual. The default with a mouse (macOS, Windows,
  /// Linux, web on desktop), where Kumo's dense 36px controls are the norm.
  shrinkWrap;

  /// The platform default.
  static KumoTapTargetSize get platformDefault => switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.android || TargetPlatform.fuchsia => padded,
        _ => shrinkWrap,
      };
}

/// A resolved Kumo theme for one mode. Read it with `context.kumo`.
///
/// ```dart
/// final kumo = context.kumo;
/// Container(color: kumo.colors.base, child: Text('Hi', style: kumo.text()));
/// ```
@immutable
class KumoThemeData {
  const KumoThemeData({
    required this.brightness,
    required this.colors,
    this.variant = KumoThemeVariant.kumo,
    this.typography = const KumoTypography(),
    this.tapTargetSize = KumoTapTargetSize.shrinkWrap,
  });

  /// Kumo light mode.
  factory KumoThemeData.light({
    KumoThemeVariant variant = KumoThemeVariant.kumo,
    KumoTypography typography = const KumoTypography(),
    KumoTapTargetSize? tapTargetSize,
  }) =>
      KumoThemeData(
        brightness: Brightness.light,
        colors: variant == KumoThemeVariant.fedramp ? KumoColorSchemes.fedrampLight : KumoColorSchemes.light,
        variant: variant,
        typography: typography,
        tapTargetSize: tapTargetSize ?? KumoTapTargetSize.platformDefault,
      );

  /// Kumo dark mode.
  factory KumoThemeData.dark({
    KumoThemeVariant variant = KumoThemeVariant.kumo,
    KumoTypography typography = const KumoTypography(),
    KumoTapTargetSize? tapTargetSize,
  }) =>
      KumoThemeData(
        brightness: Brightness.dark,
        colors: variant == KumoThemeVariant.fedramp ? KumoColorSchemes.fedrampDark : KumoColorSchemes.dark,
        variant: variant,
        typography: typography,
        tapTargetSize: tapTargetSize ?? KumoTapTargetSize.platformDefault,
      );

  /// Used when no theme is above a widget.
  static const KumoThemeData fallback = KumoThemeData(brightness: Brightness.light, colors: KumoColorSchemes.light);

  final Brightness brightness;
  final KumoColorScheme colors;
  final KumoThemeVariant variant;
  final KumoTypography typography;
  final KumoTapTargetSize tapTargetSize;

  bool get isDark => brightness == Brightness.dark;

  /// Resolves a color token.
  Color color(KumoColor token) => colors[token];

  /// Minimum hit-area edge for interactive controls under [tapTargetSize].
  double get minTapTarget => tapTargetSize == KumoTapTargetSize.padded ? 44 : 0;

  /// Body text style. Color defaults to `text-kumo-default`.
  TextStyle text({
    KumoTextSize size = KumoTextSize.base,
    FontWeight weight = KumoTypography.normal,
    KumoColor color = KumoColor.textDefault,
    double height = KumoTypography.bodyHeight,
  }) =>
      typography.body(size: size, weight: weight, color: colors[color], height: height);

  /// Heading text style.
  TextStyle heading({KumoHeadingSize size = KumoHeadingSize.base, KumoColor color = KumoColor.textDefault}) =>
      typography.heading(size: size, color: colors[color]);

  /// Monospace text style.
  TextStyle code({bool large = false, KumoColor color = KumoColor.textDefault, FontWeight weight = KumoTypography.normal}) =>
      typography.code(large: large, color: colors[color], weight: weight);

  /// Box shadows for an elevation step.
  List<BoxShadow> shadow(KumoShadow shadow) => shadow.boxShadows;

  KumoThemeData copyWith({
    Brightness? brightness,
    KumoColorScheme? colors,
    KumoThemeVariant? variant,
    KumoTypography? typography,
    KumoTapTargetSize? tapTargetSize,
  }) =>
      KumoThemeData(
        brightness: brightness ?? this.brightness,
        colors: colors ?? this.colors,
        variant: variant ?? this.variant,
        typography: typography ?? this.typography,
        tapTargetSize: tapTargetSize ?? this.tapTargetSize,
      );

  /// Interpolates colors; discrete settings switch at the midpoint.
  static KumoThemeData lerp(KumoThemeData a, KumoThemeData b, double t) {
    if (identical(a, b) || a == b) return b;
    return KumoThemeData(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      colors: KumoColorScheme.lerp(a.colors, b.colors, t),
      variant: t < 0.5 ? a.variant : b.variant,
      typography: t < 0.5 ? a.typography : b.typography,
      tapTargetSize: t < 0.5 ? a.tapTargetSize : b.tapTargetSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KumoThemeData &&
      other.brightness == brightness &&
      other.colors == colors &&
      other.variant == variant &&
      other.typography == typography &&
      other.tapTargetSize == tapTargetSize;

  @override
  int get hashCode => Object.hash(brightness, colors, variant, typography, tapTargetSize);
}
