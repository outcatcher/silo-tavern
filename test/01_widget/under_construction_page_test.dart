// Widget tests for UnderConstructionPage
@Tags(['widget', 'ui', 'connection'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

void main() {
  group('UnderConstructionPage Tests', () {
    testWidgets('Displays server name as title', (WidgetTester tester) async {
      // Arrange
      const serverName = 'Test Server';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnderConstructionPage(title: serverName),
          ),
        ),
      );

      // Assert
      expect(find.text(serverName), findsOneWidget);
    });

    testWidgets('Displays under construction message', (WidgetTester tester) async {
      // Arrange
      const serverName = 'Test Server';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnderConstructionPage(title: serverName),
          ),
        ),
      );

      // Assert
      expect(find.text('Under Construction'), findsOneWidget);
      expect(find.text('This feature is currently being developed'), findsOneWidget);
    });

    testWidgets('Displays construction icon', (WidgetTester tester) async {
      // Arrange
      const serverName = 'Test Server';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnderConstructionPage(title: serverName),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('Has back button in app bar', (WidgetTester tester) async {
      // Arrange
      const serverName = 'Test Server';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnderConstructionPage(title: serverName),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Back button navigates back to server list page without error', (WidgetTester tester) async {
      // This test verifies that the back button no longer causes the navigation error
      // "You have popped the last page off of the stack, there are no pages left to show"
      
      // Arrange
      const serverName = 'Test Server';
      
      // Set up router with under construction page as initial location
      final router = GoRouter(
        initialLocation: '/servers/connect/1?backUrl=/servers',
        routes: [
          GoRoute(
            path: '/servers',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: Text('SiloTavern - Servers')),
              body: Center(child: Text('Server List Page Content')),
            ),
          ),
          GoRoute(
            path: '/servers/connect/:id',
            builder: (context, state) {
              final backUrl = state.uri.queryParameters['backUrl'] ?? '/servers';
              return UnderConstructionPage(title: serverName, backUrl: backUrl);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on the under construction page
      expect(find.text(serverName), findsOneWidget);

      // Act: Tap the back button - this should navigate to /servers, not pop
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Assert: We should be on the server list page, no errors thrown
      expect(find.text('SiloTavern - Servers'), findsOneWidget);
      expect(find.text('Server List Page Content'), findsOneWidget);
      expect(find.text(serverName), findsNothing);
    });
  });
}