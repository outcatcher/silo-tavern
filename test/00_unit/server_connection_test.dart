// Unit tests for ServerConnection
@Tags(['unit', 'servers', 'connection'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/repository.dart';
import 'package:silo_tavern/common/result.dart';

import 'server_connection_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerRepository>(), MockSpec<ConnectionDomain>()])
void main() {
  group('ServerConnection Tests', () {
    late MockServerRepository repository;
    late MockConnectionDomain connectionDomain;
    late ServerDomain domain;

    setUp(() async {
      repository = MockServerRepository();
      connectionDomain = MockConnectionDomain();

      // Mock the repository methods to return some initial servers
      when(repository.getAll()).thenAnswer(
        (_) async => Result.success([
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
        ]),
      );
      when(repository.getById(any)).thenAnswer(
        (_) async => Result.success(Server(
          id: '1',
          name: 'Test Server 1',
          address: 'https://test1.example.com',
        )),
      );
      when(repository.create(any)).thenAnswer((_) async => Result.success(null));
      when(repository.update(any)).thenAnswer((_) async => Result.success(null));
      when(repository.delete(any)).thenAnswer((_) async => Result.success(null));

      domain = ServerDomain(
        ServerOptions(repository, connectionDomain: connectionDomain),
      );

      // Initialize the domain
      await domain.initialize();
    });
  });
}
