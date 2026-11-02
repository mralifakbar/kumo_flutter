import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({super.key, this.initial = false, this.keepMounted = false, this.disabled = false, this.onChange});

  final bool initial;
  final bool keepMounted;
  final bool disabled;
  final ValueChanged<bool>? onChange;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool open = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: KumoCollapsible(
        open: open,
        disabled: widget.disabled,
        keepMounted: widget.keepMounted,
        onOpenChange: (v) {
          widget.onChange?.call(v);
          setState(() => open = v);
        },
        label: 'Advanced settings',
        child: widget.keepMounted
            ? const SizedBox(width: 200, child: KumoEditable(key: Key('field')))
            : const SizedBox(height: 120, child: Text('Compatibility date')),
      ),
    );
  }
}

/// Fraction of its half turn the first caret under [scope] has made.
double caretTurn(WidgetTester tester, [Finder? scope]) {
  final caret = find.byType(KumoDisclosureCaret);
  final transform = tester.widget<Transform>(
    find
        .descendant(
          of: scope == null ? caret.first : find.descendant(of: scope, matching: caret).first,
          matching: find.byType(Transform),
        )
        .first,
  );
  final m = transform.transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0)).abs() / math.pi;
}

const double _fullHeight = 120 + 2 * KumoSpace.s2 + 2 * KumoSpace.s1;

void main() {
  for (final b in Brightness.values) {
    testWidgets('renders open and closed in $b', (tester) async {
      await pumpKumo(tester, const _Host(initial: true), brightness: b);
      expect(find.text('Compatibility date'), findsOneWidget);
      await pumpKumo(tester, const _Host(key: ValueKey('closed')), brightness: b);
      expect(find.text('Compatibility date'), findsNothing);
    });
  }

  testWidgets('tap toggles; height animates while content keeps its size', (tester) async {
    final changes = <bool>[];
    await pumpKumo(tester, _Host(onChange: changes.add));
    await tester.tap(find.text('Advanced settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(changes, [true]);
    final mid = tester.getSize(find.byType(KumoCollapsiblePanel)).height;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(120 + 2 * KumoSpace.s2 + 2 * KumoSpace.s1));
    // The content is laid out at full height (clipped, not squeezed).
    final content = find.ancestor(of: find.text('Compatibility date'), matching: find.byType(SizedBox)).first;
    expect(tester.getSize(content).height, 120);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(KumoCollapsiblePanel)).height, 120 + 2 * KumoSpace.s2 + 2 * KumoSpace.s1);
    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    expect(find.text('Compatibility date'), findsNothing);
  });

  testWidgets('reversing mid-flight continues from the current height', (tester) async {
    await pumpKumo(tester, const _Host());
    await tester.tap(find.text('Advanced settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final before = tester.getSize(find.byType(KumoCollapsiblePanel)).height;
    await tester.tap(find.text('Advanced settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final after = tester.getSize(find.byType(KumoCollapsiblePanel)).height;
    expect((after - before).abs(), lessThan(30), reason: 'no jump to fully open or closed');
    await tester.pumpAndSettle();
  });

  testWidgets('disabled trigger does not toggle', (tester) async {
    final changes = <bool>[];
    await pumpKumo(tester, _Host(disabled: true, onChange: changes.add));
    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('semantics: trigger announces expanded state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host());
    expect(
      tester.getSemantics(find.text('Advanced settings')),
      matchesSemantics(
        label: 'Advanced settings',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('Advanced settings')).flagsCollection.isExpanded.toBoolOrNull(), isTrue);
    handle.dispose();
  });

  testWidgets('keyboard: Enter and Space toggle', (tester) async {
    final changes = <bool>[];
    await pumpKumo(tester, _Host(onChange: changes.add), size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
  });

  testWidgets('keepMounted keeps field text across close and open', (tester) async {
    await pumpKumo(tester, const _Host(initial: true, keepMounted: true));
    await tester.enterText(
      find.descendant(of: find.byKey(const Key('field')), matching: find.byType(TextField)),
      'workers.dev',
    );
    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('field')).hitTestable(), findsNothing);
    await tester.tap(find.text('Advanced settings'));
    await tester.pumpAndSettle();
    expect(find.text('workers.dev'), findsOneWidget);
  });

  testWidgets('reduced motion: opens instantly', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true);
    await tester.tap(find.text('Advanced settings'));
    await tester.pump();
    expect(tester.getSize(find.byType(KumoCollapsiblePanel)).height, 120 + 2 * KumoSpace.s2 + 2 * KumoSpace.s1);
  });

  testWidgets('custom trigger and plain panel, text scale 2', (tester) async {
    var open = false;
    await pumpKumo(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KumoCollapsible(
          open: open,
          onOpenChange: (v) => setState(() => open = v),
          panelStyle: KumoCollapsiblePanelStyle.plain,
          triggerBuilder: (context, open, toggle) =>
              KumoButton(label: open ? 'Hide details' : 'Show details', onPress: toggle),
          child: const Text('Routes, bindings and environment variables for image-resizer.'),
        ),
      ),
      textScale: 2,
    );
    await tester.tap(find.text('Show details'));
    await tester.pumpAndSettle();
    expect(find.text('Hide details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caret turns in step with the panel, reversing mid-flight with it', (tester) async {
    await pumpKumo(tester, const _Host());
    expect(caretTurn(tester), 0);
    await tester.tap(find.text('Advanced settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final turn = caretTurn(tester);
    final height = tester.getSize(find.byType(KumoCollapsiblePanel)).height / _fullHeight;
    expect(turn, greaterThan(0.05));
    expect(turn, lessThan(0.95));
    expect(turn, closeTo(height, 0.02), reason: 'caret and height share one clock');

    await tester.tap(find.text('Advanced settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final back = caretTurn(tester);
    expect(back, lessThan(turn));
    expect(turn - back, lessThan(0.3), reason: 'reverses from where it is, no jump');
    expect(back, closeTo(tester.getSize(find.byType(KumoCollapsiblePanel)).height / _fullHeight, 0.02));
    await tester.pumpAndSettle();
    expect(caretTurn(tester), 0);
  });

  testWidgets('reduced motion: caret and panel land in one frame', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true);
    await tester.tap(find.text('Advanced settings'));
    await tester.pump();
    expect(caretTurn(tester), closeTo(1, 0.001));
    expect(tester.getSize(find.byType(KumoCollapsiblePanel)).height, _fullHeight);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
