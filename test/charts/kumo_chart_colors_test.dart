import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  test('categorical colors follow Kumo order and wrap after six', () {
    const p = KumoChartColors.light;
    expect(p.categorical(0), const Color(0xFF4290F0));
    expect(p.categorical(1), const Color(0xFFF5B647));
    expect(p.categorical(5), const Color(0xFFD37536));
    expect(p.categorical(6), p.categorical(0));
    expect(KumoChartColors.dark.categorical(1), const Color(0xFFEEB720));
  });

  test('semantic colors differ by mode where Kumo tunes them', () {
    for (final name in KumoChartSemanticColor.values) {
      expect(KumoChartColors.light.semantic(name), isA<Color>());
    }
    expect(KumoChartColors.light.semantic(KumoChartSemanticColor.attention), const Color(0xFFFC574A));
    expect(KumoChartColors.light.semantic(KumoChartSemanticColor.neutral), const Color(0xFFB9D6FF));
    expect(KumoChartColors.dark.semantic(KumoChartSemanticColor.neutral), const Color(0xFF8EC5FF));
    expect(KumoChartColors.dark.semantic(KumoChartSemanticColor.skeleton), const Color(0xFF5C5C5C));
  });

  test('sequential scale reverses in dark mode around the same base', () {
    final light = KumoChartColors.light.sequential();
    final dark = KumoChartColors.dark.sequential(KumoChartSequentialPalette.blues);
    expect(light, hasLength(5));
    expect(light[2], dark[2]);
    expect(light.first, dark.last);
    expect(() => light.add(const Color(0xFF000000)), throwsUnsupportedError);
  });

  test('map colors keep the low end distinct from the no-data fill', () {
    for (final p in [KumoChartColors.light, KumoChartColors.dark]) {
      expect(p.map.scale, hasLength(5));
      expect(p.map.scale.first, isNot(p.map.area));
      expect(p.map.bubble, p.categorical(0));
    }
  });

  testWidgets('of(context) follows the theme mode', (tester) async {
    for (final b in Brightness.values) {
      late KumoChartColors palette;
      await pumpKumo(
        tester,
        Builder(
          builder: (context) {
            palette = KumoChartColors.of(context);
            return const SizedBox();
          },
        ),
        brightness: b,
      );
      expect(palette.brightness, b);
      expect(identical(palette, KumoChartColors.forBrightness(b)), isTrue);
    }
  });
}
