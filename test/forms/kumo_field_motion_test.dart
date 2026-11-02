import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

/// An input whose error the test switches from outside.
class _Host extends StatefulWidget {
  const _Host({this.label, this.description});

  final String? label;
  final String? description;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? error;
  String value = '';

  void setError(String? e) => setState(() => error = e);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KumoInput(
          label: widget.label,
          semanticLabel: 'Hostname',
          description: widget.description,
          error: error,
          value: value,
          onValueChange: (v) => setState(() => value = v),
        ),
        const SizedBox(key: ValueKey('below'), height: 10),
      ],
    ),
  );
}

_HostState _host(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host));

double _belowTop(WidgetTester tester) => tester.getTopLeft(find.byKey(const ValueKey('below'))).dy;

const _long =
    'Enter a fully qualified hostname such as api.example.com, without a scheme, path or port, so the record resolves.';

void main() {
  testWidgets('an error grows in and fades in, so the content below slides', (tester) async {
    await pumpKumo(tester, const _Host(label: 'Hostname'));
    final before = _belowTop(tester);
    _host(tester).setError('Enter a valid hostname');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _belowTop(tester);
    final fade = tester
        .widgetList<FadeTransition>(find.ancestor(of: find.text('Enter a valid hostname'), matching: find.byType(FadeTransition)))
        .firstWhere((f) => f.alwaysIncludeSemantics);
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    final after = _belowTop(tester);
    expect(mid, inExclusiveRange(before, after));
  });

  testWidgets('a cleared error closes its space the same way, then leaves the tree', (tester) async {
    await pumpKumo(tester, const _Host(label: 'Hostname'));
    final before = _belowTop(tester);
    _host(tester).setError('Enter a valid hostname');
    await tester.pumpAndSettle();
    final open = _belowTop(tester);
    _host(tester).setError(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_belowTop(tester), inExclusiveRange(before, open));
    expect(find.text('Enter a valid hostname'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid hostname'), findsNothing);
    expect(_belowTop(tester), before);
  });

  testWidgets('description and error cross-fade when they swap', (tester) async {
    await pumpKumo(tester, const _Host(label: 'Hostname', description: 'A fully qualified domain name.'));
    _host(tester).setError('Enter a valid hostname');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('A fully qualified domain name.'), findsOneWidget);
    expect(find.text('Enter a valid hostname'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('A fully qualified domain name.'), findsNothing);
  });

  testWidgets('reduced motion: messages of any size appear and swap at once, nothing keeps running', (tester) async {
    await pumpKumo(tester, const _Host(label: 'Hostname', description: 'Short.'), disableAnimations: true);
    final before = _belowTop(tester);
    _host(tester).setError(_long);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Short.'), findsNothing);
    expect(_belowTop(tester), greaterThan(before + 20));
    expect(tester.hasRunningAnimations, isFalse);
    _host(tester).setError('Bad');
    await tester.pump();
    expect(tester.takeException(), isNull);
    _host(tester).setError(null);
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Bad'), findsNothing);
    expect(_belowTop(tester), before);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('an error on an unlabeled field keeps the field focused and its text', (tester) async {
    await pumpKumo(tester, const _Host());
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'exa mple');
    await tester.pump();
    final editable = tester.state(find.byType(EditableText));
    _host(tester).setError('Enter a valid hostname');
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(EditableText)), same(editable));
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    _host(tester).setError(null);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(EditableText)), same(editable));
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    expect(find.text('exa mple'), findsOneWidget);
  });
}
