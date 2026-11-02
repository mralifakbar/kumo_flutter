import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Retries extends StatefulWidget {
  const _Retries({this.initial = 3, this.min = 0, this.max = 10, this.step = 1, this.fractionDigits, this.log});

  final double? initial;
  final double? min;
  final double? max;
  final double step;
  final int? fractionDigits;
  final List<double?>? log;

  @override
  State<_Retries> createState() => _RetriesState();
}

class _RetriesState extends State<_Retries> {
  late double? value = widget.initial;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KumoNumberInput(
          label: 'Max retries',
          value: value,
          min: widget.min,
          max: widget.max,
          step: widget.step,
          fractionDigits: widget.fractionDigits,
          onValueChange: (v) {
            widget.log?.add(v);
            setState(() => value = v);
          },
        ),
        Text('value: $value'),
      ],
    ),
  );
}

String _text(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  testWidgets('renders every size in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in KumoFieldSize.values)
                KumoNumberInput(size: s, label: s.name, value: 5, onValueChange: (_) {}),
              const KumoNumberInput(label: 'Port', value: 70000, error: 'Use a port from 1 to 65535'),
              const KumoNumberInput(label: 'Port', disabled: true, value: 8080),
            ],
          ),
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('steppers add and remove one step', (tester) async {
    await pumpKumo(tester, const _Retries());
    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.pump();
    expect(find.text('value: 4.0'), findsOneWidget);
    expect(_text(tester), '4');
    await tester.tap(find.bySemanticsLabel('Decrease'));
    await tester.tap(find.bySemanticsLabel('Decrease'));
    await tester.pump();
    expect(find.text('value: 2.0'), findsOneWidget);
  });

  testWidgets('steppers stop at the bounds and disable there', (tester) async {
    await pumpKumo(tester, const _Retries(initial: 9));
    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.pump();
    expect(find.text('value: 10.0'), findsOneWidget);
    final plus = tester.widget<KumoPressable>(
      find.ancestor(of: find.byIcon(KumoIcons.plus), matching: find.byType(KumoPressable)),
    );
    expect(plus.disabled, isTrue);
    await tester.tap(find.bySemanticsLabel('Increase'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('value: 10.0'), findsOneWidget);
  });

  testWidgets('press and hold repeats, and stops on release', (tester) async {
    final log = <double?>[];
    await pumpKumo(tester, _Retries(initial: 0, max: 100, log: log));
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(KumoIcons.plus)));
    await tester.pump();
    expect(log, [1]);
    // Nothing repeats before the hold delay.
    await tester.pump(const Duration(milliseconds: 300));
    expect(log.length, 1);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
    expect(log.length, 4);
    await gesture.up();
    await tester.pump();
    final afterRelease = log.length;
    // Released: no more steps, and no running timers or animations.
    await tester.pump(const Duration(seconds: 2));
    expect(log.length, afterRelease);
    expect(find.text('value: ${log.last}'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a hold stops by itself at the bound', (tester) async {
    final log = <double?>[];
    await pumpKumo(tester, _Retries(initial: 7, max: 10, log: log));
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(KumoIcons.plus)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(log, [8, 9, 10]);
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(log, [8, 9, 10]);
  });

  testWidgets('a quick tap steps once (press-in and press do not double up)', (tester) async {
    final log = <double?>[];
    await pumpKumo(tester, _Retries(log: log));
    await tester.tap(find.byIcon(KumoIcons.plus));
    await tester.pump(const Duration(seconds: 1));
    expect(log, [4]);
  });

  testWidgets('ArrowUp and ArrowDown step, Shift and PageUp take ten steps', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    double? value = 20;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: StatefulBuilder(
          builder: (context, setState) => KumoNumberInput(
            semanticLabel: 'Concurrency',
            value: value,
            max: 100,
            focusNode: focus,
            onValueChange: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(value, 21);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(value, 19);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pump();
    expect(value, 29);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(value, 19);
  });

  testWidgets('typing reports numbers in range; out of range shows the error ring and clamps on blur', (tester) async {
    final log = <double?>[];
    await pumpKumo(tester, _Retries(log: log));
    await tester.enterText(find.byType(EditableText), '7');
    await tester.pump();
    expect(log.last, 7);
    await tester.enterText(find.byType(EditableText), '42');
    await tester.pump();
    expect(log.last, 7);
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).error, isTrue);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(log.last, 10);
    expect(_text(tester), '10');
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).error, isFalse);
  });

  testWidgets('letters are rejected; a partial number reverts on blur', (tester) async {
    await pumpKumo(tester, const _Retries(min: -5));
    await tester.enterText(find.byType(EditableText), '3a');
    await tester.pump();
    expect(_text(tester), '3');
    await tester.enterText(find.byType(EditableText), '-');
    await tester.pump();
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).error, isFalse);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(_text(tester), '3');
  });

  testWidgets('no minus sign when min is zero or more', (tester) async {
    await pumpKumo(tester, const _Retries());
    await tester.enterText(find.byType(EditableText), '-2');
    await tester.pump();
    expect(_text(tester), '3');
  });

  testWidgets('clearing reports null', (tester) async {
    final log = <double?>[];
    await pumpKumo(tester, _Retries(log: log));
    await tester.enterText(find.byType(EditableText), '');
    await tester.pump();
    expect(log.last, isNull);
    expect(find.text('value: null'), findsOneWidget);
  });

  testWidgets('decimal steps do not drift and use fractionDigits', (tester) async {
    await pumpKumo(tester, const _Retries(initial: 0.1, min: 0, max: 1, step: 0.1, fractionDigits: 2));
    expect(_text(tester), '0.10');
    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.pump();
    expect(find.text('value: 0.3'), findsOneWidget);
    expect(_text(tester), '0.30');
  });

  testWidgets('a value from outside replaces the text', (tester) async {
    double? value = 1;
    late StateSetter set;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return KumoNumberInput(semanticLabel: 'Count', value: value, onValueChange: (v) {});
          },
        ),
      ),
    );
    set(() => value = 250);
    await tester.pump();
    expect(_text(tester), '250');
  });

  testWidgets('disabled and read-only do not step', (tester) async {
    var changes = 0;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoNumberInput(label: 'Count', value: 1, disabled: true, onValueChange: (_) => changes++),
      ),
    );
    await tester.tap(find.byIcon(KumoIcons.plus), warnIfMissed: false);
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoNumberInput(label: 'Count', value: 1, readOnly: true, onValueChange: (_) => changes++),
      ),
    );
    await tester.tap(find.byIcon(KumoIcons.plus), warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));
    expect(changes, 0);
  });

  testWidgets('semantics: increase and decrease actions on the field', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Retries());
    final data = tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.label, 'Max retries');
    expect(data.increasedValue, '4');
    expect(data.decreasedValue, '2');
    tester.semantics.performAction(find.semantics.byLabel('Max retries'), SemanticsAction.increase);
    await tester.pump();
    expect(find.text('value: 4.0'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('keyboard type is numeric', (tester) async {
    await pumpKumo(tester, const _Retries(min: -10, fractionDigits: 0));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, const TextInputType.numberWithOptions(signed: true, decimal: false));
  });

  testWidgets('text scale 2.0 at 390px does not overflow; steppers keep the field height', (tester) async {
    await pumpKumo(tester, const Padding(padding: EdgeInsets.all(16), child: _Retries()), textScale: 2);
    expect(tester.takeException(), isNull);
    await pumpKumo(tester, const _Retries());
    expect(tester.getSize(find.byType(KumoFieldBox)).height, 36);
  });

  double maxShift(WidgetTester tester) => tester
      .widgetList<Transform>(find.descendant(of: find.byType(KumoNumberInput), matching: find.byType(Transform)))
      .map((t) => t.transform.getTranslation().y.abs())
      .fold(0.0, (a, b) => a > b ? a : b);

  testWidgets('a step lands the new number with a short rise; reduced motion does not move it', (tester) async {
    await pumpKumo(tester, const _Retries());
    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(maxShift(tester), inExclusiveRange(0, 4));
    await tester.pumpAndSettle();
    expect(maxShift(tester), 0);

    await pumpKumo(tester, const _Retries(), disableAnimations: true);
    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.pump();
    expect(maxShift(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
