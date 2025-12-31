// Widget tests for LoginPage functionality
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/login_page.dart';

void main() {
  group('LoginPage Tests', () {
    late Server testServer;

    setUp(() {
      testServer = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
        authentication: const AuthenticationInfo.none(),
      );
    });

    testWidgets('Displays server name and address', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: testServer),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login to Test Server'), findsOneWidget);
      expect(find.text('Server: https://test.example.com'), findsOneWidget);
    });

    testWidgets('Has username and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: testServer),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Shows validation errors for empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: testServer),
        ),
      );
      await tester.pumpAndSettle();

      // Find the login button by its label text
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Accepts input in username and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: testServer),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'testpass');

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('testpass'), findsOneWidget);
    });

    testWidgets('Toggles password visibility icons appear', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(server: testServer),
        ),
      );
      await tester.pumpAndSettle();

      // Check that visibility icons are present
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
      
      // Tap visibility icon to show password
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Check that the icon changed
      expect(find.byIcon(Icons.visibility), findsNothing);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Navigates back when back button is pressed', (WidgetTester tester) async {
      late GoRouter router;
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Home')),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => LoginPage(
              server: testServer,
              backUrl: '/',
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.go('/login');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Navigates to connection page on successful login', (WidgetTester tester) async {
      late GoRouter router;
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/servers',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Server List')),
            ),
          ),
          GoRoute(
            path: '/servers/login/:id',
            builder: (context, state) => LoginPage(
              server: testServer,
              backUrl: '/servers',
            ),
          ),
          GoRoute(
            path: '/servers/connect/:id',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Connected')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.go('/servers/login/1');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'testpass');
      
      // Find the login button by its label text
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);
    });
  });
}