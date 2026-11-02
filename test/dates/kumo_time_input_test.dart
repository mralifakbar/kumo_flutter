import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({
    this.initial,
    this.use24Hour = false,
    this.showSeconds = false,
    this.minuteStep = 1,
    this.disabled = false,
  });

  final KumoTimeValue? initial;
  final bool use24Hour;
  final bool showSeconds;
  final int minuteStep;
  final bool disabled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late KumoTimeValue? value = widget.initial;
  final changes = <KumoTimeValue?>[];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: KumoTimeInput(
      label: 'Backup window starts',
      value: value,
      use24Hour: widget.use24Hour,
      showSeconds: widget.showSeconds,
      minuteStep: widget.minuteStep,
      disabled: widget.disabled,
      onValueChange: (t) => setState(() {
        changes.add(t);
        value = t;
      }),
    ),
  );
}

Finder _part(String label) => find.descendant(of: find.bySemanticsLabel(label), matching: find.byType(EditableText));

void main() {
  test('KumoTimeValue formats, compares and converts', () {
    const t = KumoTimeValue(hour: 14, minute: 5, second: 9);
    expect(t.format(), '2:05 PM');
    expect(t.format(use24Hour: true, showSeconds: true), '14:05:09');
    expect(const KumoTimeValue(hour: 0).format(), '12:00 AM');
    expect(const KumoTimeValue(hour: 12).hour12, 12);
    expect(t.on(DateTime(2026, 3, 4)), DateTime(2026, 3, 4, 14, 5, 9));
    expect(t.compareTo(const KumoTimeValue(hour: 9)), greaterThan(0));
    expect(t, KumoTimeValue.fromDateTime(DateTime(2020, 1, 1, 14, 5, 9)));
    withClock(Clock.fixed(DateTime(2026, 3, 4, 8, 15)), () {
      expect(KumoTimeValue.now(), const KumoTimeValue(hour: 8, minute: 15));
    });
  });

  testWidgets('renders the value in light and dark, 12 and 24 hour', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Host(initial: KumoTimeValue(hour: 14, minute: 30)), brightness: b);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    }
    await pumpKumo(
      tester,
      const _Host(initial: KumoTimeValue(hour: 14, minute: 30), use24Hour: true, showSeconds: true),
    );
    expect(find.text('14'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);
    expect(find.text('PM'), findsNothing);
  });

  testWidgets('typing fills parts, auto-advances and reports a complete time', (tester) async {
    await pumpKumo(tester, const _Host(use24Hour: true));
    final state = tester.state<_HostState>(find.byType(_Host));
    await tester.tap(_part('Hours'));
    await tester.enterText(_part('Hours'), '9');
    await tester.pump();
    // "9" can not start a two-digit hour, so the hour is done.
    expect(find.text('09'), findsOneWidget);
    expect(state.changes, isEmpty);
    await tester.enterText(_part('Minutes'), '45');
    await tester.pump();
    expect(state.value, const KumoTimeValue(hour: 9, minute: 45));
  });

  testWidgets('arrow keys step and wrap; minute step snaps to the grid', (tester) async {
    await pumpKumo(tester, const _Host(initial: KumoTimeValue(hour: 23, minute: 7), use24Hour: true, minuteStep: 5));
    final state = tester.state<_HostState>(find.byType(_Host));
    await tester.tap(_part('Hours'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(state.value, const KumoTimeValue(hour: 0, minute: 7));
    await tester.tap(_part('Minutes'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(state.value, const KumoTimeValue(hour: 0, minute: 10));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(state.value, const KumoTimeValue(hour: 0, minute: 55));
  });

  testWidgets('AM/PM toggles by tap and by key, and is announced', (tester) async {
    await pumpKumo(tester, const _Host(initial: KumoTimeValue(hour: 9, minute: 0)));
    final state = tester.state<_HostState>(find.byType(_Host));
    expect(tester.getSemantics(find.bySemanticsLabel('AM or PM')), containsSemantics(value: 'AM', isButton: true));
    await tester.tap(find.text('AM'));
    await tester.pump();
    expect(state.value, const KumoTimeValue(hour: 21));
    await tester.tap(_part('Minutes'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pump();
    expect(state.value, const KumoTimeValue(hour: 9));
  });

  testWidgets('clearing every part reports null', (tester) async {
    await pumpKumo(tester, const _Host(initial: KumoTimeValue(hour: 9, minute: 5), use24Hour: true));
    final state = tester.state<_HostState>(find.byType(_Host));
    await tester.enterText(_part('Hours'), '');
    await tester.pump();
    expect(state.changes, isEmpty);
    await tester.enterText(_part('Minutes'), '');
    await tester.pump();
    expect(state.value, isNull);
  });

  testWidgets('shows a new value from the parent when not editing', (tester) async {
    await pumpKumo(tester, const KumoTimeInput(value: KumoTimeValue(hour: 9), use24Hour: true));
    expect(find.text('09'), findsOneWidget);
    await pumpKumo(tester, const KumoTimeInput(value: KumoTimeValue(hour: 18, minute: 20), use24Hour: true));
    expect(find.text('18'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('disabled parts do not edit', (tester) async {
    await pumpKumo(tester, const _Host(disabled: true, use24Hour: true));
    final field = tester.widget<TextField>(
      find.descendant(of: find.bySemanticsLabel('Hours'), matching: find.byType(TextField)),
    );
    expect(field.enabled, isFalse);
  });

  testWidgets('text scale 2.0 at 390px with seconds does not overflow', (tester) async {
    await pumpKumo(tester, const _Host(showSeconds: true, initial: KumoTimeValue(hour: 10)), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
