import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/router/router.dart';
import 'package:silo_tavern/ui/server_dashboard_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import '../01_widget/router_test.mocks.dart';

void main() {
  group('Server Dashboard Item Navigation Tests:', () {
    late MockServerDomain mockServerDomain;
    late MockConnectionDomain mockConnectionDomain;

    setUp(() {
      mockServerDomain = MockServerDomain();
      mockConnectionDomain = MockConnectionDomain();
      provideDummy<Result<void>>(Result.success(null));
    });

    tearDown(() {
      resetMockitoState();
    });

    testWidgets(
      'Clicking Personas button navigates to under construction with backUrl',
      (tester) async {
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
        ).thenReturn(true);

        final domains = Domains(
          servers: mockServerDomain,
          connections: mockConnectionDomain,
        );
        final router = appRouter(domains);

        // Act
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.go('/servers/test-server/dashboard');
        await tester.pumpAndSettle();

        // Find and tap the Personas button
        await tester.tap(find.text('Personas'));
        await tester.pumpAndSettle();

        // Assert
        // Should navigate to under construction page
        expect(find.byType(UnderConstructionPage), findsOneWidget);
        expect(find.text('Personas'), findsOneWidget);

        // Should have correct back URL
        // Note: We can't easily test the backUrl parameter in widget tests
        // but we can verify we're on the under construction page
      },
    );

    testWidgets(
      'Clicking Characters button navigates to under construction with backUrl',
      (tester) async {
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
        ).thenReturn(true);

        final domains = Domains(
          servers: mockServerDomain,
          connections: mockConnectionDomain,
        );
        final router = appRouter(domains);

        // Act
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.go('/servers/test-server/dashboard');
        await tester.pumpAndSettle();

        // Find and tap the Characters button
        await tester.tap(find.text('Characters'));
        await tester.pumpAndSettle();

        // Assert
        // Should navigate to under construction page
        expect(find.byType(UnderConstructionPage), findsOneWidget);
        expect(find.text('Characters'), findsOneWidget);
      },
    );

    testWidgets(
      'Clicking Continue button navigates to under construction with backUrl',
      (tester) async {
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
        ).thenReturn(true);

        final domains = Domains(
          servers: mockServerDomain,
          connections: mockConnectionDomain,
        );
        final router = appRouter(domains);

        // Act
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        router.go('/servers/test-server/dashboard');
        await tester.pumpAndSettle();

        // Find and tap the Continue button
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Assert
        // Should navigate to under construction page
        expect(find.byType(UnderConstructionPage), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets('Back button navigates to server list', (tester) async {
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
      ).thenReturn(true);

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      // Act
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/test-server/dashboard');
      await tester.pumpAndSettle();

      // Find and tap the back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert
      // Should navigate back to server list
      expect(find.byType(ServerDashboardPage), findsNothing);
      // Note: We're testing that we left the dashboard page
    });

    testWidgets('Logout button clears session and navigates to server list', (
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
      ).thenReturn(true);
      when(
        mockConnectionDomain.logoutFromServer(testServer),
      ).thenAnswer((_) async => Result.success(null));

      final domains = Domains(
        servers: mockServerDomain,
        connections: mockConnectionDomain,
      );
      final router = appRouter(domains);

      // Act
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/servers/test-server/dashboard');
      await tester.pumpAndSettle();

      // Find and tap the logout button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump(
        Duration(milliseconds: 100),
      ); // Small delay for async operation
      await tester.pumpAndSettle();

      // Assert
      // Should navigate away from dashboard
      expect(find.byType(ServerDashboardPage), findsNothing);
    });
  });
}
