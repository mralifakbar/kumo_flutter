import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';
import 'data_test_utils.dart';

void main() {
  testWidgets('renders every size, masked and plain, in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in KumoClipboardTextSize.values) ...[
              KumoClipboardText(text: '023e105f4ecef8ad9ca31a8372d0c353', size: s),
              KumoClipboardText(text: 'cf_live_7Hq2xK9mZ', size: s, masked: true),
            ],
          ],
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('heights match Kumo with a mouse and reach 44 on touch', (tester) async {
    for (final s in KumoClipboardTextSize.values) {
      await pumpKumo(
        tester,
        KumoClipboardText(text: 'abc', size: s),
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
      );
      expect(tester.getSize(find.byType(KumoClipboardText)).height, s.height);
    }
    await pumpKumo(tester, const KumoClipboardText(text: 'abc', size: KumoClipboardTextSize.sm));
    expect(tester.getSize(find.byType(KumoClipboardText)).height, 44);
  });

  testWidgets('copies text, or textToCopy when given, and calls onCopy', (tester) async {
    final copied = mockClipboard(tester);
    var calls = 0;
    await pumpKumo(
      tester,
      KumoClipboardText(text: 'cf_live_***', textToCopy: 'cf_live_7Hq2xK9mZ', onCopy: () => calls++),
    );
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settleCopy(tester);
    expect(copied, ['cf_live_7Hq2xK9mZ']);
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('the check slides in, bumps on repeat, announces, and resets after 1.5s', (tester) async {
    mockClipboard(tester);
    final announced = mockAnnouncements(tester);
    await pumpKumo(tester, const KumoClipboardText(text: 'abc'));
    expect(find.byIcon(KumoIcons.check), findsOneWidget); // mounted, transparent, below the copy icon
    double checkOpacity() => tester
        .widget<Opacity>(find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(Opacity)).first)
        .opacity;
    expect(checkOpacity(), 0);
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settleCopy(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(checkOpacity(), 1);
    expect(announced, ['Copied']);

    // A second copy while "Copied" shows kicks the bump spring.
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settleCopy(tester);
    final scale = tester.widget<ScaleTransition>(
      find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(ScaleTransition)),
    );
    expect(scale.scale.value, greaterThan(1));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(checkOpacity(), 1);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(checkOpacity(), 0);
    expect(announced, ['Copied', 'Copied']);
  });

  testWidgets('failure shows a warning icon and announces the failure copy', (tester) async {
    mockClipboard(tester, fail: true);
    final announced = mockAnnouncements(tester);
    var calls = 0;
    await pumpKumo(tester, KumoClipboardText(text: 'abc', onCopy: () => calls++));
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settleCopy(tester);
    expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);
    expect(announced, ['Could not copy']);
    expect(calls, 0);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('masked values reveal and hide with a toggle button', (tester) async {
    final handle = tester.ensureSemantics();
    final copied = mockClipboard(tester);
    await pumpKumo(tester, const KumoClipboardText(text: 'cf_live_7Hq2xK9mZ', masked: true));
    expect(find.text('••••••••'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show')),
      matchesSemantics(
        label: 'Show',
        isButton: true,
        hasToggledState: true,
        isToggled: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Show'));
    await tester.pumpAndSettle();
    expect(find.text('cf_live_7Hq2xK9mZ'), findsOneWidget);
    expect(find.bySemanticsLabel('Hide'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settleCopy(tester);
    expect(copied, ['cf_live_7Hq2xK9mZ']);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('copy button: Tab focus and Enter', (tester) async {
    final copied = mockClipboard(tester);
    await pumpKumo(tester, const KumoClipboardText(text: 'abc'), tapTargetSize: KumoTapTargetSize.shrinkWrap);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleCopy(tester);
    expect(copied, ['abc']);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('tooltip mode shows an anchored Copied bubble', (tester) async {
    mockClipboard(tester);
    await pumpKumo(
      tester,
      const KumoClipboardText(
        text: 'npx wrangler deploy',
        tooltip: KumoClipboardTextTooltip(copiedText: 'Command copied'),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settleCopy(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.text('Command copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Command copied'), findsNothing);
  });

  testWidgets('long values truncate at 390px and 2x text, also in RTL', (tester) async {
    await pumpKumo(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: KumoClipboardText(
          text: 'https://example.com/a/very/long/path/to/an/r2/object.png',
          block: true,
          masked: true,
        ),
      ),
      textScale: 2,
      textDirection: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion swaps the icon without animating', (tester) async {
    mockClipboard(tester);
    await pumpKumo(tester, const KumoClipboardText(text: 'abc'), disableAnimations: true);
    await tester.tap(find.bySemanticsLabel('Copy'));
    await settleCopy(tester);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('revealing cross-fades the value and the eye icon', (tester) async {
    await pumpKumo(tester, const KumoClipboardText(text: 'cf_live_7Hq2xK9mZ', masked: true));
    await tester.tap(find.byIcon(KumoIcons.eye));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    double fadeOf(Finder f) =>
        tester.widget<FadeTransition>(find.ancestor(of: f, matching: find.byType(FadeTransition)).first).opacity.value;
    expect(fadeOf(find.text('cf_live_7Hq2xK9mZ')), inExclusiveRange(0, 1));
    expect(fadeOf(find.text('••••••••')), inExclusiveRange(0, 1));
    expect(fadeOf(find.byIcon(KumoIcons.eyeSlash)), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.text('••••••••'), findsNothing);
  });

  testWidgets('reduced motion: revealing lands in one frame', (tester) async {
    await pumpKumo(tester, const KumoClipboardText(text: 'cf_live_7Hq2xK9mZ', masked: true), disableAnimations: true);
    await tester.tap(find.byIcon(KumoIcons.eye));
    await tester.pump();
    await tester.pump();
    expect(find.text('••••••••'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
