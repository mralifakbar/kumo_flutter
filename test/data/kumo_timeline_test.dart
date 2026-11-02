import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _items = [
  KumoTimelineItem(
    title: 'Deploying version 8f2c1a0',
    time: 'Now',
    status: KumoTimelineStatus.active,
    statusLabel: 'In progress',
  ),
  KumoTimelineItem(
    title: 'Deployed to production',
    time: '2 min ago',
    description: 'image-resizer, 100% of traffic',
    status: KumoTimelineStatus.success,
    statusLabel: 'Succeeded',
  ),
  KumoTimelineItem(
    title: 'Build failed',
    time: '1 h ago',
    description: 'wrangler.toml: missing compatibility_date',
    status: KumoTimelineStatus.danger,
    statusLabel: 'Failed',
  ),
];

void main() {
  testWidgets('renders every status in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: KumoTimeline(items: [
            for (final s in KumoTimelineStatus.values) KumoTimelineItem(title: s.name, status: s, time: '1 min ago'),
          ]),
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('each status has a distinct icon, so color is never the only cue', (tester) async {
    final icons = KumoTimelineStatus.values.map((s) => s.icon).toSet();
    expect(icons, hasLength(KumoTimelineStatus.values.length));
    await pumpKumo(tester, const KumoTimeline(items: _items));
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    expect(find.byIcon(KumoIcons.x), findsOneWidget);
    expect(find.byIcon(KumoIcons.hourglassMedium), findsOneWidget);
  });

  testWidgets('screen readers hear status, title, time and description as one item', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoTimeline(items: _items, semanticLabel: 'Deployment history'));
    final node = tester.getSemantics(find.text('Build failed'));
    expect(node.label, contains('Failed'));
    expect(node.label, contains('Build failed'));
    expect(node.label, contains('1 h ago'));
    expect(node.label, contains('missing compatibility_date'));
    expect(find.bySemanticsLabel('Deployment history'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the rail connects items and stops at the last one', (tester) async {
    await pumpKumo(tester, const SizedBox(width: 360, child: KumoTimeline(items: _items)));
    final line = KumoThemeData.light().colors.line;
    final rails = tester.widgetList<ColoredBox>(find.byType(ColoredBox)).where((c) => c.color == line);
    expect(rails, hasLength(_items.length - 1));
  });

  testWidgets('pressable items fire onPress', (tester) async {
    var pressed = 0;
    await pumpKumo(
      tester,
      KumoTimeline(items: [
        KumoTimelineItem(title: 'Deployed to production', onPress: () => pressed++, semanticLabel: 'Open deployment'),
      ]),
    );
    await tester.tap(find.text('Deployed to production'));
    expect(pressed, 1);
  });

  testWidgets('custom content and trailing widgets render', (tester) async {
    await pumpKumo(
      tester,
      const KumoTimeline(items: [
        KumoTimelineItem(title: 'Rolled back', content: Text('Reverted to 7d1e9b3'), trailing: Text('Undo')),
      ]),
    );
    expect(find.text('Reverted to 7d1e9b3'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('2x text at 390px in RTL does not overflow', (tester) async {
    await pumpKumo(
      tester,
      const Padding(padding: EdgeInsets.all(16), child: KumoTimeline(items: _items)),
      textScale: 2,
      textDirection: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    final marker = tester.getCenter(find.byIcon(KumoIcons.check));
    expect(marker.dx, greaterThan(tester.getCenter(find.text('Deployed to production')).dx));
  });

  testWidgets('an empty list renders nothing', (tester) async {
    await pumpKumo(tester, const KumoTimeline(items: []));
    expect(tester.getSize(find.byType(KumoTimeline)).height, 0);
  });

  testWidgets('a status change cross-fades the marker icon', (tester) async {
    final handle = tester.ensureSemantics();
    KumoTimeline timeline(KumoTimelineStatus status) => KumoTimeline(items: [
          KumoTimelineItem(id: 'deploy', title: 'Deploying', status: status, statusLabel: status.name),
        ]);
    await pumpKumo(tester, timeline(KumoTimelineStatus.active));
    await pumpKumo(tester, timeline(KumoTimelineStatus.success), settle: false);
    await tester.pump(const Duration(milliseconds: 60));
    double fadeOf(IconData icon) => tester
        .widget<FadeTransition>(find.ancestor(of: find.byIcon(icon), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(fadeOf(KumoIcons.check), inExclusiveRange(0, 1));
    expect(fadeOf(KumoIcons.hourglassMedium), inExclusiveRange(0, 1));
    expect(find.semantics.byLabel(RegExp('active')), findsNothing, reason: 'the outgoing status is not read');
    expect(find.semantics.byLabel(RegExp('success')), findsOne);
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.hourglassMedium), findsNothing);
    handle.dispose();
  });

  testWidgets('an event added later slides open and fades in; first ones do not', (tester) async {
    const first = KumoTimelineItem(id: 'b', title: 'Build finished', status: KumoTimelineStatus.success);
    await pumpKumo(tester, const KumoTimeline(items: [first]));
    expect(find.byType(SizeTransition), findsNothing);
    await pumpKumo(
      tester,
      const KumoTimeline(items: [KumoTimelineItem(id: 'a', title: 'Deploying', status: KumoTimelineStatus.active), first]),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    final size = tester.widget<SizeTransition>(find.byType(SizeTransition)).sizeFactor.value;
    expect(size, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(tester.widget<SizeTransition>(find.byType(SizeTransition)).sizeFactor.value, 1);
  });

  testWidgets('reduced motion: new events and status changes land at once', (tester) async {
    const first = KumoTimelineItem(id: 'b', title: 'Build finished', status: KumoTimelineStatus.success);
    await pumpKumo(tester, const KumoTimeline(items: [first]), disableAnimations: true);
    await pumpKumo(
      tester,
      const KumoTimeline(items: [KumoTimelineItem(id: 'a', title: 'Deploying', status: KumoTimelineStatus.danger), first]),
      disableAnimations: true,
      settle: false,
    );
    await tester.pump();
    expect(tester.widget<SizeTransition>(find.byType(SizeTransition)).sizeFactor.value, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
