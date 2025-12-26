// Unit tests for ServerService
@Tags(['unit', 'servers'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/server.dart';
import 'package:silo_tavern/domain/server_service.dart';
import 'package:silo_tavern/services/server_storage.dart';

import 'server_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerStorage>()])
void main() {
  group('ServerService Tests', () {
    late MockServerStorage storage;
    late ServerService service;

    setUp(() async {
      storage = MockServerStorage();
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

      service = ServerService(ServerOptions(storage));

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
        authentication: AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
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
        authentication: originalServer.authentication,
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

    test('Update non-existent server throws exception', () async {
      final initialCount = service.serverCount;
      final fakeServer = Server(
        id: 'fake-id',
        name: 'Fake Server',
        address: 'https://fake.example.com',
        authentication: AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      expect(
        () => service.updateServer(fakeServer),
        throwsA(
          predicate(
            (e) => e is ArgumentError && e.message.contains('does\'t exist'),
          ),
        ),
      );

      expect(service.serverCount, initialCount); // No change
    });

    group('ServerService Negative Validation Tests', () {
      test('Adding remote HTTPS server without authentication fails', () async {
        final httpsRemoteNoAuthServer = Server(
          id: 'https-remote-no-auth-server',
          name: 'HTTPS Remote No Auth Server',
          address: 'https://external.com',
          authentication: const AuthenticationInfo.none(),
        );

        expect(
          () => service.addServer(httpsRemoteNoAuthServer),
          throwsA(isA<ArgumentError>()),
        );
        expect(service.findServerById('https-remote-no-auth-server'), isNull);
      });

      test('Adding remote HTTP server with authentication fails', () async {
        final httpRemoteWithAuthServer = Server(
          id: 'http-remote-with-auth-server',
          name: 'HTTP Remote With Auth Server',
          address: 'http://external.com',
          authentication: AuthenticationInfo.credentials(
            username: 'user',
            password: 'pass',
          ),
        );

        expect(
          () => service.addServer(httpRemoteWithAuthServer),
          throwsA(isA<ArgumentError>()),
        );
        expect(service.findServerById('http-remote-with-auth-server'), isNull);
      });

      test('Adding remote HTTP server without authentication fails', () async {
        final httpRemoteNoAuthServer = Server(
          id: 'http-remote-no-auth-server',
          name: 'HTTP Remote No Auth Server',
          address: 'http://external.com',
          authentication: const AuthenticationInfo.none(),
        );

        expect(
          () => service.addServer(httpRemoteNoAuthServer),
          throwsA(isA<ArgumentError>()),
        );
        expect(service.findServerById('http-remote-no-auth-server'), isNull);
      });

      test('Updating server to forbidden configuration fails', () async {
        // First add a valid server
        final validServer = Server(
          id: 'valid-server',
          name: 'Valid Server',
          address: 'https://example.com',
          authentication: AuthenticationInfo.credentials(
            username: 'user',
            password: 'pass',
          ),
        );
        await service.addServer(validServer);
        expect(service.findServerById('valid-server'), isNotNull);

        // Try to update it to an invalid configuration (HTTP without auth)
        final invalidServer = Server(
          id: 'valid-server',
          name: 'Invalid Server',
          address: 'http://external.com',
          authentication: const AuthenticationInfo.none(),
        );

        expect(
          () => service.updateServer(invalidServer),
          throwsA(isA<ArgumentError>()),
        );

        // Original server should still exist
        expect(service.findServerById('valid-server'), isNotNull);
        expect(
          service.findServerById('valid-server')!.address,
          'https://example.com',
        );
      });

      test('Updating server to HTTPS without auth fails', () async {
        // First add a valid server
        final validServer = Server(
          id: 'valid-server-2',
          name: 'Valid Server 2',
          address: 'https://example.com',
          authentication: AuthenticationInfo.credentials(
            username: 'user',
            password: 'pass',
          ),
        );
        await service.addServer(validServer);
        expect(service.findServerById('valid-server-2'), isNotNull);

        // Try to update it to HTTPS without authentication
        final invalidServer = Server(
          id: 'valid-server-2',
          name: 'Invalid Server 2',
          address: 'https://external.com',
          authentication: const AuthenticationInfo.none(),
        );

        expect(
          () => service.updateServer(invalidServer),
          throwsA(isA<ArgumentError>()),
        );

        // Original server should still exist
        expect(service.findServerById('valid-server-2'), isNotNull);
        expect(
          service
              .findServerById('valid-server-2')!
              .authentication
              .useCredentials,
          isTrue,
        );
      });

      test('Adding server with duplicate ID fails', () async {
        final server1 = Server(
          id: 'duplicate-id',
          name: 'Server 1',
          address: 'https://example.com',
          authentication: AuthenticationInfo.credentials(
            username: 'user',
            password: 'pass',
          ),
        );

        final server2 = Server(
          id: 'duplicate-id',
          name: 'Server 2',
          address: 'https://example2.com',
          authentication: AuthenticationInfo.credentials(
            username: 'user',
            password: 'pass',
          ),
        );

        // First server should be added successfully
        expect(() => service.addServer(server1), returnsNormally);
        expect(service.findServerById('duplicate-id'), isNotNull);

        // Second server with same ID should fail
        expect(() => service.addServer(server2), throwsA(isA<ArgumentError>()));

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
        'Adding remote HTTPS server without authentication throws correct error message',
        () async {
          final httpsRemoteNoAuthServer = Server(
            id: 'https-remote-no-auth-server',
            name: 'HTTPS Remote No Auth Server',
            address: 'https://external.com',
            authentication: const AuthenticationInfo.none(),
          );

          expect(
            () => service.addServer(httpsRemoteNoAuthServer),
            throwsA(
              predicate(
                (e) =>
                    e is ArgumentError &&
                    e.message.contains(
                      'Authentication must be used for external servers',
                    ),
              ),
            ),
          );
        },
      );

      test(
        'Adding remote HTTP server with authentication throws correct error message',
        () async {
          final httpRemoteWithAuthServer = Server(
            id: 'http-remote-with-auth-server',
            name: 'HTTP Remote With Auth Server',
            address: 'http://external.com',
            authentication: AuthenticationInfo.credentials(
              username: 'user',
              password: 'pass',
            ),
          );

          expect(
            () => service.addServer(httpRemoteWithAuthServer),
            throwsA(
              predicate(
                (e) =>
                    e is ArgumentError &&
                    e.message.contains(
                      'HTTPS must be used for external servers',
                    ),
              ),
            ),
          );
        },
      );

      test(
        'Updating server to forbidden configuration throws correct error message',
        () async {
          // First add a valid server
          final validServer = Server(
            id: 'valid-server-error',
            name: 'Valid Server',
            address: 'https://example.com',
            authentication: AuthenticationInfo.credentials(
              username: 'user',
              password: 'pass',
            ),
          );
          await service.addServer(validServer);

          // Try to update it to an invalid configuration
          final invalidServer = Server(
            id: 'valid-server-error',
            name: 'Invalid Server',
            address: 'http://external.com',
            authentication: const AuthenticationInfo.none(),
          );

          expect(
            () => service.updateServer(invalidServer),
            throwsA(
              predicate(
                (e) =>
                    e is ArgumentError &&
                    e.message.contains(
                      'HTTPS must be used for external servers',
                    ),
              ),
            ),
          );
        },
      );
    });
  });
}
