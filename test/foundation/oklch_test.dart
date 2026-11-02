import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

void main() {
  group('Oklch', () {
    test('converts Tailwind palette values to the hex Tailwind publishes', () {
      // Tailwind v4 publishes these sRGB fallbacks for its OKLCH palette.
      expect(const Oklch(0.546, 0.245, 262.881).toArgb(), 0xFF155DFC); // blue-600
      expect(const Oklch(0.577, 0.245, 27.325).toArgb(), 0xFFE7000B); // red-600
      expect(const Oklch(0.596, 0.145, 163.225).toArgb(), 0xFF009966); // emerald-600
      expect(const Oklch(0.21, 0.006, 285.885).toArgb(), 0xFF18181B); // zinc-900
    });

    test('white, black and alpha', () {
      expect(const Oklch(1, 0, 0).toArgb(), 0xFFFFFFFF);
      expect(const Oklch(0, 0, 0).toArgb(), 0xFF000000);
      expect(const Oklch(0, 0, 0, 0.12).toArgb() >> 24, 31);
    });

    test('round-trips sRGB colors', () {
      for (final argb in [0xFF056DFF, 0xFFF6821F, 0xFF737373, 0xFF5B697C]) {
        expect(Oklch.fromArgb(argb).toArgb(), argb);
      }
    });

    test('gamut maps out-of-range chroma instead of clipping hue', () {
      final vivid = const Oklch(0.7, 0.4, 145).toArgb();
      final g = (vivid >> 8) & 0xFF;
      final r = (vivid >> 16) & 0xFF;
      expect(g, greaterThan(r), reason: 'stays green');
    });

    test('color-mix in oklch keeps the colored side hue when mixing with black', () {
      final brand = Oklch.fromArgb(0xFF056DFF);
      final darker = brand.mix(const Oklch(0, 0, 0), 0.1);
      expect(darker.h, closeTo(brand.h, 0.001));
      expect(darker.l, closeTo(brand.l * 0.9, 0.0001));
    });
  });

  group('KumoColorUtils', () {
    test('contrast ratio matches WCAG reference values', () {
      expect(KumoColorUtils.contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
      expect(KumoColorUtils.contrastRatio(const Color(0xFF777777), const Color(0xFFFFFFFF)), closeTo(4.48, 0.01));
    });

    test('Kumo body text passes AA on every surface it sits on, in both modes', () {
      for (final scheme in [KumoColorSchemes.light, KumoColorSchemes.dark]) {
        for (final surface in [scheme.canvas, scheme.base, scheme.elevated, scheme.recessed]) {
          expect(KumoColorUtils.contrastRatio(scheme.textDefault, surface), greaterThanOrEqualTo(4.5));
          expect(KumoColorUtils.contrastRatio(scheme.textSubtle, surface), greaterThanOrEqualTo(4.0));
        }
      }
    });

    test('white button text on primary and destructive passes large-text contrast', () {
      for (final scheme in [KumoColorSchemes.light, KumoColorSchemes.dark]) {
        expect(KumoColorUtils.contrastRatio(const Color(0xFFFFFFFF), scheme.brand), greaterThanOrEqualTo(4.5));
        expect(KumoColorUtils.contrastRatio(const Color(0xFFFFFFFF), scheme.danger), greaterThanOrEqualTo(3));
      }
    });
  });
}
