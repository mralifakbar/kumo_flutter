import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

class _Subdomain extends StatefulWidget {
  const _Subdomain();

  @override
  State<_Subdomain> createState() => _SubdomainState();
}

class _SubdomainState extends State<_Subdomain> {
  String value = 'kumo';

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: KumoInputGroup(
      label: 'Subdomain',
      children: [
        KumoInputGroupInput(value: value, onValueChange: (v) => setState(() => value = v)),
        const KumoInputGroupSuffix('.workers.dev'),
      ],
    ),
  );
}

void main() {
  testWidgets('renders every size and part in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final s in KumoFieldSize.values)
                KumoInputGroup(
                  size: s,
                  label: s.name,
                  children: [
                    const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
                    const KumoInputGroupInput(placeholder: 'Search Workers'),
                    KumoInputGroupAddon(
                      align: KumoInputGroupAlign.end,
                      child: KumoInputGroupButton(icon: KumoIcons.question, tooltip: 'Query help', onPress: () {}),
                    ),
                  ],
                ),
              const KumoInputGroup(
                error: 'This subdomain is taken',
                label: 'Subdomain',
                children: [
                  KumoInputGroupInput(value: 'kumo'),
                  KumoInputGroupSuffix('.workers.dev'),
                ],
              ),
              KumoInputGroup(
                children: [
                  const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
                  const KumoInputGroupInput(semanticLabel: 'Search'),
                  KumoInputGroupButton(label: 'Search', variant: KumoButtonVariant.secondary, onPress: () {}),
                ],
              ),
            ],
          ),
        ),
        brightness: b,
        center: false,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('group height matches the field size with a mouse', (tester) async {
    for (final s in KumoFieldSize.values) {
      await pumpKumo(
        tester,
        SizedBox(
          width: 300,
          child: KumoInputGroup(
            size: s,
            children: [
              const KumoInputGroupInput(semanticLabel: 'Path'),
              KumoInputGroupAddon(
                align: KumoInputGroupAlign.end,
                child: KumoInputGroupButton(icon: KumoIcons.x, semanticLabel: 'Clear', onPress: () {}),
              ),
            ],
          ),
        ),
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
      );
      expect(tester.getSize(find.byType(KumoFieldBox)).height, s.height);
    }
  });

  testWidgets('a button in an addon keeps the group at its Kumo height on touch', (tester) async {
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInputGroup(
          children: [
            const KumoInputGroupInput(semanticLabel: 'Password'),
            KumoInputGroupAddon(
              align: KumoInputGroupAlign.end,
              child: KumoInputGroupButton(icon: KumoIcons.eye, semanticLabel: 'Show password', onPress: () {}),
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(KumoFieldBox)).height, 36);
    expect(tester.getSize(find.byType(KumoPressable)), const Size(44, 36));
  });

  testWidgets('start addons come first and end addons last, whatever the order', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 320,
        child: KumoInputGroup(
          children: [
            KumoInputGroupAddon(align: KumoInputGroupAlign.end, text: '.json'),
            KumoInputGroupInput(placeholder: 'endpoint', semanticLabel: 'API path'),
            KumoInputGroupAddon(text: '/api/'),
          ],
        ),
      ),
    );
    final start = tester.getCenter(find.text('/api/')).dx;
    final input = tester.getCenter(find.byType(EditableText)).dx;
    final end = tester.getCenter(find.text('.json')).dx;
    expect(start, lessThan(input));
    expect(input, lessThan(end));
  });

  testWidgets('one focus ring around the whole group, including while a button inside has focus', (tester) async {
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInputGroup(
          children: [
            const KumoInputGroupInput(semanticLabel: 'Search'),
            KumoInputGroupAddon(
              align: KumoInputGroupAlign.end,
              child: KumoInputGroupButton(icon: KumoIcons.x, semanticLabel: 'Clear', onPress: () {}),
            ),
          ],
        ),
      ),
    );
    KumoFieldBox box() => tester.widget<KumoFieldBox>(find.byType(KumoFieldBox));
    expect(box().focused, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(box().focused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(box().focused, isTrue);
    expect(find.byType(KumoFieldBox), findsOneWidget);
  });

  testWidgets('tapping an addon or the suffix focuses the input; a button keeps its own tap', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var cleared = 0;
    await pumpKumo(
      tester,
      SizedBox(
        width: 320,
        child: KumoInputGroup(
          children: [
            const KumoInputGroupAddon(text: '@'),
            KumoInputGroupInput(semanticLabel: 'Username', focusNode: focus),
            const KumoInputGroupSuffix('.example.com'),
            KumoInputGroupAddon(
              align: KumoInputGroupAlign.end,
              child: KumoInputGroupButton(icon: KumoIcons.x, semanticLabel: 'Clear', onPress: () => cleared++),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('@'));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    focus.unfocus();
    await tester.pump();
    await tester.tap(find.text('.example.com'));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pump();
    expect(cleared, 1);
  });

  testWidgets('the suffix follows the typed value', (tester) async {
    await pumpKumo(tester, const _Subdomain());
    final before = tester.getTopLeft(find.text('.workers.dev')).dx;
    await tester.enterText(find.byType(EditableText), 'image-resizer');
    await tester.pump();
    final after = tester.getTopLeft(find.text('.workers.dev')).dx;
    expect(after, greaterThan(before));
    // The suffix sits right after the text, not at the far end.
    final editable = tester.getRect(find.byType(EditableText));
    expect(after - editable.right, lessThan(4));
  });

  testWidgets('a long value pushes the suffix out instead of overflowing', (tester) async {
    await pumpKumo(tester, const _Subdomain());
    await tester.enterText(find.byType(EditableText), 'a-very-long-subdomain-name-for-a-worker-route');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(EditableText)).right,
      lessThanOrEqualTo(tester.getRect(find.byType(KumoFieldBox)).right),
    );
  });

  testWidgets('disabled group disables the input and buttons', (tester) async {
    var taps = 0;
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInputGroup(
          disabled: true,
          label: 'Search',
          children: [
            const KumoInputGroupInput(),
            KumoInputGroupAddon(
              align: KumoInputGroupAlign.end,
              child: KumoInputGroupButton(icon: KumoIcons.x, semanticLabel: 'Clear', onPress: () => taps++),
            ),
          ],
        ),
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.byType(KumoPressable));
    expect(taps, 0);
  });

  testWidgets('error turns the ring red and names the input', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInputGroup(
          label: 'Email',
          error: 'Enter a valid email address',
          children: [
            KumoInputGroupInput(),
            KumoInputGroupAddon(align: KumoInputGroupAlign.end, text: '@example.com'),
          ],
        ),
      ),
    );
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).error, isTrue);
    final data = tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.label, 'Email');
    expect(data.hint, 'Enter a valid email address');
    handle.dispose();
  });

  testWidgets('tooltip names an icon-only button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoInputGroup(
          children: [
            const KumoInputGroupInput(semanticLabel: 'Query'),
            KumoInputGroupAddon(
              align: KumoInputGroupAlign.end,
              child: KumoInputGroupButton(icon: KumoIcons.question, tooltip: 'Query language help', onPress: () {}),
            ),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Query language help'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a solid direct button attaches to the end at full height and fires', (tester) async {
    var searches = 0;
    await pumpKumo(
      tester,
      SizedBox(
        width: 320,
        child: KumoInputGroup(
          children: [
            const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
            const KumoInputGroupInput(semanticLabel: 'Search'),
            KumoInputGroupButton(label: 'Search', variant: KumoButtonVariant.secondary, onPress: () => searches++),
          ],
        ),
      ),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    final zone = tester.getRect(find.byType(KumoFieldBox));
    final button = tester.getRect(find.widgetWithText(KumoPressable, 'Search'));
    expect(button.height, 36);
    expect(button.left, closeTo(zone.right - 1, 0.5));
    await tester.tap(find.text('Search'));
    expect(searches, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(searches, 2);
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await pumpKumo(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: KumoInputGroup(
          label: 'Route pattern',
          description: 'Requests that match go to this Worker.',
          children: [
            const KumoInputGroupAddon(text: 'https://'),
            const KumoInputGroupInput(placeholder: 'example.com/*'),
            KumoInputGroupButton(label: 'Add route', variant: KumoButtonVariant.primary, onPress: () {}),
          ],
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL mirrors addons', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoInputGroup(
          children: [
            KumoInputGroupAddon(text: '@'),
            KumoInputGroupInput(semanticLabel: 'User'),
          ],
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    expect(tester.getCenter(find.text('@')).dx, greaterThan(tester.getCenter(find.byType(EditableText)).dx));
  });
}
