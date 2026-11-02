import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

/// A parent that owns the value, the way an app would.
class _Controlled extends StatefulWidget {
  const _Controlled({this.transform, this.onChange});

  final String Function(String)? transform;
  final ValueChanged<String>? onChange;

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  String value = '';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      KumoInput(
        label: 'Worker name',
        value: value,
        onValueChange: (v) {
          widget.onChange?.call(v);
          setState(() => value = widget.transform?.call(v) ?? v);
        },
      ),
      KumoButton(label: 'Reset', onPress: () => setState(() => value = 'image-resizer')),
    ],
  );
}

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
                KumoInput(size: s, label: s.name, placeholder: 'example.com', leadingIcon: KumoIcons.globe),
              const KumoInput(label: 'Token', error: 'Token expired', value: 'abc'),
              const KumoInput(label: 'Zone', readOnly: true, value: 'example.com'),
              const KumoInput(label: 'Zone', disabled: true, value: 'example.com'),
            ],
          ),
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('heights match Kumo field sizes', (tester) async {
    for (final s in KumoFieldSize.values) {
      await pumpKumo(
        tester,
        SizedBox(
          width: 300,
          child: KumoInput(size: s, semanticLabel: 'Name'),
        ),
      );
      expect(tester.getSize(find.byType(KumoFieldBox)).height, s.height);
    }
  });

  testWidgets('typing calls onValueChange and the parent value is shown', (tester) async {
    final changes = <String>[];
    await pumpKumo(tester, SizedBox(width: 300, child: _Controlled(onChange: changes.add)));
    await tester.enterText(find.byType(EditableText), 'api-gateway');
    await tester.pump();
    expect(changes.last, 'api-gateway');
    expect(find.text('api-gateway'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('image-resizer'), findsOneWidget);
  });

  testWidgets('caret stays put when the value matches, and clamps when it changes', (tester) async {
    final controller = TextEditingController();
    var value = 'example.com';
    late StateSetter set;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return KumoInput(semanticLabel: 'Zone', controller: controller, value: value, onValueChange: (v) {});
          },
        ),
      ),
    );
    expect(controller.text, 'example.com');
    controller.selection = const TextSelection.collapsed(offset: 3);
    set(() {});
    await tester.pump();
    expect(controller.selection.baseOffset, 3);

    set(() => value = 'ex');
    await tester.pump();
    expect(controller.text, 'ex');
    expect(controller.selection.baseOffset, 2);
  });

  testWidgets('a parent that transforms the value keeps the caret', (tester) async {
    await pumpKumo(tester, SizedBox(width: 300, child: _Controlled(transform: (v) => v.toLowerCase())));
    await tester.enterText(find.byType(EditableText), 'API');
    await tester.pump();
    expect(find.text('api'), findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.selection.baseOffset, 3);
  });

  testWidgets('disabled and read-only fields do not edit', (tester) async {
    var changes = 0;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInput(semanticLabel: 'Zone', disabled: true, onValueChange: (_) => changes++),
      ),
    );
    await tester.tap(find.byType(KumoInput));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);

    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInput(semanticLabel: 'Zone', readOnly: true, value: 'a', onValueChange: (_) => changes++),
      ),
    );
    await tester.tap(find.byType(KumoInput));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'b').catchError((_) {});
    expect(tester.widget<EditableText>(find.byType(EditableText)).readOnly, isTrue);
    expect(changes, 0);
  });

  testWidgets('label, description and error render; error replaces description', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(label: 'Email', description: 'Receipts go here', showOptional: true),
      ),
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('(optional)'), findsOneWidget);
    expect(find.text('Receipts go here'), findsOneWidget);

    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(label: 'Email', description: 'Receipts go here', error: 'Enter a valid email address'),
      ),
    );
    expect(find.text('Receipts go here'), findsNothing);
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('error without a label still shows', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(semanticLabel: 'Hostname', error: 'Enter a valid hostname'),
      ),
    );
    expect(find.text('Enter a valid hostname'), findsOneWidget);
  });

  testWidgets('semantics: the field carries the label, hint, required and invalid state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(label: 'Email', description: 'Receipts go here', required: true),
      ),
    );
    final node = tester.getSemantics(find.byType(EditableText));
    final data = node.getSemanticsData();
    expect(data.label, 'Email');
    expect(data.hint, 'Receipts go here');
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.flagsCollection.isRequired, Tristate.isTrue);

    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(label: 'Email', error: 'Enter a valid email'),
      ),
    );
    final invalid = tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(invalid.validationResult, SemanticsValidationResult.invalid);
    expect(invalid.hint, 'Enter a valid email');
    handle.dispose();
  });

  testWidgets('bare input is named by semanticLabel', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const SizedBox(width: 300, child: KumoInput(semanticLabel: 'Search Workers')));
    expect(tester.getSemantics(find.byType(EditableText)).getSemanticsData().label, 'Search Workers');
    handle.dispose();
  });

  testWidgets('tapping the label focuses the field', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInput(label: 'Worker name', focusNode: focus),
      ),
    );
    await tester.tap(find.text('Worker name'));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('Tab moves focus into the field, focus shows the ring', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInput(semanticLabel: 'Name', focusNode: focus),
      ),
    );
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).focused, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).focused, isTrue);
  });

  testWidgets('passwordManagerIgnore drops autofill hints and suggestions', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(
          semanticLabel: 'API token',
          obscureText: true,
          autofillHints: [AutofillHints.password],
          passwordManagerIgnore: true,
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, isNull);
    expect(field.enableSuggestions, isFalse);
    expect(field.obscureText, isTrue);
  });

  testWidgets('keyboard type and autofill hints pass through', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          autofillHints: [AutofillHints.email],
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.emailAddress);
    expect(field.autofillHints, [AutofillHints.email]);
  });

  testWidgets('text scale 2.0 grows the field instead of clipping, no overflow at 390px', (tester) async {
    await pumpKumo(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: KumoInput(
          label: 'A long label for a Worker route pattern',
          labelTooltip: 'Routes match requests to this Worker',
          description: 'Use a wildcard such as example.com/* to match every path.',
          placeholder: 'example.com/*',
          leadingIcon: KumoIcons.link,
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(KumoFieldBox)).height, greaterThan(36));
  });

  testWidgets('focused field scrolls into view inside a scroll view', (tester) async {
    final focus = FocusNode();
    final scroll = ScrollController();
    addTearDown(focus.dispose);
    addTearDown(scroll.dispose);
    await pumpKumo(
      tester,
      SingleChildScrollView(
        controller: scroll,
        child: Column(
          children: [
            const SizedBox(height: 1200),
            KumoInput(label: 'Route', description: 'Path pattern', focusNode: focus),
            const SizedBox(height: 400),
          ],
        ),
      ),
      center: false,
    );
    expect(scroll.offset, 0);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    final box = tester.getRect(find.byType(KumoFieldBox));
    expect(box.bottom, lessThanOrEqualTo(kumoPhoneSize.height));
    expect(box.top, greaterThanOrEqualTo(0));
  });

  testWidgets('RTL puts the leading icon on the right', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInput(semanticLabel: 'Search', leadingIcon: KumoIcons.magnifyingGlass),
      ),
      textDirection: TextDirection.rtl,
    );
    expect(tester.getCenter(find.byType(KumoIcon)).dx, greaterThan(tester.getCenter(find.byType(EditableText)).dx));
  });
}
