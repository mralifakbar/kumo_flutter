import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _regions = <KumoSelectItem<String>>[
  KumoSelectOption(value: 'enam', label: 'Eastern North America'),
  KumoSelectOption(value: 'wnam', label: 'Western North America'),
  KumoSelectOption(value: 'sam', label: 'South America', disabled: true),
  KumoSelectSeparator(),
  KumoSelectGroup(label: 'Europe', options: [
    KumoSelectOption(value: 'weur', label: 'Western Europe'),
    KumoSelectOption(value: 'eeur', label: 'Eastern Europe'),
  ]),
];

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    this.initial,
    this.options = _regions,
    this.presentation = KumoPresentation.auto,
    this.disabled = false,
    this.loading = false,
    this.onChange,
  });

  final String? initial;
  final List<KumoSelectItem<String>> options;
  final KumoPresentation presentation;
  final bool disabled;
  final bool loading;
  final ValueChanged<String?>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 280,
            child: KumoSelect<String>(
              label: 'Region',
              placeholder: 'Choose a region',
              options: widget.options,
              value: value,
              presentation: widget.presentation,
              disabled: widget.disabled,
              loading: widget.loading,
              onValueChange: (v) {
                widget.onChange?.call(v);
                setState(() => value = v);
              },
            ),
          ),
        ),
      );
}

class _MultiHost extends StatefulWidget {
  const _MultiHost({this.presentation = KumoPresentation.auto});

  final KumoPresentation presentation;

  @override
  State<_MultiHost> createState() => _MultiHostState();
}

class _MultiHostState extends State<_MultiHost> {
  List<String> values = ['Name'];

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 280,
          child: KumoSelect<String>.multiple(
            label: 'Visible columns',
            presentation: widget.presentation,
            options: KumoSelectOption.fromLabels(['Name', 'Route', 'Status', 'Last deploy']),
            values: values,
            onValuesChange: (v) => setState(() => values = v),
          ),
        ),
      );
}

Finder _trigger() => find.byType(KumoFieldBox);

