import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('KumoText variants resolve Kumo styles', (tester) async {
    await pumpKumo(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KumoText('Body'),
          KumoText('Muted', variant: KumoTextVariant.secondary),
          KumoText('Title', variant: KumoTextVariant.heading, size: KumoTextSize.lg, headingLevel: 1),
          KumoText('code', variant: KumoTextVariant.mono),
          KumoText('Strong', bold: true),
        ],
      ),
    );
    TextStyle style(String t) => tester.widget<Text>(find.text(t)).style!;
    expect(style('Body').fontSize, 14);
    expect(style('Muted').color, KumoColorSchemes.light.textSubtle);
    expect(style('Title').fontSize, 20);
    expect(style('Title').fontWeight, FontWeight.w600);
    expect(style('code').fontFamily, 'packages/kumo_flutter/JetBrainsMono');
    expect(style('Strong').fontWeight, FontWeight.w500);
  });

  testWidgets('heading level is exposed to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoText('Workers', variant: KumoTextVariant.heading, headingLevel: 2));
    expect(tester.getSemantics(find.text('Workers')).getSemanticsData().flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('truncate ellipsizes to one line', (tester) async {
    await pumpKumo(tester, const SizedBox(width: 60, child: KumoText('A long resource name here', truncate: true)));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('KumoIcon is decorative unless labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoIcon(KumoIcons.gear));
    expect(find.bySemanticsLabel('Settings'), findsNothing);
    await pumpKumo(tester, const KumoIcon(KumoIcons.gear, semanticLabel: 'Settings'));
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    expect(tester.widget<Icon>(find.byType(Icon)).size, 16);
    handle.dispose();
  });

  test('icon constants use the bundled fonts', () {
    expect(KumoIcons.caretDown.fontFamily, 'Phosphor');
    expect(KumoIcons.caretDown.fontPackage, 'kumo_flutter');
    expect(KumoIcons.starFill.fontFamily, 'PhosphorFill');
  });

  testWidgets('loader announces and stops under reduced motion', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoLoader(), settle: false);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
    await pumpKumo(tester, const KumoLoader(), disableAnimations: true);
    expect(tester.hasRunningAnimations, isFalse);
    handle.dispose();
  });

  testWidgets('loader reads its default name from KumoStrings', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      const KumoLocale(
        strings: KumoStrings(loading: 'Memuat'),
        child: KumoLoader(),
      ),
      disableAnimations: true,
    );
    expect(find.bySemanticsLabel('Memuat'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('loader sizes', (tester) async {
    for (final s in KumoLoaderSize.values) {
      await pumpKumo(tester, KumoLoader(size: s), settle: false);
      expect(tester.getSize(find.byType(KumoLoader)), Size.square(s.dimension));
    }
  });

  testWidgets('layer card plain, layered and pressable', (tester) async {
    var taps = 0;
    await pumpKumo(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KumoLayerCard(child: Text('Plain')),
          const KumoLayerCard.layered(
            children: [
              KumoLayerCardSecondary(child: Text('Header')),
              KumoLayerCardPrimary(child: Text('Content')),
            ],
          ),
          KumoLayerCard(onPress: () => taps++, semanticLabel: 'Open Worker', child: const Text('Pressable')),
        ],
      ),
    );
    expect(find.text('Header'), findsOneWidget);
    await tester.tap(find.text('Pressable'));
    expect(taps, 1);
  });

  testWidgets('focus trap cycles Tab and restores focus', (tester) async {
    await pumpKumo(
      tester,
      KumoFocusTrap(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KumoButton(label: 'One', onPress: () {}),
            KumoButton(label: 'Two', onPress: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip can be controlled from outside', (tester) async {
    await pumpKumo(tester, const KumoTooltip(content: 'Status: healthy', open: true, child: Text('bar')));
    expect(find.text('Status: healthy'), findsOneWidget);
    await pumpKumo(tester, const KumoTooltip(content: 'Status: healthy', open: false, child: Text('bar')));
    expect(find.text('Status: healthy'), findsNothing);
  });
}
