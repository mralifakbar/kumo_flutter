import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders every variant and size in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in KumoButtonVariant.values)
            for (final s in KumoButtonSize.values) KumoButton(label: '${v.name} ${s.name}', variant: v, size: s, onPress: () {}),
        ]),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('heights match Kumo with a mouse', (tester) async {
    for (final s in KumoButtonSize.values) {
      await pumpKumo(tester, KumoButton(label: 'Save', size: s, onPress: () {}), tapTargetSize: KumoTapTargetSize.shrinkWrap);
      expect(tester.getSize(find.byType(KumoButton)).height, s.height);
    }
  });

  testWidgets('touch hit area is at least 44 even for small buttons', (tester) async {
    await pumpKumo(tester, KumoButton(label: 'Save', size: KumoButtonSize.xs, onPress: () {}));
    expect(tester.getSize(find.byType(KumoPressable)).height, 44);
  });

  testWidgets('fires onPress; disabled, null onPress and loading do not', (tester) async {
    var taps = 0;
    await pumpKumo(tester, KumoButton(label: 'Save', onPress: () => taps++));
    await tester.tap(find.text('Save'));
    expect(taps, 1);
    await pumpKumo(tester, KumoButton(label: 'Save', disabled: true, onPress: () => taps++));
    await tester.tap(find.text('Save'));
    await pumpKumo(tester, KumoButton(label: 'Save', loading: true, onPress: () => taps++), settle: false);
    await tester.tap(find.text('Save'));
    expect(taps, 1);
  });

  testWidgets('loading keeps the label and width, shows a spinner', (tester) async {
    await pumpKumo(tester, KumoButton(label: 'Deploy', onPress: () {}));
    final width = tester.getSize(find.byType(KumoButton)).width;
    await pumpKumo(tester, KumoButton(label: 'Deploy', loading: true, onPress: () {}), settle: false);
    expect(find.text('Deploy'), findsOneWidget);
    expect(find.byType(KumoLoader), findsOneWidget);
    expect(tester.getSize(find.byType(KumoButton)).width, closeTo(width + 6 + 14 - 12 + 10, 20));
  });

  testWidgets('icon-only buttons are square and labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      KumoButton(icon: KumoIcons.trash, shape: KumoButtonShape.square, semanticLabel: 'Delete', onPress: () {}),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    expect(tester.getSize(find.byType(KumoButton)), const Size(36, 36));
    expect(find.bySemanticsLabel('Delete'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('disabled semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoButton(label: 'Save'));
    expect(
      tester.getSemantics(find.byType(KumoButton)),
      matchesSemantics(label: 'Save', isButton: true, hasEnabledState: true, isFocusable: false),
    );
    handle.dispose();
  });

  testWidgets('keyboard activation', (tester) async {
    var taps = 0;
    await pumpKumo(tester, KumoButton(label: 'Save', onPress: () => taps++));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('title shows a tooltip on hover after the delay', (tester) async {
    await pumpKumo(
      tester,
      KumoButton(icon: KumoIcons.copy, shape: KumoButtonShape.square, title: 'Copy token', onPress: () {}),
      size: kumoDesktopSize,
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(KumoButton)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Copy token'), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Copy token'), findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text('Copy token'), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('block stretches; text scale 2 does not overflow', (tester) async {
    await pumpKumo(tester, SizedBox(width: 300, child: KumoButton(label: 'Create Worker', block: true, onPress: () {})));
    expect(tester.getSize(find.byType(KumoButton)).width, 300);
    await pumpKumo(tester, SizedBox(width: 200, child: KumoButton(label: 'Create a very long Worker name', icon: KumoIcons.plus, onPress: () {})), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh button spins only while loading', (tester) async {
    await pumpKumo(tester, KumoRefreshButton(onPress: () {}, loading: true), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await pumpKumo(tester, KumoRefreshButton(onPress: () {}));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('RTL puts the icon on the right', (tester) async {
    await pumpKumo(tester, KumoButton(label: 'Add', icon: KumoIcons.plus, onPress: () {}), textDirection: TextDirection.rtl);
    expect(tester.getCenter(find.byType(KumoIcon)).dx, greaterThan(tester.getCenter(find.text('Add')).dx));
  });

  group('motion', () {
    double fadeOf(WidgetTester tester, Finder f) => tester
        .widget<FadeTransition>(find.ancestor(of: f, matching: find.byType(FadeTransition)).first)
        .opacity
        .value;

    testWidgets('loading cross-fades the icon into a spinner and keeps the label', (tester) async {
      await pumpKumo(tester, KumoButton(label: 'Deploy', icon: KumoIcons.rocketLaunch, onPress: () {}));
      await pumpKumo(tester, KumoButton(label: 'Deploy', icon: KumoIcons.rocketLaunch, loading: true, onPress: () {}), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(fadeOf(tester, find.byType(KumoLoader)), inExclusiveRange(0, 1));
      expect(fadeOf(tester, find.byIcon(KumoIcons.rocketLaunch)), inExclusiveRange(0, 1));
      expect(find.text('Deploy'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(KumoIcons.rocketLaunch), findsNothing);
      await pumpKumo(tester, KumoButton(label: 'Deploy', icon: KumoIcons.rocketLaunch, onPress: () {}), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(fadeOf(tester, find.byIcon(KumoIcons.rocketLaunch)), inExclusiveRange(0, 1), reason: 'and back');
      await tester.pumpAndSettle();
    });

    testWidgets('a spinner in a label-only button fades in while the button widens', (tester) async {
      await pumpKumo(tester, KumoButton(label: 'Save', onPress: () {}));
      final rest = tester.getSize(find.byType(KumoButton)).width;
      await pumpKumo(tester, KumoButton(label: 'Save', loading: true, onPress: () {}), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      final mid = tester.getSize(find.byType(KumoButton)).width;
      expect(fadeOf(tester, find.byType(KumoLoader)), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 300));
      final loading = tester.getSize(find.byType(KumoButton)).width;
      expect(mid, inExclusiveRange(rest, loading));
    });

    testWidgets('a new label cross-fades and the width eases', (tester) async {
      await pumpKumo(tester, KumoButton(label: 'Copy', onPress: () {}));
      final short = tester.getSize(find.byType(KumoButton)).width;
      await pumpKumo(tester, KumoButton(label: 'Copied to clipboard', onPress: () {}), settle: false);
      await tester.pump(const Duration(milliseconds: 60));
      expect(fadeOf(tester, find.text('Copied to clipboard')), inExclusiveRange(0, 1));
      final mid = tester.getSize(find.byType(KumoButton)).width;
      await tester.pumpAndSettle();
      expect(mid, inExclusiveRange(short, tester.getSize(find.byType(KumoButton)).width));
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('disabling eases to half opacity', (tester) async {
      await pumpKumo(tester, KumoButton(label: 'Deploy', onPress: () {}));
      await pumpKumo(tester, const KumoButton(label: 'Deploy'), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      final faded = tester
          .widgetList<FadeTransition>(find.ancestor(of: find.text('Deploy'), matching: find.byType(FadeTransition)))
          .map((f) => f.opacity.value)
          .reduce((a, b) => a < b ? a : b);
      expect(faded, inExclusiveRange(0.5, 1));
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion: label, loading and disabled changes land at once without errors', (tester) async {
      await pumpKumo(tester, KumoButton(label: 'Save', onPress: () {}), disableAnimations: true);
      await pumpKumo(
        tester,
        const KumoButton(label: 'Saving your changes', loading: true),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Save'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      await pumpKumo(tester, KumoButton(label: 'OK', onPress: () {}), disableAnimations: true, settle: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('refresh button stays still under reduced motion', (tester) async {
      await pumpKumo(tester, KumoRefreshButton(onPress: () {}, loading: true), disableAnimations: true, settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('tooltips: a warm reopen is instant; Escape closes at once', (tester) async {
      double popupOpacity(String text) =>
          tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;
      await pumpKumo(
        tester,
        Row(mainAxisSize: MainAxisSize.min, children: [
          KumoButton(icon: KumoIcons.copy, shape: KumoButtonShape.square, title: 'Copy token', onPress: () {}),
          const SizedBox(width: 40),
          KumoButton(icon: KumoIcons.trash, shape: KumoButtonShape.square, title: 'Delete token', onPress: () {}),
        ]),
        size: kumoDesktopSize,
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byIcon(KumoIcons.copy)));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(popupOpacity('Copy token'), inExclusiveRange(0, 1), reason: 'a cold open animates');
      await tester.pumpAndSettle();

      await mouse.moveTo(tester.getCenter(find.byIcon(KumoIcons.trash)));
      await tester.pump();
      await tester.pump();
      expect(popupOpacity('Delete token'), 1, reason: 'a warm open appears at once');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('Copy token'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(find.text('Copy token'), findsNothing);
    });
  });
}

