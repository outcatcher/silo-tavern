// Unit tests for ServerService
@Tags(['unit', 'servers'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/server.dart';
import 'package:silo_tavern/domain/server_service.dart';

void main() {
  group('ServerService Tests', () {
    late ServerService service;

    setUp(() {
      service = ServerService();
    });

    test('Initial server list is populated', () {
      expect(service.serverCount, greaterThan(0));
      expect(service.servers, isNotEmpty);
    });

    test('Get servers returns immutable list', () {
      final servers1 = service.servers;
      final servers2 = service.servers;

      expect(servers1, isNot(same(servers2))); // Different instances
      expect(servers1.length, servers2.length); // Same content
    });

    test('Add server increases server count', () {
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

      service.addServer(newServer);

      expect(service.serverCount, initialCount + 1);
      expect(service.findServerById('new-server'), isNotNull);
    });

    test('Update server modifies existing server', () {
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

      service.updateServer(updatedServer);

      final foundServer = service.findServerById(originalId);
      expect(foundServer, isNotNull);
      expect(foundServer!.name, 'Updated Name');
      expect(foundServer.name, isNot(originalName));
      expect(foundServer.id, originalId); // ID preserved
    });

    test('Remove server decreases server count', () {
      final initialCount = service.serverCount;
      final firstServerId = service.servers[0].id;

      service.removeServer(firstServerId);

      expect(service.serverCount, initialCount - 1);
      expect(service.findServerById(firstServerId), isNull);
    });

    test('Find server by ID returns correct server', () {
      final firstServer = service.servers[0];
      final foundServer = service.findServerById(firstServer.id);

      expect(foundServer, isNotNull);
      expect(foundServer!.id, firstServer.id);
      expect(foundServer.name, firstServer.name);
    });

    test('Find non-existent server returns null', () {
      final foundServer = service.findServerById('non-existent-id');
      expect(foundServer, isNull);
    });

    test('Update non-existent server does nothing', () {
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

      service.updateServer(fakeServer);

      expect(service.serverCount, initialCount); // No change
    });

    group('ServerService Negative Validation Tests', () {
      test('Adding remote HTTPS server without authentication fails', () {
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

      test('Adding remote HTTP server with authentication fails', () {
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

      test('Adding remote HTTP server without authentication fails', () {
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

      test('Updating server to forbidden configuration fails', () {
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
        service.addServer(validServer);
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

      test('Updating server to HTTPS without auth fails', () {
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
        service.addServer(validServer);
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

      test('Adding server with duplicate ID fails', () {
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

      test('Removing non-existent server does nothing', () {
        final initialCount = service.serverCount;

        service.removeServer('non-existent-id');

        expect(service.serverCount, initialCount);
      });

      test('Finding non-existent server returns null', () {
        expect(service.findServerById('non-existent-id'), isNull);
      });

      test(
        'Adding remote HTTPS server without authentication throws correct error message',
        () {
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
                      'Remote servers must use HTTPS and authentication',
                    ),
              ),
            ),
          );
        },
      );

      test(
        'Adding remote HTTP server with authentication throws correct error message',
        () {
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
                      'Remote servers must use HTTPS and authentication',
                    ),
              ),
            ),
          );
        },
      );

      test(
        'Updating server to forbidden configuration throws correct error message',
        () {
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
          service.addServer(validServer);

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
                      'Remote servers must use HTTPS and authentication',
                    ),
              ),
            ),
          );
        },
      );
    });
  });
}
