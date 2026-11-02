import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class Worker {
  const Worker(this.name, this.requests, this.status);
  final String name;
  final int requests;
  final String status;
}

const _workers = [
  Worker('image-resizer', 18240, 'Active'),
  Worker('auth-proxy', 920, 'Active'),
  Worker('cron-cleanup', 12, 'Paused'),
];

List<KumoTableColumn<Worker>> _columns({bool sortable = true, KumoTableColumnPin? pinLast}) => [
      KumoTableColumn(id: 'name', label: 'Name', sortable: sortable, cell: (context, w) => Text(w.name)),
      KumoTableColumn(
        id: 'requests',
        label: 'Requests',
        numeric: true,
        sortable: sortable,
        width: const KumoTableColumnWidth.fixed(120),
        cell: (context, w) => Text('${w.requests}'),
      ),
      KumoTableColumn(
        id: 'status',
        label: 'Status',
        pin: pinLast,
        width: const KumoTableColumnWidth.fixed(100),
        cell: (context, w) => Text(w.status),
      ),
    ];

void main() {
  testWidgets('renders header variants, densities and states in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        SingleChildScrollView(
          child: Column(children: [
            for (final h in KumoTableHeaderVariant.values)
              for (final d in KumoTableDensity.values)
                KumoTable<Worker>(rows: _workers, columns: _columns(), headerVariant: h, density: d),
            KumoTable<Worker>(rows: const [], columns: _columns()),
            KumoTable<Worker>(rows: _workers, columns: _columns(), loading: true),
            KumoTable<Worker>(rows: _workers, columns: _columns(), error: const KumoTablePlaceholder(title: 'Could not load')),
            KumoTable<Worker>(rows: _workers, columns: _columns(), layout: KumoTableLayout.cards, selected: const {}, rowId: (w) => w.name),
          ]),
        ),
        brightness: b,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('header has a bottom border in kumo-fill; rows are striped', (tester) async {
    await pumpKumo(tester, KumoTable<Worker>(rows: _workers, columns: _columns()), size: kumoDesktopSize);
    final light = KumoThemeData.light().colors;
    final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    expect(
      boxes.any((d) {
        final dec = d.decoration;
        return dec is BoxDecoration && dec.border is Border && (dec.border! as Border).bottom.color == light.fill;
      }),
      isTrue,
    );
    final rowColors = tester.widgetList<ColoredBox>(find.byType(ColoredBox)).map((c) => c.color).toList();
    expect(rowColors, containsAllInOrder([light.base, light.elevated, light.base]));
  });

  testWidgets('numeric columns align to the end with tabular figures', (tester) async {
    await pumpKumo(tester, KumoTable<Worker>(rows: _workers, columns: _columns()), size: kumoDesktopSize);
    final number = find.text('12');
    final style = tester.widget<RichText>(find.descendant(of: number, matching: find.byType(RichText))).text.style!;
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    final cell = tester.getRect(find.ancestor(of: number, matching: find.byType(Padding)).first);
    expect(tester.getRect(number).right, closeTo(cell.right - 12, 1));
  });

  testWidgets('sortable headers report the next sort and expose sort semantics', (tester) async {
    final handle = tester.ensureSemantics();
    KumoTableSort? next;
    await pumpKumo(
      tester,
      KumoTable<Worker>(
        rows: _workers,
        columns: _columns(),
        sort: const KumoTableSort('requests', KumoTableSortDirection.ascending),
        onSortChange: (s) => next = s,
      ),
      size: kumoDesktopSize,
    );
    expect(find.byIcon(KumoIcons.arrowUp), findsOneWidget);
    expect(find.byIcon(KumoIcons.caretUpDown), findsOneWidget);
    expect(
      tester.getSemantics(find.ancestor(of: find.text('Requests'), matching: find.byType(KumoPressable))),
      matchesSemantics(
        label: 'Requests',
        value: 'Sorted ascending',
        hint: 'Sort descending',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await tester.tap(find.text('Requests'));
    expect(next, const KumoTableSort('requests', KumoTableSortDirection.descending));
    await tester.tap(find.text('Name'));
    expect(next, const KumoTableSort('name', KumoTableSortDirection.ascending));
    handle.dispose();
  });

  testWidgets('sort headers work from the keyboard', (tester) async {
    KumoTableSort? next;
    await pumpKumo(
      tester,
      KumoTable<Worker>(rows: _workers, columns: _columns(), onSortChange: (s) => next = s),
      size: kumoDesktopSize,
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(next, const KumoTableSort('name', KumoTableSortDirection.ascending));
  });

  testWidgets('selection: row and select-all checkboxes, mixed state, selected tint', (tester) async {
    final handle = tester.ensureSemantics();
    Set<Object> selected = {'auth-proxy'};
    late StateSetter set;
    await pumpKumo(
      tester,
      StatefulBuilder(builder: (context, setState) {
        set = setState;
        return KumoTable<Worker>(
          rows: _workers,
          columns: _columns(),
          rowId: (w) => w.name,
          rowLabel: (w) => w.name,
          selected: selected,
          onSelectionChange: (ids) => setState(() => selected = ids),
        );
      }),
      size: kumoDesktopSize,
    );
    expect(set, isNotNull);
    final all = find.bySemanticsLabel('Select all');
    expect(tester.getSemantics(all), matchesSemantics(label: 'Select all', isButton: true, isCheckStateMixed: true, hasCheckedState: true, hasEnabledState: true, isEnabled: true, hasTapAction: true, isFocusable: true, hasFocusAction: true));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Select auth-proxy')),
      matchesSemantics(label: 'Select auth-proxy', isButton: true, hasCheckedState: true, isChecked: true, hasEnabledState: true, isEnabled: true, hasTapAction: true, isFocusable: true, hasFocusAction: true),
    );
    final tint = KumoThemeData.light().colors.tint;
    expect(tester.widgetList<ColoredBox>(find.byType(ColoredBox)).where((c) => c.color == tint), hasLength(1));

    await tester.tap(find.bySemanticsLabel('Select image-resizer'));
    await tester.pumpAndSettle();
    expect(selected, {'auth-proxy', 'image-resizer'});
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect(selected, {'auth-proxy', 'image-resizer', 'cron-cleanup'});
    await tester.tap(all);
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    handle.dispose();
  });

  testWidgets('row press fires with the row; feedback starts on pointer down', (tester) async {
    Worker? pressed;
    await pumpKumo(
      tester,
      KumoTable<Worker>(rows: _workers, columns: _columns(), onRowPress: (w) => pressed = w),
      size: kumoDesktopSize,
    );
    final tint = KumoThemeData.light().colors.tint;
    final gesture = await tester.startGesture(tester.getCenter(find.text('cron-cleanup')));
    // Inside a scroll view, tap-down waits out the press timeout so a
    // scroll does not flash rows.
    await tester.pump(kPressTimeout);
    expect(tester.widgetList<ColoredBox>(find.byType(ColoredBox)).where((c) => c.color == tint), hasLength(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pressed?.name, 'cron-cleanup');
  });

  testWidgets('empty, loading and error states replace the rows', (tester) async {
    await pumpKumo(tester, KumoTable<Worker>(rows: const [], columns: _columns()));
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);

    await pumpKumo(
      tester,
      KumoTable<Worker>(
        rows: const [],
        columns: _columns(),
        empty: const KumoTablePlaceholder(title: 'No Workers yet', description: 'Deploy a Worker to see it here.'),
      ),
    );
    expect(find.text('No Workers yet'), findsOneWidget);

    await pumpKumo(tester, KumoTable<Worker>(rows: _workers, columns: _columns(), loading: true), settle: false);
    expect(find.byType(KumoLoader), findsOneWidget);
    expect(find.text('image-resizer'), findsNothing);

    await pumpKumo(
      tester,
      KumoTable<Worker>(rows: _workers, columns: _columns(), error: const KumoTablePlaceholder(title: 'Could not load Workers')),
    );
    expect(find.text('Could not load Workers'), findsOneWidget);
  });

  testWidgets('with a bounded height rows build lazily and the header stays put', (tester) async {
    final many = [for (var i = 0; i < 2000; i++) Worker('worker-$i', i, 'Active')];
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpKumo(
      tester,
      SizedBox(height: 400, child: KumoTable<Worker>(rows: many, columns: _columns(), controller: controller)),
      size: kumoDesktopSize,
    );
    expect(find.text('worker-0'), findsOneWidget);
    expect(find.text('worker-1999'), findsNothing);
    expect(find.text('worker-60'), findsNothing);
    final headerTop = tester.getTopLeft(find.text('Name')).dy;
    controller.jumpTo(3000);
    await tester.pump();
    expect(find.text('worker-0'), findsNothing);
    expect(tester.getTopLeft(find.text('Name')).dy, headerTop);
  });

  testWidgets('narrow screens scroll sideways with an edge fade; pinned columns stay put', (tester) async {
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoTable<Worker>(
          rows: _workers,
          columns: [
            ..._columns(pinLast: KumoTableColumnPin.end),
          ].map((c) => c.id == 'name'
              ? KumoTableColumn<Worker>(id: 'name', label: 'Name', width: const KumoTableColumnWidth.flex(1, 200), cell: c.cell)
              : c).toList(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final scroll = find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal);
    expect(scroll, findsOneWidget);
    // The end fade shows while content is hidden to the right.
    expect(find.byWidgetPredicate((w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient != null), findsWidgets);

    final pinnedBefore = tester.getRect(find.text('Paused'));
    final nameBefore = tester.getRect(find.text('cron-cleanup'));
    final viewport = tester.getRect(scroll);
    // Pinned to the end, the status column is visible before scrolling.
    expect(pinnedBefore.right, lessThanOrEqualTo(viewport.right));
    await tester.drag(scroll, const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('cron-cleanup')).left, lessThan(nameBefore.left));
    expect(tester.getRect(find.text('Paused')).left, closeTo(pinnedBefore.left, 1));
  });

  testWidgets('pinned cells receive taps at their painted position', (tester) async {
    var pressed = 0;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoTable<Worker>(
          rows: _workers.take(1).toList(),
          columns: [
            KumoTableColumn(id: 'name', label: 'Name', width: const KumoTableColumnWidth.fixed(400), cell: (context, w) => Text(w.name)),
            KumoTableColumn(
              id: 'actions',
              label: '',
              pin: KumoTableColumnPin.end,
              width: const KumoTableColumnWidth.fixed(60),
              cell: (context, w) => KumoButton(
                icon: KumoIcons.trash,
                shape: KumoButtonShape.square,
                size: KumoButtonSize.sm,
                semanticLabel: 'Delete ${w.name}',
                onPress: () => pressed++,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byIcon(KumoIcons.trash));
    expect(pressed, 1);
  });

  testWidgets('cards layout: one card per row with label and value pairs', (tester) async {
    Worker? pressed;
    await pumpKumo(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: KumoTable<Worker>(rows: _workers, columns: _columns(), layout: KumoTableLayout.cards, onRowPress: (w) => pressed = w),
      ),
    );
    expect(find.text('Requests'), findsNWidgets(3));
    expect(find.text('auth-proxy'), findsOneWidget);
    await tester.tap(find.text('auth-proxy'));
    expect(pressed?.name, 'auth-proxy');
  });

  testWidgets('auto layout: cards on phones, table on desktop', (tester) async {
    Widget table() => KumoTable<Worker>(rows: _workers, columns: _columns(), layout: KumoTableLayout.auto);
    await pumpKumo(tester, table(), size: kumoPhoneSize);
    expect(find.text('Requests'), findsNWidgets(3));
    await pumpKumo(tester, table(), size: kumoDesktopSize);
    expect(find.text('Requests'), findsOneWidget);
  });

  testWidgets('cards layout selection has a select-all row', (tester) async {
    Set<Object> selected = {};
    await pumpKumo(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KumoTable<Worker>(
          rows: _workers,
          columns: _columns(),
          layout: KumoTableLayout.cards,
          rowId: (w) => w.name,
          rowLabel: (w) => w.name,
          selected: selected,
          onSelectionChange: (ids) => setState(() => selected = ids),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Select all'));
    await tester.pumpAndSettle();
    expect(selected, hasLength(3));
    await tester.tap(find.bySemanticsLabel('Select cron-cleanup'));
    await tester.pumpAndSettle();
    expect(selected, hasLength(2));
  });

  testWidgets('RTL puts the first column on the right', (tester) async {
    await pumpKumo(tester, KumoTable<Worker>(rows: _workers, columns: _columns()), textDirection: TextDirection.rtl, size: kumoDesktopSize);
    expect(tester.getCenter(find.text('Name')).dx, greaterThan(tester.getCenter(find.text('Status')).dx));
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpKumo(
      tester,
      KumoTable<Worker>(
        rows: _workers,
        columns: _columns(),
        selected: const {'auth-proxy'},
        rowId: (w) => w.name,
        footer: const Padding(padding: EdgeInsets.all(12), child: Text('3 Workers')),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await pumpKumo(tester, KumoTable<Worker>(rows: _workers, columns: _columns(), layout: KumoTableLayout.cards), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch rows and sortable headers are at least 44px tall', (tester) async {
    await pumpKumo(
      tester,
      KumoTable<Worker>(
        rows: _workers,
        columns: _columns(),
        headerVariant: KumoTableHeaderVariant.compact,
        density: KumoTableDensity.compact,
        onRowPress: (_) {},
      ),
      size: kumoDesktopSize,
    );
    final header = find.ancestor(of: find.text('Name'), matching: find.byType(KumoPressable));
    expect(tester.getSize(header).height, greaterThanOrEqualTo(44));
    final row = find.ancestor(of: find.text('auth-proxy'), matching: find.byType(KumoPressable));
    expect(tester.getSize(row).height, greaterThanOrEqualTo(44));
  });

  testWidgets('mouse hover tints a pressable row instantly', (tester) async {
    await pumpKumo(
      tester,
      KumoTable<Worker>(rows: _workers, columns: _columns(), onRowPress: (_) {}),
      size: kumoDesktopSize,
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.text('auth-proxy')));
    await tester.pump();
    final tint = KumoThemeData.light().colors.tint;
    expect(tester.widgetList<ColoredBox>(find.byType(ColoredBox)).where((c) => c.color == tint), hasLength(1));
    await gesture.removePointer();
  });

  testWidgets('unbounded parents build every row', (tester) async {
    await pumpKumo(
      tester,
      SingleChildScrollView(child: KumoTable<Worker>(rows: _workers, columns: _columns())),
    );
    expect(find.text('cron-cleanup'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  test('KumoTableSort toggles ascending then descending', () {
    const asc = KumoTableSort('a', KumoTableSortDirection.ascending);
    expect(asc.toggled('a'), const KumoTableSort('a', KumoTableSortDirection.descending));
    expect(asc.toggled('a').toggled('a'), asc);
    expect(asc.toggled('b'), const KumoTableSort('b', KumoTableSortDirection.ascending));
  });

  testWidgets('render object reports semantics bounds for pinned cells', (tester) async {
    await pumpKumo(tester, KumoTable<Worker>(rows: _workers, columns: _columns(pinLast: KumoTableColumnPin.end)));
    final box = tester.renderObject<RenderBox>(find.text('Paused'));
    expect(box.localToGlobal(Offset.zero).dx, isNonNegative);
  });

  testWidgets('cards layout: a label stays level with a cell taller than its text', (tester) async {
    await pumpKumo(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: KumoTable<Worker>(
          rows: _workers.take(1).toList(),
          layout: KumoTableLayout.cards,
          columns: [
            KumoTableColumn(id: 'name', label: 'Name', cell: (context, w) => Text(w.name)),
            KumoTableColumn(
              id: 'proxy',
              label: 'Proxy',
              // A switch-like cell: a 44px touch target around a 20px control.
              cell: (context, w) => const SizedBox(
                height: 44,
                width: 44,
                child: Center(child: SizedBox.square(key: Key('control'), dimension: 20)),
              ),
            ),
          ],
        ),
      ),
    );
    final label = tester.getCenter(find.text('Proxy')).dy;
    final control = tester.getCenter(find.byKey(const Key('control'))).dy;
    expect((label - control).abs(), lessThan(1));
  });

  group('motion', () {
    Widget table({KumoTableSort? sort, Set<Object> selected = const {}}) => KumoTable<Worker>(
          rows: _workers,
          columns: _columns(),
          rowId: (w) => w.name,
          sort: sort,
          onSortChange: (_) {},
          selected: selected,
          onSelectionChange: (_) {},
        );
    double turns(WidgetTester tester) => tester
        .widget<RotationTransition>(
          find.ancestor(of: find.byIcon(KumoIcons.arrowUp), matching: find.byType(RotationTransition)).first,
        )
        .turns
        .value;
    double rowOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(find.ancestor(of: find.text('auth-proxy'), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;

    testWidgets('the sort arrow turns over and the rows fade back in', (tester) async {
      await pumpKumo(tester, table(sort: const KumoTableSort('requests', KumoTableSortDirection.ascending)));
      expect(turns(tester), 0);
      await pumpKumo(
        tester,
        table(sort: const KumoTableSort('requests', KumoTableSortDirection.descending)),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 80));
      expect(turns(tester), inExclusiveRange(0, 0.5));
      expect(rowOpacity(tester), inExclusiveRange(0.2, 1));
      await tester.pumpAndSettle();
      expect(turns(tester), 0.5);
      expect(rowOpacity(tester), 1);
    });

    testWidgets('unsorted caret cross-fades into the arrow', (tester) async {
      await pumpKumo(tester, table());
      await pumpKumo(tester, table(sort: const KumoTableSort('name', KumoTableSortDirection.ascending)), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      final fades = tester.widgetList<FadeTransition>(
        find.ancestor(of: find.byIcon(KumoIcons.caretUpDown).first, matching: find.byType(FadeTransition)),
      );
      expect(fades.first.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
    });

    testWidgets('selecting a row eases its tint and lands the check', (tester) async {
      Color rowColor() => tester
          .widget<ColoredBox>(find.ancestor(of: find.text('auth-proxy'), matching: find.byType(ColoredBox)).first)
          .color;
      await pumpKumo(tester, table());
      final rest = rowColor();
      await pumpKumo(tester, table(selected: {'auth-proxy'}), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      final mid = rowColor();
      final scale = tester
          .widget<Transform>(find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(Transform)).first)
          .transform
          .getMaxScaleOnAxis();
      expect(scale, inExclusiveRange(0.6, 1.1));
      await tester.pumpAndSettle();
      final tint = rowColor();
      expect(mid, isNot(rest));
      expect(mid, isNot(tint));
      expect(tint, isNot(rest));
    });

    testWidgets('reduced motion: sort and selection land in one frame', (tester) async {
      await pumpKumo(
        tester,
        table(sort: const KumoTableSort('requests', KumoTableSortDirection.ascending)),
        disableAnimations: true,
      );
      await pumpKumo(
        tester,
        table(sort: const KumoTableSort('requests', KumoTableSortDirection.descending), selected: {'auth-proxy'}),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump();
      expect(turns(tester), 0.5);
      expect(rowOpacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
