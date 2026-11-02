import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({super.key, this.initial, this.use24Hour = false, this.minuteStep = 1});

  final KumoTimeValue? initial;
  final bool use24Hour;
  final int minuteStep;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late KumoTimeValue? value = widget.initial;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 240,
        child: KumoTimePicker(
          label: 'Cron trigger time',
          value: value,
          use24Hour: widget.use24Hour,
          minuteStep: widget.minuteStep,
          onValueChange: (t) => setState(() => value = t),
        ),
      ),
    ),
  );
}

Future<void> _at(Future<void> Function() body) => withClock(Clock.fixed(DateTime(2026, 3, 4, 10, 22)), body);

void main() {
  testWidgets('renders placeholder and value in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Host(), brightness: b, center: false);
      expect(find.text('Pick a time'), findsOneWidget);
      await pumpKumo(
        tester,
        _Host(key: UniqueKey(), initial: const KumoTimeValue(hour: 18, minute: 5)),
        brightness: b,
        center: false,
      );
      expect(find.text('6:05 PM'), findsOneWidget);
    }
  });

  testWidgets('wide: popover columns pick hour, minute and period', (tester) async {
    await _at(() async {
      await pumpKumo(tester, const _Host(minuteStep: 15), size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Pick a time'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoPopupSurface), findsOneWidget);
      // Minutes are listed on the 15-minute grid.
      expect(find.text('45'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
      await tester.tap(find.text('45'));
      await tester.pumpAndSettle();
      final state = tester.state<_HostState>(find.byType(_Host));
      // An empty value starts from now (10:22), on the grid.
      expect(state.value, const KumoTimeValue(hour: 10, minute: 45));
      await tester.tap(find.text('PM').last);
      await tester.pumpAndSettle();
      expect(state.value, const KumoTimeValue(hour: 22, minute: 45));
      expect(find.text('10:45 PM'), findsOneWidget);
    });
  });

  testWidgets('keyboard: columns are adjustable with arrows, Enter closes', (tester) async {
    await _at(() async {
      await pumpKumo(
        tester,
        const _Host(initial: KumoTimeValue(hour: 9, minute: 30), use24Hour: true),
        size: kumoDesktopSize,
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
        center: false,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final state = tester.state<_HostState>(find.byType(_Host));
      // The hour column has focus first.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(state.value, const KumoTimeValue(hour: 10, minute: 30));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(state.value, const KumoTimeValue(hour: 10, minute: 29));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(state.value, const KumoTimeValue(hour: 10, minute: 59));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(KumoPopupSurface), findsNothing);
    });
  });

  testWidgets('semantics: columns announce as adjustable values', (tester) async {
    await _at(() async {
      await pumpKumo(
        tester,
        const _Host(initial: KumoTimeValue(hour: 9, minute: 30)),
        size: kumoDesktopSize,
        center: false,
      );
      await tester.tap(find.text('9:30 AM'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Minutes')),
        containsSemantics(label: 'Minutes', value: '30', hasIncreaseAction: true, hasDecreaseAction: true),
      );
    });
  });

  testWidgets('narrow: wheels follow a fling, snap and report the value; Done closes', (tester) async {
    await _at(() async {
      await pumpKumo(tester, const _Host(initial: KumoTimeValue(hour: 9, minute: 30), use24Hour: true), center: false);
      await tester.tap(find.text('09:30'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoSheet), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsNWidgets(2));
      final state = tester.state<_HostState>(find.byType(_Host));
      final minutes = find.byType(ListWheelScrollView).at(1);
      // Drag up by three rows: the wheel follows and settles on 33.
      await tester.drag(minutes, const Offset(0, -132));
      await tester.pumpAndSettle();
      expect(state.value, const KumoTimeValue(hour: 9, minute: 33));
      // A fast flick travels further than the drag distance.
      await tester.fling(minutes, const Offset(0, -80), 3000);
      await tester.pumpAndSettle();
      expect((state.value!.minute - 33 + 60) % 60, greaterThan(3));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoSheet), findsNothing);
    });
  });

  testWidgets('narrow: Done on an empty value commits the time the wheels show', (tester) async {
    await _at(() async {
      await pumpKumo(tester, const _Host(use24Hour: true), center: false);
      await tester.tap(find.text('Pick a time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final state = tester.state<_HostState>(find.byType(_Host));
      expect(state.value, const KumoTimeValue(hour: 10, minute: 22));
    });
  });

  testWidgets('clear button resets the value', (tester) async {
    await pumpKumo(tester, const _Host(initial: KumoTimeValue(hour: 9)), center: false);
    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a time'), findsOneWidget);
  });

  testWidgets('reduced motion and text scale 2.0', (tester) async {
    await _at(() async {
      await pumpKumo(
        tester,
        const _Host(initial: KumoTimeValue(hour: 9)),
        center: false,
        disableAnimations: true,
        textScale: 2,
      );
      await tester.tap(find.text('9:00 AM'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
