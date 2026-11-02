import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

double _boxHeight(WidgetTester tester) => tester.getSize(find.byType(KumoFieldBox)).height;

void main() {
  testWidgets('renders every size in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final s in KumoFieldSize.values) KumoInputArea(size: s, label: s.name, placeholder: 'Notes'),
              const KumoInputArea(label: 'Message', value: 'Hi', error: 'Write at least 10 characters'),
              const KumoInputArea(label: 'Notes', disabled: true),
            ],
          ),
        ),
        brightness: b,
        center: false,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('rows sets a fixed height that does not grow', (tester) async {
    await pumpKumo(tester, const SizedBox(width: 300, child: KumoInputArea(semanticLabel: 'Notes', rows: 2)));
    final two = _boxHeight(tester);
    await pumpKumo(tester, const SizedBox(width: 300, child: KumoInputArea(semanticLabel: 'Notes', rows: 4)));
    final four = _boxHeight(tester);
    // 14px text at 1.5 line height: 21px a row.
    expect(four - two, closeTo(42, 1));

    await tester.enterText(find.byType(EditableText), 'one\ntwo\nthree\nfour\nfive\nsix');
    await tester.pump();
    expect(_boxHeight(tester), four);
  });

  testWidgets('autoResize grows from minRows up to maxRows, then stops', (tester) async {
    var text = '';
    late StateSetter set;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return KumoInputArea(
              semanticLabel: 'Notes',
              autoResize: true,
              minRows: 2,
              maxRows: 4,
              value: text,
              onValueChange: (v) => setState(() => text = v),
            );
          },
        ),
      ),
    );
    final min = _boxHeight(tester);
    set(() => text = 'a\nb\nc');
    await tester.pump();
    final three = _boxHeight(tester);
    expect(three - min, closeTo(21, 1));
    set(() => text = 'a\nb\nc\nd\ne\nf\ng');
    await tester.pump();
    expect(_boxHeight(tester) - min, closeTo(42, 1));
  });

  testWidgets('typing calls onValueChange with newlines', (tester) async {
    String? last;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInputArea(label: 'Notes', onValueChange: (v) => last = v),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Line one\nLine two');
    expect(last, 'Line one\nLine two');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
  });

  testWidgets('semantics name the field and mark errors', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInputArea(label: 'Feedback', error: 'Write at least 20 characters'),
      ),
    );
    final data = tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.label, 'Feedback');
    expect(data.hint, 'Write at least 20 characters');
    expect(data.flagsCollection.isTextField, isTrue);
    handle.dispose();
  });

  testWidgets('disabled does not focus', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInputArea(label: 'Notes', disabled: true, focusNode: focus),
      ),
    );
    await tester.tap(find.byType(KumoFieldBox));
    await tester.tap(find.text('Notes'));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('text scale 2.0 at 390px does not overflow or clip', (tester) async {
    await pumpKumo(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: KumoInputArea(
          label: 'Worker script',
          labelTooltip: 'Paste the module source',
          placeholder: 'export default { async fetch(request) { return new Response("ok"); } }',
          rows: 2,
          mono: true,
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(_boxHeight(tester), greaterThan(2 * 42));
  });
}
