import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _tabs = [
  KumoPageHeaderTab(label: 'Overview', value: 'overview'),
  KumoPageHeaderTab(label: 'Metrics', value: 'metrics'),
  KumoPageHeaderTab(label: 'Settings', value: 'settings'),
];

Widget _header({String value = 'overview', ValueChanged<String>? onValueChange, bool tabs = true, VoidCallback? onDeploy}) {
  return Align(
    alignment: Alignment.topCenter,
    child: KumoPageHeader(
      breadcrumbs: const SizedBox(height: 48, child: Text('Workers / image-resizer')),
      title: 'image-resizer',
      description: 'Resizes and converts images at the edge.',
      tabs: tabs ? _tabs : null,
      value: value,
      onValueChange: onValueChange,
      actions: [
        KumoButton(label: 'Edit code', icon: KumoIcons.code, onPress: () {}),
        KumoButton(label: 'Deploy', variant: KumoButtonVariant.primary, onPress: onDeploy ?? () {}),
      ],
    ),
  );
}

void main() {
  testWidgets('renders every section in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(tester, _header(), brightness: b, size: kumoDesktopSize, center: false);
      expect(tester.takeException(), isNull);
      expect(find.text('image-resizer'), findsOneWidget);
      expect(find.text('Resizes and converts images at the edge.'), findsOneWidget);
      expect(find.text('Metrics'), findsOneWidget);
    }
  });

  testWidgets('title is a level 1 heading', (tester) async {
    await pumpKumo(tester, _header(), size: kumoDesktopSize, center: false);
    final handle = tester.ensureSemantics();
    expect(tester.getSemantics(find.text('image-resizer')), matchesSemantics(label: 'image-resizer', isHeader: true));
    handle.dispose();
  });

  testWidgets('tab press reports the value and marks the selected tab', (tester) async {
    final picked = <String>[];
    await pumpKumo(tester, _header(onValueChange: picked.add), size: kumoDesktopSize, center: false);
    await tester.tap(find.text('Settings'));
    expect(picked, ['settings']);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('Overview')),
      matchesSemantics(
        label: 'Overview',
        isSelected: true,
        hasSelectedState: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(tester.getSemantics(find.text('Metrics')).flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('the tabs are a segmented KumoTabs whose indicator moves to the selected tab', (tester) async {
    await pumpKumo(tester, _header(), size: kumoDesktopSize, center: false);
    await tester.pumpAndSettle();
    final tabs = tester.widget<KumoTabs>(find.byType(KumoTabs));
    expect(tabs.variant, KumoTabsVariant.segmented);
    expect(tabs.tabs.map((t) => t.label), ['Overview', 'Metrics', 'Settings']);
    final indicator = find.byKey(const ValueKey('kumo-tabs-indicator'));
    final first = tester.getRect(indicator);
    expect(first.center.dx, closeTo(tester.getCenter(find.text('Overview')).dx, 1));
    await tester.pumpWidget(kumoHarness(_header(value: 'settings'), size: kumoDesktopSize, center: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.getRect(indicator).center.dx;
    await tester.pumpAndSettle();
    final end = tester.getRect(indicator).center.dx;
    expect(end, closeTo(tester.getCenter(find.text('Settings')).dx, 1));
    expect(mid, inExclusiveRange(first.center.dx, end));
  });

  testWidgets('arrow keys move focus between tabs', (tester) async {
    final picked = <String>[];
    await pumpKumo(tester, _header(onValueChange: picked.add), size: kumoDesktopSize, center: false);
    Focus.of(tester.element(find.text('Overview'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picked, ['metrics']);
  });

  testWidgets('wide: actions share the tab row', (tester) async {
    await pumpKumo(tester, _header(), size: kumoDesktopSize, center: false);
    final tabs = tester.getRect(find.text('Overview'));
    final deploy = tester.getRect(find.text('Deploy'));
    expect((deploy.center.dy - tabs.center.dy).abs(), lessThan(4));
    expect(deploy.left, greaterThan(tabs.right));
  });

  testWidgets('narrow: actions wrap below the tabs', (tester) async {
    await pumpKumo(tester, _header(), center: false);
    expect(tester.getRect(find.text('Deploy')).top, greaterThan(tester.getRect(find.text('Overview')).bottom));
  });

  testWidgets('without tabs, actions sit beside the title or below it on narrow screens', (tester) async {
    await pumpKumo(tester, _header(tabs: false), size: kumoDesktopSize, center: false);
    final title = tester.getRect(find.text('image-resizer'));
    expect(tester.getRect(find.text('Deploy')).top, lessThan(title.bottom));
    await pumpKumo(tester, _header(tabs: false), center: false);
    expect(
      tester.getRect(find.text('Deploy')).top,
      greaterThan(tester.getRect(find.text('Resizes and converts images at the edge.')).bottom),
    );
  });

  testWidgets('actions fire', (tester) async {
    var deploys = 0;
    await pumpKumo(tester, _header(onDeploy: () => deploys++), center: false);
    await tester.tap(find.text('Deploy'));
    expect(deploys, 1);
  });

  testWidgets('spacing changes the gap between sections', (tester) async {
    Future<double> gap(KumoPageHeaderSpacing spacing) async {
      await pumpKumo(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: KumoPageHeader(
            spacing: spacing,
            breadcrumbs: const SizedBox(height: 40, child: Text('crumbs')),
            title: 'Page title',
          ),
        ),
        size: kumoDesktopSize,
        center: false,
      );
      return tester.getRect(find.text('Page title')).top;
    }

    final compact = await gap(KumoPageHeaderSpacing.compact);
    final relaxed = await gap(KumoPageHeaderSpacing.relaxed);
    expect(relaxed - compact, closeTo(12, 0.5));
  });

  testWidgets('reduced motion moves the indicator in one frame', (tester) async {
    await pumpKumo(tester, _header(), size: kumoDesktopSize, center: false, disableAnimations: true);
    await tester.pumpWidget(
      kumoHarness(_header(value: 'settings'), size: kumoDesktopSize, center: false, disableAnimations: true),
    );
    await tester.pump();
    final indicator = tester.getRect(find.byKey(const ValueKey('kumo-tabs-indicator')));
    expect(indicator.center.dx, closeTo(tester.getCenter(find.text('Settings')).dx, 1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('390px with 2x text does not overflow', (tester) async {
    await pumpKumo(tester, _header(), textScale: 2, center: false);
    expect(tester.takeException(), isNull);
  });
}
