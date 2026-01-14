// Unit tests for connection domain models
@Tags(['unit', 'connection', 'models'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:silo_tavern/services/connection/models/models.dart';

void main() {
  group('ConnectionCredentials Tests', () {
    test('ConnectionCredentials creation', () {
      final credentials = ConnectionCredentials(
        handle: 'testuser',
        password: 'testpass',
      );

      expect(credentials.handle, 'testuser');
      expect(credentials.password, 'testpass');
    });

    test('ConnectionCredentials equality', () {
      final credentials1 = ConnectionCredentials(
        handle: 'testuser',
        password: 'testpass',
      );

      final credentials2 = ConnectionCredentials(
        handle: 'testuser',
        password: 'testpass',
      );

      final credentials3 = ConnectionCredentials(
        handle: 'otheruser',
        password: 'otherpass',
      );

      expect(credentials1, equals(credentials2));
      expect(credentials1, isNot(equals(credentials3)));
    });

    test('ConnectionCredentials hash code', () {
      final credentials1 = ConnectionCredentials(
        handle: 'testuser',
        password: 'testpass',
      );

      final credentials2 = ConnectionCredentials(
        handle: 'testuser',
        password: 'testpass',
      );

      expect(credentials1.hashCode, equals(credentials2.hashCode));
    });

    test('ConnectionCredentials toJson', () {
      final credentials = ConnectionCredentials(
        handle: 'testuser',
        password: 'testpass',
      );

      final json = credentials.toJson();

      expect(json, {'handle': 'testuser', 'password': 'testpass'});
    });

    test('ConnectionCredentials fromJson', () {
      final json = {'handle': 'testuser', 'password': 'testpass'};

      final credentials = ConnectionCredentials.fromJson(json);

      expect(credentials.handle, 'testuser');
      expect(credentials.password, 'testpass');
    });
  });

  group('Result Tests', () {
    test('Result success creation', () {
      final result = Result.success('test value');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.value, 'test value');
      expect(result.error, isNull);
    });

    test('Result failure creation', () {
      final result = Result.failure('Connection failed');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.error, 'Connection failed');
      expect(result.value, isNull);
    });

    test('Result equality', () {
      final success1 = Result.success('test');
      final success2 = Result.success('test');
      final failure1 = Result.failure('Error 1');
      final failure2 = Result.failure('Error 1');
      final failure3 = Result.failure('Error 2');

      expect(success1, equals(success2));
      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
      expect(success1, isNot(equals(failure1)));
    });

    test('Result hash code', () {
      final success1 = Result.success('test');
      final success2 = Result.success('test');
      final failure1 = Result.failure('Error');
      final failure2 = Result.failure('Error');

      // Just verify that identical values have the same hash code
      expect(success1.hashCode, equals(success2.hashCode));
      expect(failure1.hashCode, equals(failure2.hashCode));
    });
  });
}
