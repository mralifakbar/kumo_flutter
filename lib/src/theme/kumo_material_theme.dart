import 'package:flutter/material.dart';

import 'kumo_theme.dart';
import 'kumo_theme_data.dart';
import 'kumo_typography.dart';

/// Builds a Material [ThemeData] from a Kumo theme, so Material widgets you
/// still use (Scaffold, scrollbars, text selection) match Kumo colors and
/// type. Ink splashes are off: Kumo controls give feedback by tint and scale.
ThemeData kumoMaterialTheme(KumoThemeData kumo) {
  final c = kumo.colors;
  TextStyle body([KumoTextSize size = KumoTextSize.base]) => kumo.typography.body(size: size, color: c.textDefault);
  TextStyle heading(KumoHeadingSize size) => kumo.typography.heading(size: size, color: c.textDefault);

  final scheme = ColorScheme(
    brightness: kumo.brightness,
    primary: c.brand,
    onPrimary: const Color(0xFFFFFFFF),
    secondary: c.fill,
    onSecondary: c.textDefault,
    error: c.danger,
    onError: const Color(0xFFFFFFFF),
    surface: c.base,
    onSurface: c.textDefault,
    onSurfaceVariant: c.textSubtle,
    surfaceContainerLowest: c.canvas,
    surfaceContainerLow: c.elevated,
    surfaceContainer: c.elevated,
    surfaceContainerHigh: c.recessed,
    surfaceContainerHighest: c.tint,
    outline: c.interact,
    outlineVariant: c.hairline,
    inverseSurface: c.contrast,
    onInverseSurface: c.textInverse,
    scrim: const Color(0x66000000),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: kumo.brightness,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.base,
    dividerColor: c.hairline,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    fontFamily: kumo.typography.sans,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.textDefault,
      selectionColor: c.brand.withValues(alpha: 0.24),
      selectionHandleColor: c.brand,
    ),
    textTheme: TextTheme(
      displayLarge: heading(KumoHeadingSize.h1),
      displayMedium: heading(KumoHeadingSize.h1),
      displaySmall: heading(KumoHeadingSize.h2),
      headlineLarge: heading(KumoHeadingSize.h2),
      headlineMedium: heading(KumoHeadingSize.lg),
      headlineSmall: heading(KumoHeadingSize.lg),
      titleLarge: heading(KumoHeadingSize.lg),
      titleMedium: heading(KumoHeadingSize.base),
      titleSmall: body().copyWith(fontWeight: KumoTypography.medium),
      bodyLarge: body(),
      bodyMedium: body(),
      bodySmall: body(KumoTextSize.sm).copyWith(color: c.textSubtle),
      labelLarge: body().copyWith(fontWeight: KumoTypography.medium),
      labelMedium: body(KumoTextSize.sm).copyWith(fontWeight: KumoTypography.medium),
      labelSmall: body(KumoTextSize.xs),
    ),
  );
}

/// Wraps [child] in a Material [Theme] derived from the nearest [KumoTheme].
/// Place it under [KumoThemeProvider] when mixing Material widgets in.
class KumoMaterialTheme extends StatelessWidget {
  const KumoMaterialTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(data: kumoMaterialTheme(context.kumo), child: child);
}
