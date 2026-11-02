import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _databases = <KumoSelectItem<String>>[
  KumoSelectOption(value: 'd1', label: 'D1'),
  KumoSelectOption(value: 'hyperdrive', label: 'Hyperdrive'),
  KumoSelectOption(value: 'kv', label: 'Workers KV'),
  KumoSelectOption(value: 'do', label: 'Durable Objects', disabled: true),
  KumoSelectGroup(
    label: 'Storage',
    options: [
      KumoSelectOption(value: 'r2', label: 'R2 buckets'),
      KumoSelectOption(value: 'queues', label: 'Queues'),
    ],
  ),
];

class _Single extends StatefulWidget {
  const _Single({this.initial, this.onChange, this.disabled = false, this.loading = false, this.filter});

  final String? initial;
  final ValueChanged<String?>? onChange;
  final bool disabled;
  final bool loading;
  final KumoOptionFilter<String>? filter;

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 300,
        child: KumoCombobox<String>(
          label: 'Database',
          placeholder: 'Search databases',
          options: _databases,
          value: value,
          disabled: widget.disabled,
          loading: widget.loading,
          filter: widget.filter,
          onValueChange: (v) {
            widget.onChange?.call(v);
            setState(() => value = v);
          },
        ),
      ),
    ),
  );
}

class _Multi extends StatefulWidget {
  const _Multi({this.inputSide = KumoComboboxInputSide.right});

  final KumoComboboxInputSide inputSide;

  @override
  State<_Multi> createState() => _MultiState();
}

class _MultiState extends State<_Multi> {
  List<String> values = ['d1', 'kv'];

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 300,
        child: KumoCombobox<String>.multiple(
          label: 'Bindings',
          placeholder: 'Add a binding',
          inputSide: widget.inputSide,
          options: _databases,
          values: values,
          onValuesChange: (v) => setState(() => values = v),
        ),
      ),
    ),
  );
}

Finder get _input => find.byType(TextField);

void main() {
  testWidgets('renders in light and dark, with the chosen label in the field', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        const _Single(initial: 'kv'),
        brightness: b,
        size: kumoDesktopSize,
        center: false,
      );
      expect(find.text('Workers KV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('typing filters, highlights the first match and Enter picks it', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Single(onChange: picked.add), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuRow), findsNWidgets(6));
    await tester.enterText(_input, 'qu');
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuRow), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, ['queues']);
    expect(find.byType(KumoMenuRow), findsNothing);
    expect(tester.widget<TextField>(_input).controller!.text, 'Queues');
    // Focus stayed in the field.
    expect(tester.widget<TextField>(_input).focusNode!.hasFocus, isTrue);
  });

  testWidgets('arrows move the highlight past disabled rows while focus stays in the field', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Single(onChange: picked.add), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.pump();
    final lit = tester.widgetList<KumoMenuRow>(find.byType(KumoMenuRow)).where((r) => r.highlighted).single;
    expect(lit.label, 'R2 buckets');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, ['r2']);
  });

  testWidgets('no matches shows the empty state from KumoStrings', (tester) async {
    await pumpKumo(tester, const _Single(), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    await pumpKumo(
      tester,
      const KumoLocale(
        strings: KumoStrings(noResults: 'Tidak ada hasil'),
        child: _Single(),
      ),
      size: kumoDesktopSize,
      center: false,
    );
    await tester.tap(_input);
    await tester.enterText(_input, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada hasil'), findsOneWidget);
  });

  testWidgets('custom filter replaces the substring match', (tester) async {
    await pumpKumo(tester, _Single(filter: (o, q) => o.value.startsWith(q)), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'r');
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuRow), findsOneWidget);
    expect(find.text('R2 buckets'), findsOneWidget);
  });

  testWidgets('loading shows a loading row instead of the empty state', (tester) async {
    await pumpKumo(tester, const _Single(loading: true), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.enterText(_input, 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('No results'), findsNothing);
    expect(find.byType(KumoLoader), findsOneWidget);
  });

  testWidgets('clear button resets the value; Escape closes and reverts typed text', (tester) async {
    final picked = <String?>[];
    await pumpKumo(
      tester,
      _Single(initial: 'd1', onChange: picked.add),
      size: kumoDesktopSize,
      center: false,
    );
    await tester.tap(_input);
    await tester.enterText(_input, 'hyp');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuRow), findsNothing);
    expect(tester.widget<TextField>(_input).controller!.text, 'D1');

    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pumpAndSettle();
    expect(picked, [null]);
    expect(tester.widget<TextField>(_input).controller!.text, isEmpty);
  });

  testWidgets('disabled does not open or accept text', (tester) async {
    await pumpKumo(tester, const _Single(disabled: true), size: kumoDesktopSize, center: false);
    await tester.tap(_input, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuRow), findsNothing);
    expect(tester.widget<TextField>(_input).enabled, isFalse);
  });

  testWidgets('multiple: chips render, picks toggle and keep the list open', (tester) async {
    await pumpKumo(tester, const _Multi(), size: kumoDesktopSize, center: false);
    expect(find.text('D1'), findsOneWidget);
    expect(find.text('Workers KV'), findsOneWidget);
    await tester.tap(_input);
    await tester.enterText(_input, 'hyp');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Hyperdrive'), findsNWidgets(2));
    expect(tester.widget<TextField>(_input).controller!.text, isEmpty);
    expect(find.byType(KumoMenuPanel), findsOneWidget);
  });

  testWidgets('multiple: Backspace on empty input and the X button remove chips', (tester) async {
    await pumpKumo(tester, const _Multi(), size: kumoDesktopSize, center: false);
    await tester.tap(_input);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(find.text('Workers KV'), findsOneWidget); // still listed in the open menu
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Workers KV'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Remove D1'));
    await tester.pumpAndSettle();
    expect(find.text('D1'), findsNothing);
  });

  testWidgets('multiple with the input on top, at 390px and 2x text, does not overflow', (tester) async {
    await pumpKumo(tester, const _Multi(inputSide: KumoComboboxInputSide.top), textScale: 2, center: false);
    await tester.tap(_input);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip remove targets reach 44px wide on touch', (tester) async {
    await pumpKumo(tester, const _Multi(), center: false);
    final remove = find.bySemanticsLabel('Remove D1');
    final rect = tester.getRect(remove);
    // A tap 10px past the X still removes the chip.
    await tester.tapAt(rect.centerRight + const Offset(10, 0));
    await tester.pumpAndSettle();
    expect(find.text('D1'), findsNothing);
  });

  testWidgets('semantics: text field with a label and expanded state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Single(), size: kumoDesktopSize, center: false);
    expect(find.bySemanticsLabel('Database'), findsWidgets);
    await tester.tap(_input);
    await tester.pumpAndSettle();
    final expandable = find.byWidgetPredicate((w) => w is Semantics && w.properties.expanded != null);
    expect(tester.getSemantics(expandable), containsSemantics(isExpanded: true));
    handle.dispose();
  });

  testWidgets('opens above the field when the keyboard covers the room below', (tester) async {
    await pumpKumo(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
          child: const Align(
            alignment: Alignment(0, 0.2),
            child: SizedBox(width: 300, child: KumoCombobox<String>(options: _databases)),
          ),
        ),
      ),
      center: false,
    );
    await tester.tap(_input);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.byType(KumoMenuPanel)).dy, lessThan(tester.getTopLeft(_input).dy));
  });
}