void main() {
  testWidgets('renders placeholder, label and value in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Host(), brightness: b, size: kumoDesktopSize, center: false);
      expect(find.text('Region'), findsOneWidget);
      expect(find.text('Choose a region'), findsOneWidget);
      await pumpKumo(tester, _Host(key: UniqueKey(), initial: 'weur'), brightness: b, size: kumoDesktopSize, center: false);
      expect(find.text('Western Europe'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('wide: tap opens an anchored list, pick reports value and closes', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Host(onChange: picked.add), size: kumoDesktopSize, center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    expect(find.text('Europe'), findsOneWidget);
    expect(find.byType(KumoMenuSeparator), findsOneWidget);
    expect(tester.getTopLeft(find.byType(KumoMenuPanel)).dy, greaterThan(tester.getBottomLeft(_trigger()).dy));
    expect(tester.getSize(find.byType(KumoMenuPanel)).width, greaterThanOrEqualTo(280));
    await tester.tap(find.text('Western Europe'));
    await tester.pumpAndSettle();
    expect(picked, ['weur']);
    expect(find.byType(KumoMenuPanel), findsNothing);
    expect(find.text('Western Europe'), findsOneWidget);
  });

  testWidgets('disabled options and disabled or loading selects do not pick or open', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Host(onChange: picked.add), size: kumoDesktopSize, center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    await tester.tap(find.text('South America'));
    await tester.pumpAndSettle();
    expect(picked, isEmpty);

    await pumpKumo(tester, const _Host(disabled: true), size: kumoDesktopSize, center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsNothing);

    await pumpKumo(tester, const _Host(loading: true), size: kumoDesktopSize, center: false);
    expect(find.text('Choose a region'), findsNothing);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsNothing);
  });

  testWidgets('keyboard: Tab focuses, arrows open and move, Enter picks, Escape closes', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Host(initial: 'enam', onChange: picked.add), size: kumoDesktopSize, center: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    // Highlight starts on the current value; down moves to the next, and
    // the disabled row is skipped on the way to Europe.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, ['weur']);
    expect(find.byType(KumoMenuPanel), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsNothing);
    // Focus came back to (stayed on) the trigger.
    final focused = FocusManager.instance.primaryFocus!;
    expect(focused.context!.findAncestorWidgetOfExactType<KumoSelect<String>>(), isNotNull);
  });

  testWidgets('typeahead jumps to the matching option, open and closed', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Host(onChange: picked.add), size: kumoDesktopSize, center: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    // Closed: typing picks directly, like a native select.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pump();
    expect(picked.last, 'wnam');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pump();
    expect(picked.last, 'weur');

    await tester.pump(const Duration(seconds: 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    // Highlight starts on Western Europe; "e" moves to the next E option,
    // and "e" again cycles to the first one.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked.last, 'enam');
  });

  testWidgets('semantics: button with expanded state, label and value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(initial: 'enam'), size: kumoDesktopSize, center: false);
    expect(
      tester.getSemantics(find.byType(KumoPressable).first),
      matchesSemantics(
        isButton: true,
        label: 'Region',
        value: 'Eastern North America',
        hasExpandedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.byType(KumoPressable).first), containsSemantics(isExpanded: true));
    expect(find.bySemanticsLabel('Western Europe'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('multiple: toggles keep the list open and the trigger summarizes', (tester) async {
    await pumpKumo(tester, const _MultiHost(), size: kumoDesktopSize, center: false);
    expect(find.text('Name'), findsOneWidget);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Status'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    expect(find.text('Name, Status'), findsOneWidget);
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();
    expect(find.text('Status').first, findsOneWidget);
    await tester.tapAt(const Offset(1000, 700));
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsNothing);
    expect(find.text('Status'), findsOneWidget);
  });

  testWidgets('narrow: opens a sheet with the current option checked; pick closes it', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Host(initial: 'wnam', onChange: picked.add), center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    expect(find.byType(KumoMenuPanel), findsNothing);
    final checked = find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(KumoMenuRow));
    expect(tester.widget<KumoMenuRow>(checked).label, 'Western North America');
    await tester.tap(find.text('Eastern Europe'));
    await tester.pumpAndSettle();
    expect(picked, ['eeur']);
    expect(find.byType(KumoSheet), findsNothing);
  });

  testWidgets('narrow: the sheet follows a downward fling and dismisses', (tester) async {
    final picked = <String?>[];
    await pumpKumo(tester, _Host(onChange: picked.add), center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    final handle = find.byType(KumoSheetHandle);
    final before = tester.getTopLeft(handle).dy;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(tester.getTopLeft(handle).dy, closeTo(before + 60, 20));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(handle).dy, closeTo(before, 1));
    await tester.fling(handle, const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsNothing);
    expect(picked, isEmpty);
  });

  testWidgets('narrow multiple: sheet stays open and reflects toggles', (tester) async {
    await pumpKumo(tester, const _MultiHost(), center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Route'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    expect(find.byIcon(KumoIcons.check), findsNWidgets(2));
  });

  testWidgets('long lists build lazily and open scrolled to the current value', (tester) async {
    final many = [for (var i = 0; i < 3000; i++) KumoSelectOption(value: 'w$i', label: 'worker-$i')];
    await pumpKumo(tester, _Host(options: many, initial: 'w2400'), size: kumoDesktopSize, center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('worker-2400'), findsNWidgets(2));
    expect(find.text('worker-0'), findsNothing);
    expect(find.byType(KumoMenuRow).evaluate().length, lessThan(200));
    // End jumps to the last row even though it has never been built.
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(find.text('worker-2999'), findsOneWidget);
  });

  testWidgets('reduced motion, 2x text and 390px width do not overflow', (tester) async {
    await pumpKumo(tester, const _Host(initial: 'enam'), disableAnimations: true, textScale: 2, center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('unbounded width falls back to the Kumo default width', (tester) async {
    await pumpKumo(
      tester,
      const Row(mainAxisSize: MainAxisSize.min, children: [KumoSelect<String>(options: _regions, placeholder: 'Pick')]),
      size: kumoDesktopSize,
    );
    expect(tester.getSize(_trigger()).width, 280);
  });

  testWidgets('error shows under the trigger and turns the ring red', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(width: 280, child: KumoSelect<String>(options: _regions, label: 'Region', error: 'Choose a region to deploy to')),
      size: kumoDesktopSize,
    );
    expect(find.text('Choose a region to deploy to'), findsOneWidget);
    final box = tester.widget<KumoFieldBox>(_trigger());
    expect(box.error, isTrue);
  });

  testWidgets('presentation overrides the width rule both ways', (tester) async {
    await pumpKumo(tester, const _Host(presentation: KumoPresentation.popover), center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    expect(find.byType(KumoSheet), findsNothing);

    await pumpKumo(tester, const _MultiHost(presentation: KumoPresentation.sheet), size: kumoDesktopSize, center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    expect(find.text('Visible columns'), findsNWidgets(2));
  });

  testWidgets('RTL: the list aligns to the trigger start on the right', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, textDirection: TextDirection.rtl, center: false);
    await tester.tap(_trigger());
    await tester.pumpAndSettle();
    expect(tester.getTopRight(find.byType(KumoMenuPanel)).dx, closeTo(tester.getTopRight(_trigger()).dx, 1));
  });

  testWidgets('the shown value cross-fades when it changes; instant under reduced motion', (tester) async {
    for (final reduce in [false, true]) {
      await pumpKumo(tester, const _Host(initial: 'enam'), size: kumoDesktopSize, center: false, disableAnimations: reduce);
      await tester.tap(_trigger());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Western Europe').last);
      await tester.pump();
      if (!reduce) {
        await tester.pump(const Duration(milliseconds: 50));
        // Both labels are in the trigger for a moment.
        expect(find.descendant(of: _trigger(), matching: find.text('Eastern North America')), findsOneWidget);
        expect(find.descendant(of: _trigger(), matching: find.text('Western Europe')), findsOneWidget);
      } else {
        expect(find.descendant(of: _trigger(), matching: find.text('Eastern North America')), findsNothing);
      }
      await tester.pumpAndSettle();
      expect(find.descendant(of: _trigger(), matching: find.text('Eastern North America')), findsNothing);
    }
  });
}
