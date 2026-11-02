import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _nodes = [
  KumoTreeNode(
    id: 'src',
    label: 'src',
    icon: KumoIcons.folder,
    expandedIcon: KumoIcons.folderOpen,
    children: [
      KumoTreeNode(id: 'src/index.ts', label: 'index.ts', icon: KumoIcons.fileTs),
      KumoTreeNode(
        id: 'src/lib',
        label: 'lib',
        icon: KumoIcons.folder,
        children: [KumoTreeNode(id: 'src/lib/cache.ts', label: 'cache.ts', icon: KumoIcons.fileTs)],
      ),
    ],
  ),
  KumoTreeNode(id: 'wrangler.toml', label: 'wrangler.toml', icon: KumoIcons.file),
];

/// A tree that owns its expanded and selected state, like an app would.
class _Host extends StatefulWidget {
  const _Host({this.nodes = _nodes, this.initialExpanded = const {}, this.loadChildren, this.showGuides = false});

  final List<KumoTreeNode> nodes;
  final Set<Object> initialExpanded;
  final Future<List<KumoTreeNode>> Function(KumoTreeNode)? loadChildren;
  final bool showGuides;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late Set<Object> expanded = widget.initialExpanded;
  Object? value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            child: KumoTree(
          nodes: widget.nodes,
          expanded: expanded,
          onExpandedChange: (ids) => setState(() => expanded = ids),
          value: value,
          onValueChange: (id) => setState(() => value = id),
          loadChildren: widget.loadChildren,
          showGuides: widget.showGuides,
          semanticLabel: 'Worker files',
            ),
          ),
          KumoButton(label: 'Deploy', onPress: () {}),
        ],
      );
}

_HostState _host(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host));

