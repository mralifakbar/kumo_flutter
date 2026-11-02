import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _items = [
  KumoAccordionItem(value: 'routes', title: 'Which routes run this Worker?', child: Text('example.com/api/*')),
  KumoAccordionItem(
    value: 'limits',
    title: 'What are the CPU limits?',
    description: 'Standard usage model',
    child: Text('30 seconds'),
  ),
  KumoAccordionItem(value: 'legacy', title: 'Legacy bindings', disabled: true, child: Text('None')),
  KumoAccordionItem(
    value: 'logs',
    title: 'Where do logs go?',
    icon: KumoIcons.listBullets,
    child: Text('Workers Logs'),
  ),
];

class _Host extends StatefulWidget {
  const _Host({this.type = KumoAccordionType.single, this.collapsible = true, this.initial = const {}, this.onChange});

  final KumoAccordionType type;
  final bool collapsible;
  final Set<String> initial;
  final ValueChanged<Set<String>>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late Set<String> value = widget.initial;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 358,
    child: KumoAccordion(
      items: _items,
      type: widget.type,
      collapsible: widget.collapsible,
      value: value,
      onValueChange: (v) {
        widget.onChange?.call(v);
        setState(() => value = v);
      },
    ),
  );
}

double _turn(WidgetTester tester, String title) {
  final header = find.ancestor(of: find.text(title), matching: find.byType(KumoPressable)).first;
  final transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.descendant(of: header, matching: find.byType(KumoDisclosureCaret)),
          matching: find.byType(Transform),
        )
        .first,
  );
  final m = transform.transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0)).abs() / math.pi;
}

void main() {
  for (final b in Brightness.values) {
    testWidgets('renders in $b', (tester) async {
      await pumpKumo(tester, const _Host(initial: {'routes'}), brightness: b);
      expect(find.text('example.com/api/*'), findsOneWidget);
      expect(find.text('30 seconds'), findsNothing);
    });
  }

  testWidgets('single: opening one closes the other', (tester) async {
    final changes = <Set<String>>[];
    await pumpKumo(tester, _Host(initial: const {'routes'}, onChange: changes.add));
    await tester.tap(find.text('What are the CPU limits?'));
    await tester.pumpAndSettle();
    expect(changes.last, {'limits'});
    expect(find.text('example.com/api/*'), findsNothing);
    expect(find.text('30 seconds'), findsOneWidget);
    await tester.tap(find.text('What are the CPU limits?'));
    await tester.pumpAndSettle();
    expect(changes.last, <String>{});
  });

  testWidgets('single, not collapsible: the open item stays open', (tester) async {
    final changes = <Set<String>>[];
    await pumpKumo(tester, _Host(initial: const {'routes'}, collapsible: false, onChange: changes.add));
    await tester.tap(find.text('Which routes run this Worker?'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('multiple: items open independently', (tester) async {
    final changes = <Set<String>>[];
    await pumpKumo(tester, _Host(type: KumoAccordionType.multiple, onChange: changes.add));
    await tester.tap(find.text('Which routes run this Worker?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Where do logs go?'));
    await tester.pumpAndSettle();
    expect(changes.last, {'routes', 'logs'});
  });

  testWidgets('disabled item does not toggle', (tester) async {
    final changes = <Set<String>>[];
    await pumpKumo(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Legacy bindings'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('keyboard: arrows move between headers, skipping disabled; Home, End, Enter', (tester) async {
    final changes = <Set<String>>[];
    await pumpKumo(tester, _Host(onChange: changes.add), size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'KumoAccordion 0');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'KumoAccordion 3');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'KumoAccordion 0');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes.last, {'logs'});
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus!.debugLabel, 'KumoAccordion 1');
  });

  testWidgets('semantics: headers are expandable buttons', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(initial: {'routes'}));
    expect(
      tester.getSemantics(find.text('Which routes run this Worker?')),
      containsSemantics(isHeader: true, isButton: true, hasExpandedState: true, isExpanded: true),
    );
    expect(
      tester.getSemantics(find.text('What are the CPU limits?')),
      containsSemantics(isHeader: true, hasExpandedState: true, isExpanded: false),
    );
    handle.dispose();
  });

  testWidgets('reduced motion and text scale 2', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true, textScale: 2);
    await tester.tap(find.text('Which routes run this Worker?'));
    await tester.pump();
    expect(find.text('example.com/api/*'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chevrons turn with their panels: one opens while the other closes', (tester) async {
    await pumpKumo(tester, const _Host(initial: {'routes'}));
    expect(_turn(tester, 'Which routes run this Worker?'), closeTo(1, 0.001));
    final routesPanel = find.byType(KumoCollapsiblePanel).first;
    final limitsPanel = find.byType(KumoCollapsiblePanel).at(1);
    final routesFull = tester.getSize(routesPanel).height;
    await tester.tap(find.text('What are the CPU limits?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final opening = _turn(tester, 'What are the CPU limits?');
    final closing = _turn(tester, 'Which routes run this Worker?');
    expect(opening, inExclusiveRange(0.05, 0.95));
    expect(closing, inExclusiveRange(0.05, 0.95));
    expect(closing, closeTo(tester.getSize(routesPanel).height / routesFull, 0.02));
    final limitsMid = tester.getSize(limitsPanel).height;
    await tester.pumpAndSettle();
    expect(opening, closeTo(limitsMid / tester.getSize(limitsPanel).height, 0.02));
    expect(_turn(tester, 'What are the CPU limits?'), closeTo(1, 0.001));
    expect(_turn(tester, 'Which routes run this Worker?'), 0);
  });

  testWidgets('reduced motion: chevron lands in one frame', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true);
    await tester.tap(find.text('Where do logs go?'));
    await tester.pump();
    expect(_turn(tester, 'Where do logs go?'), closeTo(1, 0.001));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
