import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/login_page.dart';

import 'mocks.mocks.dart';

void main() {
  group('Login Page Tests:', () {
    late MockConnectionDomain connectionDomain;
    late MockGoRouter router;

    setUp(() {
      // Provide dummy value for Result<void> to avoid Mockito errors
      provideDummy<Result<void>>(Result.success(null));
    });

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
      ).thenAnswer((_) async => Result.success(null));

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

    testWidgets('Back button navigates with default back URL', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      final router = MockGoRouter();

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

    testWidgets('Form validation prevents submission with empty fields', (
      tester,
    ) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      final router = MockGoRouter();
      final connectionDomain = MockConnectionDomain();

      when(
        connectionDomain.hasPersistentSession(server),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            server: server,
            router: router,
            connectionDomain: connectionDomain,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Try to submit empty form
      final loginButton = find.byKey(const ValueKey('loginButton')).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Successful login navigates to connect page', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      final router = MockGoRouter();
      final connectionDomain = MockConnectionDomain();

      when(connectionDomain.hasExistingSession(server)).thenReturn(false);
      when(
        connectionDomain.authenticateWithServer(any, any),
      ).thenAnswer((_) async => Result.success(null));
      when(router.go(any)).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            server: server,
            router: router,
            connectionDomain: connectionDomain,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

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

      // Should authenticate and navigate
      verify(connectionDomain.authenticateWithServer(any, any)).called(1);
      verify(router.go(any)).called(1);
    });

    testWidgets('Login shows error dialog on authentication failure', (
      tester,
    ) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      final router = MockGoRouter();
      final connectionDomain = MockConnectionDomain();

      when(
        connectionDomain.hasPersistentSession(server),
      ).thenAnswer((_) async => false);
      when(
        connectionDomain.authenticateWithServer(any, any),
      ).thenAnswer((_) async => Result.failure('Invalid credentials'));

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            server: server,
            router: router,
            connectionDomain: connectionDomain,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Fill in the form
      await tester.enterText(
        find.byKey(const ValueKey('usernameField')),
        'testuser',
      );
      await tester.enterText(
        find.byKey(const ValueKey('passwordField')),
        'wrongpass',
      );
      await tester.pump();

      // Tap login button
      final loginButton = find.byKey(const ValueKey('loginButton')).first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show error dialog
      expect(find.byKey(const ValueKey('errorDialog')), findsOneWidget);
      expect(find.text('Login Failed'), findsOneWidget);
      expect(
        find.text(
          'Invalid username or password. Please check your credentials and try again.',
        ),
        findsOneWidget,
      );

      // Close dialog
      await tester.tap(find.byKey(const ValueKey('errorDialogOkButton')).first);
      await tester.pumpAndSettle();

      // Button should be enabled again
      expect(find.byKey(const ValueKey('loginButton')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Enter key submits form in password field', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      final router = MockGoRouter();
      final connectionDomain = MockConnectionDomain();

      when(
        connectionDomain.hasPersistentSession(server),
      ).thenAnswer((_) async => false);
      when(
        connectionDomain.authenticateWithServer(any, any),
      ).thenAnswer((_) async => Result.success(null));
      when(router.go(any)).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            server: server,
            router: router,
            connectionDomain: connectionDomain,
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

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

      // Submit with Enter key in password field
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should authenticate and navigate
      verify(connectionDomain.authenticateWithServer(any, any)).called(1);
      verify(router.go(any)).called(1);
    });

    testWidgets('Tab key moves focus from username to password', (
      tester,
    ) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      when(
        connectionDomain.hasPersistentSession(server),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: server, connectionDomain: connectionDomain),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Fill in username
      await tester.enterText(
        find.byKey(const ValueKey('usernameField')),
        'testuser',
      );

      // Submit with Enter key in username field (should move focus to password)
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Focus should be on password field
      expect(
        FocusScope.of(
          tester.element(find.byKey(const ValueKey('passwordField'))),
        ).hasFocus,
        isTrue,
      );
    });
  });
}
