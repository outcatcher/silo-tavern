import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/router/router.dart';
import 'package:silo_tavern/router/auth_guard.dart';
import 'package:silo_tavern/ui/server_dashboard_page.dart';

import 'mocks.mocks.dart';

void main() {
  group('Server Dashboard Route Tests:', () {
    late MockServerDomain mockServerDomain;
    late MockConnectionDomain mockConnectionDomain;

    setUp(() {
      mockServerDomain = MockServerDomain();
      mockConnectionDomain = MockConnectionDomain();
    });

    tearDown(() {
      resetMockitoState();
      clearAuthCacheForTesting();
    });

    testWidgets('Redirects to dashboard when server has persistent session', (
      tester,
    ) async {
      // Arrange
      final testServer = Server(
        id: 'test-server',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      when(
        mockServerDomain.findServerById('test-server'),
      ).thenReturn(testServer);
      when(
        mockConnectionDomain.hasExistingSession(testServer),
      ).thenReturn(false);
      when(
        mockConnectionDomain.hasPersistentSession(testServer),
      ).thenAnswer((_) async => true);

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      // Act
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/test-server/dashboard');

      // Pump once to trigger the initial build
      await tester.pump();

      // Wait for async operations
      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Assert
      // Should show the dashboard page
      expect(find.text('Test Server'), findsOneWidget);
      expect(find.byType(ServerDashboardPage), findsOneWidget);
    });

    testWidgets('Redirects to server list when no valid session exists', (
      tester,
    ) async {
      // Arrange
      final testServer = Server(
        id: 'test-server',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      when(
        mockServerDomain.findServerById('test-server'),
      ).thenReturn(testServer);
      when(
        mockConnectionDomain.hasExistingSession(testServer),
      ).thenReturn(false);
      when(
        mockConnectionDomain.hasPersistentSession(testServer),
      ).thenAnswer((_) async => false);

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      // Act
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/test-server/dashboard');
      await tester.pumpAndSettle();

      // Assert
      // Should redirect to server list (root route redirects to /servers)
      expect(find.text('Checking authentication'), findsNothing);
      expect(find.byType(ServerDashboardPage), findsNothing);
      // Should be on the server list page now
      expect(find.text('SiloTavern - Servers'), findsWidgets);
    });
  });
}
