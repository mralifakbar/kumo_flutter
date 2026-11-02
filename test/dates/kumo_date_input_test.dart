import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.initial, this.format = KumoDateInputFormat.iso, this.minDate, this.disabled = false});

  final DateTime? initial;
  final KumoDateInputFormat format;
  final DateTime? minDate;
  final bool disabled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late DateTime? value = widget.initial;
  final changes = <DateTime?>[];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 280,
        child: KumoDateInput(
          label: 'Token expires on',
          value: value,
          format: widget.format,
          minDate: widget.minDate,
          disabled: widget.disabled,
          onValueChange: (d) => setState(() {
            changes.add(d);
            value = d;
          }),
        ),
      ),
    ),
  );
}

Future<void> _at(Future<void> Function() body) => withClock(Clock.fixed(DateTime(2026, 3, 4)), body);

void main() {
  test('formats parse and print, rejecting impossible days', () {
    expect(KumoDateInputFormat.iso.format(DateTime(2026, 3, 4)), '2026-03-04');
    expect(KumoDateInputFormat.mdy.format(DateTime(2026, 3, 4)), '03/04/2026');
    expect(KumoDateInputFormat.dmy.parse('04/03/2026'), DateTime(2026, 3, 4));
    expect(KumoDateInputFormat.iso.parse('2026-02-30'), isNull);
    expect(KumoDateInputFormat.iso.parse('2026-13-01'), isNull);
    expect(KumoDateInputFormat.iso.parse('2026-03'), isNull);
  });

  testWidgets('renders in light and dark with the pattern as placeholder', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Host(), brightness: b, center: false);
      expect(find.text('YYYY-MM-DD'), findsOneWidget);
      expect(find.text('Token expires on'), findsOneWidget);
    }
  });

  testWidgets('typing inserts separators and reports a valid day', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    final state = tester.state<_HostState>(find.byType(_Host));
    await tester.enterText(find.byType(TextField), '2026');
    await tester.pump();
    expect(find.text('2026-'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '20260318');
    await tester.pump();
    expect(find.text('2026-03-18'), findsOneWidget);
    expect(state.value, DateTime(2026, 3, 18));
  });

  testWidgets('impossible and unavailable days show an announced error', (tester) async {
    await pumpKumo(tester, _Host(minDate: DateTime(2026, 3, 1)), center: false);
    final state = tester.state<_HostState>(find.byType(_Host));
    await tester.enterText(find.byType(TextField), '20260230');
    await tester.pump();
    expect(find.text('Enter a date as YYYY-MM-DD.'), findsOneWidget);
    expect(state.changes, isEmpty);
    await tester.enterText(find.byType(TextField), '20260210');
    await tester.pump();
    expect(find.text('This date is not available. Pick another day.'), findsOneWidget);
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).error, isTrue);
    await tester.enterText(find.byType(TextField), '20260310');
    await tester.pump();
    expect(find.textContaining('not available'), findsNothing);
    expect(state.value, DateTime(2026, 3, 10));
  });

  testWidgets('an incomplete date is an error only after leaving the field', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    await tester.enterText(find.byType(TextField), '2026');
    await tester.pump();
    expect(find.textContaining('Enter a date'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Enter a date as YYYY-MM-DD.'), findsOneWidget);
  });

  testWidgets('clearing the text reports null', (tester) async {
    await pumpKumo(tester, _Host(initial: DateTime(2026, 3, 4)), center: false);
    final state = tester.state<_HostState>(find.byType(_Host));
    expect(find.text('2026-03-04'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(state.value, isNull);
  });

  testWidgets('day-first format', (tester) async {
    await pumpKumo(tester, const _Host(format: KumoDateInputFormat.dmy), center: false);
    final state = tester.state<_HostState>(find.byType(_Host));
    await tester.enterText(find.byType(TextField), '04032026');
    await tester.pump();
    expect(find.text('04/03/2026'), findsOneWidget);
    expect(state.value, DateTime(2026, 3, 4));
  });

  testWidgets('calendar button opens a popover on wide screens and fills the field', (tester) async {
    await _at(() async {
      await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
      await tester.tap(find.bySemanticsLabel('Choose date from calendar'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoPopupSurface), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^Friday, March 20, 2026')));
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsNothing);
      expect(find.text('2026-03-20'), findsOneWidget);
      expect(tester.state<_HostState>(find.byType(_Host)).value, DateTime(2026, 3, 20));
    });
  });

  testWidgets('calendar opens in a sheet on phones', (tester) async {
    await _at(() async {
      await pumpKumo(tester, const _Host(), center: false);
      await tester.tap(find.bySemanticsLabel('Choose date from calendar'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoSheet), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('^Monday, March 9, 2026')));
      await tester.pumpAndSettle();
      expect(find.byType(KumoSheet), findsNothing);
      expect(find.text('2026-03-09'), findsOneWidget);
    });
  });

  testWidgets('Alt+Down opens the calendar and Escape closes it', (tester) async {
    await _at(() async {
      await pumpKumo(
        tester,
        const _Host(),
        size: kumoDesktopSize,
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
        center: false,
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsNothing);
    });
  });

  testWidgets('follows the parent value when not editing', (tester) async {
    await pumpKumo(tester, KumoDateInput(value: DateTime(2026, 3, 4)));
    expect(find.text('2026-03-04'), findsOneWidget);
    await pumpKumo(tester, KumoDateInput(value: DateTime(2026, 7, 1)));
    expect(find.text('2026-07-01'), findsOneWidget);
  });

  testWidgets('disabled blocks typing and the calendar', (tester) async {
    await pumpKumo(tester, const _Host(disabled: true), center: false);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.bySemanticsLabel('Choose date from calendar'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(KumoCalendar), findsNothing);
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await pumpKumo(tester, _Host(initial: DateTime(2026, 3, 4)), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
