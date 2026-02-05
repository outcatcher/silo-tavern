import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/ui/server_dashboard_page.dart';

import '../01_widget/mocks.mocks.dart';

void main() {
  late MockGoRouter router;
  late MockConnectionDomain connectionDomain;
  late MockServerDomain serverDomain;

  setUp(() {
    router = MockGoRouter();
    connectionDomain = MockConnectionDomain();
    serverDomain = MockServerDomain();
  });

  tearDown(() {
    resetMockitoState();
  });

  group('Server Dashboard Page Tests:', () {
    testWidgets('Renders correctly with server info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ServerDashboardPage(
            serverId: 'test-server',
            serverName: 'Test Server',
            router: router,
            connectionDomain: connectionDomain,
            serverDomain: serverDomain,
          ),
        ),
      );

      // Verify the page renders
      expect(find.text('Test Server'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
      
      // Verify menu buttons
      expect(find.text('Personas'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Back button calls router navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ServerDashboardPage(
            serverId: 'test-server',
            serverName: 'Test Server',
            router: router,
            connectionDomain: connectionDomain,
            serverDomain: serverDomain,
          ),
        ),
      );

      // Tap the back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify router navigation was called
      verify(router.go('/')).called(1);
    });

    testWidgets('Logout button calls router navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ServerDashboardPage(
            serverId: 'test-server',
            serverName: 'Test Server',
            router: router,
            connectionDomain: connectionDomain,
            serverDomain: serverDomain,
          ),
        ),
      );

      // Tap the logout button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Verify router navigation was called
      verify(router.go('/')).called(1);
    });
  });
}