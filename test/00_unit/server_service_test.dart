// Unit tests for ServerService
@Tags(['unit', 'servers'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';

import 'mocks.mocks.dart';

void main() {
  group('ServerService Tests', () {
    late MockServerStorage storage;
    late MockConnectionDomain connectionDomain;
    late ServerDomain service;

    setUp(() async {
      storage = MockServerStorage();
      connectionDomain = MockConnectionDomain();

      // Mock the storage methods to return some initial servers
      when(storage.getAll()).thenAnswer(
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
      when(storage.getById(any)).thenAnswer(
        (_) async => Server(
          id: '1',
          name: 'Test Server 1',
          address: 'https://test1.example.com',
        ),
      );
      when(storage.create(any)).thenAnswer((_) async {});
      when(storage.update(any)).thenAnswer((_) async {});
      when(storage.delete(any)).thenAnswer((_) async {});

      service = ServerDomain(
        ServerOptions(storage, connectionDomain: connectionDomain),
      );

      // Initialize the service
      await service.initialize();
    });

    test('Initial server list is populated', () async {
      expect(service.serverCount, greaterThan(0));
      expect(service.servers, isNotEmpty);
    });

    test('Get servers returns immutable list', () async {
      final servers1 = service.servers;
      final servers2 = service.servers;

      expect(servers1, isNot(same(servers2))); // Different instances
      expect(servers1.length, servers2.length); // Same content
    });

    test('Add server increases server count', () async {
      final initialCount = service.serverCount;
      final newServer = Server(
        id: 'new-server',
        name: 'New Server',
        address: 'https://new.example.com',
      );

      await service.addServer(newServer);

      expect(service.serverCount, initialCount + 1);
      expect(service.findServerById('new-server'), isNotNull);
    });

    test('Update server modifies existing server', () async {
      // Get first server
      final originalServer = service.servers[0];
      final originalId = originalServer.id;
      final originalName = originalServer.name;

      // Create updated server with same ID but different name
      final updatedServer = Server(
        id: originalId,
        name: 'Updated Name',
        address: originalServer.address,
      );

      await service.updateServer(updatedServer);

      final foundServer = service.findServerById(originalId);
      expect(foundServer, isNotNull);
      expect(foundServer!.name, 'Updated Name');
      expect(foundServer.name, isNot(originalName));
      expect(foundServer.id, originalId); // ID preserved
    });

    test('Remove server decreases server count', () async {
      final initialCount = service.serverCount;
      final firstServerId = service.servers[0].id;

      await service.removeServer(firstServerId);

      expect(service.serverCount, initialCount - 1);
      expect(service.findServerById(firstServerId), isNull);
    });

    test('Find server by ID returns correct server', () async {
      final firstServer = service.servers[0];
      final foundServer = service.findServerById(firstServer.id);

      expect(foundServer, isNotNull);
      expect(foundServer!.id, firstServer.id);
      expect(foundServer.name, firstServer.name);
    });

    test('Find non-existent server returns null', () async {
      final foundServer = service.findServerById('non-existent-id');
      expect(foundServer, isNull);
    });

    test('Update non-existent server returns failure result', () async {
      final initialCount = service.serverCount;
      final fakeServer = Server(
        id: 'fake-id',
        name: 'Fake Server',
        address: 'https://fake.example.com',
      );

      final result = await service.updateServer(fakeServer);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('does\'t exist'));

      expect(service.serverCount, initialCount); // No change
    });

    group('ServerService Negative Validation Tests', () {
      test('Updating server to forbidden configuration fails', () async {
        // First add a valid server
        final validServer = Server(
          id: 'valid-server',
          name: 'Valid Server',
          address: 'https://example.com',
        );
        await service.addServer(validServer);
        expect(service.findServerById('valid-server'), isNotNull);

        // Try to update it to an invalid configuration (HTTP without auth)
        final invalidServer = Server(
          id: 'valid-server',
          name: 'Invalid Server',
          address: 'http://external.com',
        );

        final result = await service.updateServer(invalidServer);
        expect(result.isSuccess, isFalse);
        expect(result.error, 'HTTPS must be used for external servers');

        // Original server should still exist
        expect(service.findServerById('valid-server'), isNotNull);
        expect(
          service.findServerById('valid-server')!.address,
          'https://example.com',
        );
      });

      test('Adding server with duplicate ID fails', () async {
        final server1 = Server(
          id: 'duplicate-id',
          name: 'Server 1',
          address: 'https://example.com',
        );

        final server2 = Server(
          id: 'duplicate-id',
          name: 'Server 2',
          address: 'https://example2.com',
        );

        // First server should be added successfully
        final result1 = await service.addServer(server1);
        expect(result1.isSuccess, isTrue);
        expect(service.findServerById('duplicate-id'), isNotNull);

        // Second server with same ID should fail
        final result2 = await service.addServer(server2);
        expect(result2.isSuccess, isFalse);
        expect(result2.error, contains('already exists'));

        // Original server should still exist
        expect(service.findServerById('duplicate-id'), isNotNull);
        expect(service.findServerById('duplicate-id')!.name, 'Server 1');
      });

      test('Removing non-existent server does nothing', () async {
        final initialCount = service.serverCount;

        await service.removeServer('non-existent-id');

        expect(service.serverCount, initialCount);
      });

      test('Finding non-existent server returns null', () async {
        expect(service.findServerById('non-existent-id'), isNull);
      });

      test(
        'Updating server to forbidden configuration throws correct error message',
        () async {
          // First add a valid server
          final validServer = Server(
            id: 'valid-server-error',
            name: 'Valid Server',
            address: 'https://example.com',
          );
          await service.addServer(validServer);

          // Try to update it to an invalid configuration
          final invalidServer = Server(
            id: 'valid-server-error',
            name: 'Invalid Server',
            address: 'http://external.com',
          );

          final result = await service.updateServer(invalidServer);
          expect(result.isSuccess, isFalse);
          expect(result.error, 'HTTPS must be used for external servers');
        },
      );
    });
  });
}
