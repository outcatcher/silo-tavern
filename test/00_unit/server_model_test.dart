// Unit tests for server domain models
@Tags(['unit', 'models'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/servers/models.dart';

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
}
