import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

double _minFade(WidgetTester tester, Finder f) => tester
    .widgetList<FadeTransition>(find.ancestor(of: f, matching: find.byType(FadeTransition)))
    .map((t) => t.opacity.value)
    .fold(1.0, (a, b) => a < b ? a : b);

void main() {
  Widget pad(Widget child) => Padding(padding: const EdgeInsets.all(16), child: child);

  testWidgets('every variant, size and state renders in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final v in KumoProgressVariant.values)
                for (final s in KumoProgressSize.values) ...[
                  KumoProgress(variant: v, size: s, value: 40, label: 'Uploading assets', showValue: true),
                  KumoProgress(variant: v, size: s),
                ],
            ],
          ),
        ),
        brightness: b,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('track heights follow the size', (tester) async {
    for (final s in KumoProgressSize.values) {
      await pumpKumo(tester, pad(KumoProgress(value: 50, size: s)));
      expect(tester.getSize(find.byType(KumoMeterTrack)).height, s.trackHeight);
    }
    await pumpKumo(
      tester,
      const KumoProgress(value: 50, variant: KumoProgressVariant.circular, size: KumoProgressSize.lg),
    );
    expect(tester.getSize(find.byType(CustomPaint).last), const Size(40, 40));
  });

  testWidgets('determinate semantics carry the percentage', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, pad(const KumoProgress(value: 42, label: 'Uploading assets', showValue: true)));
    expect(find.text('42%'), findsOneWidget);
    expect(tester.getSemantics(find.byType(KumoProgress)), matchesSemantics(label: 'Uploading assets', value: '42%'));
    await pumpKumo(tester, pad(const KumoProgress(value: 3, max: 4, semanticLabel: 'Migrating tables')));
    expect(tester.getSemantics(find.byType(KumoProgress)), matchesSemantics(label: 'Migrating tables', value: '75%'));
    handle.dispose();
  });

  testWidgets('indeterminate loops while mounted and stops when a value arrives', (tester) async {
    await pumpKumo(tester, pad(const KumoProgress(label: 'Provisioning database')), settle: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.hasRunningAnimations, isTrue);
    final handle = tester.ensureSemantics();
    expect(tester.getSemantics(find.byType(KumoProgress)), matchesSemantics(label: 'Provisioning database'));
    handle.dispose();
    await pumpKumo(tester, pad(const KumoProgress(label: 'Provisioning database', value: 100)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('indeterminate stands still under reduced motion and off screen', (tester) async {
    for (final v in KumoProgressVariant.values) {
      await pumpKumo(tester, pad(KumoProgress(variant: v)), disableAnimations: true);
      expect(tester.hasRunningAnimations, isFalse, reason: v.name);
      await pumpKumo(tester, pad(TickerMode(enabled: false, child: KumoProgress(variant: v))), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse, reason: '${v.name} TickerMode');
    }
  });

  testWidgets('default accessible name is the localized loading string', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, pad(const KumoProgress(value: 10)));
    expect(tester.getSemantics(find.byType(KumoProgress)), matchesSemantics(label: 'Loading', value: '10%'));
    handle.dispose();
  });

  testWidgets('value changes animate from the current value', (tester) async {
    double fill() => tester
        .widget<FractionallySizedBox>(
          find.descendant(of: find.byType(KumoMeterTrack), matching: find.byType(FractionallySizedBox)),
        )
        .widthFactor!;
    await pumpKumo(tester, pad(const KumoProgress(value: 10)));
    await pumpKumo(tester, pad(const KumoProgress(value: 90)), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(fill(), inExclusiveRange(0.1, 0.9));
    await tester.pumpAndSettle();
    expect(fill(), closeTo(0.9, 1e-9));
  });

  testWidgets('2x text at 390px and RTL do not overflow', (tester) async {
    await pumpKumo(
      tester,
      pad(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KumoProgress(value: 64, label: 'Uploading 1,204 objects to the assets bucket', showValue: true),
            KumoProgress(
              value: 64,
              variant: KumoProgressVariant.circular,
              label: 'Building image-resizer',
              showValue: true,
            ),
          ],
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await pumpKumo(tester, pad(const KumoProgress()), textDirection: TextDirection.rtl, settle: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('indeterminate to measured cross-fades', (tester) async {
    Widget progress(double? value) => SizedBox(
      width: 300,
      child: KumoProgress(value: value, label: 'Uploading assets'),
    );
    await pumpKumo(tester, progress(null), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    await pumpKumo(tester, progress(40), settle: false);
    await tester.pump(const Duration(milliseconds: 60));
    expect(_minFade(tester, find.byType(KumoMeterTrack)), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_minFade(tester, find.byType(KumoMeterTrack)), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion: measured progress replaces the loop at once', (tester) async {
    Widget progress(double? value) => SizedBox(
      width: 300,
      child: KumoProgress(value: value, label: 'Uploading assets'),
    );
    await pumpKumo(tester, progress(null), disableAnimations: true);
    await pumpKumo(tester, progress(40), disableAnimations: true, settle: false);
    await tester.pump();
    expect(_minFade(tester, find.byType(KumoMeterTrack)), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
