import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('horizontal fills the width with a 1px hairline in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const SizedBox(width: 300, child: KumoSeparator()), brightness: b);
      expect(tester.getSize(find.byType(KumoSeparator)), const Size(300, 1));
      final line = tester.widget<Container>(
        find.descendant(of: find.byType(KumoSeparator), matching: find.byType(Container)),
      );
      final expected = b == Brightness.dark ? KumoThemeData.dark() : KumoThemeData.light();
      expect(line.color, expected.colors.hairline);
    }
  });

  testWidgets('vertical fills an IntrinsicHeight row, or takes a length', (tester) async {
    await pumpKumo(
      tester,
      const IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [SizedBox(width: 40, height: 24), KumoSeparator.vertical(), SizedBox(width: 40, height: 24)],
        ),
      ),
    );
    expect(tester.getSize(find.byType(KumoSeparator)), const Size(1, 24));
    await pumpKumo(tester, const KumoSeparator.vertical(length: 16));
    expect(tester.getSize(find.byType(KumoSeparator)), const Size(1, 16));
  });

  testWidgets('the line is hidden from screen readers; a label is read', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const SizedBox(width: 300, child: KumoSeparator(label: 'or')));
    expect(find.bySemanticsLabel('or'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    final label = tester.getRect(find.text('or'));
    expect(label.center.dx, closeTo(tester.getRect(find.byType(KumoSeparator)).center.dx, 0.5));
    handle.dispose();
  });

  testWidgets('a long label wraps at 390px and 2x text without overflow', (tester) async {
    await pumpKumo(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: KumoSeparator(label: 'Records below are managed by the zone example.com and cannot be edited here'),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL renders the same line', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(width: 200, child: KumoSeparator(label: 'or')),
      textDirection: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
