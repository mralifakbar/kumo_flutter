import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('static by default: 8px tall, no running animation, light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const SizedBox(width: 200, child: KumoSkeletonLine(widthFactor: 1)), brightness: b);
      expect(tester.getSize(find.byType(ClipRRect)), const Size(200, 8));
      expect(tester.hasRunningAnimations, isFalse);
    }
  });

  testWidgets('widthFactor sets an exact width; otherwise it stays within min and max', (tester) async {
    await pumpKumo(tester, const SizedBox(width: 200, child: KumoSkeletonLine(widthFactor: 0.5)));
    expect(tester.getSize(find.byType(ClipRRect)).width, 100);
    for (var i = 0; i < 10; i++) {
      await pumpKumo(
        tester,
        SizedBox(width: 200, child: KumoSkeletonLine(key: ValueKey(i), minWidth: 40, maxWidth: 60)),
      );
      final w = tester.getSize(find.byType(ClipRRect)).width;
      expect(w, inInclusiveRange(80, 120));
    }
  });

  testWidgets('the random width is picked once, not on every rebuild', (tester) async {
    final notifier = ValueNotifier(0);
    await pumpKumo(
      tester,
      SizedBox(
        width: 200,
        child: ValueListenableBuilder(valueListenable: notifier, builder: (context, v, _) => const KumoSkeletonLine()),
      ),
    );
    final first = tester.getSize(find.byType(ClipRRect)).width;
    notifier.value++;
    await tester.pump();
    expect(tester.getSize(find.byType(ClipRRect)).width, first);
  });

  testWidgets('blockHeight centers the bar in a box of that height', (tester) async {
    await pumpKumo(tester, const SizedBox(width: 200, child: KumoSkeletonLine(widthFactor: 1, blockHeight: 32)));
    expect(tester.getSize(find.byType(KumoSkeletonLine)).height, 32);
    expect(tester.getRect(find.byType(ClipRRect)).center.dy, tester.getRect(find.byType(KumoSkeletonLine)).center.dy);
  });

  testWidgets('animate runs the shimmer only while true', (tester) async {
    Widget line(bool animate) => SizedBox(width: 200, child: KumoSkeletonLine(widthFactor: 1, animate: animate));
    await pumpKumo(tester, line(true), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await pumpKumo(tester, line(false));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion keeps the line still even with animate', (tester) async {
    await pumpKumo(tester, const SizedBox(width: 200, child: KumoSkeletonLine(animate: true)), disableAnimations: true);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('TickerMode off pauses the shimmer', (tester) async {
    await pumpKumo(
      tester,
      const TickerMode(enabled: false, child: SizedBox(width: 200, child: KumoSkeletonLine(animate: true))),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('hidden from screen readers unless labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const SizedBox(width: 200, child: KumoSkeletonLine(semanticLabel: 'Loading DNS records')));
    expect(find.bySemanticsLabel('Loading DNS records'), findsOneWidget);
    handle.dispose();
  });
}
