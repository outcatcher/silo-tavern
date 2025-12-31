// Simple test to debug login page rendering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/login_page.dart';

void main() {
  testWidgets('Simple login page test', (WidgetTester tester) async {
    // Arrange
    final server = Server(
      id: '1',
      name: 'Test Server',
      address: 'https://test.example.com',
      authentication: const AuthenticationInfo.none(),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(server: server),
      ),
    );

    // Debug: Print the widget tree
    print(tester.widgetList(find.byType(Text)));
    
    // Assert
    expect(find.text('Login to Test Server'), findsOneWidget);
  });
}