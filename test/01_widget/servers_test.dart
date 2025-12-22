// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
@Tags(['widget', 'servers'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silo_tavern/main.dart';

void main() {
  testWidgets('1.1 Server list basic display', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Verify that the app title is correct.
    expect(find.text('SiloTavern - Servers'), findsOneWidget);

    // Verify that we have the initial servers.
    expect(find.text('Production Server'), findsOneWidget);
    expect(find.text('Staging Server'), findsOneWidget);
    expect(find.text('Development Server'), findsOneWidget);

    // Verify that the '+' icon is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('2.2 Form validation rejects empty server name', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Tap the '+' icon to open the creation page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the server creation page.
    expect(find.text('Add New Server'), findsOneWidget);

    // Fill in only the URL (leave name empty)
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'https://test.example.com',
    );
    // Try to submit the form
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify that we're still on the creation page (validation failed)
    expect(find.text('Add New Server'), findsOneWidget);
    // Verify that name validation error is shown
    expect(find.text('Please enter a server name'), findsOneWidget);
  });

  testWidgets('2.2 Form validation rejects invalid URL format', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Tap the '+' icon to open the creation page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the server creation page.
    expect(find.text('Add New Server'), findsOneWidget);

    // Fill in name but invalid URL
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Server');
    await tester.enterText(find.byType(TextFormField).at(1), 'invalid-url');
    // Try to submit the form
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify that we're still on the creation page (validation failed)
    expect(find.text('Add New Server'), findsOneWidget);
    // Verify that URL validation error is shown
    expect(
      find.text('Please enter a valid URL (http:// or https://)'),
      findsOneWidget,
    );
  });

  testWidgets('2.3 Form submission - valid form can be submitted', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Tap the '+' icon to open the creation page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the server creation page.
    expect(find.text('Add New Server'), findsOneWidget);

    // Fill in the form fields.
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Server');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'https://test.example.com',
    );

    // Tap the save button (checkmark icon).
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify that we're back on the server list page.
    expect(find.text('SiloTavern - Servers'), findsOneWidget);

    // Verify that the new server appears in the list.
    expect(find.text('Test Server'), findsOneWidget);
  });

  testWidgets('5.2 Credentials authentication field visibility', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Tap the '+' icon to open the creation page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the server creation page.
    expect(find.text('Add New Server'), findsOneWidget);

    // Verify authentication section exists.
    expect(find.text('Authentication'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('Credentials'), findsOneWidget);

    // Select credentials authentication.
    await tester.tap(find.text('Credentials'));
    await tester.pumpAndSettle();

    // Verify that authentication fields appear by counting the total number of TextFormFields
    // Initially there are 2 TextFormFields (name and URL)
    // After selecting credentials, there should be 4 TextFormFields (name, URL, user handle, password)
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('5.2 Credentials authentication requires username', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Tap the '+' icon to open the creation page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the server creation page.
    expect(find.text('Add New Server'), findsOneWidget);

    // Select credentials authentication.
    await tester.tap(find.text('Credentials'));
    await tester.pumpAndSettle();

    // Fill in only the required fields except username
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Server');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'https://test.example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');

    // Try to submit the form
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify that we're still on the creation page (validation failed)
    expect(find.text('Add New Server'), findsOneWidget);
    // Verify that username validation error is shown
    expect(find.text('Please enter a username'), findsOneWidget);
  });

  testWidgets('5.2 Credentials authentication requires password', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Tap the '+' icon to open the creation page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the server creation page.
    expect(find.text('Add New Server'), findsOneWidget);

    // Select credentials authentication.
    await tester.tap(find.text('Credentials'));
    await tester.pumpAndSettle();

    // Fill in only the required fields except password
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Server');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'https://test.example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'testuser');

    // Try to submit the form
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify that we're still on the creation page (validation failed)
    expect(find.text('Add New Server'), findsOneWidget);
    // Verify that password validation error is shown
    expect(find.text('Please enter a password'), findsOneWidget);
  });

  testWidgets(
    '5.2 Credentials authentication validates correctly with valid data',
    (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const SiloTavernApp());

      // Tap the '+' icon to open the creation page.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify that we're on the server creation page.
      expect(find.text('Add New Server'), findsOneWidget);

      // Select credentials authentication.
      await tester.tap(find.text('Credentials'));
      await tester.pumpAndSettle();

      // Fill in all required fields including credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Server');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'https://test.example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      // Submit the form
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Verify that we're back on the server list page
      expect(find.text('SiloTavern - Servers'), findsOneWidget);
      // Verify that the new server appears in the list
      expect(find.text('Test Server'), findsOneWidget);
    },
  );

  testWidgets('1.2 Server row UI - dismissible items', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Verify that servers are displayed with Dismissible widgets.
    expect(find.byType(Dismissible), findsWidgets);

    // Verify initial server exists.
    expect(find.text('Production Server'), findsOneWidget);
  });

  testWidgets('4.1 Swipe action - delete triggers process', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Verify initial server exists.
    expect(find.text('Production Server'), findsOneWidget);
    final initialServerCount = tester
        .widgetList(find.byType(Dismissible))
        .length;

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform right-to-left swipe (delete) - this should start the removal process
    await tester.drag(dismissibleFinder, const Offset(-300, 0));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The server should still exist because the confirmation dialog appeared
    expect(find.text('Production Server'), findsOneWidget);
    expect(
      tester.widgetList(find.byType(Dismissible)).length,
      initialServerCount,
    );
  });

  testWidgets('1.2 Server row UI - edit swipe background', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform left-to-right swipe (edit) using drag method
    await tester.drag(
      dismissibleFinder,
      const Offset(300, 0),
    ); // Drag left to right
    await tester.pump();

    // Should show blue background with edit icon on the left
    expect(find.byIcon(Icons.edit), findsOneWidget);

    // Reset
    await tester.pumpAndSettle();
  });

  testWidgets('1.2 Server row UI - delete swipe background', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform right-to-left swipe (delete) using drag method
    await tester.drag(
      dismissibleFinder,
      const Offset(-300, 0),
    ); // Drag right to left
    await tester.pump();

    // Should show red background with delete icon on the right
    expect(find.byIcon(Icons.delete), findsOneWidget);

    // Reset
    await tester.pumpAndSettle();
  });

  testWidgets('4.2 Confirmation dialog appearance', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Verify initial server exists.
    expect(find.text('Production Server'), findsOneWidget);

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    await tester.drag(
      dismissibleFinder,
      const Offset(-300, 0),
    ); // Drag right to left
    await tester.pumpAndSettle(
      const Duration(seconds: 1),
    ); // Wait longer for dialog

    // Verify confirmation dialog is shown
    expect(find.byType(AlertDialog), findsOne);
    expect(find.text('DELETE'), findsOne);
    expect(find.text('CANCEL'), findsOne);
  });

  testWidgets('4.3 Dialog actions - CANCEL preserves server', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Verify initial server exists.
    expect(find.text('Production Server'), findsOneWidget);
    final initialServerCount = tester
        .widgetList(find.byType(Dismissible))
        .length;

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform right-to-left swipe (delete)
    await tester.drag(dismissibleFinder, const Offset(-300, 0));
    await tester.pumpAndSettle(
      const Duration(seconds: 2),
    ); // Wait longer for dialog

    // Tap CANCEL button
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    // Verify server still exists
    expect(find.text('Production Server'), findsOneWidget);
    expect(
      tester.widgetList(find.byType(Dismissible)).length,
      initialServerCount,
    );
  });

  testWidgets('4.3 Dialog actions - DELETE removes server', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Verify initial server exists.
    expect(find.text('Production Server'), findsOneWidget);
    final initialServerCount = tester
        .widgetList(find.byType(Dismissible))
        .length;

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform right-to-left swipe (delete)
    await tester.drag(dismissibleFinder, const Offset(-300, 0));
    await tester.pumpAndSettle(
      const Duration(seconds: 2),
    ); // Wait longer for dialog

    // Tap DELETE button
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();

    // Verify server is removed
    expect(find.text('Production Server'), findsNothing);
    expect(
      tester.widgetList(find.byType(Dismissible)).length,
      initialServerCount - 1,
    );
  });

  testWidgets('6.2 Back button cancels creation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Tap the '+' icon to open the creation page.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that we're on the server creation page.
    expect(find.text('Add New Server'), findsOneWidget);

    // Fill in some form data
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Server');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'https://test.example.com',
    );

    // Tap the back button (arrow back icon)
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify that we're back on the server list page
    expect(find.text('SiloTavern - Servers'), findsOneWidget);
    // Verify that the new server does NOT appear in the list (creation was canceled)
    expect(find.text('Test Server'), findsNothing);
  });

  testWidgets('3.1 Edit server form pre-fills existing data', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform left-to-right swipe (edit)
    await tester.drag(dismissibleFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verify that we're on the server edit page.
    expect(find.text('Edit Server'), findsOneWidget);
    // Verify that existing server data is pre-filled
    expect(find.text('Production Server'), findsOneWidget);
    expect(find.text('https://prod.example.com'), findsOneWidget);
  });

  testWidgets('3.1 Edit preserves server ID and status', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform left-to-right swipe (edit)
    await tester.drag(dismissibleFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verify that we're on the server edit page.
    expect(find.text('Edit Server'), findsOneWidget);

    // Modify the server name but keep URL the same
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Updated Production Server',
    );

    // Save the changes
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify that we're back on the server list page
    expect(find.byType(Scaffold), findsOneWidget);
    // Verify the updated server appears
    expect(find.text('Updated Production Server'), findsOneWidget);
    // Verify the original server is gone
    expect(find.text('Production Server'), findsNothing);
  });

  testWidgets('3.2 Edit form preserves authentication data', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform left-to-right swipe (edit)
    await tester.drag(dismissibleFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verify that we're on the server edit page.
    expect(find.text('Edit Server'), findsOneWidget);

    // Verify form is pre-filled with existing data
    expect(find.text('Production Server'), findsOneWidget);
    expect(find.text('https://prod.example.com'), findsOneWidget);

    // Modify only the name, keep other data the same
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Updated Production Server',
    );

    // Save the changes
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify the updated server appears
    expect(find.text('Updated Production Server'), findsOneWidget);
    // Original should be gone
    expect(find.text('Production Server'), findsNothing);
  });

  testWidgets('3.2 Edit with credentials authentication preserves auth data', (
    WidgetTester tester,
  ) async {
    // First, create a server with credentials
    await tester.pumpWidget(const SiloTavernApp());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Fill in server creation form with credentials
    await tester.enterText(find.byType(TextFormField).at(0), 'Auth Server');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'https://auth.example.com',
    );

    // Select credentials authentication
    await tester.tap(find.text('Credentials'));
    await tester.pumpAndSettle();

    // Fill in credentials
    await tester.enterText(find.byType(TextFormField).at(2), 'testuser');
    await tester.enterText(find.byType(TextFormField).at(3), 'testpass');

    // Save the server
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Now edit the server
    final dismissibleFinder = find.ancestor(
      of: find.text('Auth Server'),
      matching: find.byType(Dismissible),
    );

    // Perform left-to-right swipe (edit)
    await tester.drag(dismissibleFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verify we're on edit page
    expect(find.text('Edit Server'), findsOneWidget);

    // Verify form is pre-filled
    expect(find.text('Auth Server'), findsOneWidget);
    expect(find.text('https://auth.example.com'), findsOneWidget);
    expect(find.text('testuser'), findsOneWidget);

    // Modify the name
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Updated Auth Server',
    );

    // Save changes
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify update
    expect(find.text('Updated Auth Server'), findsOneWidget);
    expect(find.text('Auth Server'), findsNothing);
  });

  testWidgets('3.2 Edit cancel preserves original server', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiloTavernApp());

    // Find the Production Server dismissible
    final dismissibleFinder = find.ancestor(
      of: find.text('Production Server'),
      matching: find.byType(Dismissible),
    );

    // Perform left-to-right swipe (edit)
    await tester.drag(dismissibleFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    // Verify that we're on the server edit page.
    expect(find.text('Edit Server'), findsOneWidget);

    // Modify the server name
    await tester.enterText(find.byType(TextFormField).at(0), 'Temp Name');

    // Cancel the edit (back button)
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify original server still exists
    expect(find.text('Production Server'), findsOneWidget);
    // Updated name should not exist
    expect(find.text('Temp Name'), findsNothing);
  });
}

