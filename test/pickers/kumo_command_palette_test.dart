import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

List<KumoCommandGroup> _groups(List<String> ran) => [
      KumoCommandGroup(label: 'Workers', items: [
        KumoCommandItem(title: 'Deploy image-resizer', icon: KumoIcons.rocket, onSelect: () => ran.add('deploy')),
        KumoCommandItem(title: 'View logs', icon: KumoIcons.terminal, keywords: ['tail'], onSelect: () => ran.add('logs')),
        const KumoCommandItem(title: 'Delete Worker', icon: KumoIcons.trash, disabled: true),
      ]),
      KumoCommandGroup(label: 'Cache', items: [
        KumoCommandItem(
          title: 'Purge everything',
          breadcrumbs: const ['example.com'],
          shortcut: 'P',
          onSelect: () => ran.add('purge'),
        ),
        KumoCommandItem(title: 'Cache docs', external: true, onSelect: () => ran.add('docs')),
      ]),
    ];

class _Opener extends StatelessWidget {
  const _Opener({required this.ran, this.onResult, this.onSearch, this.presentation = KumoPresentation.auto});

  final List<String> ran;
  final ValueChanged<KumoCommandItem?>? onResult;
  final KumoCommandSearch? onSearch;
  final KumoPresentation presentation;

  @override
  Widget build(BuildContext context) => KumoCommandPaletteShortcut(
        onTrigger: () => _open(context),
        child: KumoButton(label: 'Open command palette', onPress: () => _open(context)),
      );

  Future<void> _open(BuildContext context) async {
    final r = await showKumoCommandPalette(
      context: context,
      placeholder: 'Search commands',
      groups: _groups(ran),
      onSearch: onSearch,
      presentation: presentation,
      footer: const KumoCommandPaletteFooter(children: [
        KumoCommandPaletteKeyHint(label: 'Navigate', keys: ['Up', 'Down'], icons: [KumoIcons.arrowUp, KumoIcons.arrowDown]),
        KumoCommandPaletteKeyHint(label: 'Run', keys: ['Enter'], icons: [KumoIcons.arrowElbowDownLeft]),
      ]),
    );
    onResult?.call(r);
  }
}

Finder get _input => find.byType(TextField);

Finder _item(String title) =>
    find.byWidgetPredicate((w) => w is KumoCommandPaletteItem && w.item.title == title);

Finder _itemButton(String title) => find.descendant(of: _item(title), matching: find.byType(KumoPressable));

