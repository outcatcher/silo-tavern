// Widget tests for ServerListPage login functionality
@Tags(['widget', 'ui', 'servers', 'login'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/services/servers/storage.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/login_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import 'server_list_connection_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerStorage>(), MockSpec<ConnectionDomain>()])
void main() {
  group('ServerListPage Login Navigation Tests', () {
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
            authentication: const AuthenticationInfo.none(),
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

      // Set up router
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            name: 'servers',
            builder: (context, state) => ServerListPage(serverDomain: domain),
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
              return LoginPage(server: server);
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

    testWidgets('Navigates to login page when tapping server', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Act
      final serverCard = find.text('Test Server').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Login to Test Server'), findsOneWidget);
      expect(find.text('Server: https://test.example.com'), findsOneWidget);
    });
  });
}
