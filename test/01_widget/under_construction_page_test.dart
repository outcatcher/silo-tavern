import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import 'mocks.mocks.dart';

void main() {
  late MockGoRouter router;

  setUp(() {
    router = MockGoRouter();
  });

  tearDown(() {
    resetMockitoState();
  });

  group('Under Construction Page Tests:', () {
    testWidgets('Renders correctly with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UnderConstructionPage(title: 'Test Feature', router: router),
        ),
      );

      expect(find.text('Test Feature'), findsOneWidget);
      expect(find.text('Under Construction'), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('Back button navigates with router', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UnderConstructionPage(title: 'Test Feature', router: router),
        ),
      );

      final backButton = find.byType(IconButton).first;
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(router.go('/')).called(1);
    });

    testWidgets('Back button navigates with custom backUrl', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UnderConstructionPage(
            title: 'Test Feature',
            backUrl: '/custom',
            router: router,
          ),
        ),
      );

      final backButton = find.byType(IconButton).first;
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(router.go('/custom')).called(1);
    });
  });
}
