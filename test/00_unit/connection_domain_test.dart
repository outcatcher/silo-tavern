// Unit tests for ConnectionDomain
@Tags(['unit', 'connection'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/connection/models.dart';
import 'package:silo_tavern/services/connection/service.dart';
import 'package:silo_tavern/domain/servers/models.dart' as server_models;

import 'connection_domain_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ConnectionService>(),
  MockSpec<FlutterSecureStorage>(),
])
void main() {
  group('ConnectionDomain Tests', () {
    late MockConnectionService connectionService;
    late MockFlutterSecureStorage secureStorage;
    late ConnectionDomain domain;

    setUp(() {
      connectionService = MockConnectionService();
      secureStorage = MockFlutterSecureStorage();

      domain = ConnectionDomain(
        ConnectionOptions(
          connectionService: connectionService,
          secureStorage: secureStorage,
        ),
      );
    });

    test('Connect to server successfully', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
        authentication: server_models.AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      when(
        connectionService.obtainCsrfToken(any),
      ).thenAnswer((_) async => 'mock-csrf-token');
      when(
        connectionService.authenticate(any, any, any),
      ).thenAnswer((_) async {});

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      // Verify interactions
      verify(connectionService.obtainCsrfToken(server.address)).called(1);
      verify(
        connectionService.authenticate(
          server.address,
          'mock-csrf-token',
          argThat(
            predicate<ConnectionCredentials>(
              (creds) => creds.username == 'user' && creds.password == 'pass',
            ),
          ),
        ),
      ).called(1);
    });

    test('Connect to server without authentication', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Local Server',
        address: 'http://localhost:8080',
        authentication: const server_models.AuthenticationInfo.none(),
      );

      when(
        connectionService.obtainCsrfToken(any),
      ).thenAnswer((_) async => 'mock-csrf-token');

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);

      // Verify authentication was not called
      verify(connectionService.obtainCsrfToken(server.address)).called(1);
      verifyNever(connectionService.authenticate(any, any, any));
    });

    test('Connect to server with authentication failure', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
        authentication: server_models.AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      when(
        connectionService.obtainCsrfToken(any),
      ).thenAnswer((_) async => 'mock-csrf-token');
      when(
        connectionService.authenticate(any, any, any),
      ).thenThrow(Exception('Authentication failed'));

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Authentication failed'));
    });

    test('Disconnect from server', () async {
      // Arrange
      const serverId = '1';
      when(connectionService.disconnect(any)).thenAnswer((_) async {});

      // Act
      await domain.disconnect(serverId);

      // Assert
      verify(connectionService.disconnect(serverId)).called(1);
    });

    test('Check if connected to server', () async {
      // Arrange
      const serverId = '1';
      when(connectionService.hasCachedCredentials(any)).thenReturn(true);

      // Act
      final isConnected = await domain.isConnected(serverId);

      // Assert
      expect(isConnected, isTrue);
    });

    test('Check if connected to server with no credentials', () async {
      // Arrange
      const serverId = '1';
      when(connectionService.hasCachedCredentials(any)).thenReturn(false);

      // Act
      final isConnected = await domain.isConnected(serverId);

      // Assert
      expect(isConnected, isFalse);
    });

    test('Get authenticated client', () async {
      // Act
      final client = await domain.getAuthenticatedClient(
        '1',
        'https://test.example.com',
      );

      // Assert
      expect(client, isNotNull);
      expect(client.serverId, equals('1'));
      expect(client.baseUrl, equals('https://test.example.com'));
    });

    test('Reauthenticate successfully with cached credentials', () async {
      // Arrange
      const serverId = '1';
      const serverUrl = 'https://test.example.com';

      // Pre-populate credential cache by connecting first
      final server = server_models.Server(
        id: serverId,
        name: 'Test Server',
        address: serverUrl,
        authentication: server_models.AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      when(
        connectionService.obtainCsrfToken(any),
      ).thenAnswer((_) async => 'mock-csrf-token');
      when(
        connectionService.authenticate(any, any, any),
      ).thenAnswer((_) async {});

      // Connect first to populate cache
      await domain.connectToServer(server);

      // Reset mocks for reauthentication
      reset(connectionService);
      when(
        connectionService.hasCachedCredentials(any),
      ).thenReturn(false); // Service doesn't have cached credentials
      when(
        connectionService.obtainCsrfToken(any),
      ).thenAnswer((_) async => 'new-csrf-token');
      when(
        connectionService.authenticate(any, any, any),
      ).thenAnswer((_) async {});

      // Act
      final result = await domain.reauthenticate(serverId, serverUrl);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      // Verify interactions
      verify(connectionService.obtainCsrfToken(serverUrl)).called(1);
      verify(
        connectionService.authenticate(
          serverUrl,
          'new-csrf-token',
          argThat(
            predicate<ConnectionCredentials>(
              (creds) => creds.username == 'user' && creds.password == 'pass',
            ),
          ),
        ),
      ).called(1);
    });

    test('Reauthenticate fails with no cached credentials', () async {
      // Arrange
      const serverId = '1';
      const serverUrl = 'https://test.example.com';

      when(connectionService.hasCachedCredentials(any)).thenReturn(false);

      // Act
      final result = await domain.reauthenticate(serverId, serverUrl);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('No cached credentials'));
    });

    test('Reauthenticate fails when credentials are not in cache', () async {
      // Arrange
      const serverId = '1';
      const serverUrl = 'https://test.example.com';

      when(
        connectionService.hasCachedCredentials(any),
      ).thenReturn(true); // Service has credentials but domain cache doesn't

      // Act
      final result = await domain.reauthenticate(serverId, serverUrl);

      // Assert - this should still fail because the domain cache is empty
      // and we're not mocking the service to return credentials
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('No cached credentials'));
    });

    test('Reauthenticate fails with exception', () async {
      // Arrange
      const serverId = '1';
      const serverUrl = 'https://test.example.com';

      // Pre-populate credential cache by connecting first
      final server = server_models.Server(
        id: serverId,
        name: 'Test Server',
        address: serverUrl,
        authentication: server_models.AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      when(
        connectionService.obtainCsrfToken(any),
      ).thenAnswer((_) async => 'mock-csrf-token');
      when(
        connectionService.authenticate(any, any, any),
      ).thenAnswer((_) async {});

      // Connect first to populate cache
      await domain.connectToServer(server);

      // Reset mocks for reauthentication
      reset(connectionService);
      when(connectionService.hasCachedCredentials(any)).thenReturn(false);
      when(
        connectionService.obtainCsrfToken(any),
      ).thenAnswer((_) async => 'new-csrf-token');
      when(
        connectionService.authenticate(any, any, any),
      ).thenThrow(Exception('Network error'));

      // Act
      final result = await domain.reauthenticate(serverId, serverUrl);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Re-authentication failed'));
      expect(result.errorMessage, contains('Network error'));
    });
  });
}
