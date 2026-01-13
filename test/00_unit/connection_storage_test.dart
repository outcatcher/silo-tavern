// Unit tests for ConnectionStorage
@Tags(['unit', 'connection'])
library;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/services/connection/storage.dart';
import 'package:silo_tavern/common/app_storage.dart';

import 'connection_storage_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<JsonSecureStorage>(),
  MockSpec<FlutterSecureStorage>(),
])
void main() {
  group('ConnectionStorage Tests', () {
    late MockJsonSecureStorage mockSecureStorage;
    late ConnectionStorage storage;

    setUp(() {
      mockSecureStorage = MockJsonSecureStorage();
      storage = ConnectionStorage(mockSecureStorage);
    });

    group('saveSessionCookies', () {
      test('Successfully saves cookies', () async {
        // Arrange
        const serverId = 'server123';
        final cookies = [
          Cookie('session', 'abc123')
            ..domain = 'example.com'
            ..path = '/'
            ..expires = DateTime(2025, 12, 31),
          Cookie('auth', 'xyz789')
            ..domain = 'example.com'
            ..path = '/api',
        ];

        final expectedData = [
          {
            'name': 'session',
            'value': 'abc123',
            'domain': 'example.com',
            'path': '/',
            'expires': '2025-12-31T00:00:00.000',
          },
          {
            'name': 'auth',
            'value': 'xyz789',
            'domain': 'example.com',
            'path': '/api',
          },
        ];

        when(
          mockSecureStorage.set(serverId, expectedData),
        ).thenAnswer((_) async => Future.value());

        // Act
        await storage.saveSessionCookies(serverId, cookies);

        // Assert
        verify(mockSecureStorage.set(serverId, expectedData)).called(1);
      });

      test('Handles cookies without expiration dates', () async {
        // Arrange
        const serverId = 'server456';
        final cookies = [
          Cookie('session', 'abc123')
            ..domain = 'example.com'
            ..path = '/',
        ];

        final expectedData = [
          {
            'name': 'session',
            'value': 'abc123',
            'domain': 'example.com',
            'path': '/',
          },
        ];

        when(
          mockSecureStorage.set(serverId, expectedData),
        ).thenAnswer((_) async => Future.value());

        // Act
        await storage.saveSessionCookies(serverId, cookies);

        // Assert
        verify(mockSecureStorage.set(serverId, expectedData)).called(1);
      });

      test('Handles empty cookie list', () async {
        // Arrange
        const serverId = 'server789';
        final cookies = <Cookie>[];

        final expectedData = <Map<String, dynamic>>[];

        when(
          mockSecureStorage.set(serverId, expectedData),
        ).thenAnswer((_) async => Future.value());

        // Act
        await storage.saveSessionCookies(serverId, cookies);

        // Assert
        verify(mockSecureStorage.set(serverId, expectedData)).called(1);
      });
    });

    group('loadSessionCookies', () {
      test('Successfully loads existing cookies', () async {
        // Arrange
        const serverId = 'server123';
        final storedData = [
          {
            'name': 'session',
            'value': 'abc123',
            'domain': 'example.com',
            'path': '/',
            'expires': '2025-12-31T00:00:00.000',
          },
          {
            'name': 'auth',
            'value': 'xyz789',
            'domain': 'example.com',
            'path': '/api',
          },
        ];

        when(
          mockSecureStorage.get(serverId),
        ).thenAnswer((_) async => storedData);

        // Act
        final result = await storage.loadSessionCookies(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotNull);
        expect(result.value, hasLength(2));

        final firstCookie = result.value![0];
        expect(firstCookie.name, 'session');
        expect(firstCookie.value, 'abc123');
        expect(firstCookie.domain, 'example.com');
        expect(firstCookie.path, '/');
        expect(firstCookie.expires, DateTime(2025, 12, 31));

        final secondCookie = result.value![1];
        expect(secondCookie.name, 'auth');
        expect(secondCookie.value, 'xyz789');
        expect(secondCookie.domain, 'example.com');
        expect(secondCookie.path, '/api');
        expect(secondCookie.expires, isNull);
      });

      test('Returns null when no cookies exist for server', () async {
        // Arrange
        const serverId = 'nonexistent';

        when(mockSecureStorage.get(serverId)).thenAnswer((_) async => null);

        // Act
        final result = await storage.loadSessionCookies(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });

      test('Handles cookies without expiration dates', () async {
        // Arrange
        const serverId = 'server456';
        final storedData = [
          {
            'name': 'session',
            'value': 'abc123',
            'domain': 'example.com',
            'path': '/',
          },
        ];

        when(
          mockSecureStorage.get(serverId),
        ).thenAnswer((_) async => storedData);

        // Act
        final result = await storage.loadSessionCookies(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotNull);
        expect(result.value, hasLength(1));

        final cookie = result.value![0];
        expect(cookie.name, 'session');
        expect(cookie.value, 'abc123');
        expect(cookie.domain, 'example.com');
        expect(cookie.path, '/');
        expect(cookie.expires, isNull);
      });

      test('Handles empty cookie list', () async {
        // Arrange
        const serverId = 'server789';
        final storedData = <Map<String, dynamic>>[];

        when(
          mockSecureStorage.get(serverId),
        ).thenAnswer((_) async => storedData);

        // Act
        final result = await storage.loadSessionCookies(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNotNull);
        expect(result.value, isEmpty);
      });

      test('Returns null when stored data is not a list', () async {
        // Arrange
        const serverId = 'notlist';
        const storedData = 'not-a-list';

        when(
          mockSecureStorage.get(serverId),
        ).thenAnswer((_) async => storedData);

        // Act
        final result = await storage.loadSessionCookies(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });
    });

    group('saveCsrfToken', () {
      test('Successfully saves CSRF token', () async {
        // Arrange
        const serverId = 'server123';
        const token = 'abc123xyz';
        const key = 'server123_csrf_token';

        when(
          mockSecureStorage.set(key, token),
        ).thenAnswer((_) async => Future.value());

        // Act
        await storage.saveCsrfToken(serverId, token);

        // Assert
        verify(mockSecureStorage.set(key, token)).called(1);
      });

      test('Returns failure when saving CSRF token fails', () async {
        // Arrange
        const serverId = 'server123';
        const token = 'abc123xyz';
        const key = 'server123_csrf_token';
        final exception = Exception('Storage error');

        when(mockSecureStorage.set(key, token)).thenThrow(exception);

        // Act
        final result = await storage.saveCsrfToken(serverId, token);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Storage error'));
      });

      test('Returns failure when debugPrint fails', () async {
        // Arrange
        const serverId = 'server123';
        final cookies = [
          Cookie('session', 'abc123')
            ..domain = 'example.com'
            ..path = '/',
        ];
        final exception = Exception('Storage error');

        final expectedData = [
          {
            'name': 'session',
            'value': 'abc123',
            'domain': 'example.com',
            'path': '/',
          },
        ];

        when(
          mockSecureStorage.set(serverId, expectedData),
        ).thenThrow(exception);

        // Act
        final result = await storage.saveSessionCookies(serverId, cookies);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Storage error'));
      });
    });

    group('loadCsrfToken', () {
      test('Successfully loads existing CSRF token', () async {
        // Arrange
        const serverId = 'server123';
        const token = 'abc123xyz';
        const key = 'server123_csrf_token';

        when(mockSecureStorage.get(key)).thenAnswer((_) async => token);

        // Act
        final result = await storage.loadCsrfToken(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(token));
      });

      test('Returns null when no CSRF token exists for server', () async {
        // Arrange
        const serverId = 'nonexistent';
        const key = 'nonexistent_csrf_token';

        when(mockSecureStorage.get(key)).thenAnswer((_) async => null);

        // Act
        final result = await storage.loadCsrfToken(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });

      test('Returns null when stored data is not a string', () async {
        // Arrange
        const serverId = 'notstring';
        const key = 'notstring_csrf_token';
        const storedData = 123;

        when(mockSecureStorage.get(key)).thenAnswer((_) async => storedData);

        // Act
        final result = await storage.loadCsrfToken(serverId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });

      test('Returns failure when loading CSRF token fails', () async {
        // Arrange
        const serverId = 'server123';
        const key = 'server123_csrf_token';
        final exception = Exception('Storage error');

        when(mockSecureStorage.get(key)).thenThrow(exception);

        // Act
        final result = await storage.loadCsrfToken(serverId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Storage error'));
      });

      test('Returns failure when loading session cookies fails', () async {
        // Arrange
        const serverId = 'server123';
        final exception = Exception('Storage error');

        when(mockSecureStorage.get(serverId)).thenThrow(exception);

        // Act
        final result = await storage.loadSessionCookies(serverId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Storage error'));
      });
    });

    group('deleteCsrfToken', () {
      test('Successfully deletes CSRF token', () async {
        // Arrange
        const serverId = 'server123';
        const key = 'server123_csrf_token';

        when(
          mockSecureStorage.delete(key),
        ).thenAnswer((_) async => Future.value());

        // Act
        await storage.deleteCsrfToken(serverId);

        // Assert
        verify(mockSecureStorage.delete(key)).called(1);
      });

      test('Returns failure when deleting CSRF token fails', () async {
        // Arrange
        const serverId = 'server123';
        const key = 'server123_csrf_token';
        final exception = Exception('Storage error');

        when(mockSecureStorage.delete(key)).thenThrow(exception);

        // Act
        final result = await storage.deleteCsrfToken(serverId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Storage error'));
      });

      test('Returns failure when debugPrint fails during delete', () async {
        // Arrange
        const serverId = 'server123';
        const key = 'server123_csrf_token';
        final exception = Exception('Storage error');

        when(mockSecureStorage.delete(key)).thenThrow(exception);

        // Act
        final result = await storage.deleteCsrfToken(serverId);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Storage error'));
      });
    });

    group('Error Handling', () {
      test('saveSessionCookies returns failure when storage fails', () async {
        // Arrange
        const serverId = 'server123';
        final cookies = [
          Cookie('session', 'abc123')
            ..domain = 'example.com'
            ..path = '/',
        ];
        final exception = Exception('Storage error');

        final expectedData = [
          {
            'name': 'session',
            'value': 'abc123',
            'domain': 'example.com',
            'path': '/',
          },
        ];

        when(
          mockSecureStorage.set(serverId, expectedData),
        ).thenThrow(exception);

        // Act
        final result = await storage.saveSessionCookies(serverId, cookies);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Storage error'));
      });

      test(
        'loadSessionCookies returns failure when storage throws exception',
        () async {
          // Arrange
          const serverId = 'server123';
          final exception = Exception('Storage error');

          when(mockSecureStorage.get(serverId)).thenThrow(exception);

          // Act
          final result = await storage.loadSessionCookies(serverId);

          // Assert
          expect(result.isFailure, isTrue);
          expect(result.error, contains('Storage error'));
        },
      );
    });

    group('Default Instance Factory', () {
      test('Creates ConnectionStorage with proper configuration', () async {
        // Arrange
        final mockFlutterSecureStorage = MockFlutterSecureStorage();

        // Act
        final storage = ConnectionStorage.defaultInstance(
          mockFlutterSecureStorage,
        );

        // Assert
        expect(storage, isNotNull);
        expect(storage, isA<ConnectionStorage>());
      });
    });
  });
}
