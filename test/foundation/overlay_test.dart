import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.trapFocus = false, this.alignment = Alignment.center});

  final bool trapFocus;
  final Alignment alignment;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: KumoAnchoredOverlay(
        open: open,
        trapFocus: widget.trapFocus,
        onDismiss: () => setState(() => open = false),
        overlayBuilder: (context, placement) => KumoPopupSurface(
          placement: placement,
          showArrow: true,
          child: SizedBox(
            width: 150,
            height: 100,
            child: Column(
              children: [
                Text('Popup ${placement.side.name}'),
                KumoButton(label: 'Inside', onPress: () {}),
              ],
            ),
          ),
        ),
        child: KumoButton(label: 'Trigger', onPress: () => setState(() => open = !open)),
      ),
    );
  }
}

void main() {
  testWidgets('opens below the anchor and toggles from the anchor', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    expect(find.text('Popup bottom'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(KumoPopupSurface)).dy,
      greaterThan(tester.getBottomLeft(find.text('Trigger')).dy),
    );
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Popup'), findsNothing);
  });

  testWidgets('flips to the top when there is no room below', (tester) async {
    await pumpKumo(tester, const _Host(alignment: Alignment.bottomCenter), center: false);
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    expect(find.text('Popup top'), findsOneWidget);
  });

  testWidgets('stays inside the screen horizontally', (tester) async {
    await pumpKumo(tester, const _Host(alignment: Alignment.centerRight), center: false);
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(KumoPopupSurface));
    expect(rect.right, lessThanOrEqualTo(kumoPhoneSize.width - 8 + 0.01));
  });

  testWidgets('outside tap and Escape dismiss', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('Popup'), findsNothing);

    // Opened by pointer, nothing focused: Escape still closes it.
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.textContaining('Popup'), findsNothing);

    // Opened from the keyboard: the focused anchor handles Escape.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Popup bottom'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.textContaining('Popup'), findsNothing);
  });

  testWidgets('enters with a scale from 0.9 anchored to the trigger', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    await tester.tap(find.text('Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final scale = tester
        .widgetList<Transform>(find.ancestor(of: find.byType(KumoPopupSurface), matching: find.byType(Transform)))
        .first;
    expect(scale.transform.storage[0], lessThan(1));
    expect(scale.alignment, const Alignment(0, -1));
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion opens without scaling', (tester) async {
    await pumpKumo(tester, const _Host(), center: false, disableAnimations: true);
    await tester.tap(find.text('Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final still = tester
        .widgetList<Transform>(find.ancestor(of: find.byType(KumoPopupSurface), matching: find.byType(Transform)))
        .first;
    expect(still.transform.storage[0], 1);
  });

  testWidgets('trapFocus moves focus inside and returns it on close', (tester) async {
    await pumpKumo(tester, const _Host(trapFocus: true), center: false);
    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final inside = find.ancestor(of: find.text('Inside'), matching: find.byType(Focus));
    expect(Focus.of(tester.element(find.text('Inside'))).hasFocus || tester.widgetList(inside).isNotEmpty, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.textContaining('Popup'), findsNothing);
  });

  testWidgets('an overlay that never opened disposes cleanly', (tester) async {
    await pumpKumo(tester, const _Host());
    await pumpKumo(tester, const SizedBox());
    expect(tester.takeException(), isNull);
  });

  group('KumoSheet', () {
    testWidgets('opens, follows a drag and dismisses on a downward flick', (tester) async {
      String? result;
      await pumpKumo(
        tester,
        Builder(
          builder: (context) => KumoButton(
            label: 'Open',
            onPress: () async {
              result = await showKumoSheet<String>(
                context: context,
                semanticLabel: 'Regions',
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: KumoButton(label: 'Pick', onPress: () => KumoSheetScope.closeFrom(context, 'iad')),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Pick'), findsOneWidget);
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(result, 'iad');
      expect(find.text('Pick'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.fling(find.text('Pick'), const Offset(0, 300), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Pick'), findsNothing);
    });

    testWidgets('a small drag springs back', (tester) async {
      await pumpKumo(
        tester,
        Builder(
          builder: (context) => KumoButton(
            label: 'Open',
            onPress: () => showKumoSheet<void>(
              context: context,
              builder: (_) => const SizedBox(height: 300, child: Text('Body')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.text('Body')).dy;
      await tester.drag(find.text('Body'), const Offset(0, 30));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Body')).dy, closeTo(before, 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });
  });

  testWidgets('dialog route scales from 0.9 and closes on scrim tap', (tester) async {
    await pumpKumo(
      tester,
      Builder(
        builder: (context) => KumoButton(
          label: 'Open',
          onPress: () =>
              Navigator.of(context).push(KumoDialogRoute<void>(builder: (_) => const Center(child: Text('Dialog')))),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final scale = tester.widget<ScaleTransition>(
      find.ancestor(of: find.text('Dialog'), matching: find.byType(ScaleTransition)).first,
    );
    expect(scale.scale.value, inInclusiveRange(0.9, 1.0));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsNothing);
  });
}
