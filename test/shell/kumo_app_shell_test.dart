import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const Size _medium = Size(800, 1000);

Widget _shell({
  List<bool>? drawerChanges,
  List<String>? pressed,
  bool bottom = true,
  bool fullScreen = false,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return Builder(builder: (context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(padding: padding, viewPadding: padding),
      child: KumoAppShell(
        onDrawerOpenChange: drawerChanges?.add,
        fullScreenDrawer: fullScreen,
        sidebar: KumoSidebar(
          header: const KumoSidebarHeader(children: [
            Expanded(child: KumoText('Company', bold: true)),
            KumoSidebarClose(),
          ]),
          footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
          child: KumoSidebarContent(children: [
            KumoSidebarGroup(children: [
              KumoSidebarMenuButton(
                icon: KumoIcons.house,
                label: 'Home',
                active: true,
                onPress: () => pressed?.add('Home'),
              ),
              KumoSidebarMenuButton(
                icon: KumoIcons.code,
                label: 'Workers',
                onPress: () => pressed?.add('Workers'),
              ),
            ]),
          ]),
        ),
        topBar: const KumoText('Overview', variant: KumoTextVariant.heading),
        bottomNavigation: bottom ? const SizedBox(height: 56, child: Center(child: Text('Bottom bar'))) : null,
        body: const Center(child: Text('Page body')),
      ),
    );
  });
}

double _drawerLeft(WidgetTester tester) => tester.getRect(find.byType(KumoSidebar)).left;

Future<void> _openWithButton(WidgetTester tester) async {
  await tester.tap(find.text('Menu'));
  await tester.pumpAndSettle();
}

