import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';
import 'package:kumo_flutter_example/gallery/categories.dart';
import 'package:kumo_flutter_example/gallery/category_page.dart';
import 'package:kumo_flutter_example/main.dart';

/// Renders every demo in light and dark, at phone and desktop widths and at
/// 2x text, and fails on any exception (overflow, missing ancestor, assert).
void main() {
  final configs = <(String, Size, Brightness, double)>[
    ('phone light', const Size(390, 844), Brightness.light, 1),
    ('phone dark', const Size(390, 844), Brightness.dark, 1),
    ('phone 2x text', const Size(390, 844), Brightness.light, 2),
    ('desktop dark', const Size(1280, 800), Brightness.dark, 1),
  ];

  for (final category in galleryCategories) {
    for (final demo in category.demos) {
      for (final (name, size, brightness, scale) in configs) {
        testWidgets('${category.title} / ${demo.title} / $name', (tester) async {
          tester.view.physicalSize = size * tester.view.devicePixelRatio;
          addTearDown(tester.view.resetPhysicalSize);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), platformBrightness: brightness),
              child: GalleryApp(home: DemoPage(demo: demo)),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(find.text(demo.title), findsWidgets);
          expectNoFallbackText(tester);
          // Demos simulate network work with timers; let them finish.
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 30));
        });
      }
    }
  }

  testWidgets('home lists every category and opens one', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    for (final c in galleryCategories.take(1)) {
      expect(find.text(c.title), findsOneWidget);
    }
    await tester.ensureVisible(find.text(galleryCategories.first.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(galleryCategories.first.title));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryPage), findsOneWidget);
  });

  testWidgets('theme button cycles system, light, dark', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme: System'));
    await tester.pumpAndSettle();
    expect(find.text('Theme: Light'), findsOneWidget);
    await tester.tap(find.text('Theme: Light'));
    await tester.pumpAndSettle();
    expect(find.text('Theme: Dark'), findsOneWidget);
    expect(KumoTheme.of(tester.element(find.text('Theme: Dark'))).isDark, isTrue);
  });
}

/// Text that fell back to Flutter's debug style (red, yellow double
/// underline) has no Kumo or Material text style above it.
void expectNoFallbackText(WidgetTester tester) {
  for (final p in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
    final style = p.text.style;
    expect(style?.decorationColor == const Color(0xFFFFFF00) && style?.decorationStyle == TextDecorationStyle.double, isFalse,
        reason: 'Fallback text style on "${p.text.toPlainText()}"');
  }
}
