import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Host extends StatefulWidget {
  const _Host({this.presentation = KumoPresentation.auto, this.onAction});

  final KumoPresentation presentation;
  final ValueChanged<String>? onAction;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool lineNumbers = false;
  String region = 'wnam';
  final opens = <bool>[];

  @override
  Widget build(BuildContext context) {
    void act(String a) => widget.onAction?.call(a);
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: KumoDropdownMenu(
          presentation: widget.presentation,
          semanticLabel: 'Worker actions',
          onOpenChange: opens.add,
          triggerBuilder: (context, menu) => KumoButton(label: 'Actions', onPress: menu.toggle),
          items: [
            KumoDropdownItem(label: 'Rename', icon: KumoIcons.pencilSimple, onPress: () => act('rename')),
            KumoDropdownItem(label: 'Duplicate', shortcut: '⌘D', onPress: () => act('duplicate')),
            const KumoDropdownItem(label: 'Archive', disabled: true),
            KumoDropdownLinkItem(label: 'Open logs', onPress: () => act('logs')),
            KumoDropdownCheckboxItem(
              label: 'Show line numbers',
              checked: lineNumbers,
              onCheckedChange: (v) => setState(() => lineNumbers = v),
            ),
            KumoDropdownSubmenu(
              label: 'Region',
              icon: KumoIcons.globe,
              children: [
                KumoDropdownRadioGroup<String>(
                  value: region,
                  onValueChange: (v) => setState(() => region = v),
                  children: const [
                    KumoDropdownRadioItem(value: 'wnam', label: 'Western North America'),
                    KumoDropdownRadioItem(value: 'weur', label: 'Western Europe'),
                  ],
                ),
              ],
            ),
            const KumoDropdownSeparator(),
            KumoDropdownItem(label: 'Delete', icon: KumoIcons.trash, destructive: true, onPress: () => act('delete')),
          ],
        ),
      ),
    );
  }
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders open in ${brightness.name} at desktop size', (tester) async {
      await pumpKumo(tester, const _Host(), brightness: brightness, size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      expect(find.byType(KumoMenuPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('item press fires and closes; disabled does not fire', (tester) async {
    final actions = <String>[];
    await pumpKumo(tester, _Host(onAction: actions.add), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(actions, ['rename']);
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('checkbox stays open and reflects the new value', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show line numbers'));
    await tester.pumpAndSettle();
    expect(find.text('Show line numbers'), findsOneWidget);
    final state = tester.state<_HostState>(find.byType(_Host));
    expect(state.lineNumbers, isTrue);
  });

  testWidgets('submenu opens on tap and its radio changes the value', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Region'));
    await tester.pumpAndSettle();
    expect(find.text('Western Europe'), findsOneWidget);
    // Opens to the side of its row.
    expect(tester.getTopLeft(find.text('Western Europe')).dx, greaterThan(tester.getTopRight(find.text('Region')).dx));
    await tester.tap(find.text('Western Europe'));
    await tester.pumpAndSettle();
    expect(tester.state<_HostState>(find.byType(_Host)).region, 'weur');
  });

  testWidgets('submenu opens on hover after a short delay', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Region')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('Western Europe'), findsOneWidget);
    await mouse.moveTo(tester.getCenter(find.text('Rename')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Western Europe'), findsNothing);
    await mouse.removePointer();
  });

  testWidgets(
    'keyboard: ArrowDown opens on the first item, arrows move, ArrowRight and ArrowLeft drive submenus, Escape closes',
    (tester) async {
      await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('Rename'))).hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(Focus.of(tester.element(find.text('Delete'))).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(Focus.of(tester.element(find.text('Region'))).hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Western Europe'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('Western North America'))).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Western Europe'), findsNothing);
      expect(Focus.of(tester.element(find.text('Region'))).hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Western Europe'), findsNothing);
      expect(find.text('Rename'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
      await tester.pump();
      expect(Focus.of(tester.element(find.text('Actions'))).hasFocus, isTrue);
    },
  );

  testWidgets('Enter activates the focused item', (tester) async {
    final actions = <String>[];
    await pumpKumo(tester, _Host(onAction: actions.add), size: kumoDesktopSize, center: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(actions, ['duplicate']);
  });

  testWidgets('outside tap closes', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(1000, 700));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsNothing);
    expect(tester.state<_HostState>(find.byType(_Host)).opens, [true, false]);
  });

  testWidgets('semantics: item roles and states', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Show line numbers')),
      matchesSemantics(
        label: 'Show line numbers',
        isButton: true,
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    final link = tester.getSemantics(find.text('Open logs')).getSemanticsData();
    expect(link.flagsCollection.isLink, isTrue);
    final archive = tester.getSemantics(find.text('Archive')).getSemanticsData();
    expect(archive.flagsCollection.isEnabled, Tristate.isFalse);
    final region = tester.getSemantics(find.text('Region')).getSemanticsData();
    expect(region.flagsCollection.isExpanded, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('narrow screens open a sheet; submenus push in place with a back row', (tester) async {
    final actions = <String>[];
    await pumpKumo(tester, _Host(onAction: actions.add), center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    expect(find.byType(KumoMenuPanel), findsNothing);
    await tester.tap(find.text('Region'));
    await tester.pumpAndSettle();
    expect(find.text('Western Europe'), findsOneWidget);
    expect(find.text('Rename'), findsNothing);
    await tester.tap(find.text('Western Europe'));
    await tester.pumpAndSettle();
    expect(tester.state<_HostState>(find.byType(_Host)).region, 'weur');
    // The sheet stays open on a radio and shows the new value.
    final checked = tester.getSemantics(find.text('Western Europe')).getSemanticsData();
    expect(checked.flagsCollection.isChecked, CheckedState.isTrue);
    await tester.tap(find.text('Region'));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(actions, ['rename']);
    expect(find.byType(KumoSheet), findsNothing);
  });

  testWidgets('sheet dismisses with a downward fling and reports closed', (tester) async {
    await pumpKumo(tester, const _Host(), center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.fling(find.text('Rename'), const Offset(0, 400), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsNothing);
    expect(tester.state<_HostState>(find.byType(_Host)).opens, [true, false]);
  });

  testWidgets('presentation overrides: popover on phone, sheet on desktop', (tester) async {
    await pumpKumo(tester, const _Host(presentation: KumoPresentation.popover), center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoMenuPanel), findsOneWidget);
    await pumpKumo(tester, const SizedBox());
    await pumpKumo(tester, const _Host(presentation: KumoPresentation.sheet), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
  });

  testWidgets('controlled open reflects the value it is given', (tester) async {
    Widget build(bool open) => KumoDropdownMenu(
      open: open,
      presentation: KumoPresentation.popover,
      trigger: const Text('Zone'),
      items: const [KumoDropdownItem(label: 'Purge cache')],
    );
    await pumpKumo(tester, build(false));
    expect(find.text('Purge cache'), findsNothing);
    await pumpKumo(tester, build(true));
    expect(find.text('Purge cache'), findsOneWidget);
    await pumpKumo(tester, build(false));
    expect(find.text('Purge cache'), findsNothing);
  });

  testWidgets('trigger slot is pressable and disabled blocks opening', (tester) async {
    var calls = 0;
    Widget build({bool disabled = false}) => KumoDropdownMenu(
      disabled: disabled,
      presentation: KumoPresentation.popover,
      onOpenChange: (_) => calls++,
      trigger: const Text('Zone'),
      items: const [KumoDropdownItem(label: 'Purge cache')],
    );
    await pumpKumo(tester, build(disabled: true));
    await tester.tap(find.text('Zone'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await pumpKumo(tester, build());
    await tester.tap(find.text('Zone'));
    await tester.pumpAndSettle();
    expect(find.text('Purge cache'), findsOneWidget);
  });

  testWidgets('reduced motion opens without scale and settles', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false, disableAnimations: true);
    await tester.tap(find.text('Actions'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final scale = tester
        .widgetList<Transform>(find.ancestor(of: find.byType(KumoMenuPanel), matching: find.byType(Transform)))
        .first;
    expect(scale.transform.storage[0], 1);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('text scale 2 at 390px and RTL do not overflow', (tester) async {
    await pumpKumo(tester, const _Host(presentation: KumoPresentation.popover), textScale: 2, center: false);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Region'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await pumpKumo(tester, const _Host(), textScale: 2, center: false, textDirection: TextDirection.rtl);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL opens submenus to the left', (tester) async {
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false, textDirection: TextDirection.rtl);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Region'));
    await tester.pumpAndSettle();
    expect(tester.getTopRight(find.text('Western Europe')).dx, lessThan(tester.getTopLeft(find.text('Region')).dx));
  });

  group('motion', () {
    Transform checkTransform(WidgetTester tester) => tester.widget<Transform>(
      find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(Transform)).first,
    );
    Opacity checkOpacity(WidgetTester tester) =>
        tester.widget<Opacity>(find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(Opacity)).first);

    testWidgets('a checkbox check lands with a bounce and fades when cleared', (tester) async {
      await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(find.byIcon(KumoIcons.check), findsNothing);
      await tester.tap(find.text('Show line numbers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final landing = checkTransform(tester).transform.storage[0];
      expect(landing, greaterThan(0.5));
      expect(landing, lessThan(1));
      await tester.pumpAndSettle();
      expect(checkTransform(tester).transform.storage[0], closeTo(1, 0.001));

      await tester.tap(find.text('Show line numbers'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final fading = checkOpacity(tester).opacity;
      expect(fading, greaterThan(0));
      expect(fading, lessThan(1));
      await tester.pumpAndSettle();
      expect(find.byIcon(KumoIcons.check), findsNothing);
    });

    testWidgets('a radio check moves to the picked option', (tester) async {
      await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Region'));
      await tester.pumpAndSettle();
      expect(find.byIcon(KumoIcons.check), findsOneWidget);
      await tester.tap(find.text('Western Europe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.byIcon(KumoIcons.check), findsNWidgets(2), reason: 'the old check leaves while the new one lands');
      await tester.pumpAndSettle();
      expect(find.byIcon(KumoIcons.check), findsOneWidget);
      final row = find.ancestor(of: find.text('Western Europe'), matching: find.byType(KumoMenuRow));
      expect(find.descendant(of: row, matching: find.byIcon(KumoIcons.check)), findsOneWidget);
    });

    testWidgets('reduced motion: checks change at once', (tester) async {
      await pumpKumo(tester, const _Host(), size: kumoDesktopSize, center: false, disableAnimations: true);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show line numbers'));
      await tester.pump();
      expect(checkTransform(tester).transform.storage[0], 1);
      // The open popup's overlay layout leaves a framework frame callback
      // registered, so check for scheduled frames instead.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('the sheet resizes smoothly when a submenu pushes in', (tester) async {
      await pumpKumo(tester, const _Host(), center: false);
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      Finder sized() => find.descendant(of: find.byType(KumoSheet), matching: find.byType(AnimatedSize)).first;
      final before = tester.getSize(sized()).height;
      await tester.tap(find.text('Region'));
      await tester.pumpAndSettle();
      final after = tester.getSize(sized()).height;
      expect(after, lessThan(before));
      await tester.tap(find.text('Region'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getSize(sized()).height;
      expect(mid, greaterThan(after));
      expect(mid, lessThan(before));
      await tester.pumpAndSettle();
      expect(tester.getSize(sized()).height, closeTo(before, 0.5));
    });

    Widget caretMenu() => Align(
      alignment: AlignmentDirectional.topStart,
      child: KumoDropdownMenu(
        presentation: KumoPresentation.popover,
        triggerBuilder: (context, menu) => KumoButton(
          onPress: menu.toggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Zone'),
              KumoDropdownCaret(open: menu.isOpen),
            ],
          ),
        ),
        items: const [KumoDropdownItem(label: 'example.com')],
      ),
    );

    double caretTurns(WidgetTester tester) => tester
        .widget<RotationTransition>(
          find.descendant(of: find.byType(KumoDropdownCaret), matching: find.byType(RotationTransition)),
        )
        .turns
        .value;

    testWidgets('KumoDropdownCaret turns over with the menu and reverses mid-flight', (tester) async {
      await pumpKumo(tester, caretMenu(), size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Zone'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final opening = caretTurns(tester);
      expect(opening, greaterThan(0));
      expect(opening, lessThan(0.5));
      await tester.tapAt(const Offset(1000, 700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final reversing = caretTurns(tester);
      expect(reversing, lessThan(0.5));
      expect(reversing, greaterThan(0), reason: 'turns back from where it was, no jump');
      await tester.pumpAndSettle();
      expect(caretTurns(tester), 0);
    });

    testWidgets('reduced motion: the caret flips at once', (tester) async {
      await pumpKumo(tester, caretMenu(), size: kumoDesktopSize, center: false, disableAnimations: true);
      await tester.tap(find.text('Zone'));
      await tester.pump();
      expect(caretTurns(tester), 0.5);
      await tester.pumpAndSettle();
      // The open popup's overlay layout leaves a framework frame callback
      // registered, so check for scheduled frames instead.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('backLabel defaults to KumoStrings.back', (tester) async {
      await pumpKumo(
        tester,
        const KumoLocale(
          strings: KumoStrings(back: 'Kembali'),
          child: _Host(),
        ),
        center: false,
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Region'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Kembali'), findsOneWidget);
    });
  });
}
