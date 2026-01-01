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
      expect(server.status, ServerStatus.ready);
    });

    test('Server creation with custom values', () {
      final server = Server(
        id: '2',
        name: 'Custom Server',
        address: 'https://custom.example.com',
      );

      expect(server.id, '2');
      expect(server.name, 'Custom Server');
      expect(server.address, 'https://custom.example.com');
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
}
