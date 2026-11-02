import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Code extends StatefulWidget {
  const _Code({this.onComplete, this.alphanumeric = false, this.length = 6, this.groups});

  final ValueChanged<String>? onComplete;
  final bool alphanumeric;
  final int length;
  final List<int>? groups;

  @override
  State<_Code> createState() => _CodeState();
}

class _CodeState extends State<_Code> {
  String code = '';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      KumoInputOtp(
        label: 'Verification code',
        length: widget.length,
        groups: widget.groups,
        alphanumeric: widget.alphanumeric,
        value: code,
        onComplete: widget.onComplete,
        onValueChange: (v) => setState(() => code = v),
      ),
      Text('code: $code'),
    ],
  );
}

EditableText _editable(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText));

void main() {
  testWidgets('renders sizes, groups and states in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final s in KumoFieldSize.values) KumoInputOtp(size: s, label: s.name, value: '12'),
              const KumoInputOtp(label: 'Code', groups: [3, 3], value: '123456'),
              const KumoInputOtp(label: 'Code', value: '1234', error: 'That code has expired'),
              const KumoInputOtp(label: 'Code', disabled: true),
              const KumoInputOtp(label: 'PIN', length: 4, obscureText: true, value: '12'),
            ],
          ),
        ),
        brightness: b,
        center: false,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('draws one cell per character with the typed characters', (tester) async {
    await pumpKumo(tester, const _Code());
    expect(find.byType(KumoFieldBox), findsNWidgets(6));
    await tester.enterText(find.byType(EditableText), '482');
    await tester.pump();
    expect(find.text('code: 482'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('cells are square and keep Kumo height', (tester) async {
    await pumpKumo(tester, const KumoInputOtp(semanticLabel: 'Code', size: KumoFieldSize.base));
    expect(tester.getSize(find.byType(KumoFieldBox).first), const Size(36, 36));
  });

  testWidgets('pasting a formatted code fills every cell and completes', (tester) async {
    final completed = <String>[];
    await pumpKumo(tester, _Code(onComplete: completed.add));
    await tester.enterText(find.byType(EditableText), '123 456');
    await tester.pump();
    expect(find.text('code: 123456'), findsOneWidget);
    expect(completed, ['123456']);
  });

  testWidgets('extra characters are dropped, letters rejected in numeric mode', (tester) async {
    await pumpKumo(tester, const _Code());
    await tester.enterText(find.byType(EditableText), '12ab345678');
    await tester.pump();
    expect(find.text('code: 123456'), findsOneWidget);
  });

  testWidgets('backspace clears the previous cell', (tester) async {
    await pumpKumo(tester, const _Code());
    await tester.showKeyboard(find.byType(EditableText));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: '123', selection: TextSelection.collapsed(offset: 3)),
    );
    await tester.pump();
    expect(find.text('code: 123'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(find.text('code: 12'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('the caret stays at the end so cells fill in order', (tester) async {
    await pumpKumo(tester, const _Code());
    await tester.enterText(find.byType(EditableText), '1234');
    await tester.pump();
    _editable(tester).controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump();
    expect(_editable(tester).controller.selection.baseOffset, 4);
  });

  testWidgets('the active cell shows the focus ring', (tester) async {
    await pumpKumo(tester, const _Code());
    await tester.tap(find.byType(KumoInputOtp));
    await tester.enterText(find.byType(EditableText), '12');
    await tester.pump();
    final boxes = tester.widgetList<KumoFieldBox>(find.byType(KumoFieldBox)).toList();
    expect([for (final b in boxes) b.focused], [false, false, true, false, false, false]);
  });

  testWidgets('number keyboard and one-time-code autofill', (tester) async {
    await pumpKumo(tester, const _Code());
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.number);
    expect(field.autofillHints, [AutofillHints.oneTimeCode]);
  });

  testWidgets('alphanumeric codes are uppercased', (tester) async {
    await pumpKumo(tester, const _Code(alphanumeric: true));
    await tester.enterText(find.byType(EditableText), 'ab12');
    await tester.pump();
    expect(find.text('code: AB12'), findsOneWidget);
  });

  testWidgets('groups add a separator between cells', (tester) async {
    await pumpKumo(tester, const _Code(groups: [3, 3]));
    expect(find.byIcon(KumoIcons.minus), findsOneWidget);
    final third = tester.getRect(find.byType(KumoFieldBox).at(2));
    final fourth = tester.getRect(find.byType(KumoFieldBox).at(3));
    final separator = tester.getCenter(find.byIcon(KumoIcons.minus)).dx;
    expect(separator, greaterThan(third.right));
    expect(separator, lessThan(fourth.left));
  });

  testWidgets('disabled does not accept input', (tester) async {
    await pumpKumo(tester, const KumoInputOtp(label: 'Code', disabled: true));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('semantics: one text field named by the label, cells hidden', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoInputOtp(label: 'Verification code', error: 'That code has expired'));
    final data = tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.label, 'Verification code');
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.hint, 'That code has expired');
    handle.dispose();
  });

  testWidgets('8 cells at text scale 2.0 fit 390px without overflow', (tester) async {
    await pumpKumo(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: _Code(length: 8, groups: [4, 4]),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(KumoFieldBox).last).right, lessThanOrEqualTo(390));
  });

  Finder caret() => find.byWidgetPredicate((w) => w.runtimeType.toString() == '_OtpCaret');
  double caretOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.descendant(of: caret(), matching: find.byType(Opacity))).opacity;

  testWidgets('the next empty cell shows a caret that blinks only while focused', (tester) async {
    await pumpKumo(tester, const _Code());
    expect(caret(), findsNothing);
    await tester.tap(find.byType(KumoInputOtp));
    await tester.enterText(find.byType(EditableText), '12');
    await tester.pump();
    expect(caret(), findsOneWidget);
    // In the third cell, the active one.
    final third = tester.widgetList<KumoFieldBox>(find.byType(KumoFieldBox)).elementAt(2);
    expect(find.descendant(of: find.byWidget(third), matching: caret()), findsOneWidget);
    expect(caretOpacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(caretOpacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(caretOpacity(tester), 1);
    // A blinking caret does not keep pumpAndSettle waiting.
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(caret(), findsNothing);
  });

  testWidgets('reduced motion: the caret holds still', (tester) async {
    await pumpKumo(tester, const _Code(), disableAnimations: true);
    await tester.tap(find.byType(KumoInputOtp));
    await tester.pump();
    expect(caretOpacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 600));
    expect(caretOpacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
