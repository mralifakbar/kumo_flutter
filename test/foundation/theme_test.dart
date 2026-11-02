import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

void main() {
  test('generated schemes cover every token', () {
    for (final scheme in [
      KumoColorSchemes.light,
      KumoColorSchemes.dark,
      KumoColorSchemes.fedrampLight,
      KumoColorSchemes.fedrampDark,
    ]) {
      for (final token in KumoColor.values) {
        expect(scheme[token], isA<Color>());
      }
    }
  });

  test('values match Kumo CSS', () {
    expect(KumoColorSchemes.light.base, const Color(0xFFFFFFFF));
    expect(KumoColorSchemes.light.textBrand, const Color(0xFFF6821F));
    expect(KumoColorSchemes.light.badgeBlue, const Color(0xFF155DFC));
    expect(KumoColorSchemes.fedrampLight.canvas, const Color(0xFF5B697C));
    expect(KumoColorSchemes.fedrampDark.hairline, const Color(0xFFC8D4E5));
    expect(KumoColorSchemes.dark.textDefault, isNot(KumoColorSchemes.light.textDefault));
  });

  test('copyWith overrides one token', () {
    final custom = KumoColorSchemes.light.copyWith({KumoColor.brand: const Color(0xFF123456)});
    expect(custom.brand, const Color(0xFF123456));
    expect(custom.base, KumoColorSchemes.light.base);
  });

  test('lerp interpolates colors and switches discrete fields at the midpoint', () {
    final a = KumoThemeData.light();
    final b = KumoThemeData.dark();
    final mid = KumoThemeData.lerp(a, b, 0.25);
    expect(mid.brightness, Brightness.light);
    expect(KumoThemeData.lerp(a, b, 0.75).brightness, Brightness.dark);
    expect(mid.colors.base, Color.lerp(a.colors.base, b.colors.base, 0.25));
  });

  test('typography: content text is 14px, mono is 1px smaller, headings semibold', () {
    final t = KumoThemeData.light();
    expect(t.text().fontSize, 14);
    expect(t.text().fontFamily, 'packages/kumo_flutter/Inter');
    expect(t.code().fontSize, 13);
    expect(t.code(large: true).fontSize, 14);
    expect(t.heading().fontWeight, FontWeight.w600);
    expect(t.heading(size: KumoHeadingSize.lg).fontSize, 20);
  });

  test('tap target follows the setting', () {
    expect(KumoThemeData.light(tapTargetSize: KumoTapTargetSize.padded).minTapTarget, 44);
    expect(KumoThemeData.light(tapTargetSize: KumoTapTargetSize.shrinkWrap).minTapTarget, 0);
  });

  testWidgets('provider follows the platform brightness in system mode', (tester) async {
    late KumoThemeData seen;
    Widget app(Brightness platform) => MediaQuery(
      data: MediaQueryData(platformBrightness: platform),
      child: KumoThemeProvider(
        child: Builder(
          builder: (context) {
            seen = context.kumo;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(app(Brightness.light));
    expect(seen.brightness, Brightness.light);
    await tester.pumpWidget(app(Brightness.dark));
    await tester.pumpAndSettle();
    expect(seen.brightness, Brightness.dark);
    expect(seen.colors, KumoColorSchemes.dark);
  });

  testWidgets('provider cross-fades a mode change, instantly under reduced motion', (tester) async {
    late KumoThemeData seen;
    Widget app(KumoThemeMode mode, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: KumoThemeProvider(
        mode: mode,
        child: Builder(
          builder: (context) {
            seen = context.kumo;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(app(KumoThemeMode.light));
    await tester.pumpWidget(app(KumoThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 100));
    expect(seen.colors.base, isNot(KumoColorSchemes.dark.base));
    await tester.pumpAndSettle();
    expect(seen.colors.base, KumoColorSchemes.dark.base);

    await tester.pumpWidget(app(KumoThemeMode.light, reduce: true));
    await tester.pump();
    await tester.pump();
    expect(seen.colors.base, KumoColorSchemes.light.base);
  });

  testWidgets('fedramp variant recolors surfaces', (tester) async {
    late KumoThemeData seen;
    await tester.pumpWidget(
      KumoThemeProvider(
        mode: KumoThemeMode.light,
        variant: KumoThemeVariant.fedramp,
        child: Builder(
          builder: (context) {
            seen = context.kumo;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.colors.canvas, const Color(0xFF5B697C));
  });

  testWidgets('Material bridge maps Kumo tokens', (tester) async {
    final m = kumoMaterialTheme(KumoThemeData.light());
    expect(m.colorScheme.primary, KumoColorSchemes.light.brand);
    expect(m.scaffoldBackgroundColor, KumoColorSchemes.light.canvas);
    expect(m.splashFactory, NoSplash.splashFactory);
  });

  test('window size classes', () {
    expect(KumoWindowSize.of(390), KumoWindowSize.compact);
    expect(KumoWindowSize.of(800), KumoWindowSize.medium);
    expect(KumoWindowSize.of(1280), KumoWindowSize.expanded);
    expect(KumoRadius.concentric(12, 4), 8);
  });

  test('motion helpers', () {
    expect(KumoMotion.project(0), 0);
    expect(KumoMotion.project(1000), greaterThan(400));
    expect(KumoMotion.rubberband(100, 800), lessThan(100));
    expect(KumoMotion.rubberband(-100, 800), greaterThan(-100));
  });
}
