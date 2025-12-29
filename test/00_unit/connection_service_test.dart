import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/services/connection/service.dart';
import 'package:silo_tavern/domain/connection/models.dart';

import 'connection_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<http.Client>(),
  MockSpec<FlutterSecureStorage>(),
])
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
        verify(httpClient.get(Uri.parse('https://test.example.com/csrf-token'))).called(1);
      });

      test('Obtain CSRF token fails with HTTP error', () async {
        // Arrange
        const serverUrl = 'https://test.example.com';
        
        when(
          httpClient.get(Uri.parse('https://test.example.com/csrf-token')),
        ).thenAnswer(
          (_) async => http.Response('Error', 500),
        );

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
        ).thenAnswer(
          (_) async => http.Response('', 200),
        );

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
        ).thenAnswer(
          (_) async => http.Response('Unauthorized', 401),
        );

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
  });
}