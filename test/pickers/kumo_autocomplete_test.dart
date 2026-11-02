import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

final _routes = <KumoSelectItem<String>>[
  ...KumoSelectOption.fromLabels(['example.com/*', 'api.example.com/*', 'example.com/images/*']),
  const KumoSelectGroup(label: 'Staging', options: [
    KumoSelectOption(value: 'staging.example.com/*', label: 'staging.example.com/*'),
  ]),
];

class _Host extends StatefulWidget {
  const _Host({this.emptyMessage, this.onOpenChange, this.disabled = false});

  final String? emptyMessage;
  final ValueChanged<bool>? onOpenChange;
  final bool disabled;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String value = '';

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KumoAutocomplete(
                  label: 'Route pattern',
                  placeholder: 'example.com/*',
                  options: _routes,
                  value: value,
                  emptyMessage: widget.emptyMessage,
                  onOpenChange: widget.onOpenChange,
                  disabled: widget.disabled,
                  onValueChange: (v) => setState(() => value = v),
                ),
                Text('value=$value'),
              ],
            ),
          ),
        ),
      );
}

Finder get _input => find.byType(TextField);

void main() {
  testWidgets('renders in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Host(), brightness: b, size: kumoDesktopSize, center: false);
      expect(find.text('Route pattern'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('free text is the value; suggestions narrow as you type', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'api');
    await tester.pumpAndSettle();
    expect(find.text('value=api'), findsOneWidget);
    expect(find.byType(KumoMenuRow), findsOneWidget);
    await tester.enterText(_input, 'my-zone.dev/*');
    await tester.pumpAndSettle();
    // Nothing matches: the list hides and the typed text stands.
    expect(find.byType(KumoMenuPanel), findsNothing);
    expect(find.text('value=my-zone.dev/*'), findsOneWidget);
  });

  testWidgets('tap or arrows plus Enter put a suggestion in the field', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'example');
    await tester.pumpAndSettle();
    await tester.tap(find.text('example.com/images/*'));
    await tester.pumpAndSettle();
    expect(find.text('value=example.com/images/*'), findsOneWidget);
    expect(find.byType(KumoMenuPanel), findsNothing);

    await tester.enterText(_input, 'stag');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('value=staging.example.com/*'), findsOneWidget);
  });

  testWidgets('Enter with nothing highlighted keeps the text; Escape closes', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'example');
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsNothing);
    expect(find.text('value=example'), findsOneWidget);
  });

  testWidgets('emptyMessage keeps the list open with a message; onOpenChange reports', (tester) async {
    final opens = <bool>[];
    await pumpKumo(tester, _Host(emptyMessage: 'No saved routes match', onOpenChange: opens.add), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No saved routes match'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(opens, [true, false]);
  });

  testWidgets('disabled does not open', (tester) async {
    await pumpKumo(tester, const _Host(disabled: true), size: kumoDesktopSize, center: false);
    await tester.tap(_input, warnIfMissed: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsNothing);
  });

  testWidgets('390px, 2x text and reduced motion do not overflow', (tester) async {
    await pumpKumo(tester, const _Host(), textScale: 2, disableAnimations: true, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'e');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics: labelled text field that reports expanded', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    expect(find.bySemanticsLabel('Route pattern'), findsWidgets);
    await tester.tap(_input);
    await tester.enterText(_input, 'example');
    await tester.pumpAndSettle();
    final expandable = find.byWidgetPredicate((w) => w is Semantics && w.properties.expanded != null);
    expect(tester.getSemantics(expandable), containsSemantics(isExpanded: true));
    handle.dispose();
  });
}
