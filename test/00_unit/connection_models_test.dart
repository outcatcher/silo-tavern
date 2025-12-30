// Unit tests for connection domain models
@Tags(['unit', 'connection', 'models'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/connection/models.dart';
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

  group('ConnectionResult Tests', () {
    test('ConnectionResult success creation', () {
      final result = ConnectionResult.success();

      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('ConnectionResult failure creation', () {
      final result = ConnectionResult.failure('Connection failed');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Connection failed');
    });

    test('ConnectionResult equality', () {
      final success1 = ConnectionResult.success();
      final success2 = ConnectionResult.success();
      final failure1 = ConnectionResult.failure('Error 1');
      final failure2 = ConnectionResult.failure('Error 1');
      final failure3 = ConnectionResult.failure('Error 2');

      expect(success1, equals(success2));
      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
      expect(success1, isNot(equals(failure1)));
    });

    test('ConnectionResult hash code', () {
      final success1 = ConnectionResult.success();
      final success2 = ConnectionResult.success();
      final failure1 = ConnectionResult.failure('Error');
      final failure2 = ConnectionResult.failure('Error');

      expect(success1.hashCode, equals(success2.hashCode));
      expect(failure1.hashCode, equals(failure2.hashCode));
    });
  });
}
