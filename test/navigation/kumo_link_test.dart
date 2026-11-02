import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  for (final b in Brightness.values) {
    testWidgets('every variant renders in $b', (tester) async {
      await pumpKumo(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in KumoLinkVariant.values) KumoLink(label: 'View logs ${v.name}', variant: v, onPress: () {}),
            KumoLink(label: 'Workers docs', external: true, onPress: () {}),
          ],
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('inline is link blue and underlined; current inherits the color', (tester) async {
    await pumpKumo(
      tester,
      DefaultTextStyle(
        style: const TextStyle(color: Color(0xFFCC0000), fontSize: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KumoLink(label: 'inline', onPress: () {}),
            KumoLink(label: 'current', variant: KumoLinkVariant.current, onPress: () {}),
            KumoLink(label: 'plain', variant: KumoLinkVariant.plain, onPress: () {}),
          ],
        ),
      ),
    );
    final inline = tester.widget<Text>(find.text('inline')).style!;
    expect(inline.color, KumoColorSchemes.light.textLink);
    expect(inline.decoration, TextDecoration.underline);
    final current = tester.widget<Text>(find.text('current')).style!;
    expect(current.color, const Color(0xFFCC0000));
    expect(current.decoration, TextDecoration.underline);
    expect(tester.widget<Text>(find.text('plain')).style!.decoration, TextDecoration.none);
  });

  testWidgets('tap calls onPress; disabled does not', (tester) async {
    var taps = 0;
    await pumpKumo(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KumoLink(label: 'Open route', onPress: () => taps++),
          KumoLink(label: 'Disabled route', disabled: true, onPress: () => taps++),
        ],
      ),
    );
    await tester.tap(find.text('Open route'));
    await tester.tap(find.text('Disabled route'));
    expect(taps, 1);
  });

  testWidgets('semantics: link role, external hint', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, KumoLink(label: 'Workers docs', external: true, onPress: () {}));
    expect(
      tester.getSemantics(find.text('Workers docs')),
      containsSemantics(label: 'Workers docs', isLink: true, hint: 'Opens in a new window', hasTapAction: true),
    );
    expect(find.byIcon(KumoIcons.arrowSquareOut), findsOneWidget);
    handle.dispose();
  });

  testWidgets('keyboard: Enter activates', (tester) async {
    var taps = 0;
    await pumpKumo(
      tester,
      KumoLink(label: 'Open route', onPress: () => taps++),
      size: kumoDesktopSize,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('touch target is 44px unless turned off for inline use', (tester) async {
    await pumpKumo(tester, KumoLink(label: 'a', onPress: () {}));
    expect(tester.getSize(find.byType(KumoPressable)).height, greaterThanOrEqualTo(44));
    await pumpKumo(tester, KumoLink(label: 'a', padTapTarget: false, onPress: () {}));
    expect(tester.getSize(find.byType(KumoPressable)).height, lessThan(44));
  });

  testWidgets('sits in running text through a WidgetSpan at text scale 2', (tester) async {
    await pumpKumo(
      tester,
      SizedBox(
        width: 358,
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Read the '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: KumoLink(label: 'routing guide', padTapTarget: false, onPress: () {}),
              ),
              const TextSpan(text: ' before adding a custom domain to example.com.'),
            ],
          ),
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
