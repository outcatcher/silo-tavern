// Unit tests for ConnectionDomain
@Tags(['unit', 'connection'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/connection/models.dart';
import 'package:silo_tavern/domain/servers/models.dart' as server_models;
import 'package:silo_tavern/services/connection/models/models.dart';
import 'package:silo_tavern/services/connection/network.dart';
import 'package:silo_tavern/services/connection/storage.dart';

import 'connection_domain_test.mocks.dart';

class FakeSessionFactory implements ConnectionSessionFactory {
  final Map<String, ConnectionSessionInterface> sessions = {};

  @override
  ConnectionSessionInterface create(
    String server, {
    List<Cookie>? cookies = const [],
  }) {
    return sessions.putIfAbsent(server, () => MockConnectionSessionInterface());
  }
}

@GenerateNiceMocks([
  MockSpec<ConnectionSessionInterface>(),
  MockSpec<ConnectionStorage>(),
])
void main() {
  group('ConnectionDomain Tests', () {
    late MockConnectionStorage secureStorage;
    late FakeSessionFactory sessionFactory;
    late ConnectionDomain domain;

    setUp(() {
      secureStorage = MockConnectionStorage();
      sessionFactory = FakeSessionFactory();

      domain = ConnectionDomain(
        sessionFactory: sessionFactory,
        secureStorage: secureStorage,
      );
    });

    test('Connect to server with existing session cookies', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final existingCookies = [Cookie('session', 'abc123')];

      when(
        secureStorage.loadSessionCookies('1'),
      ).thenAnswer((_) async => existingCookies);
      when(
        secureStorage.loadCsrfToken('1'),
      ).thenAnswer((_) async => null);
      when(
        secureStorage.loadCsrfToken('1'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      // Verify that session cookies were loaded but no CSRF token or auth was requested
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verifyNever(
        secureStorage.saveSessionCookies(any, any),
      ); // No saving should happen
    });

    test('Connect to server successfully with credentials', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final session1 = MockConnectionSessionInterface();

      sessionFactory.sessions[server.address] = session1;

      when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => null);
      when(secureStorage.loadCsrfToken('1')).thenAnswer((_) async => null);
      when(session1.obtainCsrfToken()).thenAnswer((_) async {});
      when(session1.authenticate(any)).thenAnswer((_) async {});
      when(session1.getCsrfToken()).thenAnswer((_) => 'test-token');

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      // Verify interactions
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verify(session1.obtainCsrfToken()).called(1);
      verifyNever(session1.authenticate(any)); // Authentication is no longer supported
    });

    test('Connect to server successfully without credentials', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final session1 = MockConnectionSessionInterface();

      sessionFactory.sessions[server.address] = session1;

      when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => null);
      when(secureStorage.loadCsrfToken('1')).thenAnswer((_) async => null);
      when(session1.obtainCsrfToken()).thenAnswer((_) async {});
      when(session1.getCsrfToken()).thenAnswer((_) => 'test-token');

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      // Verify interactions
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verify(session1.obtainCsrfToken()).called(1);
      verifyNever(
        session1.authenticate(any),
      ); // Should not be called for no credentials
    });

    test('Connect to server fails when CSRF token request fails', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final session1 = MockConnectionSessionInterface();

      sessionFactory.sessions[server.address] = session1;

      when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => null);
      when(secureStorage.loadCsrfToken('1')).thenAnswer((_) async => null);
      when(session1.obtainCsrfToken()).thenThrow(Exception('Network error'));

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Network error'));

      // Verify interactions
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verify(session1.obtainCsrfToken()).called(1);
      verifyNever(
        session1.authenticate(any),
      ); // Should not be called if CSRF fails
    });

    test('Connect to server fails when authentication fails', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final session1 = MockConnectionSessionInterface();

      sessionFactory.sessions[server.address] = session1;

      when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => null);
      when(secureStorage.loadCsrfToken('1')).thenAnswer((_) async => null);
      when(session1.obtainCsrfToken()).thenAnswer((_) async {});
      when(session1.getCsrfToken()).thenAnswer((_) => 'test-token');

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue); // Authentication is no longer supported, so connection should succeed
      expect(result.errorMessage, isNull);

      // Verify interactions
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verify(session1.obtainCsrfToken()).called(1);
      verifyNever(session1.authenticate(any)); // Authentication is no longer supported
    });

    test('Get client returns session for connected server', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final session1 = MockConnectionSessionInterface();

      sessionFactory.sessions[server.address] = session1;

      when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => null);
      when(secureStorage.loadCsrfToken('1')).thenAnswer((_) async => null);
      when(session1.obtainCsrfToken()).thenAnswer((_) async {});
      when(session1.getCsrfToken()).thenAnswer((_) => 'test-token');

      // Connect to server first to create the session
      await domain.connectToServer(server);

      // Act
      final client = domain.getClient('1');

      // Assert
      expect(client, isNotNull);
      expect(client, equals(session1));
    });

    test('Get client returns null for non-connected server', () async {
      // Act
      final client = domain.getClient('nonexistent');

      // Assert
      expect(client, isNull);
    });

    test(
      'Default instance factory creates domain with proper dependencies',
      () async {
        // Note: We can't actually instantiate FlutterSecureStorage in tests
        // but we can at least verify the method exists and compiles
        expect(ConnectionDomain.defaultInstance, isA<Function>());
      },
    );
  });
}
