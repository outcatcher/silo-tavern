import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/router/router.dart';
import 'package:silo_tavern/ui/server_dashboard_page.dart';

import 'mocks.mocks.dart';

void main() {
  group('Server List to Dashboard Navigation Tests:', () {
    late MockServerDomain mockServerDomain;
    late MockConnectionDomain mockConnectionDomain;

    setUp(() {
      mockServerDomain = MockServerDomain();
      mockConnectionDomain = MockConnectionDomain();

      // Provide dummy values for Result types
      provideDummy<Result<void>>(Result.success(null));
    });

    tearDown(() {
      resetMockitoState();
    });

    testWidgets(
      'Clicking server with persistent session navigates to dashboard',
      (tester) async {
        // Arrange
        final testServer = Server(
          id: 'test-server',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        when(mockServerDomain.servers).thenReturn([testServer]);
        when(
          mockServerDomain.findServerById('test-server'),
        ).thenReturn(testServer);
        when(
          mockConnectionDomain.obtainCsrfTokenForServer(testServer),
        ).thenAnswer((_) async => Result.success(null));
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
        router.go('/servers');
        await tester.pumpAndSettle();

        // Find and tap the server card
        await tester.tap(find.text('Test Server'));
        await tester.pumpAndSettle();

        // Assert
        // Should navigate to dashboard, not under construction
        expect(find.text('Test Server'), findsOneWidget); // App bar title
        expect(find.byType(ServerDashboardPage), findsOneWidget);
        expect(find.text('Personas'), findsOneWidget);
        expect(find.text('Characters'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);

        // Should NOT show under construction
        expect(find.text('Under Construction'), findsNothing);
      },
    );
  });
}
