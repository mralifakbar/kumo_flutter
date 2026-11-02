part of 'kumo_charts.dart';

/// Named chart colors for data with inherent polarity: status, severity,
/// health. Kumo's `ChartSemanticColorName`.
enum KumoChartSemanticColor {
  /// Errors and breaches. `#FC574A`.
  attention,

  /// Degraded or approaching a limit. `#F8A054`.
  warning,

  /// Healthy. `#00A63E`.
  success,

  /// The baseline series of a chart, such as total requests.
  neutral,

  /// Data that is excluded or not applicable.
  disabled,

  /// Loading placeholders.
  skeleton,
}

/// Single-hue sequential scales for density (heatmaps, choropleths).
enum KumoChartSequentialPalette {
  /// Five steps around the chart blue `#4290F0`.
  blues,
}

/// Fills for map charts.
@immutable
class KumoChartMapColors {
  const KumoChartMapColors({required this.area, required this.bubble, required this.scale});

  /// Land and regions without data.
  final Color area;

  /// Default bubble fill: the first categorical color.
  final Color bubble;

  /// Choropleth ramp, low to high. The low end stays distinct from [area].
  final List<Color> scale;
}

/// Kumo's chart palette (`ChartPalette`): categorical colors for series that
/// have no inherent meaning, semantic colors for status data, a sequential
/// scale for density and map fills, each tuned for light and dark mode.
///
/// Kumo defines chart colors as hex values, separate from its OKLCH theme
/// tokens, so they are plain [Color]s here too. Read the set for the current
/// mode with [KumoChartColors.of]:
///
/// ```dart
/// final palette = KumoChartColors.of(context);
/// KumoTimeseriesData(
///   name: 'Errors',
///   color: palette.semantic(KumoChartSemanticColor.attention),
///   data: const [],
/// );
/// palette.categorical(7); // wraps to the second color
/// ```
///
/// Color alone should not carry meaning: pair semantic colors with labels,
/// and give lines a [KumoTimeseriesLineStyle] when series need telling apart.
@immutable
class KumoChartColors {
  const KumoChartColors._({
    required this.brightness,
    required this.categoricalColors,
    required Map<KumoChartSemanticColor, Color> semanticColors,
    required List<Color> blues,
    required this.textPrimary,
    required this.textSecondary,
    required this.map,
  })  : _semantic = semanticColors,
        _blues = blues;

  /// The light-mode palette.
  static const KumoChartColors light = KumoChartColors._(
    brightness: Brightness.light,
    categoricalColors: [
      Color(0xFF4290F0), // blue
      Color(0xFFF5B647), // yellow
      Color(0xFFE8649D), // pink
      Color(0xFF8D58EE), // purple
      Color(0xFF50C3B6), // teal
      Color(0xFFD37536), // orange
    ],
    semanticColors: {
      KumoChartSemanticColor.attention: Color(0xFFFC574A),
      KumoChartSemanticColor.warning: Color(0xFFF8A054),
      KumoChartSemanticColor.success: Color(0xFF00A63E),
      KumoChartSemanticColor.neutral: Color(0xFFB9D6FF),
      KumoChartSemanticColor.disabled: Color(0xFFCBCBCB),
      KumoChartSemanticColor.skeleton: Color(0xFFDDDDDD),
    },
    blues: [Color(0xFFE1EAF4), Color(0xFF8EBCF6), Color(0xFF4290F0), Color(0xFF0E58B4), Color(0xFF03254F)],
    textPrimary: Color(0xFF6B7280),
    textSecondary: Color(0xFF9CA3AF),
    map: KumoChartMapColors(
      area: Color(0xFFE5E7EB),
      bubble: Color(0xFF4290F0),
      scale: [Color(0xFFC8DEFB), Color(0xFF8FBDF6), Color(0xFF4290F0), Color(0xFF1E60BE), Color(0xFF0A3A7A)],
    ),
  );

  /// The dark-mode palette.
  static const KumoChartColors dark = KumoChartColors._(
    brightness: Brightness.dark,
    categoricalColors: [
      Color(0xFF4290F0),
      Color(0xFFEEB720),
      Color(0xFFE8649D),
      Color(0xFF8D58EE),
      Color(0xFF50C3B6),
      Color(0xFFD37536),
    ],
    semanticColors: {
      KumoChartSemanticColor.attention: Color(0xFFFC574A),
      KumoChartSemanticColor.warning: Color(0xFFF8A054),
      KumoChartSemanticColor.success: Color(0xFF00A63E),
      KumoChartSemanticColor.neutral: Color(0xFF8EC5FF),
      KumoChartSemanticColor.disabled: Color(0xFF878787),
      KumoChartSemanticColor.skeleton: Color(0xFF5C5C5C),
    },
    // The light ramp reversed around the same base, so the brightest step
    // still marks the highest value on a dark canvas.
    blues: [Color(0xFF03254F), Color(0xFF0E58B4), Color(0xFF4290F0), Color(0xFFA6BFDD), Color(0xFFE1EAF4)],
    textPrimary: Color(0xFF9CA3AF),
    textSecondary: Color(0xFF6B7280),
    map: KumoChartMapColors(
      area: Color(0xFF2B2C31),
      bubble: Color(0xFF4290F0),
      scale: [Color(0xFF26456C), Color(0xFF2C68BE), Color(0xFF4290F0), Color(0xFF79AEF4), Color(0xFFBBD6FA)],
    ),
  );

  /// The palette for the nearest [KumoTheme]'s mode.
  static KumoChartColors of(BuildContext context) => context.kumo.isDark ? dark : light;

  /// The palette for [brightness].
  static KumoChartColors forBrightness(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  final Brightness brightness;

  /// The six categorical colors in Kumo's order (blue, yellow, pink, purple,
  /// teal, orange), ordered for distance between neighbours.
  final List<Color> categoricalColors;
  final Map<KumoChartSemanticColor, Color> _semantic;
  final List<Color> _blues;

  /// Kumo's chart label colors. Components use the `textSubtle` token for
  /// axis text instead; these are for custom painters that match ECharts.
  final Color textPrimary;
  final Color textSecondary;

  /// Fills for [KumoMapChart].
  final KumoChartMapColors map;

  /// The categorical color for series [index], cycling past six.
  Color categorical(int index) => categoricalColors[index % categoricalColors.length];

  /// The color for a semantic [name].
  Color semantic(KumoChartSemanticColor name) => _semantic[name]!;

  /// The steps of a sequential [palette], low to high.
  List<Color> sequential([KumoChartSequentialPalette palette = KumoChartSequentialPalette.blues]) =>
      List.unmodifiable(_blues);
}
