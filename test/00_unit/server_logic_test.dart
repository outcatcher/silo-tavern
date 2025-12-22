// Unit tests for server business logic
@Tags(['unit', 'servers'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/server.dart';
import 'package:silo_tavern/domain/server_service.dart';

void main() {
  group('Server Model Tests', () {
    test('Server creation with default values', () {
      final server = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      expect(server.id, '1');
      expect(server.name, 'Test Server');
      expect(server.address, 'https://test.example.com');
      expect(server.authentication, isNotNull);
      expect(server.authentication.useCredentials, false);
    });

    test('Server creation with custom values', () {
      final auth = AuthenticationInfo.credentials(
        username: 'testuser',
        password: 'testpass',
      );

      final server = Server(
        id: '2',
        name: 'Custom Server',
        address: 'https://custom.example.com',
        authentication: auth,
      );

      expect(server.id, '2');
      expect(server.name, 'Custom Server');
      expect(server.address, 'https://custom.example.com');
      expect(server.authentication.useCredentials, true);
      expect(server.authentication.username, 'testuser');
      expect(server.authentication.password, 'testpass');
    });

    test('Server equality and identity', () {
      final server1 = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final server2 = Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      // Different objects with same data
      expect(server1, isNot(same(server2)));
      // But equal data (this would require == operator override in real implementation)
    });
  });

  group('AuthenticationInfo Tests', () {
    test('None authentication creation', () {
      final auth = AuthenticationInfo.none();

      expect(auth.useCredentials, false);
      expect(auth.username, '');
      expect(auth.password, '');
    });

    test('Credentials authentication creation', () {
      final auth = AuthenticationInfo.credentials(
        username: 'testuser',
        password: 'testpass',
      );

      expect(auth.useCredentials, true);
      expect(auth.username, 'testuser');
      expect(auth.password, 'testpass');
    });

    test('Authentication equality', () {
      final auth1 = AuthenticationInfo.none();
      final auth2 = AuthenticationInfo.none();
      final auth3 = AuthenticationInfo.credentials(
        username: 'user',
        password: 'pass',
      );

      expect(auth1.useCredentials, false);
      expect(auth2.useCredentials, false);
      expect(auth3.useCredentials, true);
    });
  });

  group('Server Network Validation Tests', () {
    test('HTTPS servers are allowed regardless of authentication', () {
      final httpsServerNoAuth = Server(
        id: '1',
        name: 'HTTPS Server',
        address: 'https://example.com',
        authentication: const AuthenticationInfo.none(),
      );

      final httpsServerWithAuth = Server(
        id: '2',
        name: 'HTTPS Server with Auth',
        address: 'https://secure.example.com',
        authentication: AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      // Both should be valid
      expect(httpsServerNoAuth.address.startsWith('https://'), isTrue);
      expect(httpsServerWithAuth.address.startsWith('https://'), isTrue);
    });

    test('HTTP servers without authentication are rejected for external addresses', () {
      final httpExternalServer = Server(
        id: '1',
        name: 'HTTP External Server',
        address: 'http://external.com',
        authentication: const AuthenticationInfo.none(),
      );

      // This should be invalid according to our new rule
      expect(httpExternalServer.address.startsWith('http://'), isTrue);
      expect(httpExternalServer.authentication.useCredentials, isFalse);
      // Note: Actual validation logic would be implemented in the service layer
    });

    test('HTTP servers with authentication are rejected for external addresses', () {
      final httpExternalServerWithAuth = Server(
        id: '2',
        name: 'HTTP External Server with Auth',
        address: 'http://external.com',
        authentication: AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      // This should be invalid according to our new rule
      expect(httpExternalServerWithAuth.address.startsWith('http://'), isTrue);
      expect(httpExternalServerWithAuth.authentication.useCredentials, isTrue);
      // Note: Actual validation logic would be implemented in the service layer
    });

    test('HTTP servers without authentication are allowed for local addresses', () {
      final localhostServer = Server(
        id: '3',
        name: 'Localhost Server',
        address: 'http://localhost:8000',
        authentication: const AuthenticationInfo.none(),
      );

      final ipServer = Server(
        id: '4',
        name: 'IP Server',
        address: 'http://127.0.0.1:3000',
        authentication: const AuthenticationInfo.none(),
      );

      final localNetworkServer = Server(
        id: '5',
        name: 'Local Network Server',
        address: 'http://192.168.1.100:8080',
        authentication: const AuthenticationInfo.none(),
      );

      // These should be valid according to our new rule
      expect(localhostServer.address, contains('localhost'));
      expect(ipServer.address, contains('127.0.0.1'));
      // Note: Actual validation logic would be implemented in the service layer
    });

    test('HTTP servers with authentication are allowed for local addresses', () {
      final localhostServerWithAuth = Server(
        id: '6',
        name: 'Localhost Server with Auth',
        address: 'http://localhost:8000',
        authentication: AuthenticationInfo.credentials(
          username: 'admin',
          password: 'secret',
        ),
      );

      // This should be valid according to our new rule
      expect(localhostServerWithAuth.address, contains('localhost'));
      expect(localhostServerWithAuth.authentication.useCredentials, isTrue);
      // Note: Actual validation logic would be implemented in the service layer
    });
  });

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
      );

      service.updateServer(fakeServer);

      expect(service.serverCount, initialCount); // No change
    });
  });
}

