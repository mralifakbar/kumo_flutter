import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({
    this.initial = const ['https://example.com'],
    this.validate,
    this.maxValues,
    this.allowDuplicates = false,
    this.readOnly = false,
    this.disabled = false,
    this.labels = const KumoTagInputLabels(),
  });

  final List<String> initial;
  final KumoTagValidator? validate;
  final int? maxValues;
  final bool allowDuplicates;
  final bool readOnly;
  final bool disabled;
  final KumoTagInputLabels labels;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<String> tags = widget.initial;
  int changes = 0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KumoTagInput(
              label: 'Allowed origins',
              placeholder: 'Add an origin',
              value: tags,
              validateValue: widget.validate,
              maxValues: widget.maxValues,
              allowDuplicates: widget.allowDuplicates,
              readOnly: widget.readOnly,
              disabled: widget.disabled,
              labels: widget.labels,
              onValueChange: (v) => setState(() {
                changes++;
                tags = v;
              }),
            ),
            Text('tags=${tags.join('|')}'),
            Text('changes=$changes'),
          ],
        ),
      );
}

Finder get _input => find.byType(TextField);

String? _https(String v, List<String> _) => v.startsWith('https://') ? null : 'Origins must start with https://';

void main() {
  testWidgets('renders tags in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Host(), brightness: b);
      expect(find.text('https://example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Enter and comma add tags; whitespace is trimmed', (tester) async {
    await pumpKumo(tester, const _Host(initial: []));
    await tester.tap(_input);
    await tester.enterText(_input, '  https://a.dev ');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('tags=https://a.dev'), findsOneWidget);
    expect(tester.widget<TextField>(_input).controller!.text, isEmpty);
    await tester.enterText(_input, 'https://b.dev,');
    await tester.pump();
    expect(find.text('tags=https://a.dev|https://b.dev'), findsOneWidget);
    // The soft keyboard's done action adds too.
    await tester.enterText(_input, 'https://c.dev');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('tags=https://a.dev|https://b.dev|https://c.dev'), findsOneWidget);
  });

  testWidgets('a paste with commas and line breaks adds each part', (tester) async {
    await pumpKumo(tester, const _Host(initial: []));
    await tester.tap(_input);
    await tester.enterText(_input, 'a.dev, b.dev\nc.dev');
    await tester.pump();
    expect(find.text('tags=a.dev|b.dev|c.dev'), findsOneWidget);
    expect(find.text('changes=1'), findsOneWidget);
  });

  testWidgets('a rejected tag stays in the input with the message; editing clears it', (tester) async {
    await pumpKumo(tester, const _Host(initial: [], validate: _https));
    await tester.tap(_input);
    await tester.enterText(_input, 'https://ok.dev, http://bad.dev, https://later.dev');
    await tester.pump();
    expect(find.text('tags=https://ok.dev'), findsOneWidget);
    expect(find.text('Origins must start with https://'), findsOneWidget);
    expect(tester.widget<TextField>(_input).controller!.text, 'http://bad.dev, https://later.dev');
    await tester.enterText(_input, 'https://bad.dev, https://later.dev');
    await tester.pump();
    expect(find.text('Origins must start with https://'), findsNothing);
  });

  testWidgets('empty validator message falls back to the invalidValue label', (tester) async {
    await pumpKumo(tester, _Host(initial: const [], validate: (v, _) => v.contains(' ') ? '' : null));
    await tester.tap(_input);
    await tester.enterText(_input, 'has space');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('"has space" is not valid'), findsOneWidget);
  });

  testWidgets('maxValues stops adding and says why; duplicates are skipped', (tester) async {
    await pumpKumo(tester, const _Host(initial: ['a'], maxValues: 2));
    await tester.tap(_input);
    await tester.enterText(_input, 'a, b, c');
    await tester.pump();
    expect(find.text('tags=a|b'), findsOneWidget);
    expect(find.text('You can add up to 2'), findsOneWidget);
    expect(tester.widget<TextField>(_input).controller!.text, 'c');
  });

  testWidgets('allowDuplicates accepts a repeated tag', (tester) async {
    await pumpKumo(tester, const _Host(initial: ['a'], allowDuplicates: true));
    await tester.tap(_input);
    await tester.enterText(_input, 'a,');
    await tester.pump();
    expect(find.text('tags=a|a'), findsOneWidget);
  });

  testWidgets('Backspace in the empty input and the X button remove tags', (tester) async {
    await pumpKumo(tester, const _Host(initial: ['a', 'b', 'c']));
    await tester.tap(_input);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(find.text('tags=a|b'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Remove a'));
    await tester.pump();
    expect(find.text('tags=b'), findsOneWidget);
  });

  testWidgets('leaving the field adds what was typed', (tester) async {
    await pumpKumo(tester, const _Host(initial: []));
    await tester.tap(_input);
    await tester.enterText(_input, 'pending.dev');
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    expect(find.text('tags=pending.dev'), findsOneWidget);
  });

  testWidgets('readOnly and disabled block adding and removing', (tester) async {
    for (final host in const [_Host(initial: ['a'], readOnly: true), _Host(initial: ['a'], disabled: true)]) {
      await pumpKumo(tester, host);
      await tester.tap(find.bySemanticsLabel('Remove a'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('tags=a'), findsOneWidget);
    }
  });

  testWidgets('labels localize the generated copy', (tester) async {
    await pumpKumo(
      tester,
      _Host(
        initial: const ['uno'],
        maxValues: 1,
        labels: KumoTagInputLabels(removeValue: (v) => 'Eliminar $v', maxValuesReached: (n) => 'Maximo de $n etiquetas.'),
      ),
    );
    expect(find.bySemanticsLabel('Eliminar uno'), findsOneWidget);
    await tester.tap(_input);
    await tester.enterText(_input, 'dos,');
    await tester.pump();
    expect(find.text('Maximo de 1 etiquetas.'), findsOneWidget);
  });

  testWidgets('the error is announced as a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(initial: [], validate: _https));
    await tester.tap(_input);
    await tester.enterText(_input, 'ftp://x,');
    await tester.pump();
    expect(
      tester.getSemantics(find.ancestor(of: find.text('Origins must start with https://'), matching: find.byType(Semantics)).first),
      containsSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('many tags wrap at 390px and 2x text without overflow', (tester) async {
    await pumpKumo(
      tester,
      _Host(initial: [for (var i = 0; i < 6; i++) 'worker-$i.example.workers.dev']),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    final field = tester.getRect(find.byType(KumoFieldBox));
    expect(field.width, lessThanOrEqualTo(390));
    expect(field.height, greaterThan(100));
  });

  testWidgets('RTL lays tags out from the right', (tester) async {
    await pumpKumo(tester, const _Host(initial: ['a', 'b']), textDirection: TextDirection.rtl);
    expect(tester.getCenter(find.text('a')).dx, greaterThan(tester.getCenter(find.text('b')).dx));
  });

  double chipWidth(WidgetTester tester, String label) => tester
      .getSize(
        find
            .ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_ChipReveal'))
            .first,
      )
      .width;

  testWidgets('a new tag grows in and a removed one shrinks out while the next slides over', (tester) async {
    await pumpKumo(tester, const _Host(initial: ['a.example.com', 'b.example.com']));
    final bLeft = tester.getTopLeft(find.text('b.example.com')).dx;
    await tester.tap(_input);
    await tester.enterText(_input, 'https://c.example.com,');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final full = tester.getSize(find.text('https://c.example.com')).width;
    expect(chipWidth(tester, 'https://c.example.com'), inExclusiveRange(0, full + 40));
    expect(chipWidth(tester, 'https://c.example.com'), lessThan(full));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Remove a.example.com'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Still on screen, part of the way out; the next tag is part of the way over.
    expect(find.text('a.example.com'), findsOneWidget);
    final mid = tester.getTopLeft(find.text('b.example.com')).dx;
    await tester.pumpAndSettle();
    expect(find.text('a.example.com'), findsNothing);
    final end = tester.getTopLeft(find.text('b.example.com')).dx;
    expect(mid, inExclusiveRange(end, bLeft));
    expect(find.text('tags=b.example.com|https://c.example.com'), findsOneWidget);
  });

  testWidgets('reduced motion adds and removes tags at once', (tester) async {
    await pumpKumo(tester, const _Host(initial: ['a.example.com', 'b.example.com']), disableAnimations: true);
    await tester.tap(find.bySemanticsLabel('Remove a.example.com'));
    await tester.pump();
    expect(find.text('a.example.com'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.tap(_input);
    await tester.enterText(_input, 'https://c.example.com,');
    await tester.pump();
    expect(chipWidth(tester, 'https://c.example.com'), greaterThan(tester.getSize(find.text('https://c.example.com')).width));
  });

  testWidgets('an invalid tag shows its error with a short open and fade, no shake', (tester) async {
    await pumpKumo(tester, const _Host(initial: [], validate: _https));
    await tester.tap(_input);
    await tester.enterText(_input, 'ftp://x,');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final fade = tester
        .widgetList<FadeTransition>(
          find.ancestor(of: find.text('Origins must start with https://'), matching: find.byType(FadeTransition)),
        )
        .firstWhere((f) => f.alwaysIncludeSemantics);
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    // No shake: nothing in the field is translated.
    expect(find.descendant(of: find.byType(KumoTagInput), matching: find.byType(FractionalTranslation)), findsNothing);
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
  });
}