void main() {
  testWidgets('renders collapsed and expanded, with guides, in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Host(initialExpanded: {'src', 'src/lib'}, showGuides: true), brightness: b);
      expect(find.text('cache.ts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('pressing a branch selects and expands it; children slide in', (tester) async {
    await pumpKumo(tester, const _Host());
    expect(find.text('index.ts'), findsNothing);
    await tester.tap(find.text('src'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('index.ts'), findsOneWidget);
    // Mid-animation the children are clipped, not reflowed.
    final mid = tester.getSize(find.byType(SizeTransition).first).height;
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(SizeTransition).first).height, greaterThan(mid));
    expect(_host(tester).expanded, {'src'});
    expect(_host(tester).value, 'src');
    expect(find.byIcon(KumoIcons.folderOpen), findsOneWidget);

    await tester.tap(find.text('src'));
    await tester.pumpAndSettle();
    expect(find.text('index.ts'), findsNothing);
  });

  testWidgets('pressing a leaf selects it without expanding anything', (tester) async {
    await pumpKumo(tester, const _Host());
    await tester.tap(find.text('wrangler.toml'));
    await tester.pumpAndSettle();
    expect(_host(tester).value, 'wrangler.toml');
    expect(_host(tester).expanded, isEmpty);
  });

  testWidgets('semantics: expanded and selected states', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host());
    expect(
      tester.getSemantics(find.ancestor(of: find.text('src'), matching: find.byType(KumoPressable))),
      matchesSemantics(
        label: 'src',
        hint: 'Expand',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasSelectedState: true,
        isSelected: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await tester.tap(find.text('src'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.ancestor(of: find.text('src'), matching: find.byType(KumoPressable))),
      matchesSemantics(
        label: 'src',
        hint: 'Collapse',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('keyboard: arrows move, Right expands and enters, Left collapses and climbs', (tester) async {
    await pumpKumo(tester, const _Host(), tapTargetSize: KumoTapTargetSize.shrinkWrap);
    FocusNode? focused() => FocusManager.instance.primaryFocus;
    String? focusedLabel() => focused()?.debugLabel;

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'KumoTree src');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_host(tester).expanded, {'src'});
    expect(focusedLabel(), 'KumoTree src');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'KumoTree src/index.ts');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'KumoTree src/lib');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'KumoTree src');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_host(tester).expanded, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'KumoTree wrangler.toml');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'KumoTree src');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_host(tester).value, 'wrangler.toml');

    // One Tab stop: Tab leaves the tree instead of walking its rows.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedLabel(), 'KumoPressable');
  });

  testWidgets('RTL swaps Left and Right', (tester) async {
    await pumpKumo(tester, const _Host(), tapTargetSize: KumoTapTargetSize.shrinkWrap, textDirection: TextDirection.rtl);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_host(tester).expanded, {'src'});
  });

  testWidgets('lazy children load on first expand, with a loading row', (tester) async {
    final completer = Completer<List<KumoTreeNode>>();
    var calls = 0;
    await pumpKumo(
      tester,
      _Host(
        nodes: const [KumoTreeNode(id: 'assets', label: 'assets', icon: KumoIcons.folder, hasChildren: true)],
        loadChildren: (node) {
          calls++;
          return completer.future;
        },
      ),
    );
    await tester.tap(find.text('assets'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(calls, 1);
    expect(find.text('Loading'), findsOneWidget);
    completer.complete(const [KumoTreeNode(id: 'assets/logo.png', label: 'logo.png')]);
    await tester.pumpAndSettle();
    expect(find.text('logo.png'), findsOneWidget);

    await tester.tap(find.text('assets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('assets'));
    await tester.pumpAndSettle();
    expect(calls, 1, reason: 'children are cached');
  });

  testWidgets('a failed load shows the error row and retries on press', (tester) async {
    var calls = 0;
    await pumpKumo(
      tester,
      _Host(
        nodes: const [KumoTreeNode(id: 'assets', label: 'assets', hasChildren: true)],
        loadChildren: (node) async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return const [KumoTreeNode(id: 'a', label: 'a.txt')];
        },
      ),
    );
    await tester.tap(find.text('assets'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load. Press to retry.'), findsOneWidget);
    await tester.tap(find.text('Could not load. Press to retry.'));
    await tester.pumpAndSettle();
    expect(find.text('a.txt'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('disabled nodes ignore presses', (tester) async {
    await pumpKumo(tester, const _Host(nodes: [KumoTreeNode(id: 'x', label: 'locked', disabled: true)]));
    await tester.tap(find.text('locked'));
    await tester.pumpAndSettle();
    expect(_host(tester).value, isNull);
  });

  testWidgets('reduced motion opens instantly', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true);
    await tester.tap(find.text('src'));
    await tester.pump();
    await tester.pump();
    expect(find.text('index.ts'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpKumo(tester, const _Host(initialExpanded: {'src', 'src/lib'}, showGuides: true), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the caret turns in step with the children sliding and fading in', (tester) async {
    await pumpKumo(tester, const _Host());
    await tester.tap(find.text('src'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final caret = tester
        .widget<RotationTransition>(find.ancestor(of: find.byIcon(KumoIcons.caretRight).first, matching: find.byType(RotationTransition)))
        .turns
        .value;
    final size = tester.widget<SizeTransition>(find.byType(SizeTransition).first).sizeFactor.value;
    final fade = tester
        .widgetList<FadeTransition>(find.ancestor(of: find.text('index.ts'), matching: find.byType(FadeTransition)))
        .map((f) => f.opacity.value)
        .reduce((a, b) => a < b ? a : b);
    expect(caret, inExclusiveRange(0, 0.25));
    expect(size, inExclusiveRange(0, 1));
    expect(fade, inExclusiveRange(0, 1));
    // Same duration and curve: the caret's progress matches the height's.
    expect(caret / 0.25, closeTo(size, 0.01));
    await tester.pumpAndSettle();
  });

  testWidgets('collapsing mid-open reverses from where it is', (tester) async {
    await pumpKumo(tester, const _Host());
    await tester.tap(find.text('src'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final opened = tester.widget<SizeTransition>(find.byType(SizeTransition).first).sizeFactor.value;
    await tester.tap(find.text('src'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final reversing = tester.widget<SizeTransition>(find.byType(SizeTransition).first).sizeFactor.value;
    expect(reversing, inExclusiveRange(0, opened));
    expect(opened - reversing, lessThan(0.2), reason: 'no jump back to closed');
    await tester.pumpAndSettle();
    expect(find.text('index.ts'), findsNothing);
  });

  testWidgets('lazy children cross-fade in over the loading row', (tester) async {
    final completer = Completer<List<KumoTreeNode>>();
    await pumpKumo(
      tester,
      _Host(
        nodes: const [KumoTreeNode(id: 'assets', label: 'assets', icon: KumoIcons.folder, hasChildren: true)],
        loadChildren: (node) => completer.future,
      ),
    );
    await tester.tap(find.text('assets'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    completer.complete(const [KumoTreeNode(id: 'assets/logo.png', label: 'logo.png')]);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final incoming = tester
        .widget<FadeTransition>(find.ancestor(of: find.text('logo.png'), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(incoming, inExclusiveRange(0, 1));
    expect(find.text('Loading'), findsOneWidget, reason: 'the loading row is still fading out');
    await tester.pumpAndSettle();
    expect(find.text('Loading'), findsNothing);
  });
}
