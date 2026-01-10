import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/ui/utils.dart';

void main() {
  group('UI Utils Tests', () {
    testWidgets('showErrorDialog displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showErrorDialog(
                    context,
                    'Test error message',
                    title: 'Test Error',
                  ),
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.byKey(const ValueKey('errorDialog')), findsOneWidget);
      expect(find.text('Test Error'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byKey(const ValueKey('errorDialogOkButton')), findsOneWidget);
    });

    testWidgets('showErrorDialog OK button dismisses dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      showErrorDialog(context, 'Test error message'),
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.byKey(const ValueKey('errorDialog')), findsOneWidget);

      // Tap OK button
      await tester.tap(find.byKey(const ValueKey('errorDialogOkButton')));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed
      expect(find.byKey(const ValueKey('errorDialog')), findsNothing);
    });

    testWidgets('showSuccessDialog displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showSuccessDialog(
                    context,
                    'Test success message',
                    title: 'Test Success',
                  ),
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the dialog
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.byKey(const ValueKey('successDialog')), findsOneWidget);
      expect(find.text('Test Success'), findsOneWidget);
      expect(find.text('Test success message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(
        find.byKey(const ValueKey('successDialogOkButton')),
        findsOneWidget,
      );
    });

    testWidgets('showSuccessDialog OK button dismisses dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      showSuccessDialog(context, 'Test success message'),
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the dialog
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.byKey(const ValueKey('successDialog')), findsOneWidget);

      // Tap OK button
      await tester.tap(find.byKey(const ValueKey('successDialogOkButton')));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed
      expect(find.byKey(const ValueKey('successDialog')), findsNothing);
    });

    testWidgets('Dialogs handle long titles with ellipsis', (
      WidgetTester tester,
    ) async {
      final longTitle =
          'This is a very long title that should be truncated with ellipsis to fit in the dialog header';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showErrorDialog(
                    context,
                    'Test message',
                    title: longTitle,
                  ),
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger the dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed with long title
      expect(find.byKey(const ValueKey('errorDialog')), findsOneWidget);
      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('Dialogs are not shown when context is not mounted', (
      WidgetTester tester,
    ) async {
      BuildContext? capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test Widget');
              },
            ),
          ),
        ),
      );

      // Remove the widget from the tree to unmount the context
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const Text('Different Widget'))),
      );

      // Try to show dialog with unmounted context - should not throw
      expect(() {
        if (capturedContext != null) {
          showErrorDialog(capturedContext!, 'Test message');
        }
      }, returnsNormally);

      // Pump to allow any scheduled callbacks to run
      await tester.pumpAndSettle();

      // Verify no dialog is shown
      expect(find.byKey(const ValueKey('errorDialog')), findsNothing);
    });
  });
}
