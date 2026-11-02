import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({
    this.initial = 1,
    this.total = 100,
    this.perPage = 10,
    this.controls = KumoPaginationControls.full,
    this.selector = KumoPaginationPageSelector.input,
    this.withPageSize = false,
    this.hasNextPage,
    this.compact,
  });

  final int initial;
  final int? total;
  final int perPage;
  final KumoPaginationControls controls;
  final KumoPaginationPageSelector selector;
  final bool withPageSize;
  final bool? hasNextPage;
  final bool? compact;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int page = widget.initial;
  late int perPage = widget.perPage;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: KumoPagination(
      page: page,
      onPageChange: (p) => setState(() => page = p),
      perPage: perPage,
      totalCount: widget.total,
      hasNextPage: widget.hasNextPage,
      controls: widget.controls,
      pageSelector: widget.selector,
      compact: widget.compact,
      onPerPageChange: widget.withPageSize
          ? (v) => setState(() {
              perPage = v;
              page = 1;
            })
          : null,
    ),
  );
}

Finder _button(String label) => find.bySemanticsLabel(label);

void main() {
  for (final b in Brightness.values) {
    testWidgets('renders wide and compact in $b', (tester) async {
      await pumpKumo(tester, const _Host(withPageSize: true), brightness: b, size: kumoDesktopSize);
      expect(find.text('Showing 1-10 of 100'), findsOneWidget);
      await pumpKumo(tester, const _Host(withPageSize: true), brightness: b);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('next, previous, first and last move the page', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize);
    await tester.tap(_button('Next page'));
    await tester.pump();
    expect(find.text('Showing 11-20 of 100'), findsOneWidget);
    await tester.tap(_button('Last page'));
    await tester.pump();
    expect(find.text('Showing 91-100 of 100'), findsOneWidget);
    await tester.tap(_button('Previous page'));
    await tester.pump();
    expect(find.text('Showing 81-90 of 100'), findsOneWidget);
    await tester.tap(_button('First page'));
    await tester.pump();
    expect(find.text('Showing 1-10 of 100'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('buttons disable at the ends', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize);
    expect(tester.getSemantics(_button('Previous page')), containsSemantics(isEnabled: false));
    expect(tester.getSemantics(_button('First page')), containsSemantics(isEnabled: false));
    expect(tester.getSemantics(_button('Next page')), containsSemantics(isEnabled: true, isButton: true));
    handle.dispose();
  });

  testWidgets('typed page commits on submit, clamped to the last page', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize);
    await tester.enterText(find.byType(TextField), '42');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    expect(find.text('Showing 91-100 of 100'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '3');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    expect(find.text('Showing 21-30 of 100'), findsOneWidget);
  });

  testWidgets('empty input resets to the current page', (tester) async {
    await pumpKumo(tester, const _Host(initial: 4), size: kumoDesktopSize);
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '4');
  });

  testWidgets('simple controls show only previous and next', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(controls: KumoPaginationControls.simple), size: kumoDesktopSize);
    expect(_button('First page'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(_button('Next page'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('unknown total: next follows hasNextPage, no info text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(total: null, hasNextPage: false), size: kumoDesktopSize);
    expect(tester.getSemantics(_button('Next page')), containsSemantics(isEnabled: false));
    expect(find.textContaining('Showing'), findsNothing);
    handle.dispose();
  });

  testWidgets('empty result set: one page, navigation off', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(total: 0), size: kumoDesktopSize);
    expect(find.textContaining('Showing'), findsNothing);
    expect(tester.getSemantics(_button('Last page')), containsSemantics(isEnabled: false));
    handle.dispose();
  });

  testWidgets('dropdown page selector picks a page', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      const _Host(selector: KumoPaginationPageSelector.dropdown, total: 50),
      size: kumoDesktopSize,
    );
    await tester.tap(find.bySemanticsLabel('Page number'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.pumpAndSettle();
    expect(find.text('Showing 31-40 of 50'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('page size select: popover on desktop, sheet on phone', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(withPageSize: true, initial: 3, total: 500, perPage: 25), size: kumoDesktopSize);
    expect(find.byType(KumoSelect<int>), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Page size'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsNothing);
    expect(find.text('250'), findsOneWidget);
    await tester.tap(find.text('100'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 1-100 of 500'), findsOneWidget);

    await pumpKumo(tester, const _Host(withPageSize: true, total: 500, perPage: 25));
    await tester.tap(find.bySemanticsLabel('Page size'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 1-50 of 500'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('compact on phone drops first and last', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host());
    expect(_button('First page'), findsNothing);
    expect(_button('Previous page'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('compact can be forced on a wide window', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(compact: true), size: kumoDesktopSize);
    expect(_button('First page'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    handle.dispose();
  });

  testWidgets('keyboard: Tab reaches the buttons, Enter activates', (tester) async {
    await pumpKumo(tester, const _Host(initial: 2), size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('Showing 1-10 of 100'), findsOneWidget);
  });

  testWidgets('touch targets are 44px; text scale 2 and RTL fit at 390px', (tester) async {
    await pumpKumo(tester, const _Host(withPageSize: true), textScale: 2, textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final handle = tester.ensureSemantics();
    expect(tester.getSize(_button('Next page')).height, greaterThanOrEqualTo(44));
    handle.dispose();
  });

  testWidgets('the range text cross-fades when the page changes', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize);
    await tester.tap(_button('Next page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    double opacityOf(String text) => tester
        .widget<FadeTransition>(find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(opacityOf('Showing 11-20 of 100'), inExclusiveRange(0, 1));
    expect(opacityOf('Showing 1-10 of 100'), inExclusiveRange(0, 1));
    expect(find.bySemanticsLabel('Showing 1-10 of 100'), findsNothing, reason: 'outgoing text is not read');
    await tester.pumpAndSettle();
    expect(find.text('Showing 1-10 of 100'), findsNothing);
    handle.dispose();
  });

  testWidgets('reduced motion: the range changes in one frame', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, disableAnimations: true);
    await tester.tap(find.bySemanticsLabel('Next page'));
    await tester.pump();
    expect(find.text('Showing 1-10 of 100'), findsNothing);
    expect(find.text('Showing 11-20 of 100'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
