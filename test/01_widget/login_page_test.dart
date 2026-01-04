import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/connection/models.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/login_page.dart';

import 'mocks.mocks.dart';

void main() {
  group('Login Page Tests:', () {
    late MockConnectionDomain connectionDomain;
    late MockGoRouter router;

    setUp(() {
      connectionDomain = MockConnectionDomain();
      router = MockGoRouter();
    });

    tearDown(() {
      resetMockitoState();
    });

    testWidgets('Renders correctly with server info', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: server, connectionDomain: connectionDomain),
        ),
      );

      expect(find.text('Login to Test Server'), findsOneWidget);
      expect(find.text('Server: https://test.example.com'), findsOneWidget);
      expect(find.byKey(const ValueKey('usernameField')), findsOneWidget);
      expect(find.byKey(const ValueKey('passwordField')), findsOneWidget);
      expect(find.byKey(const ValueKey('loginButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('backButton')), findsOneWidget);
    });

    testWidgets('Back button navigates with router', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            server: server,
            router: router,
            connectionDomain: connectionDomain,
          ),
        ),
      );

      final backButton = find.byKey(const ValueKey('backButton')).first;
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(router.go('/servers')).called(1);
    });

    testWidgets('Login button validates form and navigates', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      final router = MockGoRouter();
      final connectionDomain = MockConnectionDomain();

      // Mock the authenticateWithServer method to return success
      when(
        connectionDomain.authenticateWithServer(any, any),
      ).thenAnswer((_) async => ConnectionResult.success());

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            server: server,
            router: router,
            connectionDomain: connectionDomain,
          ),
        ),
      );

      // Fill in the form
      await tester.enterText(
        find.byKey(const ValueKey('usernameField')),
        'testuser',
      );
      await tester.enterText(
        find.byKey(const ValueKey('passwordField')),
        'testpass',
      );
      await tester.pump();

      // Tap login button
      final loginButton = find.byKey(const ValueKey('loginButton')).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify navigation
      verify(router.go(any)).called(1);
    });

    testWidgets('Password visibility toggle works correctly', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: server, connectionDomain: connectionDomain),
        ),
      );

      // Find the password field and visibility toggle
      final passwordField = find.byKey(const ValueKey('passwordField')).first;
      final visibilityToggle = find.byIcon(Icons.visibility).first;

      expect(passwordField, findsOneWidget);
      expect(visibilityToggle, findsOneWidget);

      // Tap the visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap the visibility toggle again
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pumpAndSettle();

      // Icon should change back to visibility
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
