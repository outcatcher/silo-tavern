import 'package:flutter/material.dart';

const String defaultPage = '/servers';

void showErrorDialog(
  BuildContext context,
  String message, {
  String title = 'Error',
}) {
  if (context.mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('errorDialog'),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              key: const ValueKey('errorDialogOkButton'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}

void showSuccessDialog(
  BuildContext context,
  String message, {
  String title = 'Success',
}) {
  if (context.mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('successDialog'),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              key: const ValueKey('successDialogOkButton'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}
