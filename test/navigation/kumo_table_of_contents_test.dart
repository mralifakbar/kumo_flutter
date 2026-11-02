import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _ids = ['overview', 'routes', 'bindings', 'limits', 'logs'];
const _items = [
  KumoTableOfContentsItem(id: 'overview', label: 'Overview'),
  KumoTableOfContentsItem(
    id: 'routes',
    label: 'Routes',
    children: [KumoTableOfContentsItem(id: 'bindings', label: 'Bindings')],
  ),
  KumoTableOfContentsItem(id: 'limits', label: 'Limits'),
  KumoTableOfContentsItem(id: 'logs', label: 'Logs'),
];

class _Page extends StatefulWidget {
  const _Page({this.onActive});

  final ValueChanged<String>? onActive;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final scroll = ScrollController();
  final keys = {for (final id in _ids) id: GlobalKey()};

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: KumoTableOfContents(
            title: 'On this page',
            items: _items,
            scrollController: scroll,
            anchors: keys,
            onActiveIdChange: widget.onActive,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final id in _ids) ...[
                  Text('Section $id', key: keys[id]),
                  SizedBox(
                    height: switch (id) {
                      'logs' => 100,
                      'limits' => 300,
                      _ => 1000,
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The rule beside [label]: the moving brand indicator when it sits on the
/// row, otherwise the row's own (hover) rule.
Color _rule(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Container)).first;
  final indicator = find.byKey(const ValueKey('kumo-toc-indicator'));
  if (indicator.evaluate().isNotEmpty) {
    final r = tester.getRect(indicator);
    final rowRect = tester.getRect(row);
    if ((r.top - rowRect.top).abs() < 0.5 && (r.height - rowRect.height).abs() < 0.5) {
      return tester.widget<ColoredBox>(find.descendant(of: indicator, matching: find.byType(ColoredBox))).color;
    }
  }
  final container = tester.widget<Container>(row);
  final border = (container.decoration! as BoxDecoration).border! as BorderDirectional;
  return border.start.color;
}

void main() {
  for (final b in Brightness.values) {
    testWidgets('renders title, items and groups in $b', (tester) async {
      await pumpKumo(
        tester,
        const KumoTableOfContents(title: 'On this page', items: _items, activeId: 'routes'),
        brightness: b,
      );
      expect(find.text('ON THIS PAGE'), findsOneWidget);
      expect(find.text('Bindings'), findsOneWidget);
      final c = b == Brightness.dark ? KumoColorSchemes.dark : KumoColorSchemes.light;
      expect(_rule(tester, 'Routes'), c.brand);
      expect(tester.widget<Text>(find.text('Routes')).style!.fontWeight, KumoTypography.medium);
    });
  }

  testWidgets('tracks the topmost heading in view while scrolling', (tester) async {
    final active = <String>[];
    await pumpKumo(tester, _Page(onActive: active.add), center: false, size: kumoDesktopSize);
    expect(active.last, 'overview');
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!;
    scroll.jumpTo(1000);
    await tester.pump();
    expect(active.last, 'routes');
    // Inside a long section with no heading in view, the last one stays.
    scroll.jumpTo(1100);
    await tester.pump();
    expect(active.last, 'routes');
    scroll.jumpTo(2042);
    await tester.pump();
    expect(active.last, 'bindings');
  });

  testWidgets('tap scrolls to the section with an animation and pins it', (tester) async {
    final active = <String>[];
    await pumpKumo(tester, _Page(onActive: active.add), center: false, size: kumoDesktopSize);
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).controller!;
    await tester.tap(find.text('Logs'));
    await tester.pump();
    expect(active.last, 'logs');
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    // Logs is short and cannot reach the top (Limits is the topmost heading
    // in view); it stays active anyway.
    expect(scroll.offset, scroll.position.maxScrollExtent);
    expect(active.last, 'logs');
    await tester.pump(const Duration(milliseconds: 200));
    expect(active.last, 'logs');
  });

  testWidgets('presentational: onSelect fires, activeId wins', (tester) async {
    final selected = <String>[];
    await pumpKumo(tester, KumoTableOfContents(items: _items, activeId: 'overview', onSelect: selected.add));
    await tester.tap(find.text('Limits'));
    await tester.pump();
    expect(selected, ['limits']);
    expect(_rule(tester, 'Overview'), KumoColorSchemes.light.brand);
  });

  testWidgets('semantics: list label and selected link', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoTableOfContents(items: _items, activeId: 'limits'));
    expect(find.bySemanticsLabel('Table of contents'), findsOneWidget);
    expect(tester.getSemantics(find.text('Limits')), containsSemantics(isLink: true, isSelected: true));
    expect(tester.getSemantics(find.text('Logs')), containsSemantics(isLink: true, isSelected: false));
    handle.dispose();
  });

  testWidgets('keyboard: Tab and Enter select', (tester) async {
    final selected = <String>[];
    await pumpKumo(
      tester,
      KumoTableOfContents(items: _items, onSelect: selected.add),
      size: kumoDesktopSize,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, ['routes']);
  });

  testWidgets('reduced motion jumps; rows are 44px on touch; text scale 2', (tester) async {
    await pumpKumo(tester, const _Page(), center: false, disableAnimations: true, textScale: 2);
    await tester.tap(find.text('Limits'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.getSize(find.ancestor(of: find.text('Limits'), matching: find.byType(KumoPressable))).height, 44);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the active rule slides along the rail from the previous item', (tester) async {
    await pumpKumo(tester, const _Page(), center: false, size: kumoDesktopSize);
    final indicator = find.byKey(const ValueKey('kumo-toc-indicator'));
    final from = tester.getRect(indicator).center.dy;
    final to = tester.getCenter(find.ancestor(of: find.text('Limits'), matching: find.byType(Container)).first).dy;
    expect(to, greaterThan(from + 20));
    await tester.tap(find.text('Limits'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final mid = tester.getRect(indicator).center.dy;
    expect(mid, inExclusiveRange(from + 1, to - 1));
    await tester.pumpAndSettle();
    expect(tester.getRect(indicator).center.dy, closeTo(to, 0.5));
  });

  testWidgets('reduced motion: the rule lands on the tapped item in one frame', (tester) async {
    await pumpKumo(tester, const _Page(), center: false, size: kumoDesktopSize, disableAnimations: true);
    await tester.tap(find.text('Limits'));
    await tester.pump();
    await tester.pump();
    expect(_rule(tester, 'Limits'), KumoColorSchemes.light.brand);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
