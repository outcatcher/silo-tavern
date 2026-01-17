import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';

import 'mocks.mocks.dart';

void main() {
  // Provide dummy values for Result types to avoid MissingDummyValueError
  provideDummy<Result<void>>(Result.success(null));

  late MockServerDomain serverDomain;
  late MockGoRouter router;

  setUp(() {
    serverDomain = MockServerDomain();
    router = MockGoRouter();

    // Provide dummy value for Result<void> to avoid Mockito errors
    provideDummy<Result<void>>(Result.success(null));

    // Provide default stubs to avoid MissingDummyValueError during verification
    when(
      serverDomain.addServer(any),
    ).thenAnswer((_) async => Result.success(null));
    when(
      serverDomain.updateServer(any),
    ).thenAnswer((_) async => Result.success(null));
  });

  tearDown(() {
    resetMockitoState();
  });

  group('Server Creation Page Tests:', () {
    testWidgets('Renders create form correctly', (tester) async {
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

      // Verify initial values are populated
      final nameField = find.byKey(const ValueKey('serverNameField'));
      final urlField = find.byKey(const ValueKey('serverUrlField'));
      expect(
        tester.widget<TextFormField>(nameField).initialValue,
        'Test Server',
      );
      expect(
        tester.widget<TextFormField>(urlField).initialValue,
        'https://test.example.com',
      );
    });

    testWidgets('Back button navigates with router', (tester) async {
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

    testWidgets('Save button shows validation errors for empty fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pump();

      expect(find.text('Please enter a server name'), findsOneWidget);
      expect(find.text('Please enter a server URL'), findsOneWidget);
    });

    testWidgets('Real-time validation for name field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      // Start with empty name field
      expect(find.text('Please enter a server name'), findsNothing);

      // Enter text and then clear it
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Test',
      );
      await tester.pump();
      expect(find.text('Please enter a server name'), findsNothing);

      // Clear the text
      await tester.enterText(find.byKey(const ValueKey('serverNameField')), '');
      await tester.pump();
      expect(find.text('Please enter a server name'), findsOneWidget);
    });

    testWidgets('Real-time validation for URL field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      // Start with empty URL field
      expect(find.text('Please enter a server URL'), findsNothing);

      // Enter valid URL
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'https://example.com',
      );
      await tester.pump();
      expect(find.text('Please enter a server URL'), findsNothing);
      expect(
        find.text('Please enter a valid URL (http:// or https://)'),
        findsNothing,
      );

      // Enter invalid URL
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'invalid-url',
      );
      await tester.pump();
      expect(
        find.text('Please enter a valid URL (http:// or https://)'),
        findsOneWidget,
      );

      // Clear the text
      await tester.enterText(find.byKey(const ValueKey('serverUrlField')), '');
      await tester.pump();
      expect(find.text('Please enter a server URL'), findsOneWidget);
    });

    testWidgets('Form validation prevents submission with invalid data', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      // Enter valid name but invalid URL
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Test Server',
      );
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'invalid-url',
      );
      await tester.pump();

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pump();

      // Should show URL validation error
      expect(
        find.text('Please enter a valid URL (http:// or https://)'),
        findsOneWidget,
      );

      // Server domain should not be called
      verifyNever(serverDomain.addServer(any));
    });

    testWidgets('Successfully adds new server with valid data', (tester) async {
      when(
        serverDomain.addServer(any),
      ).thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        MaterialApp(
          home: ServerCreationPage(serverDomain: serverDomain, router: router),
        ),
      );

      // Enter valid data
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Test Server',
      );
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'https://localhost:3000',
      );
      await tester.pump();

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify server was added
      verify(serverDomain.addServer(any)).called(1);

      // Verify success dialog is shown
      expect(find.byKey(const ValueKey('successDialog')), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Server added successfully!'), findsOneWidget);

      // Verify navigation after success
      verify(router.go('/servers')).called(1);
    });

    testWidgets('Successfully updates existing server with valid data', (
      tester,
    ) async {
      final existingServer = Server(
        id: '1',
        name: 'Original Server',
        address: 'https://original.example.com',
      );

      when(
        serverDomain.updateServer(any),
      ).thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        MaterialApp(
          home: ServerCreationPage(
            serverDomain: serverDomain,
            initialServer: existingServer,
            router: router,
          ),
        ),
      );

      // Modify the data with a local server URL to avoid validation issues
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Updated Server',
      );
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'https://localhost:3000',
      );
      await tester.pump();

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify server was updated
      verify(serverDomain.updateServer(any)).called(1);

      // No success dialog for updates
      expect(find.byKey(const ValueKey('successDialog')), findsNothing);

      // Verify navigation after update
      verify(router.go('/servers')).called(1);
    });

    testWidgets('Shows error dialog for invalid server configuration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      // Enter data that fails server configuration validation (HTTP remote server)
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Remote Server',
      );
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'http://remote.example.com',
      );
      await tester.pump();

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify error dialog is shown
      expect(find.byKey(const ValueKey('errorDialog')), findsOneWidget);
      expect(find.text('Invalid Configuration'), findsOneWidget);
      expect(
        find.text('Please use HTTPS with authentication for remote servers.'),
        findsOneWidget,
      );

      // Verify server was not added
      verifyNever(serverDomain.addServer(any));
    });

    testWidgets('Shows error dialog when server save fails', (tester) async {
      when(
        serverDomain.addServer(any),
      ).thenAnswer((_) async => Result.failure('Save failed'));

      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      // Enter valid local server data
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Local Server',
      );
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'http://localhost:3000',
      );
      await tester.pump();

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify error dialog is shown
      expect(find.byKey(const ValueKey('errorDialog')), findsOneWidget);
      expect(find.text('Save Failed'), findsOneWidget);
      expect(
        find.text('Failed to save server. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Error dialog can be dismissed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ServerCreationPage(serverDomain: serverDomain)),
      );

      // Trigger validation error
      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pump();

      // Verify error messages are shown
      expect(find.text('Please enter a server name'), findsOneWidget);
      expect(find.text('Please enter a server URL'), findsOneWidget);

      // Clear fields and try again with invalid configuration
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Test Server',
      );
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'http://invalid.com',
      );
      await tester.pump();

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify error dialog is shown
      expect(find.byKey(const ValueKey('errorDialog')), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.byKey(const ValueKey('errorDialogOkButton')));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed
      expect(find.byKey(const ValueKey('errorDialog')), findsNothing);
    });

    testWidgets('Success dialog can be dismissed', (tester) async {
      when(
        serverDomain.addServer(any),
      ).thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(
        MaterialApp(
          home: ServerCreationPage(serverDomain: serverDomain, router: router),
        ),
      );

      // Enter valid local server data
      await tester.enterText(
        find.byKey(const ValueKey('serverNameField')),
        'Local Server',
      );
      await tester.enterText(
        find.byKey(const ValueKey('serverUrlField')),
        'http://localhost:3000',
      );
      await tester.pump();

      final saveButton = find.byKey(const ValueKey('saveButton')).first;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify success dialog is shown
      expect(find.byKey(const ValueKey('successDialog')), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.byKey(const ValueKey('successDialogOkButton')));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed but navigation still occurs
      expect(find.byKey(const ValueKey('successDialog')), findsNothing);
      verify(router.go('/servers')).called(1);
    });
  });
}
