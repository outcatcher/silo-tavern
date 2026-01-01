import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';

import 'router_test.mocks.dart';
import 'server_creation_page_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerDomain>()])
void main() {
  group('Server Creation Page Tests:', () {
    testWidgets('Renders create form correctly', (tester) async {
      final serverDomain = MockServerDomain();

      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      expect(find.text('Add New Server'), findsOneWidget);
      expect(find.byKey(const ValueKey('serverNameField')), findsOneWidget);
      expect(find.byKey(const ValueKey('serverUrlField')), findsOneWidget);
      expect(find.byKey(const ValueKey('saveButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('backButton')), findsOneWidget);
    });

    testWidgets('Renders edit form correctly', (tester) async {
      final serverDomain = MockServerDomain();
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServerCreationPage(
            serverDomain: serverDomain,
            initialServer: server,
          ),
        ),
      );

      expect(find.text('Edit Server'), findsOneWidget);
      expect(find.byKey(const ValueKey('serverNameField')), findsOneWidget);
      expect(find.byKey(const ValueKey('serverUrlField')), findsOneWidget);
      expect(find.byKey(const ValueKey('saveButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('backButton')), findsOneWidget);
    });

    testWidgets('Back button navigates with router', (tester) async {
      final serverDomain = MockServerDomain();
      final router = MockGoRouter();

      await tester.pumpWidget(
        MaterialApp(
          home: ServerCreationPage(serverDomain: serverDomain, router: router),
        ),
      );

      final backButton = find.byKey(const ValueKey('backButton')).first;
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(router.go('/servers')).called(1);
    });

    testWidgets('Save button shows validation errors', (tester) async {
      final serverDomain = MockServerDomain();

      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Please enter a server name'), findsOneWidget);
      expect(find.text('Please enter a server URL'), findsOneWidget);
    });
  });
}