Future<void> _openPalette(WidgetTester tester) async {
  await tester.tap(find.text('Open command palette'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wide: opens as a dialog with the search focused, footer shown', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Opener(ran: []), size: kumoDesktopSize, brightness: b);
      await _openPalette(tester);
      expect(find.byType(KumoSheet), findsNothing);
      expect(find.byType(KumoCommandPalette), findsOneWidget);
      expect(tester.widget<TextField>(_input).focusNode!.hasFocus, isTrue);
      expect(find.text('Navigate'), findsOneWidget);
      final rect = tester.getRect(find.byType(KumoCommandPalette));
      expect(rect.width, lessThanOrEqualTo(672));
      expect(rect.top, closeTo(80, 1));
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('typing filters with marked matches; Enter runs the first result and closes', (tester) async {
    final ran = <String>[];
    KumoCommandItem? result;
    await pumpKumo(tester, _Opener(ran: ran, onResult: (r) => result = r), size: kumoDesktopSize);
    await _openPalette(tester);
    await tester.enterText(_input, 'purge');
    await tester.pumpAndSettle();
    expect(find.byType(KumoCommandPaletteItem), findsOneWidget);
    expect(find.text('Workers'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(ran, ['purge']);
    expect(result?.title, 'Purge everything');
    expect(find.byType(KumoCommandPalette), findsNothing);
  });

  testWidgets('arrows move the highlight past disabled rows and wrap', (tester) async {
    final ran = <String>[];
    await pumpKumo(tester, _Opener(ran: ran), size: kumoDesktopSize);
    await _openPalette(tester);
    bool lit(String title) =>
        tester.widget<KumoCommandPaletteItem>(_item(title)).highlighted;
    expect(lit('Deploy image-resizer'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(lit('Purge everything'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(lit('Deploy image-resizer'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(ran, ['docs']);
  });

  testWidgets('keywords, letters in order and tap all find commands; disabled rows do not run', (tester) async {
    final ran = <String>[];
    await pumpKumo(tester, _Opener(ran: ran), size: kumoDesktopSize);
    await _openPalette(tester);
    await tester.enterText(_input, 'tail');
    await tester.pumpAndSettle();
    expect(find.text('View logs'), findsOneWidget);
    await tester.enterText(_input, 'dpl');
    await tester.pumpAndSettle();
    expect(find.text('Deploy image-resizer'), findsOneWidget);
    await tester.enterText(_input, 'delete');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Worker'));
    await tester.pumpAndSettle();
    expect(ran, isEmpty);
    await tester.enterText(_input, 'logs');
    await tester.pumpAndSettle();
    await tester.tap(find.text('View logs'));
    await tester.pumpAndSettle();
    expect(ran, ['logs']);
  });

  testWidgets('empty state names the cause; Escape closes with no result', (tester) async {
    KumoCommandItem? result = const KumoCommandItem(title: 'sentinel');
    await pumpKumo(tester, _Opener(ran: const [], onResult: (r) => result = r), size: kumoDesktopSize);
    await _openPalette(tester);
    await tester.enterText(_input, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(KumoCommandPalette), findsNothing);
    expect(result, isNull);
  });

  testWidgets('remote search shows loading, then results; failures show an error', (tester) async {
    final pending = <Completer<List<KumoCommandGroup>>>[];
    Future<List<KumoCommandGroup>> search(String q) {
      final c = Completer<List<KumoCommandGroup>>();
      pending.add(c);
      return c.future;
    }

    await pumpKumo(tester, _Opener(ran: const [], onSearch: search), size: kumoDesktopSize);
    await _openPalette(tester);
    await tester.enterText(_input, 'assets');
    await tester.pump();
    expect(find.byType(KumoCommandPaletteLoading), findsOneWidget);
    pending.last.complete(const [
      KumoCommandGroup(label: 'R2 buckets', items: [KumoCommandItem(title: 'assets')]),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('R2 buckets'), findsOneWidget);

    await tester.enterText(_input, 'zzz');
    await tester.pump();
    pending.last.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Search failed'), findsOneWidget);
    expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);
  });

  testWidgets('Cmd/Ctrl+K opens the palette once', (tester) async {
    await pumpKumo(tester, const _Opener(ran: []), size: kumoDesktopSize);
    final meta = KumoCommandPaletteShortcut.usesMeta ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(meta);
    await tester.pumpAndSettle();
    expect(find.byType(KumoCommandPalette), findsOneWidget);
    await tester.sendKeyDownEvent(meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(meta);
    await tester.pumpAndSettle();
    expect(find.byType(KumoCommandPalette), findsOneWidget);
    expect(KumoCommandPaletteShortcut.label(), anyOf('Ctrl K', '⌘K'));
  });

  testWidgets('narrow: a full-height sheet with Cancel, no footer, follows a fling down', (tester) async {
    await pumpKumo(tester, const _Opener(ran: []));
    await _openPalette(tester);
    expect(find.byType(KumoSheet), findsOneWidget);
    expect(find.text('Navigate'), findsNothing);
    expect(tester.getSize(find.byType(KumoCommandPalette)).height, greaterThan(kumoPhoneSize.height * 0.8));
    expect(tester.widget<TextField>(_input).focusNode!.hasFocus, isTrue);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsNothing);

    await _openPalette(tester);
    await tester.fling(find.byType(KumoSheetHandle), const Offset(0, 400), 2000);
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsNothing);
  });

  testWidgets('semantics: rows are buttons named by path and title, highlighted row selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Opener(ran: []), size: kumoDesktopSize);
    await _openPalette(tester);
    expect(find.bySemanticsLabel('example.com, Purge everything'), findsOneWidget);
    expect(
      tester.getSemantics(_itemButton('Deploy image-resizer')),
      containsSemantics(isButton: true, isSelected: true, label: 'Deploy image-resizer'),
    );
    expect(tester.getSemantics(_itemButton('Cache docs')), containsSemantics(isLink: true));
    handle.dispose();
  });

  testWidgets('390px, 2x text and reduced motion do not overflow', (tester) async {
    await pumpKumo(tester, const _Opener(ran: []), textScale: 2, disableAnimations: true);
    await _openPalette(tester);
    expect(tester.takeException(), isNull);
    await pumpKumo(tester, const _Opener(ran: [], presentation: KumoPresentation.popover), textScale: 2);
    await _openPalette(tester);
    expect(tester.takeException(), isNull);
  });

  test('highlight ranges merge and clip', () {
    expect(KumoCommandPaletteHighlightedText.merge(const [(4, 6), (0, 2), (3, 3), (9, 20)], 12), [(0, 6), (9, 11)]);
  });

  testWidgets('embedded panel calls onSelect with newTab for Ctrl/Cmd+Enter', (tester) async {
    final calls = <(String, bool)>[];
    await pumpKumo(
      tester,
      SizedBox(
        width: 600,
        child: KumoCommandPalette(
          groups: _groups([]),
          onSelect: (item, {required newTab}) => calls.add((item.title, newTab)),
        ),
      ),
      size: kumoDesktopSize,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(calls, [('Deploy image-resizer', false), ('Deploy image-resizer', true)]);
  });

  testWidgets('filtering narrows the panel smoothly; reduced motion resizes at once', (tester) async {
    for (final reduce in [false, true]) {
      await pumpKumo(tester, const _Opener(ran: []), size: kumoDesktopSize, disableAnimations: reduce);
      await _openPalette(tester);
      final before = tester.getSize(find.byType(KumoCommandPalette)).height;
      await tester.enterText(_input, 'purge');
      await tester.pump();
      if (!reduce) await tester.pump(const Duration(milliseconds: 60));
      final now = tester.getSize(find.byType(KumoCommandPalette)).height;
      await tester.pumpAndSettle();
      final after = tester.getSize(find.byType(KumoCommandPalette)).height;
      expect(after, lessThan(before));
      if (reduce) {
        expect(now, after);
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
      } else {
        expect(now, inExclusiveRange(after, before));
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the keyboard highlight fades between rows instead of jumping', (tester) async {
    await pumpKumo(tester, const _Opener(ran: []), size: kumoDesktopSize);
    await _openPalette(tester);
    double fill(String title) => tester
        .widget<AnimatedOpacity>(find.descendant(of: _item(title), matching: find.byType(AnimatedOpacity)).first)
        .opacity;
    double shown(String title) {
      final w = find.descendant(of: _item(title), matching: find.byType(FadeTransition)).first;
      return tester.widget<FadeTransition>(w).opacity.value;
    }
    expect(fill('Deploy image-resizer'), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(fill('View logs'), 1);
    expect(shown('View logs'), inExclusiveRange(0, 1));
    expect(shown('Deploy image-resizer'), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(shown('Deploy image-resizer'), 0);
  });
}
