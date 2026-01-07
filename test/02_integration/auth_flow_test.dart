@Tags(['integration', 'e2e', 'auth', 'login'])
library;

// Integration tests for the authentication flow
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/connection/models.dart';
import 'package:silo_tavern/services/servers/storage.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';
import 'package:silo_tavern/ui/login_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import 'auth_flow_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerStorage>(), MockSpec<ConnectionDomain>()])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late MockServerStorage storage;
    late MockConnectionDomain connectionDomain;
    late ServerDomain domain;
    late GoRouter router;

    setUp(() async {
      storage = MockServerStorage();
      connectionDomain = MockConnectionDomain();

      // Mock the storage methods to return some initial servers
      when(storage.listServers()).thenAnswer(
        (_) async => [
          Server(
            id: '1',
            name: 'Test Server',
            address: 'https://test.example.com',
          ),
        ],
      );

      when(storage.createServer(any)).thenAnswer((_) async {});
      when(storage.updateServer(any)).thenAnswer((_) async {});
      when(storage.deleteServer(any)).thenAnswer((_) async {});

      domain = ServerDomain(
        ServerOptions(storage, connectionDomain: connectionDomain),
      );

      // Initialize the domain
      await domain.initialize();

      // Mock the authenticateWithServer method to return success
      when(
        connectionDomain.authenticateWithServer(any, any),
      ).thenAnswer((_) async => ConnectionResult.success());

      // Mock the obtainCsrfTokenForServer method to return success
      when(
        connectionDomain.obtainCsrfTokenForServer(any),
      ).thenAnswer((_) async => ConnectionResult.success());

      // Set up router
      router = GoRouter(
        routes: [
          GoRoute(path: '/', redirect: (_, _) => '/servers'),
          GoRoute(
            path: '/servers',
            name: 'servers',
            builder: (context, state) => ServerListPage(
              serverDomain: domain,
              connectionDomain: connectionDomain,
            ),
          ),
          GoRoute(
            path: '/servers/create',
            name: 'serverCreate',
            builder: (context, state) =>
                ServerCreationPage(serverDomain: domain),
          ),
          GoRoute(
            path: '/servers/edit/:id',
            name: 'serverEdit',
            builder: (context, state) {
              final serverId = state.pathParameters['id']!;
              final server = domain.findServerById(serverId);
              if (server == null) {
                return const Scaffold(
                  body: Center(child: Text('Server not found')),
                );
              }
              return ServerCreationPage(
                serverDomain: domain,
                initialServer: server,
              );
            },
          ),
          GoRoute(
            path: '/servers/login/:id',
            name: 'serverLogin',
            builder: (context, state) {
              final serverId = state.pathParameters['id']!;
              final server = domain.findServerById(serverId);
              if (server == null) {
                return const Scaffold(
                  body: Center(child: Text('Server not found')),
                );
              }
              return LoginPage(
                server: server,
                connectionDomain: connectionDomain,
              );
            },
          ),
          GoRoute(
            path: '/servers/connect/:id',
            name: 'serverConnect',
            builder: (context, state) {
              final serverId = state.pathParameters['id']!;
              final server = domain.findServerById(serverId);
              if (server == null) {
                return const Scaffold(
                  body: Center(child: Text('Server not found')),
                );
              }
              return UnderConstructionPage(title: server.name);
            },
          ),
        ],
      );
    });

    testWidgets('Full authentication flow: Create server, login, connect', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // 1. Verify we're on the server list page
      expect(find.byKey(const ValueKey('serverListTitle')), findsOneWidget);
      expect(find.text('Test Server').first, findsOneWidget);

      // 2. Tap on the server to trigger login
      final serverCard = find.text('Test Server').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // 3. Verify we're on the login page
      expect(find.byKey(const ValueKey('loginPageTitle')), findsOneWidget);
      expect(find.text('Server: https://test.example.com'), findsOneWidget);

      // 4. Fill in login credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'testpass');

      // 5. Submit login form
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // 6. Verify we're on the connection page (under construction)
      expect(find.text('Under Construction'), findsOneWidget);
      expect(find.text('Test Server'), findsOneWidget);

      // 7. Navigate back to server list
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // 8. Verify we're back on the server list
      expect(find.byKey(const ValueKey('serverListTitle')), findsOneWidget);
    });

    testWidgets('Password visibility toggle works in login flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Tap on the server to trigger login
      final serverCard = find.text('Test Server').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // Verify we're on the login page
      expect(find.byKey(const ValueKey('loginPageTitle')), findsOneWidget);

      // Check that visibility icons are present
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tap visibility icon to show password
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Check that the icon changed
      expect(find.byIcon(Icons.visibility), findsNothing);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Validation works in login flow', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Tap on the server to trigger login
      final serverCard = find.text('Test Server').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // Verify we're on the login page
      expect(find.byKey(const ValueKey('loginPageTitle')), findsOneWidget);

      // Try to submit without filling fields
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Fill in username only
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Only password error should remain
      expect(find.text('Please enter your username'), findsNothing);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Fill in password as well
      await tester.enterText(find.byType(TextFormField).at(1), 'testpass');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // No validation errors should remain
      expect(find.text('Please enter your username'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
    });

    testWidgets('Back navigation works in login flow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Verify we're on the server list page
      expect(find.byKey(const ValueKey('serverListTitle')), findsOneWidget);

      // Tap on the server to trigger login
      final serverCard = find.text('Test Server').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // Verify we're on the login page
      expect(find.byKey(const ValueKey('loginPageTitle')), findsOneWidget);

      // Navigate back to server list
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we're back on the server list
      expect(find.byKey(const ValueKey('serverListTitle')), findsOneWidget);
    });
  });
}
