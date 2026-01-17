import 'package:flutter/material.dart';

const String defaultPage = '/servers';

/// Shows an error dialog with standardized styling
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

/// Shows a success dialog with standardized styling
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

/// Converts technical error messages to user-friendly messages
String getUserFriendlyErrorMessage(String? technicalMessage) {
  if (technicalMessage == null || technicalMessage.isEmpty) {
    return 'An error occurred. Please try again.';
  }

  // Handle common network errors
  if (technicalMessage.contains('SocketException') ||
      technicalMessage.contains('Connection refused') ||
      technicalMessage.contains('Failed host lookup')) {
    return 'Unable to connect to the server. Please check your network connection and try again.';
  }

  // Handle timeout errors
  if (technicalMessage.contains('timeout') ||
      technicalMessage.contains('timed out')) {
    return 'Connection timed out. The server may be busy or unreachable. Please try again.';
  }

  // Handle certificate errors
  if (technicalMessage.contains('CERTIFICATE_VERIFY_FAILED') ||
      technicalMessage.contains('HandshakeException')) {
    return 'Security certificate verification failed. Please check that the server\'s SSL/TLS certificate is valid.';
  }

  // Handle general HTTP errors
  if (technicalMessage.contains('HTTP status error')) {
    return 'Server responded with an error. Please check that the server is running and accessible.';
  }

  // Default fallback message
  return 'An error occurred. Please try again.';
}

/// Converts technical authentication error messages to user-friendly messages
String getFriendlyAuthErrorMessage(String? technicalMessage) {
  if (technicalMessage == null || technicalMessage.isEmpty) {
    return 'Authentication failed. Please check your credentials and try again.';
  }

  // Handle common authentication errors
  if (technicalMessage.contains('401') ||
      technicalMessage.contains('Unauthorized') ||
      technicalMessage.contains('invalid credentials') ||
      technicalMessage.contains('Invalid credentials')) {
    return 'Invalid username or password. Please check your credentials and try again.';
  }

  // Handle network connectivity issues
  if (technicalMessage.contains('SocketException') ||
      technicalMessage.contains('Connection refused') ||
      technicalMessage.contains('Failed host lookup')) {
    return 'Unable to connect to the server. Please check your network connection and try again.';
  }

  // Handle timeout errors
  if (technicalMessage.contains('timeout') ||
      technicalMessage.contains('timed out')) {
    return 'Connection timed out. The server may be busy or unreachable. Please try again.';
  }

  // Handle certificate errors
  if (technicalMessage.contains('CERTIFICATE_VERIFY_FAILED') ||
      technicalMessage.contains('HandshakeException')) {
    return 'Security certificate verification failed. Please check that the server\'s SSL/TLS certificate is valid.';
  }

  // Default fallback message
  return 'Authentication failed. Please check your credentials and try again.';
}
