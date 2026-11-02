import 'package:flutter/widgets.dart';

import 'kumo_licenses.dart';
import 'kumo_motion.dart';
import 'kumo_theme_data.dart';
import 'kumo_typography.dart';

/// Which mode a [KumoThemeProvider] shows.
enum KumoThemeMode {
  /// Follow the platform's light/dark setting.
  system,
  light,
  dark,
}

/// Makes a resolved [KumoThemeData] available to descendants.
///
/// Most apps use [KumoThemeProvider] at the root. Use [KumoTheme] directly to
/// force a mode for a subtree, like Kumo's `data-mode` attribute:
///
/// ```dart
/// KumoTheme(data: KumoThemeData.dark(), child: const CodePanel())
/// ```
class KumoTheme extends InheritedWidget {
  const KumoTheme({super.key, required this.data, required super.child});

  final KumoThemeData data;

  /// The nearest theme, or [KumoThemeData.fallback] (light) when there is none.
  static KumoThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KumoTheme>()?.data ?? KumoThemeData.fallback;

  static KumoThemeData? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<KumoTheme>()?.data;

  @override
  bool updateShouldNotify(KumoTheme oldWidget) => data != oldWidget.data;
}

/// `context.kumo` shorthand for [KumoTheme.of].
extension KumoThemeContext on BuildContext {
  KumoThemeData get kumo => KumoTheme.of(this);
}

/// The root of a Kumo app. Resolves light or dark mode, applies a theme
/// variant, sets the default text style and cross-fades colors when the mode
/// changes (instantly under reduced motion).
///
/// ```dart
/// KumoThemeProvider(
///   mode: KumoThemeMode.system,
///   child: MyApp(),
/// )
/// ```
class KumoThemeProvider extends StatefulWidget {
  const KumoThemeProvider({
    super.key,
    this.mode = KumoThemeMode.system,
    this.variant = KumoThemeVariant.kumo,
    this.typography = const KumoTypography(),
    this.tapTargetSize,
    this.light,
    this.dark,
    this.animationDuration = KumoDurations.slow,
    required this.child,
  });

  final KumoThemeMode mode;
  final KumoThemeVariant variant;
  final KumoTypography typography;

  /// Defaults to [KumoTapTargetSize.platformDefault].
  final KumoTapTargetSize? tapTargetSize;

  /// Replaces the generated light theme, for brand overrides:
  /// `KumoThemeData.light().copyWith(colors: KumoColorSchemes.light.copyWith({KumoColor.brand: myBlue}))`.
  final KumoThemeData? light;

  /// Replaces the generated dark theme.
  final KumoThemeData? dark;

  /// How long a mode change takes to cross-fade.
  final Duration animationDuration;
  final Widget child;

  @override
  State<KumoThemeProvider> createState() => _KumoThemeProviderState();
}

class _KumoThemeProviderState extends State<KumoThemeProvider> {
  @override
  void initState() {
    super.initState();
    registerKumoLicenses();
  }

  KumoThemeData _resolve(BuildContext context) {
    final brightness = switch (widget.mode) {
      KumoThemeMode.light => Brightness.light,
      KumoThemeMode.dark => Brightness.dark,
      KumoThemeMode.system => MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light,
    };
    final base = brightness == Brightness.dark
        ? (widget.dark ??
            KumoThemeData.dark(variant: widget.variant, typography: widget.typography, tapTargetSize: widget.tapTargetSize))
        : (widget.light ??
            KumoThemeData.light(variant: widget.variant, typography: widget.typography, tapTargetSize: widget.tapTargetSize));
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final target = _resolve(context);
    return TweenAnimationBuilder<KumoThemeData>(
      tween: _KumoThemeTween(end: target),
      duration: KumoMotion.duration(context, widget.animationDuration),
      curve: KumoCurves.standard,
      builder: (context, data, child) => KumoTheme(
        data: data,
        child: DefaultTextStyle(style: data.text(), child: child!),
      ),
      child: widget.child,
    );
  }
}

class _KumoThemeTween extends Tween<KumoThemeData> {
  _KumoThemeTween({required KumoThemeData end}) : super(begin: end, end: end);

  @override
  KumoThemeData lerp(double t) => KumoThemeData.lerp(begin!, end!, t);
}
