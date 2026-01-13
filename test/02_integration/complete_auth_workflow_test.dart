@Tags(['integration', 'e2e', 'auth', 'workflow'])
library;

// Comprehensive integration test for the complete authentication workflow
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/servers/repository.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/common/result.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';
import 'package:silo_tavern/ui/login_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import 'complete_auth_workflow_test.mocks.dart';

// Provide dummy value for Result<void> to satisfy Mockito
void _provideDummyValues() {
  provideDummy<Result<void>>(Result.success(null));
  provideDummy<Result<bool>>(Result.success(true));
  provideDummy<Result<List<Server>>>(Result.success(<Server>[]));
  provideDummy<Result<Server?>>(Result.success(null));
}

@GenerateNiceMocks([MockSpec<ServerRepository>(), MockSpec<ConnectionDomain>()])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Authentication Workflow Integration Tests', () {
    late MockServerRepository repository;
    late MockConnectionDomain connectionDomain;
    late ServerDomain domain;
    late GoRouter router;

    setUp(() async {
      repository = MockServerRepository();
      connectionDomain = MockConnectionDomain();

      // Provide dummy values for Mockito
      _provideDummyValues();

      // Define initial servers
      final servers = [
        Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        ),
      ];

      // Mock repository methods
      when(
        repository.getAll(),
      ).thenAnswer((_) async => Result.success(servers));
      when(
        repository.getById(any),
      ).thenAnswer((_) async => Result.success(null));
      when(
        repository.create(any),
      ).thenAnswer((_) async => Result.success(null));
      when(
        repository.update(any),
      ).thenAnswer((_) async => Result.success(null));
      when(
        repository.delete(any),
      ).thenAnswer((_) async => Result.success(null));

      domain = ServerDomain(
        ServerOptions(repository, connectionDomain: connectionDomain),
      );
      when(
        repository.getAll(),
      ).thenAnswer((_) async => Result.success(servers));
      when(
        repository.getById(any),
      ).thenAnswer((_) async => Result.success(null));
      when(
        repository.create(any),
      ).thenAnswer((_) async => Result.success(null));
      when(
        repository.update(any),
      ).thenAnswer((_) async => Result.success(null));
      when(
        repository.delete(any),
      ).thenAnswer((_) async => Result.success(null));

      domain = ServerDomain(
        ServerOptions(repository, connectionDomain: connectionDomain),
      );

      // Initialize the domain
      await domain.initialize();

      // Mock the authenticateWithServer method to return success
      when(
        connectionDomain.authenticateWithServer(any, any),
      ).thenAnswer((_) async => Result.success(null));

      // Mock the obtainCsrfTokenForServer method to return success
      when(
        connectionDomain.obtainCsrfTokenForServer(any),
      ).thenAnswer((_) async => Result.success(null));

      // Mock the checkServerAvailability method to return success
      when(
        connectionDomain.checkServerAvailability(any),
      ).thenAnswer((_) async => Result.success(true));

      // Mock the hasPersistentSession method to return false
      when(
        connectionDomain.hasPersistentSession(any),
      ).thenAnswer((_) async => false);

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

    testWidgets('Complete workflow: Create server, login, connect', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // 1. Verify we're on the server list page (empty state)
      expect(find.byKey(const ValueKey('serverListTitle')), findsOneWidget);
      expect(find.text('No servers configured'), findsOneWidget);

      // 2. Add a new server - find the add button in the app bar
      final addButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 3. Verify we're on the server creation page
      expect(find.text('Add New Server'), findsOneWidget);

      // 4. Fill in server details
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'New Test Server',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'https://new.test.example.com',
      );

      // 5. Save the server - find the save button in the app bar
      final saveButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.check),
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // 6. Verify we're back on the server list with the new server
      expect(find.byKey(const ValueKey('serverListTitle')), findsOneWidget);
      expect(find.text('New Test Server').first, findsOneWidget);

      // 7. Tap on the new server to trigger login
      final serverCard = find.text('New Test Server').first;
      await tester.tap(serverCard, warnIfMissed: false);
      await tester.pumpAndSettle();

      // 8. Verify we're on the login page
      expect(find.byKey(const ValueKey('loginPageTitle')), findsOneWidget);
      expect(find.text('Server: https://new.test.example.com'), findsOneWidget);

      // 9. Fill in login credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpass');

      // 10. Submit login form
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // 11. Verify we're on the connection page (under construction)
      expect(find.text('Under Construction'), findsOneWidget);
      expect(find.text('New Test Server'), findsOneWidget);

      // 12. Navigate back to server list
      final backButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.arrow_back),
      );
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // 13. Verify we're back on the server list
      expect(find.byKey(const ValueKey('serverListTitle')), findsOneWidget);
      expect(find.text('New Test Server').first, findsOneWidget);
    });

    testWidgets('Login validation prevents submission with empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Add a new server
      final addButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.add),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Fill in server details
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Validation Test Server',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'https://validation.test.example.com',
      );

      // Save the server
      final saveButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.check),
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Tap on the server to trigger login
      final serverCard = find.text('Validation Test Server').first;
      await tester.tap(serverCard, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify we're on the login page
      expect(find.text('Login to Validation Test Server'), findsOneWidget);

      // Try to submit without filling fields
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Fill in only username
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

      // No validation errors should remain and we should navigate
      expect(find.text('Please enter your username'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
      expect(find.text('Under Construction'), findsOneWidget);
    });
  });
}
