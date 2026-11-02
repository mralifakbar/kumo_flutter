import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('mod is Command with a glyph on macOS and is spoken in full', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoKbd('K', modifiers: [KumoKbdModifier.mod], platform: TargetPlatform.macOS));
    expect(find.byIcon(KumoIcons.command), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
    expect(find.bySemanticsLabel('Command K'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('mod is Ctrl as text on Windows and Linux', (tester) async {
    final handle = tester.ensureSemantics();
    for (final p in [TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.android]) {
      await pumpKumo(tester, KumoKbd('K', modifiers: const [KumoKbdModifier.mod], platform: p));
      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.byIcon(KumoIcons.command), findsNothing);
      expect(find.bySemanticsLabel('Ctrl K'), findsOneWidget);
    }
    handle.dispose();
  });

  testWidgets('Apple order is control, option, shift, command whatever the input order', (tester) async {
    await pumpKumo(
      tester,
      const KumoKbd(
        'P',
        modifiers: [KumoKbdModifier.mod, KumoKbdModifier.shift, KumoKbdModifier.alt, KumoKbdModifier.control],
        platform: TargetPlatform.macOS,
      ),
    );
    final xs = [
      KumoIcons.control,
      KumoIcons.option,
      KumoIcons.arrowFatUp,
      KumoIcons.command,
    ].map((i) => tester.getCenter(find.byIcon(i)).dx).toList();
    expect(xs, orderedEquals([...xs]..sort()));
  });

  testWidgets('mod and meta together show one Command key on Apple platforms', (tester) async {
    await pumpKumo(
      tester,
      const KumoKbd('K', modifiers: [KumoKbdModifier.meta, KumoKbdModifier.mod], platform: TargetPlatform.iOS),
    );
    expect(find.byIcon(KumoIcons.command), findsOneWidget);
  });

  testWidgets('fromActivator mirrors a SingleActivator', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      KumoKbd.fromActivator(
        const SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true),
        platform: TargetPlatform.windows,
      ),
    );
    expect(find.text('Ctrl'), findsOneWidget);
    expect(find.text('Shift'), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
    expect(find.bySemanticsLabel('Ctrl Shift P'), findsOneWidget);
    await pumpKumo(
      tester,
      KumoKbd.fromActivator(const SingleActivator(LogicalKeyboardKey.enter), platform: TargetPlatform.macOS),
    );
    expect(find.byIcon(KumoIcons.keyReturn), findsOneWidget);
    handle.dispose();
  });

  testWidgets('named keys: arrows are glyphs everywhere, Esc is text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoKbd(KumoKbdKeys.arrowUp, platform: TargetPlatform.linux));
    expect(find.byIcon(KumoIcons.arrowUp), findsOneWidget);
    expect(find.bySemanticsLabel('Up arrow'), findsOneWidget);
    await pumpKumo(tester, const KumoKbd(KumoKbdKeys.escape, platform: TargetPlatform.linux));
    expect(find.text('Esc'), findsOneWidget);
    expect(find.bySemanticsLabel('Escape'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('chips are at least 20px and grow with 2x text; dark mode renders', (tester) async {
    await pumpKumo(tester, const KumoKbd('K', platform: TargetPlatform.macOS));
    final size = tester.getSize(find.byType(DecoratedBox).last);
    expect(size.height, greaterThanOrEqualTo(20));
    expect(size.width, greaterThanOrEqualTo(20));
    await pumpKumo(
      tester,
      const SizedBox(
        width: 120,
        child: KumoKbd(
          'Backspace',
          modifiers: [KumoKbdModifier.mod, KumoKbdModifier.shift],
          platform: TargetPlatform.windows,
        ),
      ),
      textScale: 2,
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
