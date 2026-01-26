import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/router.dart';
import 'package:silo_tavern/ui/login_page.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import 'router_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerDomain>(), MockSpec<ConnectionDomain>()])
void main() {
  group('Router Tests:', () {
    late MockServerDomain mockServerDomain;
    late MockConnectionDomain mockConnectionDomain;

    setUp(() {
      mockServerDomain = MockServerDomain();
      mockConnectionDomain = MockConnectionDomain();
    });

    tearDown(() {
      resetMockitoState();
    });

    testWidgets('Root route redirects to servers', (tester) async {
      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/');

      await tester.pumpAndSettle();

      expect(find.byType(ServerListPage), findsOneWidget);
    });

    testWidgets('Servers route shows server list page', (tester) async {
      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers');

      await tester.pumpAndSettle();

      expect(find.byType(ServerListPage), findsOneWidget);
    });

    testWidgets('Server create route shows creation page', (tester) async {
      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/create');

      await tester.pumpAndSettle();

      expect(find.byType(ServerCreationPage), findsOneWidget);
    });

    testWidgets('Server connect route shows under construction page', (
      tester,
    ) async {
      // Mock the findServerById method to return a server
      final server = Server(
        id: 'test',
        name: 'Test Server',
        address: 'https://test.com',
      );
      when(mockServerDomain.findServerById('test')).thenReturn(server);

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/connect/test');

      await tester.pumpAndSettle();

      expect(find.byType(UnderConstructionPage), findsOneWidget);
      expect(find.text('Connect to Server'), findsOneWidget);
    });

    testWidgets('Server login route shows login page', (tester) async {
      // Mock the findServerById method to return a server
      final server = Server(
        id: 'test',
        name: 'Test Server',
        address: 'https://test.com',
      );
      when(mockServerDomain.findServerById('test')).thenReturn(server);

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/login/test');

      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Server edit route shows creation page with server data', (
      tester,
    ) async {
      // Mock the findServerById method to return a server
      final server = Server(
        id: 'test',
        name: 'Test Server',
        address: 'https://test.com',
      );
      when(mockServerDomain.findServerById('test')).thenReturn(server);

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/edit/test');

      await tester.pumpAndSettle();

      expect(find.byType(ServerCreationPage), findsOneWidget);
      // Verify that the page is in edit mode by checking for the initial server data
      expect(find.text('Test Server'), findsOneWidget);
    });

    testWidgets('Server edit route with invalid ID redirects to servers', (
      tester,
    ) async {
      // Mock the findServerById method to return null (server not found)
      when(mockServerDomain.findServerById('invalid')).thenReturn(null);

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/edit/invalid');

      await tester.pumpAndSettle();

      // Should redirect to servers page
      expect(find.byType(ServerListPage), findsOneWidget);
    });
  });
}
