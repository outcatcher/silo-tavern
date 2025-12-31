import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/ui/server_list_page.dart';

import 'router_test.mocks.dart';
import 'server_list.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerDomain>()])
void main() {
  group('Server List Tests:', () {
    testWidgets('Empty server list', (tester) async {
      final serverDomain = MockServerDomain();

      when(serverDomain.servers).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(home: ServerListPage(serverDomain: serverDomain)),
      );

      final title = find.byKey(const ValueKey('serverListTitle'));
      expect(title, findsOneWidget);
      expect(find.byKey(const ValueKey('addServerIcon')), findsOneWidget);
      expect(find.byKey(const ValueKey('addServerIcon')), findsOneWidget);
      expect(find.byKey(const ValueKey('addServerButton')), findsOneWidget);
    });

    testWidgets('Create Triggers Creation', (tester) async {
      final serverDomain = MockServerDomain();
      final router = MockGoRouter();

      when(serverDomain.servers).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          home: ServerListPage(serverDomain: serverDomain, router: router),
        ),
      );
      await tester.pumpAndSettle();

      when(router.go('/servers/create'));

      final createIcon = find.byKey(const ValueKey('addServerIcon')).first;
      expect(createIcon, findsOneWidget);

      await tester.tap(createIcon);
      await tester.pump();

      verify(router.go('/servers/create')).called(1);

      final createButton = find.byKey(const ValueKey('addServerButton')).first;
      expect(createButton, findsOneWidget);

      await tester.tap(createButton.first);
      await tester.pumpAndSettle();

      verify(router.go('/servers/create')).called(1);
    });
  });
}
