import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget _padded(Widget child, {double width = 358}) => SizedBox(width: width, child: child);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders every variant and size in ${brightness.name} mode', (tester) async {
      await pumpKumo(
        tester,
        _padded(
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              for (final size in KumoBannerSize.values)
                for (final variant in KumoBannerVariant.values)
                  KumoBanner(
                    variant: variant,
                    size: size,
                    icon: KumoIcons.infoFill,
                    title: '${variant.name} ${size.name}',
                    description: 'Sample description',
                  ),
            ],
          ),
        ),
        brightness: brightness,
      );
      expect(find.text('alert sm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uses the variant tint and text color', (tester) async {
    await pumpKumo(
      tester,
      _padded(const KumoBanner(variant: KumoBannerVariant.error, title: 'Save failed', description: 'Try again.')),
    );
    final kumo = KumoThemeData.light();
    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('Save failed'), matching: find.byType(DecoratedBox)).first,
    );
    expect((box.decoration as BoxDecoration).color, kumo.colors.dangerTint);
    expect(tester.widget<Text>(find.text('Save failed')).style!.color, kumo.colors.textDanger);
    expect(tester.widget<Text>(find.text('Save failed')).style!.fontWeight, FontWeight.w500);
  });

  testWidgets('actions fire and disabled actions do not', (tester) async {
    var retries = 0;
    var billing = 0;
    await pumpKumo(
      tester,
      _padded(
        KumoBanner(
          variant: KumoBannerVariant.error,
          title: 'Payment failed',
          actions: [
            KumoBannerAction(label: 'Retry', onPress: () => retries++),
            KumoBannerAction(
              label: 'Go to billing',
              variant: KumoBannerActionVariant.secondary,
              disabled: true,
              onPress: () => billing++,
            ),
          ],
        ),
        width: 600,
      ),
      size: kumoDesktopSize,
    );
    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Go to billing'), warnIfMissed: false);
    expect(retries, 1);
    expect(billing, 0);
  });

  testWidgets('onDismiss adds a labeled X', (tester) async {
    final semantics = tester.ensureSemantics();
    var dismissed = false;
    await pumpKumo(
      tester,
      _padded(KumoBanner(title: 'Update available', onDismiss: () => dismissed = true)),
    );
    expect(tester.getSemantics(find.bySemanticsLabel('Dismiss')), matchesSemantics(
      label: 'Dismiss',
      isButton: true,
      isEnabled: true,
      hasEnabledState: true,
      isFocusable: true,
      hasTapAction: true,
      hasFocusAction: true,
    ));
    await tester.tap(find.byIcon(KumoIcons.x));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue, reason: 'runs once the banner has collapsed');
    semantics.dispose();
  });

  testWidgets('actions sit beside the text when wide and under it when narrow', (tester) async {
    Widget banner(double width) => _padded(
          KumoBanner(
            title: 'Session expiring',
            description: 'Your session ends in 5 minutes.',
            actions: [KumoBannerAction(label: 'Extend', onPress: () {})],
          ),
          width: width,
        );
    await pumpKumo(tester, banner(600), size: kumoDesktopSize);
    expect(tester.getCenter(find.text('Extend')).dx, greaterThan(tester.getRect(find.text('Session expiring')).right));

    await pumpKumo(tester, banner(320));
    expect(tester.getTopLeft(find.text('Extend')).dy, greaterThan(tester.getBottomLeft(find.text('Session expiring')).dy));
  });

  testWidgets('actions take the banner size', (tester) async {
    await pumpKumo(
      tester,
      _padded(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KumoBanner(title: 'Base', actions: [KumoBannerAction(label: 'Base action', onPress: () {})]),
            KumoBanner(
              title: 'Compact',
              size: KumoBannerSize.sm,
              actions: [KumoBannerAction(label: 'Compact action', onPress: () {})],
            ),
          ],
        ),
        width: 600,
      ),
      size: kumoDesktopSize,
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    double height(String label) =>
        tester.getSize(find.ancestor(of: find.text(label), matching: find.byType(Container)).first).height;
    expect(height('Base action'), KumoButtonSize.sm.height);
    expect(height('Compact action'), KumoButtonSize.xs.height);
  });

  testWidgets('touch hit areas are at least 44px', (tester) async {
    await pumpKumo(
      tester,
      _padded(KumoBanner(title: 'Update available', onDismiss: () {}), width: 358),
    );
    final size = tester.getSize(find.ancestor(of: find.byIcon(KumoIcons.x), matching: find.byType(KumoPressable)));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('an error banner is a live region', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpKumo(tester, _padded(const KumoBanner(variant: KumoBannerVariant.error, title: 'Save failed')));
    final region = find.ancestor(
      of: find.text('Save failed'),
      matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true),
    );
    expect(region, findsOneWidget);
    semantics.dispose();
  });

  testWidgets('custom description content inherits the banner color', (tester) async {
    await pumpKumo(
      tester,
      _padded(const KumoBanner(variant: KumoBannerVariant.alert, title: 'Review required', child: Text('Custom body'))),
    );
    final style = DefaultTextStyle.of(tester.element(find.text('Custom body'))).style;
    expect(style.color, KumoThemeData.light().colors.textWarning);
  });

  testWidgets('2x text at 390px and RTL do not overflow', (tester) async {
    await pumpKumo(
      tester,
      _padded(
        KumoBanner(
          icon: KumoIcons.warningFill,
          variant: KumoBannerVariant.alert,
          title: 'SSL certificate expires in 6 days',
          description: 'Renew it to keep serving example.com over HTTPS.',
          actions: [KumoBannerAction(label: 'Renew certificate', onPress: () {})],
          onDismiss: () {},
        ),
      ),
      textScale: 2,
      textDirection: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getCenter(find.byIcon(KumoIcons.warningFill)).dx, greaterThan(tester.getCenter(find.text('SSL certificate expires in 6 days')).dx));
  });

  group('motion', () {
    Widget column(Widget banner) => _padded(
          Column(mainAxisSize: MainAxisSize.min, children: [banner, const Text('Below the banner')]),
        );

    testWidgets('dismiss collapses the banner so the content below slides up', (tester) async {
      var dismissed = false;
      await pumpKumo(tester, column(KumoBanner(title: 'Update available', onDismiss: () => dismissed = true)));
      final full = tester.getSize(find.byType(KumoBanner)).height;
      final belowAtRest = tester.getTopLeft(find.text('Below the banner')).dy;
      await tester.tap(find.byIcon(KumoIcons.x));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getSize(find.byType(KumoBanner)).height;
      expect(mid, greaterThan(0));
      expect(mid, lessThan(full));
      final belowMid = tester.getTopLeft(find.text('Below the banner')).dy;
      expect(belowMid, lessThan(belowAtRest));
      expect(dismissed, isFalse, reason: 'the parent hears about it once the banner is gone');
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
      expect(tester.getSize(find.byType(KumoBanner)).height, 0);
    });

    testWidgets('open drives expand and collapse, reversing mid-flight', (tester) async {
      Widget build(bool open) => column(KumoBanner(title: 'Maintenance tonight', open: open));
      await pumpKumo(tester, build(true));
      final full = tester.getSize(find.byType(KumoBanner)).height;
      await tester.pumpWidget(kumoHarness(build(false)));
      await tester.pump(const Duration(milliseconds: 100));
      final collapsing = tester.getSize(find.byType(KumoBanner)).height;
      expect(collapsing, greaterThan(0));
      expect(collapsing, lessThan(full));
      await tester.pumpWidget(kumoHarness(build(true)));
      await tester.pump(const Duration(milliseconds: 16));
      final reopening = tester.getSize(find.byType(KumoBanner)).height;
      expect(reopening, greaterThan(collapsing * 0.8), reason: 'turns around from its current height');
      expect(reopening, lessThan(full));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(KumoBanner)).height, full);
    });

    testWidgets('reduced motion: dismiss removes the banner at once', (tester) async {
      var dismissed = false;
      await pumpKumo(
        tester,
        column(KumoBanner(title: 'Update available', onDismiss: () => dismissed = true)),
        disableAnimations: true,
      );
      await tester.tap(find.byIcon(KumoIcons.x));
      await tester.pump();
      expect(dismissed, isTrue);
      expect(tester.getSize(find.byType(KumoBanner)).height, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
