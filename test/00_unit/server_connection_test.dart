// Unit tests for ServerConnection
@Tags(['unit', 'servers', 'connection'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/services/servers/storage.dart';

import 'server_connection_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerStorage>(), MockSpec<ConnectionDomain>()])
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
          ),
          Server(
            id: '2',
            name: 'Local Server',
            address: 'http://localhost:8080',
          ),
        ],
      );
      when(storage.getServer(any)).thenAnswer(
        (_) async => Server(
          id: '1',
          name: 'Test Server 1',
          address: 'https://test1.example.com',
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
  });
}
