import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Widget _popover({
  KumoSide side = KumoSide.bottom,
  bool? open,
  ValueChanged<bool>? onOpenChange,
  VoidCallback? onSave,
  bool disabled = false,
}) => KumoPopover(
  side: side,
  open: open,
  disabled: disabled,
  onOpenChange: onOpenChange,
  triggerBuilder: (context, popover) => KumoButton(label: 'Notifications', onPress: popover.toggle),
  children: [
    const KumoPopoverTitle('Notifications'),
    const KumoPopoverDescription('No new alerts for example.com.'),
    const SizedBox(height: 12),
    KumoPopoverClose(label: 'Mark all read', onPress: onSave),
  ],
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('opens below the trigger with an arrow in ${brightness.name}', (tester) async {
      await pumpKumo(tester, _popover(), brightness: brightness);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('No new alerts for example.com.'), findsOneWidget);
      final surface = tester.getRect(find.byType(KumoPopupSurface));
      expect(surface.top, greaterThan(tester.getRect(find.byType(KumoButton).first).bottom));
      expect(tester.widget<KumoPopupSurface>(find.byType(KumoPopupSurface)).showArrow, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('side top places it above', (tester) async {
    await pumpKumo(tester, _popover(side: KumoSide.top));
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(KumoPopupSurface)).bottom,
      lessThan(tester.getRect(find.widgetWithText(KumoButton, 'Notifications').first).top),
    );
  });

  testWidgets('close part runs its callback and closes', (tester) async {
    var saved = 0;
    final changes = <bool>[];
    await pumpKumo(tester, _popover(onSave: () => saved++, onOpenChange: changes.add));
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(saved, 1);
    expect(changes, [true, false]);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('outside tap and Escape close it', (tester) async {
    await pumpKumo(tester, _popover());
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsNothing);
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('keyboard: focus moves in, Tab stays inside, focus returns to the trigger', (tester) async {
    await pumpKumo(tester, _popover());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Mark all read'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('Mark all read'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsNothing);
    expect(Focus.of(tester.element(find.text('Notifications'))).hasPrimaryFocus, isTrue);
  });

  testWidgets('controlled open and disabled', (tester) async {
    await pumpKumo(tester, _popover(open: true));
    expect(find.text('Mark all read'), findsOneWidget);
    await pumpKumo(tester, _popover(open: false));
    expect(find.text('Mark all read'), findsNothing);
    final changes = <bool>[];
    await pumpKumo(tester, _popover(disabled: true, onOpenChange: changes.add));
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('trigger slot and closeFrom', (tester) async {
    await pumpKumo(
      tester,
      KumoPopover(
        trigger: const Padding(padding: EdgeInsets.all(8), child: Text('MR')),
        children: [
          Builder(
            builder: (context) => KumoButton(label: 'Sign out', onPress: () => KumoPopover.closeFrom(context)),
          ),
        ],
      ),
    );
    await tester.tap(find.text('MR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('semantics: named by its title, title is a header', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, _popover(open: true));
    expect(find.bySemanticsLabel('Notifications'), findsWidgets);
    final title = tester.getSemantics(find.text('Notifications').last).getSemanticsData();
    expect(title.flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('reduced motion, text scale 2 and RTL', (tester) async {
    await pumpKumo(tester, _popover(), disableAnimations: true, textScale: 2, textDirection: TextDirection.rtl);
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('stays inside a 390px screen at desktop and phone sizes', (tester) async {
    for (final size in [kumoPhoneSize, kumoDesktopSize]) {
      await pumpKumo(
        tester,
        Align(alignment: Alignment.centerRight, child: _popover()),
        size: size,
        center: false,
      );
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(KumoPopupSurface)).right, lessThanOrEqualTo(size.width - 8 + 0.01));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
    }
  });
}
