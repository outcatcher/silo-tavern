import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/connection/models.dart';
import 'package:silo_tavern/services/connection/service.dart';

import 'connection_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<HttpClient>(), MockSpec<FlutterSecureStorage>()])
void main() {
  group('ConnectionService Tests', () {
    late MockClient httpClient;
    late MockFlutterSecureStorage secureStorage;
    late ConnectionService service;

    setUp(() {
      httpClient = MockClient();
      secureStorage = MockFlutterSecureStorage();
      service = ConnectionService(secureStorage, httpClient: httpClient);
    });

    tearDown(() {
      service.close();
    });

    group('CSRF Token Handling', () {
      test('Obtain CSRF token successfully', () async {
        // Arrange
        const serverUrl = 'https://test.example.com';
        const expectedToken = 'abc123xyz';

        when(
          httpClient.get(Uri.parse('https://test.example.com/csrf-token')),
        ).thenAnswer(
          (_) async => http.Response(
            '{"token":"abc123xyz"}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act
        final token = await service.obtainCsrfToken(serverUrl);

        // Assert
        expect(token, expectedToken);
        verify(
          httpClient.get(Uri.parse('https://test.example.com/csrf-token')),
        ).called(1);
      });

      test('Obtain CSRF token fails with HTTP error', () async {
        // Arrange
        const serverUrl = 'https://test.example.com';

        when(
          httpClient.get(Uri.parse('https://test.example.com/csrf-token')),
        ).thenAnswer((_) async => http.Response('Error', 500));

        // Act & Assert
        expect(
          () => service.obtainCsrfToken(serverUrl),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Authentication', () {
      test('Authenticate successfully', () async {
        // Arrange
        const serverUrl = 'https://test.example.com';
        const csrfToken = 'abc123xyz';
        const username = 'testuser';
        const password = 'testpass';

        final credentials = ConnectionCredentials(
          username: username,
          password: password,
        );

        when(
          httpClient.post(
            Uri.parse('https://test.example.com/api/users/login'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'X-CSRF-Token': csrfToken,
            },
            body: '{"handle":"$username","password":"$password"}',
          ),
        ).thenAnswer((_) async => http.Response('', 200));

        // Act & Assert
        expect(
          () => service.authenticate(serverUrl, csrfToken, credentials),
          returnsNormally,
        );
      });

      test('Authenticate fails with HTTP error', () async {
        // Arrange
        const serverUrl = 'https://test.example.com';
        const csrfToken = 'abc123xyz';
        const username = 'testuser';
        const password = 'testpass';

        final credentials = ConnectionCredentials(
          username: username,
          password: password,
        );

        when(
          httpClient.post(
            Uri.parse('https://test.example.com/api/users/login'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('Unauthorized', 401));

        // Act & Assert
        expect(
          () => service.authenticate(serverUrl, csrfToken, credentials),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Credential Caching', () {
      test('Has cached credentials returns correct value', () async {
        // Arrange
        const serverId = 'test-server';

        // Act
        final result = service.hasCachedCredentials(serverId);

        // Assert
        expect(result, isFalse);
      });

      test('Get cached credentials returns correct value', () async {
        // Arrange
        const serverId = 'test-server';

        // Act
        final result = service.getCachedCredentials(serverId);

        // Assert
        expect(result, isNull);
      });

      test('Disconnect clears cached credentials', () async {
        // Arrange
        const serverId = 'test-server';

        // Act
        await service.disconnect(serverId);

        // Assert
        expect(service.hasCachedCredentials(serverId), isFalse);
        expect(service.getCachedCredentials(serverId), isNull);
      });
    });

    group('Cookie Handling', () {
      test('Authenticate stores cookies when present in response', () async {
        // Arrange
        const serverUrl = 'https://test.example.com';
        const csrfToken = 'abc123xyz';
        const username = 'testuser';
        const password = 'testpass';

        final credentials = ConnectionCredentials(
          username: username,
          password: password,
        );

        const cookieHeader =
            'sessionid=abc123; Path=/; HttpOnly, csrftoken=def456; Path=/';

        when(
          httpClient.post(
            Uri.parse('https://test.example.com/api/users/login'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'X-CSRF-Token': csrfToken,
            },
            body: '{"handle":"$username","password":"$password"}',
          ),
        ).thenAnswer(
          (_) async =>
              http.Response('', 200, headers: {'set-cookie': cookieHeader}),
        );

        when(
          secureStorage.write(
            key: 'session_cookies_test.example.com',
            value: '{"sessionid":"abc123","csrftoken":"def456"}',
          ),
        ).thenAnswer((_) async {});

        // Act
        await service.authenticate(serverUrl, csrfToken, credentials);

        // Verify that secure storage was called to save cookies
        verify(
          secureStorage.write(
            key: 'session_cookies_test.example.com',
            value: '{"sessionid":"abc123","csrftoken":"def456"}',
          ),
        ).called(1);
      });

      test('Extract cookies from headers handles single cookie', () async {
        // Arrange
        const cookieHeader = 'sessionid=abc123';
        final headers = {'set-cookie': cookieHeader};

        // Act
        final cookies = service.extractCookiesFromHeaders(headers);

        // Assert
        expect(cookies, hasLength(1));
        expect(cookies['sessionid'], equals('abc123'));
      });

      test('Extract cookies from headers handles multiple cookies', () async {
        // Arrange
        const cookieHeader =
            'sessionid=abc123; Path=/; HttpOnly, csrftoken=def456; Path=/';
        final headers = {'set-cookie': cookieHeader};

        // Act
        final cookies = service.extractCookiesFromHeaders(headers);

        // Assert
        expect(cookies, hasLength(2));
        expect(cookies['sessionid'], equals('abc123'));
        expect(cookies['csrftoken'], equals('def456'));
      });

      test('Extract cookies from headers handles no cookie header', () async {
        // Arrange
        final headers = <String, String>{};

        // Act
        final cookies = service.extractCookiesFromHeaders(headers);

        // Assert
        expect(cookies, isEmpty);
      });
    });

    group('Constructor', () {
      test('Creates instance with default http client', () async {
        // Act
        final service = ConnectionService(secureStorage);

        // Assert
        expect(service, isNotNull);

        // Cleanup
        service.close();
      });
    });
  });
}
