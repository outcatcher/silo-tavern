// Widget tests for ServerListPage connection functionality
@Tags(['widget', 'ui', 'servers', 'connection'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/connection/models.dart' as connection_models;
import 'package:silo_tavern/services/servers/storage.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import 'server_list_connection_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ServerStorage>(),
  MockSpec<ConnectionDomain>(),
])
void main() {
  group('ServerListPage Connection Tests', () {
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
            name: 'Test Server 1',
            address: 'https://test1.example.com',
            authentication: AuthenticationInfo.credentials(
              username: 'user1',
              password: 'pass1',
            ),
          ),
          Server(
            id: '2',
            name: 'Local Server',
            address: 'http://localhost:8080',
            authentication: const AuthenticationInfo.none(),
          ),
        ],
      );
      when(storage.getServer(any)).thenAnswer(
        (_) async => Server(
          id: '1',
          name: 'Test Server 1',
          address: 'https://test1.example.com',
          authentication: AuthenticationInfo.credentials(
            username: 'user1',
            password: 'pass1',
          ),
        ),
      );

      when(storage.createServer(any)).thenAnswer((_) async {});
      when(storage.updateServer(any)).thenAnswer((_) async {});
      when(storage.deleteServer(any)).thenAnswer((_) async {});

      // Mock the connection domain methods
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async => connection_models.ConnectionResult.success(),
      );

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
              return UnderConstructionPage(title: server.name, backUrl: '/servers');
            },
          ),
        ],
      );
    });

    testWidgets('Navigates to under construction page on successful connection', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async => connection_models.ConnectionResult.success(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Act
      final serverCard = find.text('Test Server 1').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Under Construction'), findsOneWidget);
      expect(
        find.text('Test Server 1'),
        findsOneWidget,
      ); // Server name should be in the page
    });

    testWidgets('Shows error message on connection failure', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async =>
            connection_models.ConnectionResult.failure('Connection failed'),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Act
      final serverCard = find.text('Test Server 1').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Error connecting to server'), findsOneWidget);
      expect(
        find.text('Test Server 1'),
        findsOneWidget,
      ); // Still on server list page
    });

    testWidgets('Remains on server list page on connection failure', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async =>
            connection_models.ConnectionResult.failure('Connection failed'),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Act
      final serverCard = find.text('Test Server 1').first;
      await tester.tap(serverCard);
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('SiloTavern - Servers'),
        findsOneWidget,
      ); // Still on server list
    });
  });
}