void main() {
  group('wide', () {
    testWidgets('persistent sidebar beside a sticky top bar, no menu button', (tester) async {
      await pumpKumo(tester, _shell(), size: kumoDesktopSize, center: false);
      expect(find.text('Menu'), findsNothing);
      expect(find.text('Bottom bar'), findsNothing);
      expect(tester.getRect(find.byType(KumoSidebar)), const Rect.fromLTWH(0, 0, 260, 800));
      final bar = tester.getRect(find.text('Overview'));
      expect(bar.left, greaterThan(260));
      expect(tester.getRect(find.text('Page body')).top, greaterThan(bar.bottom));
      expect(KumoAppShell.of(tester.element(find.text('Page body'))).layout, KumoAppShellLayout.wide);
    });

    testWidgets('trigger collapses the sidebar and the content grows', (tester) async {
      final changes = <bool>[];
      await pumpKumo(
        tester,
        KumoAppShell(
          onSidebarOpenChange: changes.add,
          sidebar: const KumoSidebar(
            footer: KumoSidebarFooter(children: [KumoSidebarTrigger()]),
            child: KumoSidebarContent(children: []),
          ),
          body: const SizedBox.expand(key: Key('body')),
        ),
        size: kumoDesktopSize,
        center: false,
      );
      await tester.tap(find.bySemanticsLabel('Collapse sidebar'));
      await tester.pumpAndSettle();
      expect(changes, [false]);
      expect(tester.getSize(find.byType(KumoSidebar)).width, 57);
      expect(tester.getRect(find.byKey(const Key('body'))).left, 57);
    });

    testWidgets('controlled sidebarOpen is followed', (tester) async {
      Widget build(bool open) => KumoAppShell(
            sidebarOpen: open,
            sidebar: const KumoSidebar(child: KumoSidebarContent(children: [])),
            body: const SizedBox(),
          );
      await pumpKumo(tester, build(false), size: kumoDesktopSize, center: false);
      expect(tester.getSize(find.byType(KumoSidebar)).width, 57);
      await tester.pumpWidget(kumoHarness(build(true), size: kumoDesktopSize, center: false));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(KumoSidebar)).width, 260);
    });
  });

  group('medium', () {
    testWidgets('starts as the collapsed icon rail and can expand', (tester) async {
      await pumpKumo(tester, _shell(), size: _medium, center: false);
      expect(KumoAppShell.of(tester.element(find.text('Page body'))).layout, KumoAppShellLayout.medium);
      expect(tester.getSize(find.byType(KumoSidebar)).width, 57);
      expect(find.text('Menu'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Expand sidebar'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(KumoSidebar)).width, 260);
    });
  });

  group('narrow', () {
    testWidgets('top bar with a labeled menu button and a bottom bar', (tester) async {
      await pumpKumo(tester, _shell(), center: false);
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Bottom bar'), findsOneWidget);
      // Closed drawer is offstage.
      expect(find.byType(KumoSidebar), findsNothing);
      final body = tester.getRect(find.text('Page body'));
      expect(body.top, greaterThan(tester.getRect(find.text('Overview')).bottom));
      expect(body.bottom, lessThan(tester.getRect(find.text('Bottom bar')).top));
    });

    testWidgets('menu button opens the drawer from the start edge and moves focus in', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _shell(drawerChanges: changes), center: false);
      await _openWithButton(tester);
      expect(changes, [true]);
      expect(_drawerLeft(tester), 0);
      expect(tester.getSize(find.byType(KumoSidebar)).width, 260);
      final focused = FocusManager.instance.primaryFocus!;
      expect(find.descendant(of: find.byType(KumoSidebar), matching: find.byWidgetPredicate((w) => w is Focus && w.focusNode == focused)),
          findsOneWidget);
      expect(KumoAppShell.of(tester.element(find.text('Page body'))).drawerOpen, isTrue);
    });

    testWidgets('Escape closes the drawer and focus returns to the menu button', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _shell(drawerChanges: changes), center: false);
      // Focus the menu button by keyboard, then open it with Enter.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(changes, [true]);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(changes, [true, false]);
      expect(find.byType(KumoSidebar), findsNothing);
      final menu = tester.widget<KumoButton>(find.widgetWithText(KumoButton, 'Menu'));
      expect(menu.focusNode!.hasFocus, isTrue);
    });

    testWidgets('Tab stays inside the open drawer', (tester) async {
      await pumpKumo(tester, _shell(), center: false);
      await _openWithButton(tester);
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final ctx = FocusManager.instance.primaryFocus!.context!;
        expect(ctx.findAncestorWidgetOfExactType<KumoSidebar>(), isNotNull, reason: 'tab $i left the drawer');
      }
    });

    testWidgets('scrim tap closes; nav row press closes and fires', (tester) async {
      final pressed = <String>[];
      await pumpKumo(tester, _shell(pressed: pressed), center: false);
      await _openWithButton(tester);
      await tester.tapAt(const Offset(350, 400));
      await tester.pumpAndSettle();
      expect(find.byType(KumoSidebar), findsNothing);

      await _openWithButton(tester);
      await tester.tap(find.text('Workers'));
      await tester.pumpAndSettle();
      expect(pressed, ['Workers']);
      expect(find.byType(KumoSidebar), findsNothing);
    });

    testWidgets('sidebar close button and back gesture close the drawer', (tester) async {
      await pumpKumo(tester, _shell(), center: false);
      await _openWithButton(tester);
      await tester.tap(find.bySemanticsLabel('Close sidebar').last);
      await tester.pumpAndSettle();
      expect(find.byType(KumoSidebar), findsNothing);

      await _openWithButton(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(KumoSidebar), findsNothing);
    });

    testWidgets('edge swipe opens the drawer and it follows the finger', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _shell(drawerChanges: changes), center: false);
      final gesture = await tester.startGesture(const Offset(4, 400));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      // The finger is 130px in, so the drawer edge is close to x = 130.
      final right = tester.getRect(find.byType(KumoSidebar)).right;
      expect(right, closeTo(130, 30));
      await gesture.moveBy(const Offset(60, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(changes, [true]);
      expect(_drawerLeft(tester), 0);
    });

    testWidgets('a short slow edge drag springs back closed', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _shell(drawerChanges: changes), center: false);
      final gesture = await tester.startGesture(const Offset(4, 400));
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(10, 0), timeStamp: Duration(milliseconds: 100 * (i + 1)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up(timeStamp: const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(find.byType(KumoSidebar), findsNothing);
    });

    testWidgets('flick toward the edge closes an open drawer', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _shell(drawerChanges: changes), center: false);
      await _openWithButton(tester);
      await tester.flingFrom(const Offset(200, 400), const Offset(-60, 0), 1500);
      await tester.pumpAndSettle();
      expect(changes, [true, false]);
      expect(find.byType(KumoSidebar), findsNothing);
    });

    testWidgets('a small slow drag on an open drawer springs back open', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _shell(drawerChanges: changes), center: false);
      await _openWithButton(tester);
      final gesture = await tester.startGesture(const Offset(200, 400));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(-10, 0), timeStamp: Duration(milliseconds: 100 * (i + 1)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_drawerLeft(tester), lessThan(0));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up(timeStamp: const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      expect(changes, [true]);
      expect(_drawerLeft(tester), 0);
    });

    testWidgets('dragging past fully open rubberbands and settles back', (tester) async {
      await pumpKumo(tester, _shell(), center: false);
      await _openWithButton(tester);
      final gesture = await tester.startGesture(const Offset(150, 400));
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      final width = tester.getSize(find.byType(KumoSidebar)).width;
      expect(width, 260, reason: 'the sidebar keeps its size; a filler stretches behind it');
      expect(_drawerLeft(tester), greaterThan(0));
      expect(_drawerLeft(tester), lessThan(120), reason: 'resistance past the open position');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_drawerLeft(tester), 0);
    });

    testWidgets('full screen drawer covers the width', (tester) async {
      await pumpKumo(tester, _shell(fullScreen: true), center: false);
      await _openWithButton(tester);
      expect(tester.getSize(find.byType(KumoSidebar)).width, kumoPhoneSize.width);
    });

    testWidgets('bars take the safe area and the body sits between them', (tester) async {
      const padding = EdgeInsets.only(top: 47, bottom: 34);
      await pumpKumo(tester, _shell(padding: padding), center: false);
      final menu = tester.getRect(find.text('Menu'));
      expect(menu.top, greaterThan(47));
      final bottom = tester.getRect(find.text('Bottom bar'));
      expect(bottom.bottom, lessThanOrEqualTo(kumoPhoneSize.height - 34));
      final ctx = tester.element(find.text('Page body'));
      expect(MediaQuery.paddingOf(ctx), EdgeInsets.zero);
    });

    testWidgets('without a bottom bar the body keeps the bottom safe area', (tester) async {
      const padding = EdgeInsets.only(top: 47, bottom: 34);
      await pumpKumo(
        tester,
        Builder(builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: padding, viewPadding: padding),
            child: const KumoAppShell(body: SizedBox.expand(key: Key('body'))),
          );
        }),
        center: false,
      );
      expect(tester.getRect(find.byKey(const Key('body'))).bottom, kumoPhoneSize.height - 34);
    });

    testWidgets('reduced motion opens and closes without springs', (tester) async {
      await pumpKumo(tester, _shell(), center: false, disableAnimations: true);
      await tester.tap(find.text('Menu'));
      await tester.pump();
      // In place on the first frame, no spring.
      expect(_drawerLeft(tester), 0);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(KumoSidebar), findsNothing);
    });

    testWidgets('light, dark and 2x text without overflow', (tester) async {
      for (final b in Brightness.values) {
        await pumpKumo(tester, KeyedSubtree(key: ValueKey(b), child: _shell()), brightness: b, textScale: 2, center: false);
        await _openWithButton(tester);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('narrow drawer opens from the right edge in RTL', (tester) async {
      await pumpKumo(tester, _shell(), center: false, textDirection: TextDirection.rtl);
      await _openWithButton(tester);
      expect(tester.getRect(find.byType(KumoSidebar)).right, kumoPhoneSize.width);
    });
  });

  testWidgets('resizing from narrow to wide closes the drawer and keeps the sidebar', (tester) async {
    await pumpKumo(tester, _shell(), center: false);
    await _openWithButton(tester);
    tester.view.physicalSize = kumoDesktopSize * tester.view.devicePixelRatio;
    await tester.pumpWidget(kumoHarness(_shell(), size: kumoDesktopSize, center: false));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(KumoSidebar)).left, 0);
    expect(KumoAppShell.of(tester.element(find.text('Page body'))).drawerOpen, isFalse);
  });

  testWidgets('a KumoBottomNavigation keeps a single top border and pads itself', (tester) async {
    tester.view.physicalSize = kumoPhoneSize * tester.view.devicePixelRatio;
    tester.view.padding = FakeViewPadding(bottom: 34 * tester.view.devicePixelRatio);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: kumoPhoneSize,
          padding: EdgeInsets.only(bottom: 34),
          viewPadding: EdgeInsets.only(bottom: 34),
        ),
        child: KumoTheme(
          data: KumoThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: KumoAppShell(
              body: const Text('Page body'),
              bottomNavigation: KumoBottomNavigation(
                value: 'home',
                onValueChange: (_) {},
                items: const [
                  KumoBottomNavigationItem(value: 'home', label: 'Home', icon: KumoIcons.house),
                  KumoBottomNavigationItem(value: 'workers', label: 'Workers', icon: KumoIcons.code),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final bar = find.byType(KumoBottomNavigation);
    // No shell border or SafeArea wrapped around it.
    expect(find.ancestor(of: bar, matching: find.byType(SafeArea)), findsNothing);
    expect(tester.getRect(bar).bottom, kumoPhoneSize.height);
    expect(tester.getRect(find.text('Home')).bottom, lessThanOrEqualTo(kumoPhoneSize.height - 34));
  });

  testWidgets('as a route root with no Scaffold, text uses Kumo type, never the fallback underline', (tester) async {
    tester.view.physicalSize = kumoPhoneSize * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    final theme = KumoThemeData.light();
    await tester.pumpWidget(
      KumoTheme(
        data: theme,
        child: MaterialApp(
          home: KumoAppShell(
            topBar: const Text('Workers'),
            sidebar: KumoSidebar(
              child: KumoSidebarContent(children: [
                KumoSidebarGroup(children: [
                  KumoSidebarMenuButton(icon: KumoIcons.house, label: 'Home', onPress: () {}),
                ]),
              ]),
            ),
            body: const Text('Page body'),
          ),
        ),
      ),
    );
    void expectKumoText(String text) {
      final style = tester.renderObject<RenderParagraph>(find.text(text)).text.style!;
      expect(style.fontFamily, theme.text().fontFamily, reason: '$text uses the Kumo font');
      expect(style.decoration, isNot(TextDecoration.underline), reason: '$text has no fallback underline');
    }

    expectKumoText('Page body');
    expectKumoText('Workers');
    expectKumoText('Menu');
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expectKumoText('Home');
  });

  testWidgets('a standalone KumoSidebar as a route root uses Kumo type', (tester) async {
    final theme = KumoThemeData.light();
    await tester.pumpWidget(
      KumoTheme(
        data: theme,
        child: MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: KumoSidebar(
              child: KumoSidebarContent(children: [
                KumoSidebarGroup(label: 'Build', children: [
                  KumoSidebarMenuButton(icon: KumoIcons.code, label: 'Workers', onPress: () {}),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
    for (final text in ['Build', 'Workers']) {
      final style = tester.renderObject<RenderParagraph>(find.text(text)).text.style!;
      expect(style.decoration, isNot(TextDecoration.underline));
      expect(style.fontFamily, theme.text().fontFamily);
    }
  });
}

