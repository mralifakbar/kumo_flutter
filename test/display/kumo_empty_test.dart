import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

double _minFade(WidgetTester tester, Finder f) => tester
    .widgetList<FadeTransition>(find.ancestor(of: f, matching: find.byType(FadeTransition)))
    .map((t) => t.opacity.value)
    .fold(1.0, (a, b) => a < b ? a : b);

void main() {
  Widget pad(Widget child) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: child);

  testWidgets('every size renders in light and dark with Kumo padding', (tester) async {
    for (final b in Brightness.values) {
      for (final s in KumoEmptySize.values) {
        await pumpKumo(
          tester,
          pad(
            KumoEmpty(
              size: s,
              icon: KumoIcons.database,
              title: 'No D1 databases yet',
              description: 'Databases you create in this account appear here.',
              commandLine: 'npx wrangler d1 create app-db',
              contents: KumoButton(label: 'Create database', onPress: () {}),
            ),
          ),
          brightness: b,
          center: false,
        );
        expect(tester.takeException(), isNull);
        final box = tester.getRect(find.byType(KumoEmpty));
        final icon = tester.getRect(find.byIcon(KumoIcons.database));
        // 1px border + py-*
        expect(icon.top - box.top, s.paddingY + 1);
        expect(icon.height, s.iconSize);
      }
    }
  });

  testWidgets('with a description the title is a 20px level-2 heading', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      pad(const KumoEmpty(title: 'No results for "api"', description: 'Clear the filter to see all 24 records.')),
    );
    final title = tester.widget<Text>(find.text('No results for "api"'));
    expect(title.style!.fontSize, 20);
    expect(title.style!.fontWeight, FontWeight.w600);
    final node = tester.getSemantics(find.text('No results for "api"'));
    expect(node, containsSemantics(isHeader: true));
    expect(node.getSemanticsData().headingLevel, 2);
    handle.dispose();
  });

  testWidgets('title alone is 14px subtle text, still a heading', (tester) async {
    await pumpKumo(tester, pad(const KumoEmpty(title: 'No tokens')));
    final title = tester.widget<Text>(find.text('No tokens'));
    expect(title.style!.fontSize, 14);
    expect(title.style!.color, KumoThemeData.light().colors.textSubtle);
  });

  testWidgets('copy puts the command on the clipboard and shows a check for 1s', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, pad(const KumoEmpty(title: 'No projects', commandLine: 'npm create cloudflare@latest')));
    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('npm create cloudflare@latest'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Copy to clipboard'));
    await tester.pump();
    final set = calls.firstWhere((c) => c.method == 'Clipboard.setData');
    expect((set.arguments as Map)['text'], 'npm create cloudflare@latest');
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.check), findsNothing);
    expect(find.byIcon(KumoIcons.copy), findsOneWidget);
    handle.dispose();
  });

  testWidgets('contents are interactive', (tester) async {
    var taps = 0;
    await pumpKumo(
      tester,
      pad(
        KumoEmpty(
          title: 'No connection to the API',
          description: 'Check your network, then retry.',
          contents: KumoButton(label: 'Retry', variant: KumoButtonVariant.primary, onPress: () => taps++),
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    expect(taps, 1);
  });

  testWidgets('2x text at 390px: long command scrolls, nothing overflows', (tester) async {
    await pumpKumo(
      tester,
      pad(
        KumoEmpty(
          icon: KumoIcons.folderOpen,
          title: 'No Workers in this account',
          description: 'Deploy a Worker from the command line or create one from a template.',
          commandLine: 'npm create cloudflare@latest -- image-resizer --type=hello-world',
          contents: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              KumoButton(label: 'Create Worker', variant: KumoButtonVariant.primary, onPress: () {}),
              KumoButton(label: 'Browse templates', onPress: () {}),
            ],
          ),
        ),
      ),
      textScale: 2,
      center: false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the check without the bounce', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpKumo(
      tester,
      pad(const KumoEmpty(title: 'No projects', commandLine: 'npm create kumo-project')),
      disableAnimations: true,
    );
    await tester.tap(find.byIcon(KumoIcons.copy));
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a clipped command fades its hidden edge, and the fade follows the scroll', (tester) async {
    await pumpKumo(
      tester,
      pad(
        const KumoEmpty(
          title: 'No Workers',
          commandLine: 'npm create cloudflare@latest -- image-resizer --type=hello-world',
        ),
      ),
    );
    expect(find.byType(ShaderMask), findsOneWidget);
    await pumpKumo(tester, pad(const KumoEmpty(title: 'No Workers', commandLine: 'ls')));
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('copy and check cross-fade, there and back', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpKumo(tester, pad(const KumoEmpty(title: 'No projects', commandLine: 'npm create kumo-project')));
    await tester.tap(find.byIcon(KumoIcons.copy));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(_minFade(tester, find.byIcon(KumoIcons.copy)), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.copy), findsNothing);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 40));
    expect(_minFade(tester, find.byIcon(KumoIcons.copy)), inExclusiveRange(0, 1), reason: 'the copy icon fades back');
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.check), findsNothing);
  });
}
