// Unit tests for ServerConnection
@Tags(['unit', 'servers', 'connection'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/connection/models.dart' as connection_models;
import 'package:silo_tavern/services/servers/storage.dart';

import 'server_connection_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ServerStorage>(),
  MockSpec<ConnectionDomain>(),
])
void main() {
  group('ServerConnection Tests', () {
    late MockServerStorage storage;
    late MockConnectionDomain connectionDomain;
    late ServerDomain domain;

    setUp(() async {
      storage = MockServerStorage();
      connectionDomain = MockConnectionDomain();
      
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
        ServerOptions(storage, connectionDomain: connectionDomain),
      );

      // Initialize the domain
      await domain.initialize();
    });

    test('Connect to server successfully', () async {
      // Arrange
      final server = domain.servers[0];
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async => connection_models.ConnectionResult.success(),
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.server, server);
      expect(result.errorMessage, isNull);
      
      // Verify interactions
      verify(connectionDomain.connectToServer(server)).called(1);
    });

    test('Connect to server with authentication', () async {
      // Arrange
      final server = domain.servers[0]; // Server with credentials
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async => connection_models.ConnectionResult.success(),
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      
      // Verify interactions
      verify(connectionDomain.connectToServer(server)).called(1);
    });

    test('Connect to server without authentication', () async {
      // Arrange
      final server = domain.servers[1]; // Server without credentials
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async => connection_models.ConnectionResult.success(),
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      
      // Verify interactions
      verify(connectionDomain.connectToServer(server)).called(1);
    });

    test('Connect to server fails when connection fails', () async {
      // Arrange
      final server = domain.servers[0];
      when(connectionDomain.connectToServer(any)).thenAnswer(
        (_) async => connection_models.ConnectionResult.failure('Connection failed'),
      );

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.server, server);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('Connection failed'));
      
      // Verify interactions
      verify(connectionDomain.connectToServer(server)).called(1);
    });
  });
}