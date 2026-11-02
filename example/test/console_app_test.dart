import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';
import 'package:kumo_flutter_example/main.dart';
import 'package:kumo_flutter_example/sample/console_app.dart';

Future<void> _pump(WidgetTester tester, Widget home, Size size) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: GalleryApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const phone = Size(390, 844);
  const desktop = Size(1280, 800);

  testWidgets('loading state, then the Worker list', (tester) async {
    await _pump(tester, const ConsoleApp(), desktop);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('image-resizer'), findsOneWidget);
    expect(find.text('Failing'), findsOneWidget);
    expectNoFallbackText(tester);
  });

  testWidgets('filtering to nothing shows an empty state that clears', (
    tester,
  ) async {
    await _pump(tester, const ConsoleApp(simulateLoading: false), desktop);
    await tester.enterText(find.byType(TextField).first, 'nothing-matches');
    await tester.pumpAndSettle();
    expect(find.text('No Workers match these filters'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('auth-proxy'), findsOneWidget);
  });

  testWidgets('opening a failing Worker, rolling back from Deployments', (
    tester,
  ) async {
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 3, 12)), () async {
      await _pump(tester, const ConsoleApp(simulateLoading: false), desktop);
      await tester.tap(find.text('geo-redirect'));
      await tester.pumpAndSettle();
      expect(find.text('The latest deployment is failing'), findsOneWidget);
      await tester.tap(find.text('Deployments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Roll back').first);
      await tester.pumpAndSettle();
      expect(find.text('Roll back to v7?'), findsOneWidget);
      await tester.tap(find.text('Roll back').last);
      await tester.pumpAndSettle();
      expect(find.text('Rolled back to v7'), findsOneWidget);
    });
  });

  testWidgets('adding a DNS record validates, then saves', (tester) async {
    await _pump(
      tester,
      const ConsoleApp(
        initialSection: ConsoleSection.dns,
        simulateLoading: false,
      ),
      desktop,
    );
    await tester.tap(find.text('Add record').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name, or @ for the root.'), findsOneWidget);
    final fields = find.descendant(
      of: find.byType(KumoDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'api');
    await tester.enterText(fields.at(1), 'not-an-ip');
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.textContaining('needs an IPv4 address'), findsOneWidget);
    await tester.enterText(fields.at(1), '192.0.2.44');
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.text('Record added'), findsOneWidget);
    expect(find.text('192.0.2.44'), findsOneWidget);
  });

  testWidgets('deleting a Worker needs its name typed', (tester) async {
    await _pump(tester, const ConsoleApp(simulateLoading: false), desktop);
    await tester.tap(find.text('og-image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Worker'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'og-image');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KumoButton, 'Delete Worker').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('og-image deleted'), findsOneWidget);
    expect(find.text('og-image'), findsNothing);
  });

  testWidgets(
    'phone layout: bottom navigation switches sections, no overflow at 2x',
    (tester) async {
      tester.view.physicalSize = phone * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: phone, textScaler: TextScaler.linear(2)),
          child: GalleryApp(home: ConsoleApp(simulateLoading: false)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('DNS'));
      await tester.pumpAndSettle();
      expect(find.text('Add record'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}

/// Text that fell back to Flutter's debug style (red, yellow double
/// underline) has no Kumo or Material text style above it.
void expectNoFallbackText(WidgetTester tester) {
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    final style = p.text.style;
    expect(
      style?.decorationColor == const Color(0xFFFFFF00) &&
          style?.decorationStyle == TextDecorationStyle.double,
      isFalse,
      reason: 'Fallback text style on "${p.text.toPlainText()}"',
    );
  }
}
