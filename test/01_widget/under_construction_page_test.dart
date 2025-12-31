import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

import 'under_construction_page_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GoRouter>()])
void main() {
  group('Under Construction Page Tests:', () {
    testWidgets('Renders correctly with title', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const UnderConstructionPage(title: 'Test Feature'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.text('Test Feature'), findsOneWidget);
      expect(find.text('Under Construction'), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('Back button navigates with router', (tester) async {
      final mockRouter = MockGoRouter();

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => UnderConstructionPage(
              title: 'Test Feature',
              router: mockRouter,
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final backButton = find.byType(IconButton).first;
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(mockRouter.go('/')).called(1);
    });

    testWidgets('Back button navigates with custom backUrl', (tester) async {
      final mockRouter = MockGoRouter();

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => UnderConstructionPage(
              title: 'Test Feature',
              backUrl: '/custom',
              router: mockRouter,
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final backButton = find.byType(IconButton).first;
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(mockRouter.go('/custom')).called(1);
    });
  });
}
