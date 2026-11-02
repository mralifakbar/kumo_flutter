import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

/// A sidebar with every common part, holding its own open state.
class _Nav extends StatefulWidget {
  const _Nav({
    this.initialOpen = true,
    this.onOpenChange,
    this.onOpenChangeComplete,
    this.onPress,
    this.loading = false,
    this.resizable = false,
    this.onWidthChange,
  });

  final bool initialOpen;
  final ValueChanged<bool>? onOpenChange;
  final ValueChanged<bool>? onOpenChangeComplete;
  final ValueChanged<String>? onPress;
  final bool loading;
  final bool resizable;
  final ValueChanged<double>? onWidthChange;

  @override
  State<_Nav> createState() => _NavState();
}

class _NavState extends State<_Nav> {
  late bool open = widget.initialOpen;
  double width = 260;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: 700,
        child: KumoSidebar(
          open: open,
          onOpenChange: (v) {
            widget.onOpenChange?.call(v);
            setState(() => open = v);
          },
          onOpenChangeComplete: widget.onOpenChangeComplete,
          loading: widget.loading,
          width: width,
          onWidthChange: widget.resizable
              ? (w) {
                  widget.onWidthChange?.call(w);
                  setState(() => width = w);
                }
              : null,
          header: const KumoSidebarHeader(
            children: [
              KumoIcon(KumoIcons.cube),
              Expanded(child: KumoText('Company', bold: true, truncate: true)),
            ],
          ),
          footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
          child: KumoSidebarContent(
            children: [
              KumoSidebarGroup(
                children: [
                  KumoSidebarMenuButton(
                    icon: KumoIcons.house,
                    label: 'Home',
                    active: true,
                    onPress: () => widget.onPress?.call('Home'),
                  ),
                  KumoSidebarMenuButton(
                    icon: KumoIcons.chartBar,
                    label: 'Analytics and logs',
                    onPress: () => widget.onPress?.call('Analytics'),
                  ),
                ],
              ),
              KumoSidebarGroup(
                label: 'Build',
                children: [
                  KumoSidebarCollapsible(
                    icon: KumoIcons.code,
                    label: 'Compute',
                    children: [
                      KumoSidebarMenuSubButton(label: 'Workers', onPress: () => widget.onPress?.call('Workers')),
                      KumoSidebarMenuSubButton(label: 'Containers', badge: 'Beta', onPress: () {}),
                    ],
                  ),
                  KumoSidebarMenuButton(icon: KumoIcons.database, label: 'Storage', onPress: () {}),
                ],
              ),
              KumoSidebarGroup(
                label: 'Protect',
                children: [
                  KumoSidebarMenuButton(icon: KumoIcons.lock, label: 'Zero Trust', badge: 'Beta', onPress: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _sidebarWidth(WidgetTester tester) => tester.getSize(find.byType(KumoSidebar)).width;

void main() {
  testWidgets('renders expanded in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, const _Nav(), brightness: b, size: kumoDesktopSize, center: false);
      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Build'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(_sidebarWidth(tester), 260);
    }
  });

  testWidgets('trigger collapses to the 57px rail and back', (tester) async {
    final changes = <bool>[];
    final completed = <bool>[];
    await pumpKumo(
      tester,
      _Nav(onOpenChange: changes.add, onOpenChangeComplete: completed.add),
      size: kumoDesktopSize,
      center: false,
    );
    await tester.tap(find.bySemanticsLabel('Collapse sidebar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final mid = _sidebarWidth(tester);
    expect(mid, inExclusiveRange(57, 260));
    expect(completed, isEmpty);
    await tester.pumpAndSettle();
    expect(changes, [false]);
    expect(completed, [false]);
    expect(_sidebarWidth(tester), 57);

    await tester.tap(find.bySemanticsLabel('Expand sidebar'));
    await tester.pumpAndSettle();
    expect(changes, [false, true]);
    expect(completed, [false, true]);
    expect(_sidebarWidth(tester), 260);
  });

  testWidgets('labels keep their size while the width animates', (tester) async {
    await pumpKumo(tester, const _Nav(), size: kumoDesktopSize, center: false);
    final before = tester.getSize(find.text('Analytics and logs'));
    await tester.tap(find.bySemanticsLabel('Collapse sidebar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(find.text('Analytics and logs')), before);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(find.text('Analytics and logs')), before);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.text('Analytics and logs')), before);
  });

  testWidgets('collapsed rows are 34px icon tiles with tooltips', (tester) async {
    await pumpKumo(tester, const _Nav(initialOpen: false), size: kumoDesktopSize, center: false);
    expect(_sidebarWidth(tester), 57);
    final row = find.ancestor(of: find.text('Home'), matching: find.byType(KumoPressable)).first;
    final rect = tester.getRect(row);
    expect(rect.width, 34);
    expect(rect.left, 11);
    // Long press is the touch path to a tooltip.
    await tester.longPress(row);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(KumoPopupSurface), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('expanded rows show no tooltip', (tester) async {
    await pumpKumo(tester, const _Nav(), size: kumoDesktopSize, center: false);
    await tester.longPress(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(KumoPopupSurface), findsNothing);
  });

  testWidgets('menu buttons fire onPress and expose role, label and selection', (tester) async {
    final pressed = <String>[];
    await pumpKumo(tester, _Nav(onPress: pressed.add), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Analytics and logs'));
    expect(pressed, ['Analytics']);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.ancestor(of: find.text('Home'), matching: find.byType(KumoPressable)).first),
      matchesSemantics(
        label: 'Home',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('disabled rows do not fire', (tester) async {
    var pressed = 0;
    await pumpKumo(
      tester,
      SizedBox(
        height: 300,
        child: KumoSidebar(
          child: KumoSidebarContent(
            children: [
              KumoSidebarGroup(
                children: [KumoSidebarMenuButton(label: 'Billing', disabled: true, onPress: () => pressed++)],
              ),
            ],
          ),
        ),
      ),
      size: kumoDesktopSize,
    );
    await tester.tap(find.text('Billing'));
    expect(pressed, 0);
  });

  testWidgets('collapsible toggles, rotates its chevron and hides closed rows', (tester) async {
    await pumpKumo(tester, const _Nav(), size: kumoDesktopSize, center: false);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Workers'), findsNothing);
    await tester.tap(find.text('Compute'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Workers'), findsOneWidget);
    expect(tester.getRect(find.text('Workers')).top, greaterThan(tester.getRect(find.text('Compute')).bottom));
    expect(
      tester.getSemantics(find.ancestor(of: find.text('Compute'), matching: find.byType(KumoPressable)).first),
      matchesSemantics(
        label: 'Compute',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    await tester.tap(find.text('Compute'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Workers'), findsNothing);
    handle.dispose();
  });

  testWidgets('controlled collapsible reports changes and follows its value', (tester) async {
    final changes = <bool>[];
    final completes = <bool>[];
    Widget build(bool open) => SizedBox(
      height: 400,
      child: KumoSidebar(
        child: KumoSidebarContent(
          children: [
            KumoSidebarGroup(
              children: [
                KumoSidebarCollapsible(
                  label: 'Compute',
                  icon: KumoIcons.code,
                  open: open,
                  onOpenChange: changes.add,
                  onOpenChangeComplete: completes.add,
                  children: const [KumoSidebarMenuSubButton(label: 'Workers')],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await pumpKumo(tester, build(false), size: kumoDesktopSize);
    await tester.tap(find.text('Compute'));
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(completes, isEmpty, reason: 'the parent has not opened it yet');
    await tester.pumpWidget(kumoHarness(build(true), size: kumoDesktopSize));
    await tester.pumpAndSettle();
    expect(completes, [true]);
    expect(tester.getSize(find.text('Workers')).height, greaterThan(0));
  });

  testWidgets('pressing a collapsible in the rail expands the sidebar and opens it', (tester) async {
    final changes = <bool>[];
    await pumpKumo(tester, _Nav(initialOpen: false, onOpenChange: changes.add), size: kumoDesktopSize, center: false);
    await tester.tap(find.ancestor(of: find.text('Compute'), matching: find.byType(KumoPressable)).first);
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(_sidebarWidth(tester), 260);
    expect(tester.getRect(find.text('Workers')).height, greaterThan(0));
  });

  testWidgets('group labels fold into dividers in the rail', (tester) async {
    await pumpKumo(tester, const _Nav(), size: kumoDesktopSize, center: false);
    final expandedHeight = tester
        .getSize(find.ancestor(of: find.text('Build'), matching: find.byType(ClipRect)).first)
        .height;
    expect(expandedHeight, greaterThan(30));
    await tester.tap(find.bySemanticsLabel('Collapse sidebar'));
    await tester.pumpAndSettle();
    final collapsedHeight = tester
        .getSize(find.ancestor(of: find.text('Build'), matching: find.byType(ClipRect)).first)
        .height;
    expect(collapsedHeight, 0);
  });

  testWidgets('keyboard: Tab focuses rows, Enter activates, arrows move between rows', (tester) async {
    final pressed = <String>[];
    await pumpKumo(tester, _Nav(onPress: pressed.add), size: kumoDesktopSize, center: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, ['Home']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, ['Home', 'Analytics']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(pressed, ['Home', 'Analytics', 'Home']);
  });

  testWidgets('tabbing onto a collapsible opens it and leaving closes it again', (tester) async {
    await pumpKumo(tester, const _Nav(), size: kumoDesktopSize, center: false);
    // Home, Analytics, Compute.
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(tester.getSize(find.text('Workers')).height, greaterThan(0));
    // Workers, Containers, Storage: focus leaves the section.
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Workers').hitTestable(), findsNothing);
  });

  testWidgets('reduced motion collapses without animating', (tester) async {
    final completed = <bool>[];
    await pumpKumo(
      tester,
      _Nav(onOpenChangeComplete: completed.add),
      size: kumoDesktopSize,
      center: false,
      disableAnimations: true,
    );
    await tester.tap(find.bySemanticsLabel('Collapse sidebar'));
    await tester.pump();
    expect(_sidebarWidth(tester), 57);
    expect(completed, [false]);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('offcanvas collapses to zero width', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        height: 300,
        child: KumoSidebar(
          open: false,
          collapsible: KumoSidebarCollapseMode.offcanvas,
          child: KumoSidebarContent(
            children: [
              KumoSidebarGroup(children: [KumoSidebarMenuButton(label: 'Home')]),
            ],
          ),
        ),
      ),
      size: kumoDesktopSize,
    );
    expect(_sidebarWidth(tester), 0);
  });

  testWidgets('loading shows placeholder rows announced as loading', (tester) async {
    await pumpKumo(tester, const _Nav(loading: true), size: kumoDesktopSize, center: false);
    expect(find.byType(KumoSidebarLoading), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    handle.dispose();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('sliding views switch surfaces and hide the inactive one', (tester) async {
    var surface = 'account';
    late StateSetter setOuter;
    await pumpKumo(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          setOuter = setState;
          return SizedBox(
            height: 400,
            child: KumoSidebar(
              child: KumoSidebarSlidingViews(
                activeKey: surface,
                children: const [
                  KumoSidebarSlidingView(
                    value: 'account',
                    child: KumoSidebarContent(
                      children: [
                        KumoSidebarGroup(children: [KumoSidebarMenuButton(label: 'Domains')]),
                      ],
                    ),
                  ),
                  KumoSidebarSlidingView(
                    value: 'zone',
                    child: KumoSidebarContent(
                      children: [
                        KumoSidebarGroup(
                          label: 'example.com',
                          children: [KumoSidebarMenuButton(label: 'DNS')],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      size: kumoDesktopSize,
    );
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Domains'), findsOneWidget);
    expect(find.bySemanticsLabel('DNS'), findsNothing);
    setOuter(() => surface = 'zone');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final mid = tester.getRect(find.text('DNS')).left;
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('DNS')).left, lessThan(mid));
    expect(find.bySemanticsLabel('DNS'), findsOneWidget);
    expect(find.bySemanticsLabel('Domains'), findsNothing);
    handle.dispose();
  });

  testWidgets('resize handle drags the width and collapses past the minimum', (tester) async {
    final widths = <double>[];
    await pumpKumo(tester, _Nav(resizable: true, onWidthChange: widths.add), size: kumoDesktopSize, center: false);
    final handle = find.bySemanticsLabel('Resize sidebar');
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(_sidebarWidth(tester), closeTo(300, 20));
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 57);
    expect(widths, isNotEmpty);
  });

  testWidgets('resize handle responds to arrow keys, Home and End', (tester) async {
    await pumpKumo(tester, const _Nav(resizable: true), size: kumoDesktopSize, center: false);
    final focus = tester.widget<Focus>(
      find.descendant(of: find.bySemanticsLabel('Resize sidebar'), matching: find.byType(Focus)).first,
    );
    focus.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 270);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 260);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 480);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 57);
  });

  testWidgets('KumoSidebarClose renders nothing outside a drawer', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        height: 300,
        child: KumoSidebar(
          header: KumoSidebarHeader(
            children: [
              Expanded(child: KumoText('Nav')),
              KumoSidebarClose(),
            ],
          ),
          child: KumoSidebarContent(children: []),
        ),
      ),
      size: kumoDesktopSize,
    );
    expect(find.byType(KumoButton), findsNothing);
  });

  testWidgets('separator and sub menu render, RTL mirrors the border', (tester) async {
    await pumpKumo(
      tester,
      const Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          height: 300,
          child: KumoSidebar(
            child: KumoSidebarContent(
              children: [
                KumoSidebarGroup(
                  children: [
                    KumoSidebarMenuButton(label: 'Home', icon: KumoIcons.house),
                    KumoSidebarSeparator(),
                    KumoSidebarMenuSub(children: [KumoSidebarMenuSubButton(label: 'Overview', active: true)]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      size: kumoDesktopSize,
      textDirection: TextDirection.rtl,
      center: false,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(KumoSidebar)).right, kumoDesktopSize.width);
  });

  testWidgets('no overflow at 390px with 2x text', (tester) async {
    await pumpKumo(tester, const _Nav(), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Compute'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel('Collapse sidebar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('KumoSidebar.of exposes state to descendants', (tester) async {
    KumoSidebarData? data;
    await pumpKumo(
      tester,
      SizedBox(
        height: 300,
        child: KumoSidebar(
          open: false,
          child: Builder(
            builder: (context) {
              data = KumoSidebar.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
      size: kumoDesktopSize,
    );
    expect(data!.open, isFalse);
    expect(data!.collapsed, isTrue);
    expect(data!.drawer, isFalse);
  });

  testWidgets('the active tint travels from the old row to the new one', (tester) async {
    await pumpKumo(tester, const _ActiveNav(), size: kumoDesktopSize, center: false);
    final flight = find.byKey(const ValueKey('kumo-sidebar-active-flight'));
    expect(tester.getSize(flight), Size.zero, reason: 'at rest the active row paints its own tint');
    expect(_rowTint(tester, 'Home'), isNotNull);
    final homeTop = tester.getRect(find.ancestor(of: find.text('Home'), matching: find.byType(DecoratedBox)).first).top;
    final storageTop = tester
        .getRect(find.ancestor(of: find.text('Storage'), matching: find.byType(DecoratedBox)).first)
        .top;

    await tester.tap(find.text('Storage'));
    // The destination is measured after the frame that activates it.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getRect(flight);
    expect(mid.top, inExclusiveRange(homeTop, storageTop));
    expect(_rowTint(tester, 'Storage'), isNull, reason: 'the travelling tint has not landed yet');
    expect(_rowTint(tester, 'Home'), isNull);

    // Redirected mid-flight, it turns around from where it is.
    await tester.tap(find.text('Analytics and logs'));
    await tester.pump();
    expect(tester.getRect(flight).top, closeTo(mid.top, 1));
    await tester.pumpAndSettle();
    expect(tester.getSize(flight), Size.zero);
    expect(_rowTint(tester, 'Analytics and logs'), isNotNull);
    expect(_rowTint(tester, 'Storage'), isNull);
  });

  testWidgets('reduced motion moves the active tint at once', (tester) async {
    await pumpKumo(tester, const _ActiveNav(), size: kumoDesktopSize, center: false, disableAnimations: true);
    await tester.tap(find.text('Storage'));
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('kumo-sidebar-active-flight'))), Size.zero);
    expect(_rowTint(tester, 'Storage'), isNotNull);
    expect(_rowTint(tester, 'Home'), isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the collapsible chevron turns in step with the rows it reveals', (tester) async {
    await pumpKumo(tester, const _Nav(), size: kumoDesktopSize, center: false);
    final chevron = find.descendant(
      of: find.ancestor(of: find.text('Compute'), matching: find.byType(KumoPressable)).first,
      matching: find.byType(RotationTransition),
    );
    double turns() => tester.widget<RotationTransition>(chevron).turns.value;
    expect(turns(), 0);
    await tester.tap(find.text('Compute'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    final mid = turns();
    expect(mid, inExclusiveRange(0, 0.25));
    // Closing mid-flight reverses from the current angle.
    await tester.tap(find.text('Compute'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(turns(), inExclusiveRange(0, mid + 0.01));
    await tester.pumpAndSettle();
    expect(turns(), 0);
  });

  testWidgets('reduced motion opens a collapsible and turns its chevron in one frame', (tester) async {
    await pumpKumo(tester, const _Nav(), size: kumoDesktopSize, center: false, disableAnimations: true);
    await tester.tap(find.text('Compute'));
    await tester.pump();
    final chevron = find.descendant(
      of: find.ancestor(of: find.text('Compute'), matching: find.byType(KumoPressable)).first,
      matching: find.byType(RotationTransition),
    );
    expect(tester.widget<RotationTransition>(chevron).turns.value, 0.25);
    await tester.pump();
    expect(find.text('Workers').hitTestable(), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

/// Background color of the tint box behind [label]'s row, null when clear.
Color? _rowTint(WidgetTester tester, String label) {
  final box = tester.widget<DecoratedBox>(
    find.ancestor(of: find.text(label), matching: find.byType(DecoratedBox)).first,
  );
  return (box.decoration as BoxDecoration).color;
}

/// Rows whose active state follows the last press, like an app's router.
class _ActiveNav extends StatefulWidget {
  const _ActiveNav();

  @override
  State<_ActiveNav> createState() => _ActiveNavState();
}

class _ActiveNavState extends State<_ActiveNav> {
  String route = 'Home';

  @override
  Widget build(BuildContext context) {
    KumoSidebarMenuButton row(IconData icon, String label) => KumoSidebarMenuButton(
      icon: icon,
      label: label,
      active: route == label,
      onPress: () => setState(() => route = label),
    );
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: 600,
        child: KumoSidebar(
          child: KumoSidebarContent(
            children: [
              KumoSidebarGroup(children: [row(KumoIcons.house, 'Home'), row(KumoIcons.chartBar, 'Analytics and logs')]),
              KumoSidebarGroup(
                label: 'Build',
                children: [row(KumoIcons.code, 'Workers'), row(KumoIcons.database, 'Storage')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
