import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/login_page.dart';

import 'router_test.mocks.dart';

void main() {
  group('Login Page Tests:', () {
    testWidgets('Renders correctly with server info', (tester) async {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      await tester.pumpWidget(MaterialApp(home: LoginPage(server: server)));

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
      final router = MockGoRouter();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: server, router: router),
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

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: server, router: router),
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
  });
}
