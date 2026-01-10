import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/ui/login_page.dart';

void main() {
  group('Login Error Message Tests:', () {
    test('Returns default message for null input', () {
      final result = getFriendlyAuthErrorMessage(null);
      expect(
        result,
        'Authentication failed. Please check your credentials and try again.',
      );
    });

    test('Returns default message for empty input', () {
      final result = getFriendlyAuthErrorMessage('');
      expect(
        result,
        'Authentication failed. Please check your credentials and try again.',
      );
    });

    test('Returns invalid credentials message for 401 errors', () {
      final result = getFriendlyAuthErrorMessage('HTTP 401 Unauthorized');
      expect(
        result,
        'Invalid username or password. Please check your credentials and try again.',
      );
    });

    test('Returns invalid credentials message for Unauthorized', () {
      final result = getFriendlyAuthErrorMessage('Unauthorized access');
      expect(
        result,
        'Invalid username or password. Please check your credentials and try again.',
      );
    });

    test('Returns invalid credentials message for invalid credentials', () {
      final result = getFriendlyAuthErrorMessage(
        'invalid credentials provided',
      );
      expect(
        result,
        'Invalid username or password. Please check your credentials and try again.',
      );
    });

    test('Returns invalid credentials message for Invalid credentials', () {
      final result = getFriendlyAuthErrorMessage(
        'Invalid credentials provided',
      );
      expect(
        result,
        'Invalid username or password. Please check your credentials and try again.',
      );
    });

    test('Returns network error message for SocketException', () {
      final result = getFriendlyAuthErrorMessage(
        'SocketException: Connection failed',
      );
      expect(
        result,
        'Unable to connect to the server. Please check your network connection and try again.',
      );
    });

    test('Returns network error message for Connection refused', () {
      final result = getFriendlyAuthErrorMessage('Connection refused');
      expect(
        result,
        'Unable to connect to the server. Please check your network connection and try again.',
      );
    });

    test('Returns network error message for Failed host lookup', () {
      final result = getFriendlyAuthErrorMessage('Failed host lookup');
      expect(
        result,
        'Unable to connect to the server. Please check your network connection and try again.',
      );
    });

    test('Returns timeout message for timeout errors', () {
      final result = getFriendlyAuthErrorMessage('Request timeout occurred');
      expect(
        result,
        'Connection timed out. The server may be busy or unreachable. Please try again.',
      );
    });

    test('Returns timeout message for timed out errors', () {
      final result = getFriendlyAuthErrorMessage('Connection timed out');
      expect(
        result,
        'Connection timed out. The server may be busy or unreachable. Please try again.',
      );
    });

    test('Returns certificate error message for CERTIFICATE_VERIFY_FAILED', () {
      final result = getFriendlyAuthErrorMessage('CERTIFICATE_VERIFY_FAILED');
      expect(
        result,
        'Security certificate verification failed. Please check that the server\'s SSL/TLS certificate is valid.',
      );
    });

    test('Returns certificate error message for HandshakeException', () {
      final result = getFriendlyAuthErrorMessage(
        'HandshakeException: TLS handshake failed',
      );
      expect(
        result,
        'Security certificate verification failed. Please check that the server\'s SSL/TLS certificate is valid.',
      );
    });

    test('Returns default message for unknown errors', () {
      final result = getFriendlyAuthErrorMessage('Unknown error occurred');
      expect(
        result,
        'Authentication failed. Please check your credentials and try again.',
      );
    });
  });
}
