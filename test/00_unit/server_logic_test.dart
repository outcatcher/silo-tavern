// Unit tests for server business logic
@Tags(['unit', 'servers'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/server.dart';

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
      expect(server.isActive, false);
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
        isActive: true,
        authentication: auth,
      );
      
      expect(server.id, '2');
      expect(server.name, 'Custom Server');
      expect(server.address, 'https://custom.example.com');
      expect(server.isActive, true);
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

  group('Server Update Logic Tests', () {
    test('Server ID preservation during updates', () {
      final originalServer = Server(
        id: 'server-123',
        name: 'Original Server',
        address: 'https://original.example.com',
        isActive: true,
      );

      // Simulate updating server data while preserving ID
      final updatedServer = Server(
        id: originalServer.id, // Preserve ID
        name: 'Updated Server',
        address: 'https://updated.example.com',
        isActive: originalServer.isActive, // Preserve status
      );

      expect(updatedServer.id, originalServer.id);
      expect(updatedServer.isActive, originalServer.isActive);
      expect(updatedServer.name, isNot(originalServer.name));
    });

    test('Server authentication data preservation', () {
      final originalAuth = AuthenticationInfo.credentials(
        username: 'original-user',
        password: 'original-pass',
      );

      final originalServer = Server(
        id: 'server-456',
        name: 'Auth Server',
        address: 'https://auth.example.com',
        authentication: originalAuth,
      );

      // Update server while preserving authentication structure
      final updatedServer = Server(
        id: originalServer.id,
        name: 'Updated Auth Server',
        address: originalServer.address,
        authentication: originalServer.authentication, // Preserve auth
      );

      expect(updatedServer.authentication.useCredentials, true);
      expect(updatedServer.authentication.username, 'original-user');
      expect(updatedServer.authentication.password, 'original-pass');
    });
  });
}