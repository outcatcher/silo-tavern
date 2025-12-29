// Unit tests for ServerConnection
@Tags(['unit', 'servers', 'connection'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/services/connection/service.dart';
import 'package:silo_tavern/services/servers/storage.dart';

import 'server_connection_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ServerStorage>(),
  MockSpec<ServerConnectionService>(),
])
void main() {
  group('ServerConnection Tests', () {
    late MockServerStorage storage;
    late MockServerConnectionService connectionService;
    late ServerDomain domain;

    setUp(() async {
      storage = MockServerStorage();
      connectionService = MockServerConnectionService();
      
      // Mock the storage methods to return some initial servers
      when(storage.listServers()).thenAnswer(
        (_) async => [
          Server(
            id: '1',
            name: 'Test Server 1',
            address: 'https://test1.example.com',
            authentication: AuthenticationInfo.credentials(
              username: 'user1',
              password: 'pass1',
            ),
          ),
          Server(
            id: '2',
            name: 'Local Server',
            address: 'http://localhost:8080',
            authentication: const AuthenticationInfo.none(),
          ),
        ],
      );
      when(storage.getServer(any)).thenAnswer(
        (_) async => Server(
          id: '1',
          name: 'Test Server 1',
          address: 'https://test1.example.com',
          authentication: AuthenticationInfo.credentials(
            username: 'user1',
            password: 'pass1',
          ),
        ),
      );
      when(storage.createServer(any)).thenAnswer((_) async {});
      when(storage.updateServer(any)).thenAnswer((_) async {});
      when(storage.deleteServer(any)).thenAnswer((_) async {});

      domain = ServerDomain(
        ServerOptions(storage, connectionService: connectionService),
      );

      // Initialize the domain
      await domain.initialize();
    });

    test('Connect to server successfully', () async {
      // Arrange
      final server = domain.servers[0];
      when(connectionService.getCsrfToken(any)).thenAnswer(
        (_) async => 'mock-csrf-token',
      );
      when(connectionService.authenticate(any, any, any, any)).thenAnswer(
        (_) async {},
      );
      when(connectionService.storeTokens(any, any)).thenAnswer(
        (_) async {},
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.server, server);
      expect(result.errorMessage, isNull);
      
      // Verify interactions
      verify(connectionService.getCsrfToken(server.address)).called(1);
      verify(connectionService.storeTokens(server.id, any)).called(1);
    });

    test('Connect to server with authentication', () async {
      // Arrange
      final server = domain.servers[0]; // Server with credentials
      when(connectionService.getCsrfToken(any)).thenAnswer(
        (_) async => 'mock-csrf-token',
      );
      when(connectionService.authenticate(any, any, any, any)).thenAnswer(
        (_) async {},
      );
      when(connectionService.storeTokens(any, any)).thenAnswer(
        (_) async {},
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      
      // Verify authentication was called
      verify(connectionService.getCsrfToken(server.address)).called(1);
      verify(connectionService.authenticate(
        server.address,
        'mock-csrf-token',
        server.authentication.username,
        server.authentication.password,
      )).called(1);
      verify(connectionService.storeTokens(server.id, any)).called(1);
    });

    test('Connect to server without authentication', () async {
      // Arrange
      final server = domain.servers[1]; // Server without credentials
      when(connectionService.getCsrfToken(any)).thenAnswer(
        (_) async => 'mock-csrf-token',
      );
      when(connectionService.storeTokens(any, any)).thenAnswer(
        (_) async {},
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      
      // Verify authentication was NOT called
      verify(connectionService.getCsrfToken(server.address)).called(1);
      verifyNever(connectionService.authenticate(any, any, any, any));
      verify(connectionService.storeTokens(server.id, any)).called(1);
    });

    test('Connect to server fails when CSRF request fails', () async {
      // Arrange
      final server = domain.servers[0];
      when(connectionService.getCsrfToken(any)).thenThrow(
        Exception('Network error'),
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.server, server);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('Network error'));
      
      // Verify authentication was not called
      verify(connectionService.getCsrfToken(server.address)).called(1);
      verifyNever(connectionService.authenticate(any, any, any, any));
      verifyNever(connectionService.storeTokens(any, any));
    });

    test('Connect to server fails when authentication fails', () async {
      // Arrange
      final server = domain.servers[0];
      when(connectionService.getCsrfToken(any)).thenAnswer(
        (_) async => 'mock-csrf-token',
      );
      when(connectionService.authenticate(any, any, any, any)).thenThrow(
        Exception('Authentication failed'),
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.server, server);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('Authentication failed'));
      
      // Verify interactions
      verify(connectionService.getCsrfToken(server.address)).called(1);
      verify(connectionService.authenticate(
        server.address,
        'mock-csrf-token',
        server.authentication.username,
        server.authentication.password,
      )).called(1);
      verifyNever(connectionService.storeTokens(any, any));
    });
  });
}