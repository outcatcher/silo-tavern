@Tags(['integration', 'e2e', 'servers'])
library;

// True end-to-end test that runs the entire app on a platform
// This test interacts with the real app as a user would
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:silo_tavern/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('Smoke test: App loads and basic navigation works', (
      WidgetTester tester,
    ) async {
      // Start the app with isolated E2E storage
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the server list page
      expect(find.text('SiloTavern - Servers'), findsOneWidget);

      // Tap the add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify we're on the creation page
      expect(find.text('Add New Server'), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back on the server list page
      expect(find.text('SiloTavern - Servers'), findsOneWidget);
    });

    testWidgets('Add server workflow', (WidgetTester tester) async {
      // Start the app with isolated E2E storage
      app.main();
      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in basic server details
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Unique Test Server',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'http://localhost:8080',
      );

      // Save the server
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Verify we're back on the server list
      expect(find.text('SiloTavern - Servers'), findsOneWidget);
      expect(find.text('Unique Test Server').first, findsOneWidget);
    });

    testWidgets('Full workflow: Create, Edit, Delete server', (
      WidgetTester tester,
    ) async {
      // Start the app with isolated E2E storage
      app.main();
      await tester.pumpAndSettle();

      // 1. Add a server
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Workflow Test Server',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'https://workflow.example.com',
      );

      // Select credentials authentication
      await tester.tap(find.text('Credentials'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(2), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(3), 'testpass');

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Verify server was added
      expect(find.text('SiloTavern - Servers'), findsOneWidget);
      expect(find.text('Workflow Test Server').first, findsOneWidget);

      // 2. Edit the server using swipe
      final serverCard = find.ancestor(
        of: find.text('Workflow Test Server').first,
        matching: find.byType(Dismissible),
      );

      // Swipe left to right to edit
      await tester.drag(serverCard, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Verify we're on the edit page
      expect(find.text('Edit Server'), findsOneWidget);
      expect(find.text('Workflow Test Server').first, findsOneWidget);

      // Modify the server name
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Updated Workflow Server',
      );

      // Save changes
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Verify the update
      expect(find.text('SiloTavern - Servers'), findsOneWidget);
      expect(find.text('Updated Workflow Server').first, findsOneWidget);
      expect(find.text('Workflow Test Server'), findsNothing);

      // 3. Delete the server using context menu
      await tester.longPress(find.text('Updated Workflow Server').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();

      // Verify server was deleted
      expect(find.text('Updated Workflow Server'), findsNothing);
    });
  });
}
