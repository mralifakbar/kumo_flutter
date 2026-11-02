import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';
import 'data_test_utils.dart';

const _id = 'f86b3f10-32e9-4db7-ae95-84a1b2c3d4e5';

double _iconOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.ancestor(of: find.byIcon(KumoIcons.copySimple), matching: find.byType(AnimatedOpacity)))
    .opacity;

void main() {
  testWidgets('renders text variants in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        const Column(mainAxisSize: MainAxisSize.min, children: [
          KumoInlineCopyText(_id),
          KumoInlineCopyText(_id, variant: KumoTextVariant.mono, size: KumoTextSize.lg),
          KumoInlineCopyText('image-resizer', variant: KumoTextVariant.body, bold: true),
          KumoInlineCopyText.rich(value: _id, child: Text('Database ID: f86b3f10')),
        ]),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('copies the text, or value for rich content', (tester) async {
    final copied = mockClipboard(tester);
    var calls = 0;
    await pumpKumo(tester, KumoInlineCopyText(_id, onCopy: () => calls++));
    await tester.tap(find.text(_id));
    await settleCopy(tester);
    expect(copied, [_id]);
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 2));

    await pumpKumo(tester, const KumoInlineCopyText.rich(value: 'abc', child: Text('Shown')));
    await tester.tap(find.text('Shown'));
    await settleCopy(tester);
    expect(copied, [_id, 'abc']);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('semantics: button named by copyLabel, then copiedLabel; announces', (tester) async {
    final handle = tester.ensureSemantics();
    mockClipboard(tester);
    final announced = mockAnnouncements(tester);
    await pumpKumo(tester, const KumoInlineCopyText(_id, copyLabel: 'Copy database ID', copiedLabel: 'Database ID copied'));
    expect(
      tester.getSemantics(find.byType(KumoInlineCopyText)),
      matchesSemantics(
        label: 'Copy database ID',
        value: _id,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await tester.tap(find.byType(KumoInlineCopyText));
    await settleCopy(tester);
    expect(find.bySemanticsLabel('Database ID copied'), findsOneWidget);
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    expect(announced, ['Database ID copied']);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.check), findsNothing);
    expect(find.bySemanticsLabel('Copy database ID'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('icon hidden at rest with a mouse, shown on hover and focus, always on touch', (tester) async {
    await pumpKumo(tester, const KumoInlineCopyText(_id));
    expect(_iconOpacity(tester), 1);

    await pumpKumo(tester, const KumoInlineCopyText(_id), tapTargetSize: KumoTapTargetSize.shrinkWrap);
    expect(_iconOpacity(tester), 0);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.text(_id)));
    await tester.pumpAndSettle();
    expect(_iconOpacity(tester), 1);
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(_iconOpacity(tester), 0);
    await gesture.removePointer();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_iconOpacity(tester), 1);
  });

  testWidgets('a hovered table row reveals the icon', (tester) async {
    await pumpKumo(
      tester,
      KumoTable<String>(
        rows: const ['db-1'],
        columns: [
          KumoTableColumn(id: 'name', label: 'Name', cell: (context, r) => Text(r)),
          KumoTableColumn(id: 'id', label: 'ID', cell: (context, r) => const KumoInlineCopyText(_id)),
        ],
      ),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
      size: kumoDesktopSize,
    );
    expect(_iconOpacity(tester), 0);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.text('db-1')));
    await tester.pumpAndSettle();
    expect(_iconOpacity(tester), 1);
    await gesture.removePointer();
  });

  testWidgets('failure shows a warning icon and announces it', (tester) async {
    mockClipboard(tester, fail: true);
    final announced = mockAnnouncements(tester);
    await pumpKumo(tester, const KumoInlineCopyText(_id));
    await tester.tap(find.text(_id));
    await settleCopy(tester);
    expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);
    expect(announced, ['Could not copy']);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('Enter copies when focused', (tester) async {
    final copied = mockClipboard(tester);
    await pumpKumo(tester, const KumoInlineCopyText(_id), tapTargetSize: KumoTapTargetSize.shrinkWrap);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleCopy(tester);
    expect(copied, [_id]);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('truncates in a narrow row at 2x text', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(width: 160, child: Row(children: [Flexible(child: KumoInlineCopyText(_id))])),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the copy icon cross-fades to a check and back', (tester) async {
    mockClipboard(tester);
    await pumpKumo(tester, const KumoInlineCopyText(_id));
    await tester.tap(find.text(_id));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    // The lowest opacity on the way up: the swap's fade, not the hover fade.
    double fadeOf(IconData icon) => tester
        .widgetList<FadeTransition>(find.ancestor(of: find.byIcon(icon), matching: find.byType(FadeTransition)))
        .map((f) => f.opacity.value)
        .reduce((a, b) => a < b ? a : b);
    expect(fadeOf(KumoIcons.check), inExclusiveRange(0, 1));
    expect(fadeOf(KumoIcons.copySimple), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 40));
    expect(fadeOf(KumoIcons.copySimple), inExclusiveRange(0, 1), reason: 'the revert fades too');
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.check), findsNothing);
  });

  testWidgets('reduced motion: the icon swaps in one frame', (tester) async {
    mockClipboard(tester);
    await pumpKumo(tester, const KumoInlineCopyText(_id), disableAnimations: true);
    await tester.tap(find.text(_id));
    await settleCopy(tester);
    expect(find.byIcon(KumoIcons.copySimple), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 2));
  });
}
