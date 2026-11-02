import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

double _fill(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(
      find.descendant(of: find.byType(KumoMeterTrack), matching: find.byType(FractionallySizedBox)),
    )
    .widthFactor!;

Color _indicator(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(DecoratedBox)).first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  Widget meter(KumoMeter m) => Padding(padding: const EdgeInsets.all(16), child: m);

  testWidgets('shows the label and a percentage; an 8px track; light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, meter(const KumoMeter(label: 'Storage used', value: 65)), brightness: b);
      expect(find.text('Storage used'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(tester.getSize(find.byType(KumoMeterTrack)).height, 8);
      expect(_fill(tester), closeTo(0.65, 1e-9));
    }
  });

  testWidgets('customValue replaces the percentage; showValue false hides it', (tester) async {
    await pumpKumo(
      tester,
      meter(const KumoMeter(label: 'API requests', value: 750, max: 1000, customValue: '750 / 1,000')),
    );
    expect(find.text('750 / 1,000'), findsOneWidget);
    expect(find.text('75%'), findsNothing);
    await pumpKumo(tester, meter(const KumoMeter(label: 'Progress', value: 40, showValue: false)));
    expect(find.text('40%'), findsNothing);
  });

  testWidgets('clamps to min and max', (tester) async {
    await pumpKumo(tester, meter(const KumoMeter(label: 'Quota', value: 140)));
    expect(find.text('100%'), findsOneWidget);
    expect(_fill(tester), 1);
    await pumpKumo(tester, meter(const KumoMeter(label: 'Quota', value: -5)));
    expect(_fill(tester), 0);
  });

  testWidgets('a threshold switches the tone and writes the state out', (tester) async {
    const thresholds = [
      KumoMeterThreshold(value: 8, tone: KumoMeterTone.warning, label: 'Approaching the 10 GB limit'),
      KumoMeterThreshold(value: 10, tone: KumoMeterTone.danger, label: 'Limit reached. Uploads are paused'),
    ];
    final light = KumoThemeData.light().colors;
    await pumpKumo(tester, meter(const KumoMeter(label: 'R2 storage', value: 5, max: 10, thresholds: thresholds)));
    expect(_indicator(tester), light.brand);
    expect(find.text('Approaching the 10 GB limit'), findsNothing);

    await pumpKumo(tester, meter(const KumoMeter(label: 'R2 storage', value: 9, max: 10, thresholds: thresholds)));
    expect(_indicator(tester), light.warning);
    expect(find.text('Approaching the 10 GB limit'), findsOneWidget);
    expect(find.byIcon(KumoIcons.warning), findsOneWidget);

    await pumpKumo(tester, meter(const KumoMeter(label: 'R2 storage', value: 10, max: 10, thresholds: thresholds)));
    expect(_indicator(tester), light.danger);
    expect(find.text('Limit reached. Uploads are paused'), findsOneWidget);
    expect(find.text('Approaching the 10 GB limit'), findsNothing);
  });

  testWidgets('tone and indicatorColor override the brand fill', (tester) async {
    await pumpKumo(tester, meter(const KumoMeter(label: 'Upload', value: 80, tone: KumoMeterTone.success)));
    expect(_indicator(tester), KumoThemeData.light().colors.success);
    await pumpKumo(tester, meter(const KumoMeter(label: 'Upload', value: 80, indicatorColor: KumoColor.info)));
    expect(_indicator(tester), KumoThemeData.light().colors.info);
  });

  testWidgets('semantics: label, value and status', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      meter(
        const KumoMeter(
          label: 'R2 storage',
          value: 9,
          max: 10,
          customValue: '9 / 10 GB',
          thresholds: [KumoMeterThreshold(value: 8, tone: KumoMeterTone.warning, label: 'Approaching the limit')],
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(KumoMeter)),
      matchesSemantics(label: 'R2 storage', value: '9 / 10 GB, Approaching the limit'),
    );
    handle.dispose();
  });

  testWidgets('animates from its current value, and reverses mid-flight without a jump', (tester) async {
    Widget at(double v) => meter(KumoMeter(label: 'Memory usage', value: v));
    await pumpKumo(tester, at(20));
    expect(_fill(tester), closeTo(0.2, 1e-9));
    await pumpKumo(tester, at(80), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _fill(tester);
    expect(mid, inExclusiveRange(0.2, 0.8));
    await pumpKumo(tester, at(20), settle: false);
    await tester.pump();
    expect(_fill(tester), closeTo(mid, 0.02));
    await tester.pumpAndSettle();
    expect(_fill(tester), closeTo(0.2, 1e-9));
  });

  testWidgets('reduced motion jumps straight to the value', (tester) async {
    await pumpKumo(tester, meter(const KumoMeter(label: 'Memory', value: 20)), disableAnimations: true);
    await pumpKumo(tester, meter(const KumoMeter(label: 'Memory', value: 80)), disableAnimations: true, settle: false);
    await tester.pump();
    expect(_fill(tester), closeTo(0.8, 1e-9));
  });

  testWidgets('2x text at 390px and RTL do not overflow; RTL fills from the right', (tester) async {
    await pumpKumo(
      tester,
      meter(
        const KumoMeter(
          label: 'Workers KV reads this billing period',
          value: 9,
          max: 10,
          customValue: '9,000,000 / 10,000,000',
          thresholds: [
            KumoMeterThreshold(
              value: 8,
              tone: KumoMeterTone.warning,
              label: 'Reads above the included amount are billed',
            ),
          ],
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await pumpKumo(tester, meter(const KumoMeter(label: 'Storage', value: 25)), textDirection: TextDirection.rtl);
    final track = tester.getRect(find.byType(KumoMeterTrack));
    final fill = tester.getRect(
      find.descendant(of: find.byType(KumoMeterTrack), matching: find.byType(DecoratedBox)).first,
    );
    expect(fill.right, closeTo(track.right, 0.5));
  });

  testWidgets('crossing a threshold eases the tone; reduced motion swaps it at once', (tester) async {
    const thresholds = [KumoMeterThreshold(value: 8, tone: KumoMeterTone.warning, label: 'Approaching the limit')];
    final light = KumoThemeData.light().colors;
    await pumpKumo(tester, meter(const KumoMeter(label: 'R2 storage', value: 5, max: 10, thresholds: thresholds)));
    await pumpKumo(
      tester,
      meter(const KumoMeter(label: 'R2 storage', value: 9, max: 10, thresholds: thresholds)),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 120));
    final mid = _indicator(tester);
    expect(mid, isNot(light.brand));
    expect(mid, isNot(light.warning));
    expect(_fill(tester), inExclusiveRange(0.5, 0.9));
    await tester.pumpAndSettle();
    expect(_indicator(tester), light.warning);

    await pumpKumo(
      tester,
      meter(const KumoMeter(label: 'R2 storage', value: 5, max: 10, thresholds: thresholds)),
      disableAnimations: true,
      settle: false,
    );
    await tester.pump();
    expect(_indicator(tester), light.brand);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
