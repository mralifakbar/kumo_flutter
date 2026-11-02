import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

BorderRadius radiusOf(WidgetTester tester, String text) {
  final container = tester.widget<Container>(
    find.ancestor(of: find.text(text), matching: find.byType(Container)).first,
  );
  return (container.decoration! as BoxDecoration).borderRadius! as BorderRadius;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders every variant and size in $brightness', (tester) async {
      await pumpKumo(
        tester,
        brightness: brightness,
        SingleChildScrollView(
          child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final variant in KumoButtonVariant.values)
              for (final size in KumoButtonSize.values)
                KumoButtonGroup(
                  variant: variant,
                  size: size,
                  children: [
                    KumoButtonGroupButton(label: 'Deploy', onPress: () {}),
                    KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More', onPress: () {}),
                  ],
                ),
          ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('presses fire; disabled and loading buttons do not', (tester) async {
    final calls = <String>[];
    await pumpKumo(
      tester,
      KumoButtonGroup(
        children: [
          KumoButtonGroupButton(label: 'Save', onPress: () => calls.add('save')),
          KumoButtonGroupButton(label: 'Publish', disabled: true, onPress: () => calls.add('publish')),
          KumoButtonGroupButton(label: 'Copy', loading: true, onPress: () => calls.add('copy')),
          const KumoButtonGroupButton(label: 'Archive'),
        ],
      ),
      // The loading spinner turns until loading ends.
      settle: false,
    );
    await tester.pump();
    for (final label in ['Save', 'Publish', 'Copy', 'Archive']) {
      await tester.tap(find.text(label));
    }
    expect(calls, ['save']);
  });

  testWidgets('only the outer corners are rounded, mirrored in RTL', (tester) async {
    Widget group() => KumoButtonGroup(
          children: [
            KumoButtonGroupButton(label: 'One', onPress: () {}),
            KumoButtonGroupButton(label: 'Two', onPress: () {}),
            KumoButtonGroupButton(label: 'Three', onPress: () {}),
          ],
        );
    await pumpKumo(tester, group());
    expect(radiusOf(tester, 'One'), const BorderRadius.horizontal(left: Radius.circular(KumoRadius.lg)));
    expect(radiusOf(tester, 'Two'), BorderRadius.zero);
    expect(radiusOf(tester, 'Three'), const BorderRadius.horizontal(right: Radius.circular(KumoRadius.lg)));
    // Neighbors touch: one shared seam, no gap.
    final one = tester.getRect(find.ancestor(of: find.text('One'), matching: find.byType(Container)).first);
    final two = tester.getRect(find.ancestor(of: find.text('Two'), matching: find.byType(Container)).first);
    expect(two.left, one.right);

    await pumpKumo(tester, textDirection: TextDirection.rtl, group());
    expect(radiusOf(tester, 'One'), const BorderRadius.horizontal(right: Radius.circular(KumoRadius.lg)));
  });

  testWidgets('semantics: a labeled group of buttons; icon-only buttons use their label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(
      tester,
      KumoButtonGroup(
        semanticLabel: 'Deploy',
        variant: KumoButtonVariant.primary,
        children: [
          KumoButtonGroupButton(label: 'Deploy now', onPress: () {}),
          KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More deploy options', onPress: () {}),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Deploy'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('More deploy options')),
      containsSemantics(isButton: true, hasTapAction: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('keyboard: each button is a Tab stop and activates with Enter', (tester) async {
    final calls = <String>[];
    await pumpKumo(
      tester,
      KumoButtonGroup(
        children: [
          KumoButtonGroupButton(label: 'Save', onPress: () => calls.add('save')),
          KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More', onPress: () => calls.add('more')),
        ],
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, ['more']);
  });

  testWidgets('touch: 44px hit areas without spreading the buttons apart', (tester) async {
    await pumpKumo(
      tester,
      KumoButtonGroup(
        children: [
          KumoButtonGroupButton(label: 'Save', onPress: () {}),
          KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More', onPress: () {}),
        ],
      ),
    );
    final buttons = find.byType(KumoPressable);
    expect(tester.getSize(buttons.first).height, 44);
    expect(tester.getSize(buttons.last), const Size(44, 44));
    expect(tester.getRect(buttons.last).left, tester.getRect(buttons.first).right);

    await pumpKumo(
      tester,
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
      KumoButtonGroup(
        children: [
          KumoButtonGroupButton(label: 'Save', onPress: () {}),
          KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More', onPress: () {}),
        ],
      ),
    );
    expect(tester.getSize(find.byType(KumoPressable).last), const Size(36, 36));
  });

  testWidgets('a wrapped button still finds its place in the group', (tester) async {
    await pumpKumo(
      tester,
      KumoButtonGroup(
        children: [
          KumoButtonGroupButton(label: 'Save', onPress: () {}),
          KumoTooltip(content: 'Save options', child: KumoButtonGroupButton(label: 'More', onPress: () {})),
        ],
      ),
    );
    expect(radiusOf(tester, 'More'), const BorderRadius.horizontal(right: Radius.circular(KumoRadius.lg)));
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await pumpKumo(
      tester,
      textScale: 2,
      KumoButtonGroup(
        children: [
          KumoButtonGroupButton(label: 'Deploy', icon: KumoIcons.rocketLaunch, onPress: () {}),
          KumoButtonGroupButton(icon: KumoIcons.caretDown, semanticLabel: 'More', onPress: () {}),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
