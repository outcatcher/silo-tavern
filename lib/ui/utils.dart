import 'dart:async';

import 'package:flutter/material.dart';

Future<void> navigateWithLoader(
  BuildContext context,
  Future<void> action,
) async {
  bool showLoader = false;

  // start a timer for 100ms
  final timer = Timer(const Duration(milliseconds: 100), () {
    showLoader = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
  });

  try {
    await action;
  } finally {
    timer.cancel();
    if (showLoader && context.mounted) {
      Navigator.of(context).pop(); // hide loader
    }
  }
}

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
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}
