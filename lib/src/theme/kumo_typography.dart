import 'package:flutter/widgets.dart';

/// Body text sizes. Kumo content text is 14px ([base]); 16px and up is for
/// headings, so reach for [lg] only in places that are not running copy.
enum KumoTextSize {
  /// 12px, captions and dense metadata.
  xs(12),

  /// 13px, secondary rows and compact controls.
  sm(13),

  /// 14px, all content text: body, buttons, inputs, table data.
  base(14),

  /// 16px.
  lg(16);

  const KumoTextSize(this.fontSize);
  final double fontSize;
}

/// Heading steps. Kumo's `heading` is 16px, `heading` + `size="lg"` is 20px;
/// [h2] and [h1] match the deprecated `heading2`/`heading1` sizes for page titles.
enum KumoHeadingSize {
  /// 16px semibold, section and card titles.
  base(16, 24),

  /// 20px semibold, page titles.
  lg(20, 28),

  /// 24px semibold.
  h2(24, 32),

  /// 30px semibold.
  h1(30, 36);

  const KumoHeadingSize(this.fontSize, this.lineHeight);
  final double fontSize;
  final double lineHeight;
}

/// Font families and the text styles Kumo derives from them.
///
/// Inter and JetBrains Mono ship with the package (SIL OFL). To use other
/// faces, register them in your app's pubspec and pass their family names:
///
/// ```dart
/// KumoThemeProvider(
///   typography: const KumoTypography(sans: 'MyBrandSans', package: null),
///   child: app,
/// )
/// ```
@immutable
class KumoTypography {
  const KumoTypography({
    this.sans = 'Inter',
    this.mono = 'JetBrainsMono',
    this.package = 'kumo_flutter',
    this.sansFallback = const ['SF Pro Text', 'Roboto', 'Segoe UI', 'Helvetica Neue', 'Arial'],
    this.monoFallback = const ['SF Mono', 'Menlo', 'Roboto Mono', 'Consolas', 'monospace'],
  });

  final String sans;
  final String mono;

  /// Package the font assets live in; null for fonts registered by the app.
  final String? package;
  final List<String> sansFallback;
  final List<String> monoFallback;

  /// Line height multiplier for running text (Kumo inherits 1.5 from the page).
  static const double bodyHeight = 1.5;

  /// Regular weight.
  static const FontWeight normal = FontWeight.w400;

  /// Kumo's emphasis weight (`font-medium`): bold inline text, buttons, labels.
  static const FontWeight medium = FontWeight.w500;

  /// Heading weight (`font-semibold`). Kumo never uses bold (700).
  static const FontWeight semibold = FontWeight.w600;

  /// Body text at [size].
  TextStyle body({
    KumoTextSize size = KumoTextSize.base,
    FontWeight weight = normal,
    Color? color,
    double height = bodyHeight,
  }) => TextStyle(
    fontFamily: sans,
    package: package,
    fontFamilyFallback: sansFallback,
    fontSize: size.fontSize,
    fontWeight: weight,
    height: height,
    color: color,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// A semibold heading.
  TextStyle heading({KumoHeadingSize size = KumoHeadingSize.base, Color? color}) => TextStyle(
    fontFamily: sans,
    package: package,
    fontFamilyFallback: sansFallback,
    fontSize: size.fontSize,
    fontWeight: semibold,
    height: size.lineHeight / size.fontSize,
    color: color,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Monospace text. Mono reads larger than Inter at the same size, so Kumo
  /// sets it 1px smaller than the text around it: 13px by default, 14px for
  /// [large].
  TextStyle code({bool large = false, FontWeight weight = normal, Color? color, double height = bodyHeight}) =>
      TextStyle(
        fontFamily: mono,
        package: package,
        fontFamilyFallback: monoFallback,
        fontSize: large ? 14 : 13,
        fontWeight: weight,
        height: height,
        color: color,
        leadingDistribution: TextLeadingDistribution.even,
      );

  KumoTypography copyWith({String? sans, String? mono, String? package}) => KumoTypography(
    sans: sans ?? this.sans,
    mono: mono ?? this.mono,
    package: package ?? this.package,
    sansFallback: sansFallback,
    monoFallback: monoFallback,
  );

  @override
  bool operator ==(Object other) =>
      other is KumoTypography && other.sans == sans && other.mono == mono && other.package == package;

  @override
  int get hashCode => Object.hash(sans, mono, package);
}
