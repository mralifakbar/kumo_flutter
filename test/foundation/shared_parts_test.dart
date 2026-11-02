import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('KumoField shows description, then error in its place, announced', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoField(label: 'Worker name', description: 'Lowercase only', child: SizedBox(height: 36)));
    expect(find.text('Lowercase only'), findsOneWidget);
    await pumpKumo(tester, const KumoField(label: 'Worker name', description: 'Lowercase only', error: 'Name is taken', child: SizedBox(height: 36)));
    expect(find.text('Lowercase only'), findsNothing);
    expect(find.text('Name is taken'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('KumoLabel optional marker and locale override', (tester) async {
    await pumpKumo(tester, const KumoLabel('Middle name', showOptional: true));
    expect(find.text('(optional)'), findsOneWidget);
    await pumpKumo(
      tester,
      const KumoLocale(strings: KumoStrings(optional: '(opsional)'), child: KumoLabel('Nama tengah', showOptional: true)),
    );
    expect(find.text('(opsional)'), findsOneWidget);
  });

  test('strings helpers', () {
    const s = KumoStrings();
    expect(s.pageOf(2, 10), 'Page 2 of 10');
    expect(s.monthYear(DateTime(2026, 3)), 'March 2026');
    expect(s.fullDate(DateTime(2026, 3, 4)), 'Wednesday, March 4, 2026');
  });

  testWidgets('KumoFieldBox height follows size and rings change with state', (tester) async {
    for (final s in KumoFieldSize.values) {
      await pumpKumo(tester, SizedBox(width: 200, child: KumoFieldBox(size: s, child: const Text('x'))));
      expect(tester.getSize(find.byType(KumoFieldBox)).height, s.height);
    }
    await pumpKumo(tester, const SizedBox(width: 200, child: KumoFieldBox(error: true, focused: true, child: Text('x'))));
    final box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(KumoFieldBox), matching: find.byType(DecoratedBox)).first);
    final border = (box.decoration as BoxDecoration).border! as Border;
    expect(border.top.width, 1.5);
    expect(border.top.color, KumoColorSchemes.light.danger.withValues(alpha: 0.5));
  });

  testWidgets('KumoEditable types and shows placeholder', (tester) async {
    String? value;
    await pumpKumo(tester, SizedBox(width: 200, child: KumoEditable(placeholder: 'example.com', onChanged: (v) => value = v)));
    expect(find.text('example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cloudflare.dev');
    expect(value, 'cloudflare.dev');
  });

  testWidgets('presentation resolves by width', (tester) async {
    late bool narrow;
    late bool wide;
    await pumpKumo(tester, Builder(builder: (c) {
      narrow = KumoPresentation.auto.usesSheet(c);
      return const SizedBox();
    }));
    await pumpKumo(tester, Builder(builder: (c) {
      wide = KumoPresentation.auto.usesSheet(c);
      return const SizedBox();
    }), size: kumoDesktopSize);
    expect(narrow, isTrue);
    expect(wide, isFalse);
  });

  testWidgets('menu rows: arrow keys move focus, Enter activates, destructive styling', (tester) async {
    final picked = <String>[];
    await pumpKumo(
      tester,
      KumoMenuPanel(children: [
        const KumoMenuGroupLabel('Worker'),
        KumoMenuRow(label: 'Rename', icon: KumoIcons.pencilSimple, onPress: () => picked.add('rename'), autofocus: true),
        KumoMenuRow(label: 'Duplicate', onPress: () => picked.add('duplicate'), shortcut: 'D'),
        const KumoMenuSeparator(),
        KumoMenuRow(label: 'Delete', destructive: true, onPress: () => picked.add('delete')),
      ]),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(picked, ['duplicate', 'delete']);
    expect(tester.widget<Text>(find.text('Delete')).style!.color, KumoColorSchemes.light.textDanger);
  });

  testWidgets('field error grows in and the focus ring eases; reduced motion is instant', (tester) async {
    Widget field(String? error, {bool focused = false}) => SizedBox(
          width: 240,
          child: KumoField(label: 'Name', error: error, child: KumoFieldBox(focused: focused, error: error != null, child: const Text('x'))),
        );
    await pumpKumo(tester, field(null));
    final before = tester.getSize(find.byType(KumoField)).height;
    await pumpKumo(tester, field('Name is taken', focused: true), settle: false);
    await tester.pump(const Duration(milliseconds: 50));
    final mid = tester.getSize(find.byType(KumoField)).height;
    expect(mid, greaterThan(before));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(KumoField)).height, greaterThan(mid));

    await pumpKumo(tester, field(null), disableAnimations: true);
    await pumpKumo(tester, field('Name is taken'), disableAnimations: true, settle: false);
    await tester.pump();
    expect(find.text('Name is taken'), findsOneWidget);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
