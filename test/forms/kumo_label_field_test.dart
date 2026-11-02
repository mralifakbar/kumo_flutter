import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  group('KumoLabel', () {
    testWidgets('renders in light and dark, medium weight 14px', (tester) async {
      for (final b in Brightness.values) {
        await pumpKumo(tester, const KumoLabel('Zone name'), brightness: b);
        expect(tester.takeException(), isNull);
        final text = tester.widget<Text>(find.text('Zone name'));
        expect(text.style!.fontWeight, FontWeight.w500);
        expect(text.style!.fontSize, 14);
      }
    });

    testWidgets('showOptional adds "(optional)" in subtle text, localizable', (tester) async {
      await pumpKumo(tester, const KumoLabel('Phone number', showOptional: true));
      expect(find.text('(optional)'), findsOneWidget);
      await pumpKumo(
        tester,
        const KumoLocale(
          strings: KumoStrings(optional: '(opcional)'),
          child: KumoLabel('Telefone', showOptional: true),
        ),
      );
      expect(find.text('(opcional)'), findsOneWidget);
      await pumpKumo(tester, const KumoLabel('Phone', showOptional: true, optionalLabel: '(if any)'));
      expect(find.text('(if any)'), findsOneWidget);
    });

    testWidgets('tooltip adds an info icon that shows the tooltip on hover', (tester) async {
      await pumpKumo(
        tester,
        const KumoLabel('API token', tooltip: 'Find it under My Profile, API Tokens'),
        size: kumoDesktopSize,
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
      );
      expect(find.byIcon(KumoIcons.info), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byIcon(KumoIcons.info)));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Find it under My Profile, API Tokens'), findsOneWidget);
    });

    testWidgets('semantics: required is announced; the info icon is labelled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(tester, const KumoLabel('Email', required: true));
      expect(find.bySemanticsLabel('Email, Required'), findsOneWidget);
      await pumpKumo(tester, const KumoLabel('Email', tooltip: 'Receipts go here'));
      expect(find.bySemanticsLabel('More information'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('wraps at text scale 2.0 in a narrow column', (tester) async {
      await pumpKumo(
        tester,
        const SizedBox(
          width: 160,
          child: KumoLabel('Account-level API token for deployments', showOptional: true, tooltip: 'Scoped token'),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('KumoField', () {
    testWidgets('label above, control, description below; renders in dark', (tester) async {
      for (final b in Brightness.values) {
        await pumpKumo(
          tester,
          const SizedBox(
            width: 300,
            child: KumoField(
              label: 'Worker name',
              description: 'Lowercase letters, numbers and dashes.',
              child: KumoInput(semanticLabel: 'Worker name'),
            ),
          ),
          brightness: b,
        );
        expect(tester.takeException(), isNull);
      }
      final label = tester.getRect(find.text('Worker name'));
      final control = tester.getRect(find.byType(KumoFieldBox));
      final description = tester.getRect(find.text('Lowercase letters, numbers and dashes.'));
      expect(label.bottom, lessThanOrEqualTo(control.top));
      expect(control.bottom, lessThanOrEqualTo(description.top));
      // gap-2 between rows.
      expect(control.top - label.bottom, closeTo(8, 0.5));
    });

    testWidgets('error replaces the description, with an icon, and is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        const SizedBox(
          width: 300,
          child: KumoField(
            label: 'Hostname',
            description: 'A fully qualified domain name.',
            error: 'Enter a valid hostname',
            child: KumoInput(semanticLabel: 'Hostname'),
          ),
        ),
      );
      expect(find.text('A fully qualified domain name.'), findsNothing);
      expect(find.text('Enter a valid hostname'), findsOneWidget);
      expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);
      final node = tester.getSemantics(find.text('Enter a valid hostname'));
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('showOptional, labelTooltip and a custom labelWidget', (tester) async {
      await pumpKumo(
        tester,
        const SizedBox(
          width: 300,
          child: KumoField(
            label: 'Company',
            showOptional: true,
            labelTooltip: 'Shown on invoices',
            child: KumoInput(semanticLabel: 'Company'),
          ),
        ),
      );
      expect(find.text('(optional)'), findsOneWidget);
      expect(find.byIcon(KumoIcons.info), findsOneWidget);

      await pumpKumo(
        tester,
        const SizedBox(
          width: 300,
          child: KumoField(
            labelWidget: Text('Billing email'),
            child: KumoInput(semanticLabel: 'Billing email'),
          ),
        ),
      );
      expect(find.text('Billing email'), findsOneWidget);
    });

    testWidgets('hideLabel keeps the label for screen readers only', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        const SizedBox(
          width: 300,
          child: KumoField(
            label: 'Search',
            hideLabel: true,
            child: KumoInput(semanticLabel: 'Search zones'),
          ),
        ),
      );
      expect(find.text('Search'), findsNothing);
      expect(find.bySemanticsLabel('Search'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
      await pumpKumo(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: KumoField(
            label: 'Custom hostname for the SaaS zone',
            labelTooltip: 'Fallback origin must be proxied',
            error: 'The hostname is already in use by another zone in this account.',
            child: KumoInput(semanticLabel: 'Custom hostname'),
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL aligns the label to the right', (tester) async {
      await pumpKumo(
        tester,
        const SizedBox(
          width: 300,
          child: KumoField(
            label: 'Zone',
            child: KumoInput(semanticLabel: 'Zone'),
          ),
        ),
        textDirection: TextDirection.rtl,
      );
      final field = tester.getRect(find.byType(KumoField));
      expect(tester.getRect(find.text('Zone')).right, closeTo(field.right, 1));
    });
  });
}
