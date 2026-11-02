import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

List<KumoBreadcrumbsItem> _items(List<String> log) => [
  KumoBreadcrumbsItem(label: 'Account home', icon: KumoIcons.house, onPress: () => log.add('home')),
  KumoBreadcrumbsItem(label: 'example.com', onPress: () => log.add('zone')),
  KumoBreadcrumbsItem(label: 'DNS', onPress: () => log.add('dns')),
  KumoBreadcrumbsItem(label: 'Records', onPress: () => log.add('records')),
];

void main() {
  for (final b in Brightness.values) {
    for (final size in KumoBreadcrumbsSize.values) {
      testWidgets('renders $size in $b on desktop', (tester) async {
        await pumpKumo(
          tester,
          KumoBreadcrumbs(items: _items([]), current: 'api.example.com', size: size),
          brightness: b,
          size: kumoDesktopSize,
        );
        expect(find.text('Account home'), findsOneWidget);
        expect(find.text('api.example.com'), findsOneWidget);
        expect(tester.getSize(find.byType(KumoBreadcrumbs)).height, size.height < 44 ? 44 : size.height);
      });
    }
  }

  testWidgets('links navigate; current page is medium and not a link', (tester) async {
    final log = <String>[];
    await pumpKumo(
      tester,
      KumoBreadcrumbs(items: _items(log), current: 'api.example.com'),
      size: kumoDesktopSize,
    );
    await tester.tap(find.text('example.com'));
    expect(log, ['zone']);
    expect(tester.widget<Text>(find.text('api.example.com')).style!.fontWeight, KumoTypography.medium);
  });

  testWidgets('semantics: nav label, crumbs are links', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      KumoBreadcrumbs(items: _items([]), current: 'api.example.com'),
      size: kumoDesktopSize,
    );
    expect(find.bySemanticsLabel('Breadcrumbs'), findsOneWidget);
    expect(tester.getSemantics(find.text('DNS')), containsSemantics(label: 'DNS', isLink: true));
    handle.dispose();
  });

  testWidgets('tight space collapses middle crumbs into a More menu', (tester) async {
    final log = <String>[];
    await pumpKumo(
      tester,
      SizedBox(
        width: 460,
        child: KumoBreadcrumbs(items: _items(log), current: 'api.example.com'),
      ),
      size: kumoDesktopSize,
    );
    expect(find.text('Account home'), findsOneWidget);
    expect(find.text('example.com'), findsNothing);
    expect(find.text('Records'), findsOneWidget);
    final more = find.bySemanticsLabel('More');
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('example.com'), findsOneWidget);
    await tester.tap(find.text('example.com'));
    await tester.pumpAndSettle();
    expect(log, ['zone']);
    expect(find.text('example.com'), findsNothing, reason: 'menu closes after choosing');
  });

  testWidgets('More menu closes with Escape', (tester) async {
    await pumpKumo(
      tester,
      SizedBox(
        width: 380,
        child: KumoBreadcrumbs(items: _items([]), current: 'api.example.com'),
      ),
      size: kumoDesktopSize,
    );
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsNothing);
  });

  testWidgets('phone: back link to the parent by default', (tester) async {
    final log = <String>[];
    await pumpKumo(tester, KumoBreadcrumbs(items: _items(log), current: 'api.example.com'));
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Account home'), findsNothing);
    expect(find.byIcon(KumoIcons.caretLeft), findsOneWidget);
    await tester.tap(find.text('Records'));
    expect(log, ['records']);
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Back, Records'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('phone trail: More menu opens in a sheet', (tester) async {
    final log = <String>[];
    await pumpKumo(
      tester,
      KumoBreadcrumbs(items: _items(log), current: 'api.example.com', narrowLayout: KumoBreadcrumbsNarrowLayout.trail),
    );
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('api.example.com'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    await tester.tap(find.text('DNS'));
    await tester.pumpAndSettle();
    expect(log, ['dns']);
    expect(find.byType(KumoSheet), findsNothing);
  });

  testWidgets('loading current shows a placeholder announced as loading', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      KumoBreadcrumbs(items: _items([]), current: '', loading: true),
      size: kumoDesktopSize,
    );
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('root only: current page with icon', (tester) async {
    await pumpKumo(tester, const KumoBreadcrumbs(current: 'Worker analytics', currentIcon: KumoIcons.house));
    expect(find.text('Worker analytics'), findsOneWidget);
  });

  testWidgets('copy button copies the deep link and confirms', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpKumo(
      tester,
      KumoBreadcrumbs(items: _items([]), current: 'Records', copyText: 'https://dash.example.com/dns'),
      size: kumoDesktopSize,
    );
    await tester.tap(find.byIcon(KumoIcons.copy));
    await tester.pump();
    expect(copied, ['https://dash.example.com/dns']);
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byIcon(KumoIcons.copy), findsOneWidget);
  });

  testWidgets('text scale 2 and RTL at 390px: no overflow', (tester) async {
    for (final layout in KumoBreadcrumbsNarrowLayout.values) {
      await pumpKumo(
        tester,
        KumoBreadcrumbs(items: _items([]), current: 'api.example.com', narrowLayout: layout),
        textScale: 2,
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('crumbs that come out of the More menu fade in; the first layout does not', (tester) async {
    final width = ValueNotifier<double>(460);
    addTearDown(width.dispose);
    Widget host() => ValueListenableBuilder<double>(
      valueListenable: width,
      builder: (context, w, _) => SizedBox(
        width: w,
        child: KumoBreadcrumbs(items: _items([]), current: 'api.example.com'),
      ),
    );
    await pumpKumo(tester, host(), size: kumoDesktopSize, settle: false);
    expect(_opacity(tester, 'Account home'), 1, reason: 'first layout shows at once');
    await tester.pumpAndSettle();
    expect(find.text('example.com'), findsNothing);
    width.value = 1000;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_opacity(tester, 'example.com'), inExclusiveRange(0, 1));
    expect(_opacity(tester, 'Account home'), 1, reason: 'crumbs that stay do not blink');
    await tester.pumpAndSettle();
    expect(_opacity(tester, 'example.com'), 1);
  });

  testWidgets('reduced motion: revealed crumbs and the copy check land at once', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final width = ValueNotifier<double>(460);
    addTearDown(width.dispose);
    await pumpKumo(
      tester,
      ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, w, _) => SizedBox(
          width: w,
          child: KumoBreadcrumbs(items: _items([]), current: 'api.example.com', copyText: 'https://dash.example.com'),
        ),
      ),
      size: kumoDesktopSize,
      disableAnimations: true,
    );
    width.value = 1000;
    await tester.pump();
    expect(_opacity(tester, 'example.com'), 1);
    await tester.tap(find.byIcon(KumoIcons.copy));
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(KumoIcons.copy), findsNothing);
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('copy check lands with a small bounce', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpKumo(
      tester,
      KumoBreadcrumbs(items: _items([]), current: 'Records', copyText: 'https://dash.example.com/dns'),
      size: kumoDesktopSize,
    );
    await tester.tap(find.byIcon(KumoIcons.copy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final scale = tester
        .widget<ScaleTransition>(
          find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(ScaleTransition)),
        )
        .scale
        .value;
    expect(scale, inExclusiveRange(0.6, 1.2));
    expect(scale, isNot(1));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.copy), findsOneWidget);
  });
}

double _opacity(WidgetTester tester, String label) {
  var opacity = 1.0;
  for (final t in tester.widgetList<FadeTransition>(
    find.ancestor(of: find.text(label), matching: find.byType(FadeTransition)),
  )) {
    opacity *= t.opacity.value;
  }
  return opacity;
}
