import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget _list({
  bool loading = false,
  String? error,
  VoidCallback? onRetry,
  List<Widget>? children,
  Widget? empty,
  Widget? usage,
  Widget? additional,
}) {
  return KumoResourceList(
    title: 'KV namespaces',
    description: 'Store key-value data globally with low-latency access.',
    icon: KumoIcons.database,
    actions: [KumoButton(label: 'Create namespace', variant: KumoButtonVariant.primary, onPress: () {})],
    loading: loading,
    error: error,
    onRetry: onRetry,
    empty: empty,
    usage: usage,
    additionalContent: additional,
    children: children ?? const [],
  );
}

void main() {
  testWidgets('items show title, metadata and a status with icon and text', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        _list(children: const [
          KumoResourceListItem(
            title: 'production-kv',
            metadata: ['Created 2 days ago', '1,204 keys'],
            status: KumoResourceListStatus(label: 'Active', tone: KumoResourceListStatusTone.success),
          ),
          KumoResourceListItem(
            title: 'staging-kv',
            status: KumoResourceListStatus(label: 'Read only', tone: KumoResourceListStatusTone.warning),
          ),
        ]),
        brightness: b,
        size: kumoDesktopSize,
        center: false,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('production-kv'), findsOneWidget);
      expect(find.text('Created 2 days ago  ·  1,204 keys'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(KumoIcons.checkCircle), findsOneWidget);
      expect(find.byIcon(KumoIcons.warning), findsOneWidget);
    }
  });

  testWidgets('title is the level 1 heading; description shows from 768px', (tester) async {
    await pumpKumo(tester, _list(), size: kumoDesktopSize, center: false);
    final handle = tester.ensureSemantics();
    expect(tester.getSemantics(find.text('KV namespaces')), matchesSemantics(label: 'KV namespaces', isHeader: true));
    expect(find.text('Store key-value data globally with low-latency access.'), findsOneWidget);
    handle.dispose();
    await pumpKumo(tester, _list(), center: false);
    expect(find.text('Store key-value data globally with low-latency access.'), findsNothing);
  });

  testWidgets('card press and its actions are separate targets', (tester) async {
    final events = <String>[];
    await pumpKumo(
      tester,
      _list(children: [
        KumoResourceListItem(
          title: 'production-kv',
          onPress: () => events.add('open'),
          actions: [KumoButton(label: 'Rename', size: KumoButtonSize.sm, onPress: () => events.add('rename'))],
        ),
      ]),
      size: kumoDesktopSize,
      center: false,
    );
    await tester.tap(find.text('production-kv'));
    await tester.tap(find.text('Rename'));
    expect(events, ['open', 'rename']);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('production-kv'), findsWidgets);
    expect(find.bySemanticsLabel('Rename'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('loading shows still placeholder cards announced as loading', (tester) async {
    await pumpKumo(tester, _list(loading: true, children: const [KumoResourceListItem(title: 'x')]), center: false);
    expect(find.text('x'), findsNothing);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    handle.dispose();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('error shows the message and a retry button', (tester) async {
    var retries = 0;
    await pumpKumo(
      tester,
      _list(error: 'Could not load namespaces. Check your connection.', onRetry: () => retries++),
      center: false,
    );
    expect(find.text('Could not load namespaces. Check your connection.'), findsOneWidget);
    expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('empty state: default copy and a custom one with an action', (tester) async {
    await pumpKumo(tester, _list(), center: false);
    expect(find.text('No resources yet'), findsOneWidget);
    var creates = 0;
    await pumpKumo(
      tester,
      _list(
        empty: KumoResourceListEmpty(
          title: 'No KV namespaces yet',
          description: 'Create a namespace to store key-value data.',
          action: KumoButton(label: 'Create namespace', onPress: () => creates++),
        ),
      ),
      center: false,
    );
    expect(find.text('No KV namespaces yet'), findsOneWidget);
    await tester.tap(find.text('Create namespace').last);
    expect(creates, 1);
  });

  testWidgets('aside sits beside the list from 1280px and above it below', (tester) async {
    Widget build() => _list(
          usage: const SizedBox(height: 80, child: Text('Usage example')),
          additional: const SizedBox(height: 40, child: Text('Learn more')),
          children: const [KumoResourceListItem(title: 'production-kv')],
        );
    await pumpKumo(tester, build(), size: const Size(1440, 900), center: false);
    final usage = tester.getRect(find.text('Usage example'));
    final item = tester.getRect(find.text('production-kv'));
    expect(usage.left, greaterThan(item.right));
    expect((usage.top - item.top).abs(), lessThan(24));

    await pumpKumo(tester, build(), center: false);
    expect(tester.getRect(find.text('Usage example')).bottom, lessThan(tester.getRect(find.text('production-kv')).top));
    expect(tester.getRect(find.text('Learn more')).top, greaterThan(tester.getRect(find.text('production-kv')).bottom));
  });

  testWidgets('narrow items put status and actions under the name', (tester) async {
    await pumpKumo(
      tester,
      _list(children: [
        KumoResourceListItem(
          title: 'production-kv',
          status: const KumoResourceListStatus(label: 'Active', tone: KumoResourceListStatusTone.success),
          actions: [KumoButton(label: 'View', size: KumoButtonSize.sm, onPress: () {})],
        ),
      ]),
      center: false,
    );
    expect(tester.getRect(find.text('Active')).top, greaterThan(tester.getRect(find.text('production-kv')).bottom));
  });

  testWidgets('390px with 2x text does not overflow in any state', (tester) async {
    for (final w in [
      _list(children: const [
        KumoResourceListItem(
          title: 'a-very-long-namespace-name-for-production-traffic',
          metadata: ['Created 2 days ago', '1,204 keys', 'Binding: CACHE'],
          status: KumoResourceListStatus(label: 'Active', tone: KumoResourceListStatusTone.success),
        ),
      ]),
      _list(loading: true),
      _list(error: 'Could not load namespaces.', onRetry: () {}),
      _list(),
    ]) {
      await pumpKumo(tester, w, textScale: 2, center: false);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('loading cross-fades to the loaded list', (tester) async {
    final items = [const KumoResourceListItem(key: ValueKey('a'), title: 'production-kv')];
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, _list(loading: true, children: items), size: kumoDesktopSize, center: false);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await tester.pumpWidget(kumoHarness(_list(children: items), size: kumoDesktopSize, center: false));
    await tester.pump(const Duration(milliseconds: 75));
    final card = find.text('production-kv');
    expect(card, findsOneWidget);
    final fades = tester.widgetList<FadeTransition>(find.ancestor(of: card, matching: find.byType(FadeTransition)));
    final opacity = fades.fold<double>(1, (o, f) => o * f.opacity.value);
    expect(opacity, inExclusiveRange(0, 1));
    expect(find.bySemanticsLabel('Loading'), findsNothing, reason: 'the outgoing state is hidden from screen readers');
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    handle.dispose();
  });

  testWidgets('a removed card collapses out and the next one slides up', (tester) async {
    List<Widget> items(List<String> names) => [
          for (final n in names) KumoResourceListItem(key: ValueKey(n), title: n),
        ];
    await pumpKumo(tester, _list(children: items(['alpha', 'beta', 'gamma'])), size: kumoDesktopSize, center: false);
    final start = tester.getRect(find.text('gamma')).top;
    final betaTop = tester.getRect(find.text('beta')).top;
    await tester.pumpWidget(kumoHarness(_list(children: items(['alpha', 'gamma'])), size: kumoDesktopSize, center: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('beta'), findsOneWidget, reason: 'still collapsing');
    final mid = tester.getRect(find.text('gamma')).top;
    await tester.pumpAndSettle();
    expect(find.text('beta'), findsNothing);
    final end = tester.getRect(find.text('gamma')).top;
    expect(end, closeTo(betaTop, 0.5), reason: 'gamma takes beta\'s place, gap included');
    expect(mid, inExclusiveRange(end, start));

    // A new card grows in.
    await tester.pumpWidget(
      kumoHarness(_list(children: items(['alpha', 'delta', 'gamma'])), size: kumoDesktopSize, center: false),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final growing = tester.getRect(find.text('gamma')).top;
    expect(growing, inExclusiveRange(end, start));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('gamma')).top, closeTo(start, 0.5));
  });

  testWidgets('reduced motion swaps states and removes cards in one frame', (tester) async {
    List<Widget> items(List<String> names) => [
          for (final n in names) KumoResourceListItem(key: ValueKey(n), title: n),
        ];
    await pumpKumo(tester, _list(loading: true), size: kumoDesktopSize, center: false, disableAnimations: true);
    await tester.pumpWidget(kumoHarness(
      _list(children: items(['alpha', 'beta'])),
      size: kumoDesktopSize,
      center: false,
      disableAnimations: true,
    ));
    await tester.pump();
    expect(find.text('alpha'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(kumoHarness(
      _list(children: items(['alpha'])),
      size: kumoDesktopSize,
      center: false,
      disableAnimations: true,
    ));
    await tester.pump();
    expect(find.text('beta'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
