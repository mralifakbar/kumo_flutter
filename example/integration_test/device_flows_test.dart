import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';
import 'package:kumo_flutter_example/gallery/category_page.dart';
import 'package:kumo_flutter_example/main.dart';
import 'package:kumo_flutter_example/sample/console_app.dart';

/// Runs on a real device or simulator:
/// `flutter test integration_test -d <device>`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home opens a category and a demo', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    expect(find.text('Kumo for Flutter'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Selection'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selection'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryPage), findsOneWidget);
    expect(find.text('KumoSelect'), findsWidgets);
    await tester.tap(find.text('Theme: System').last);
    await tester.pumpAndSettle();
    expect(find.text('Theme: Light'), findsOneWidget);
  });

  testWidgets('console: status filter opens as a sheet on the phone and filters', (tester) async {
    await tester.pumpWidget(const GalleryApp(home: ConsoleApp(simulateLoading: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All statuses'));
    await tester.pumpAndSettle();
    expect(find.byType(KumoSheet), findsOneWidget);
    await tester.tap(find.text('Failing').last);
    await tester.pumpAndSettle();
    expect(find.text('geo-redirect'), findsOneWidget);
    expect(find.text('image-resizer'), findsNothing);
  });

  testWidgets('console: Worker detail, tabs, rollback dialog and toast', (tester) async {
    await tester.pumpWidget(const GalleryApp(home: ConsoleApp(simulateLoading: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('geo-redirect'));
    await tester.pumpAndSettle();
    expect(find.text('The latest deployment is failing'), findsOneWidget);
    await tester.tap(find.text('Deployments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roll back').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roll back').last);
    await tester.pumpAndSettle();
    expect(find.text('Rolled back to v7'), findsOneWidget);
  });

  testWidgets('console: drawer opens from the menu button and navigates', (tester) async {
    await tester.pumpWidget(const GalleryApp(home: ConsoleApp(simulateLoading: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DNS records').last);
    await tester.pumpAndSettle();
    expect(find.text('Add record'), findsWidgets);
  });

  testWidgets('console: add a DNS record through the dialog with the keyboard up', (tester) async {
    await tester.pumpWidget(const GalleryApp(home: ConsoleApp(initialSection: ConsoleSection.dns, simulateLoading: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add record').first);
    await tester.pumpAndSettle();
    final fields = find.descendant(of: find.byType(KumoDialog), matching: find.byType(TextField));
    await tester.enterText(fields.at(0), 'api');
    await tester.enterText(fields.at(1), '192.0.2.44');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.text('Record added'), findsOneWidget);
  });
}
