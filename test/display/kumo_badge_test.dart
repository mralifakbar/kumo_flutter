import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Finder _dots() =>
    find.byWidgetPredicate((w) => w is Container && w.constraints == BoxConstraints.tight(const Size(7, 7)));

double _minFade(WidgetTester tester, Finder f) => tester
    .widgetList<FadeTransition>(find.ancestor(of: f, matching: find.byType(FadeTransition)))
    .map((t) => t.opacity.value)
    .fold(1.0, (a, b) => a < b ? a : b);

void main() {
  testWidgets('renders every variant, appearance and size in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in KumoBadgeVariant.values)
              for (final a in KumoBadgeAppearance.values)
                for (final s in KumoBadgeSize.values) KumoBadge(v.name, variant: v, appearance: a, size: s),
          ],
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('base badge is 20px tall (py-0.5 around a 16px line); bordered ones add 1px per side', (tester) async {
    await pumpKumo(tester, const KumoBadge('New'));
    expect(tester.getSize(find.byType(KumoBadge)).height, 20);
    await pumpKumo(tester, const KumoBadge('Changelog', variant: KumoBadgeVariant.outline));
    expect(tester.getSize(find.byType(KumoBadge)).height, 22);
    await pumpKumo(tester, const KumoBadge('Beta', variant: KumoBadgeVariant.beta));
    expect(tester.getSize(find.byType(KumoBadge)).height, 22);
    await pumpKumo(tester, const KumoBadge('Beta', size: KumoBadgeSize.lg));
    expect(tester.getSize(find.byType(KumoBadge)).height, greaterThan(22));
  });

  testWidgets('dot appearance shows a dot only for success, warning, error and neutral', (tester) async {
    for (final v in KumoBadgeVariant.values) {
      await pumpKumo(tester, KumoBadge(v.name, variant: v, appearance: KumoBadgeAppearance.dot));
      final expected = {
        KumoBadgeVariant.success,
        KumoBadgeVariant.warning,
        KumoBadgeVariant.error,
        KumoBadgeVariant.neutral,
      }.contains(v);
      expect(_dots(), expected ? findsOneWidget : findsNothing, reason: v.name);
    }
    await pumpKumo(tester, const KumoBadge('Healthy', variant: KumoBadgeVariant.success));
    expect(_dots(), findsNothing);
  });

  testWidgets('dot colors match Kumo', (tester) async {
    expect(KumoBadgeVariant.success.dotColor, KumoColor.success);
    expect(KumoBadgeVariant.warning.dotColor, KumoColor.badgeOrange);
    expect(KumoBadgeVariant.error.dotColor, KumoColor.badgeRed);
    expect(KumoBadgeVariant.neutral.dotColor, KumoColor.badgeNeutral);
    expect(KumoBadgeVariant.primary.dotColor, isNull);
  });

  test('inverted and neutralSubtle are the primary and secondary badges', () {
    expect(KumoBadgeVariant.inverted, KumoBadgeVariant.primary);
    expect(KumoBadgeVariant.neutralSubtle, KumoBadgeVariant.secondary);
  });

  group('contrast', () {
    // Kumo pairs these at 12px with less than 4.5:1 in light mode. They pass
    // 3:1 and are kept for parity; the doc page lists them.
    const lightExceptions = {KumoBadgeVariant.warning, KumoBadgeVariant.green};

    for (final dark in [false, true]) {
      test('every filled pair in ${dark ? 'dark' : 'light'} mode', () {
        final theme = dark ? KumoThemeData.dark() : KumoThemeData.light();
        final c = theme.colors;
        for (final v in KumoBadgeVariant.values) {
          final colors = KumoBadgeColors.resolve(theme, v);
          // Tints are translucent: measure them over every surface a badge sits on.
          for (final surface in [c.base, c.canvas, c.elevated, c.control]) {
            final ratio = KumoColorUtils.contrastRatio(
              colors.foreground,
              KumoColorUtils.over(colors.background, surface),
            );
            final min = !dark && lightExceptions.contains(v) ? 3.5 : 4.5;
            expect(ratio, greaterThanOrEqualTo(min), reason: '${v.name} on $surface: ${ratio.toStringAsFixed(2)}');
          }
        }
      });

      test('dot badge text in ${dark ? 'dark' : 'light'} mode', () {
        final theme = dark ? KumoThemeData.dark() : KumoThemeData.light();
        expect(KumoColorUtils.contrastRatio(theme.colors.textDefault, theme.colors.base), greaterThanOrEqualTo(4.5));
      });
    }

    test('the light exceptions really are below 4.5, so the list stays honest', () {
      final theme = KumoThemeData.light();
      for (final v in lightExceptions) {
        final colors = KumoBadgeColors.resolve(theme, v);
        final ratio = KumoColorUtils.contrastRatio(
          colors.foreground,
          KumoColorUtils.over(colors.background, theme.colors.base),
        );
        expect(ratio, lessThan(4.5), reason: v.name);
      }
    });
  });

  testWidgets('icon sits before the label with Kumo\'s pl-1.5 inset', (tester) async {
    await pumpKumo(
      tester,
      const KumoBadge('Verified', variant: KumoBadgeVariant.success, icon: KumoIcons.checkCircle),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    final badge = tester.getRect(find.byType(KumoBadge));
    final icon = tester.getRect(find.byType(KumoIcon));
    expect(icon.left - badge.left, 6);
    expect(icon.width, 12);
    expect(icon.right, lessThan(tester.getRect(find.text('Verified')).left));
  });

  testWidgets('RTL mirrors the icon to the right', (tester) async {
    await pumpKumo(
      tester,
      const KumoBadge('Verified', variant: KumoBadgeVariant.success, icon: KumoIcons.checkCircle),
      textDirection: TextDirection.rtl,
    );
    expect(tester.getCenter(find.byType(KumoIcon)).dx, greaterThan(tester.getCenter(find.text('Verified')).dx));
  });

  testWidgets('static badges read as text; semanticLabel replaces it', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      const KumoBadge('Healthy', variant: KumoBadgeVariant.success, appearance: KumoBadgeAppearance.dot),
    );
    expect(find.bySemanticsLabel('Healthy'), findsOneWidget);
    await pumpKumo(tester, const KumoBadge('Healthy', semanticLabel: 'Status: healthy'));
    expect(tester.getSemantics(find.byType(KumoBadge)), matchesSemantics(label: 'Status: healthy'));
    handle.dispose();
  });

  testWidgets('pressable badge fires, is a link when asked, and rings on hover', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpKumo(
      tester,
      KumoBadge('View changelog', variant: KumoBadgeVariant.outline, isLink: true, onPress: () => taps++),
      size: kumoDesktopSize,
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    await tester.tap(find.text('View changelog'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(KumoPressable)),
      containsSemantics(label: 'View changelog', isLink: true, isButton: false, hasTapAction: true),
    );

    Border? ringOf() {
      final box = tester.widget<Container>(
        find.descendant(of: find.byType(KumoBadge), matching: find.byType(Container)).first,
      );
      return (box.foregroundDecoration as BoxDecoration?)?.border as Border?;
    }

    expect(ringOf(), isNull);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(KumoBadge)));
    await tester.pump();
    expect(ringOf()?.top.color, KumoThemeData.light().colors.textDefault);
    await mouse.removePointer();
    handle.dispose();
  });

  testWidgets('a long label ellipsizes instead of overflowing; 2x text grows the badge', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 120,
        child: Align(alignment: Alignment.centerLeft, child: KumoBadge('Rate limited by zone example.com')),
      ),
    );
    expect(tester.takeException(), isNull);
    await pumpKumo(tester, const KumoBadge('Healthy'), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(KumoBadge)).height, greaterThan(30));
  });

  testWidgets('a new status cross-fades the pill and eases its width', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoBadge('Deploying', variant: KumoBadgeVariant.info));
    final before = tester.getSize(find.byType(KumoBadge)).width;
    await pumpKumo(tester, const KumoBadge('Active', variant: KumoBadgeVariant.success), settle: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(_minFade(tester, find.text('Active')), inExclusiveRange(0, 1));
    expect(_minFade(tester, find.text('Deploying')), inExclusiveRange(0, 1));
    expect(find.semantics.byLabel('Deploying'), findsNothing, reason: 'the old status is not read');
    expect(find.semantics.byLabel('Active'), findsOne);
    final mid = tester.getSize(find.byType(KumoBadge)).width;
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byType(KumoBadge)).width;
    expect(mid, inExclusiveRange(after, before));
    expect(find.text('Deploying'), findsNothing);
    handle.dispose();
  });

  testWidgets('reduced motion: a new status lands in one frame', (tester) async {
    await pumpKumo(tester, const KumoBadge('Deploying', variant: KumoBadgeVariant.info), disableAnimations: true);
    await pumpKumo(
      tester,
      const KumoBadge('Active', variant: KumoBadgeVariant.success),
      disableAnimations: true,
      settle: false,
    );
    await tester.pump();
    expect(find.text('Deploying'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
