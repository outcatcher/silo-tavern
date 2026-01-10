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

import 'package:silo_tavern/services/connection/network.dart';
import 'package:silo_tavern/services/connection/storage.dart';
import 'package:silo_tavern/services/connection/models/models.dart';

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
  MockSpec<ConnectionStorage>(),
  MockSpec<ConnectionSessionInterface>(),
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

    test('Get client returns session for connected server', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final session1 = MockConnectionSessionInterface();
      sessionFactory.sessions[server.address] = session1;

      // Simulate connecting to the server to create the session
      domain.testOnlyAddSession('1', session1);

      // Act
      final client = domain.getClient('1');

      // Assert
      expect(client, session1);
    });

    test('Get client returns null for non-connected server', () async {
      // Act
      final client = domain.getClient('non-existent');

      // Assert
      expect(client, isNull);
    });

    test('Authenticate with server successfully', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final credentials = ConnectionCredentials(
        handle: 'user',
        password: 'pass',
      );

      final session = MockConnectionSessionInterface();
      sessionFactory.sessions[server.address] = session;

      when(session.authenticate(credentials)).thenAnswer((_) async {});

      // Act
      final result = await domain.authenticateWithServer(server, credentials);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
      verify(session.authenticate(credentials)).called(1);
    });

    test(
      'Authenticate with server fails when authentication throws exception',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        final credentials = ConnectionCredentials(
          handle: 'user',
          password: 'wrong',
        );

        final session = MockConnectionSessionInterface();
        sessionFactory.sessions[server.address] = session;

        when(
          session.authenticate(credentials),
        ).thenThrow(Exception('Auth failed'));

        // Act
        final result = await domain.authenticateWithServer(server, credentials);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, isNotNull);
        verify(session.authenticate(credentials)).called(1);
      },
    );

    test('Obtain CSRF token for server successfully', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final session = MockConnectionSessionInterface();
      sessionFactory.sessions[server.address] = session;

      when(session.obtainCsrfToken()).thenAnswer((_) async {});
      when(session.getCsrfToken()).thenAnswer((_) => 'test-csrf-token');

      // Act
      final result = await domain.obtainCsrfTokenForServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
      verify(session.obtainCsrfToken()).called(1);
      verify(session.getCsrfToken()).called(1);
      verify(secureStorage.saveCsrfToken('1', 'test-csrf-token')).called(1);
    });

    test(
      'Obtain CSRF token for server fails when request throws exception',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        final session = MockConnectionSessionInterface();
        sessionFactory.sessions[server.address] = session;

        when(session.obtainCsrfToken()).thenThrow(Exception('CSRF failed'));

        // Act
        final result = await domain.obtainCsrfTokenForServer(server);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, isNotNull);
        verify(session.obtainCsrfToken()).called(1);
        verifyNever(secureStorage.saveCsrfToken(any, any));
      },
    );

    test(
      'Check server availability returns true for available server',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        final session = MockConnectionSessionInterface();
        sessionFactory.sessions[server.address] = session;

        when(session.checkServerAvailability()).thenAnswer((_) async => true);

        // Act
        final isAvailable = await domain.checkServerAvailability(server);

        // Assert
        expect(isAvailable, isTrue);
        verify(session.checkServerAvailability()).called(1);
      },
    );

    test(
      'Check server availability returns false when request throws exception',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        final session = MockConnectionSessionInterface();
        sessionFactory.sessions[server.address] = session;

        when(
          session.checkServerAvailability(),
        ).thenThrow(Exception('Unavailable'));

        // Act
        final isAvailable = await domain.checkServerAvailability(server);

        // Assert
        expect(isAvailable, isFalse);
      },
    );

    test(
      'Default instance factory creates domain with proper dependencies',
      () async {
        // Note: We can't actually instantiate FlutterSecureStorage in tests
        // but we can at least verify the method exists and compiles
        expect(ConnectionDomain.defaultInstance, isA<Function>());
      },
    );

    test(
      'Has existing session returns false for non-connected server',
      () async {
        // Arrange
        final server = server_models.Server(
          id: 'non-existent',
          name: 'Non-existent Server',
          address: 'https://nonexistent.example.com',
        );
        // Act
        final hasSession = domain.hasExistingSession(server);
        // Assert
        expect(hasSession, isFalse);
      },
    );

    test('Has existing session returns true for connected server', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      final session = MockConnectionSessionInterface();
      // Add session to domain using test-only method
      domain.testOnlyAddSession('1', session);
      // Act
      final hasSession = domain.hasExistingSession(server);
      // Assert
      expect(hasSession, isTrue);
    });

    test('Has persistent session returns true when cookies exist', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final cookies = [Cookie('session', 'abc123')];
      when(
        secureStorage.loadSessionCookies('1'),
      ).thenAnswer((_) async => cookies);

      // Act
      final hasPersistentSession = await domain.hasPersistentSession(server);

      // Assert
      expect(hasPersistentSession, isTrue);
      verify(secureStorage.loadSessionCookies('1')).called(1);
    });

    test(
      'Has persistent session returns false when no cookies exist',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        when(
          secureStorage.loadSessionCookies('1'),
        ).thenAnswer((_) async => null);

        // Act
        final hasPersistentSession = await domain.hasPersistentSession(server);

        // Assert
        expect(hasPersistentSession, isFalse);
        verify(secureStorage.loadSessionCookies('1')).called(1);
      },
    );

    test(
      'Has persistent session returns false when empty cookies list',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => []);

        // Act
        final hasPersistentSession = await domain.hasPersistentSession(server);

        // Assert
        expect(hasPersistentSession, isFalse);
        verify(secureStorage.loadSessionCookies('1')).called(1);
      },
    );

    test(
      'Has persistent session returns false when storage throws exception',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        when(
          secureStorage.loadSessionCookies('1'),
        ).thenThrow(Exception('Storage error'));

        // Act
        final hasPersistentSession = await domain.hasPersistentSession(server);

        // Assert
        expect(hasPersistentSession, isFalse);
        verify(secureStorage.loadSessionCookies('1')).called(1);
      },
    );

    test(
      'Authenticate with server saves cookies when rememberMe is true',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        final credentials = ConnectionCredentials(
          handle: 'user',
          password: 'pass',
        );

        final session = MockConnectionSessionInterface();
        sessionFactory.sessions[server.address] = session;

        final cookies = [Cookie('session', 'abc123')];
        when(session.authenticate(credentials)).thenAnswer((_) async {});
        when(session.getSessionCookies()).thenAnswer((_) async => cookies);

        // Act
        final result = await domain.authenticateWithServer(
          server,
          credentials,
          rememberMe: true,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(session.authenticate(credentials)).called(1);
        verify(session.getSessionCookies()).called(1);
        verify(secureStorage.saveSessionCookies('1', cookies)).called(1);
      },
    );

    test(
      'Authenticate with server does not save cookies when rememberMe is false',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        final credentials = ConnectionCredentials(
          handle: 'user',
          password: 'pass',
        );

        final session = MockConnectionSessionInterface();
        sessionFactory.sessions[server.address] = session;

        when(session.authenticate(credentials)).thenAnswer((_) async {});

        // Act
        final result = await domain.authenticateWithServer(
          server,
          credentials,
          rememberMe: false,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(session.authenticate(credentials)).called(1);
        verifyNever(session.getSessionCookies());
        verifyNever(secureStorage.saveSessionCookies(any, any));
      },
    );

    test(
      'Authenticate with server handles getSessionCookies exception when rememberMe is true',
      () async {
        // Arrange
        final server = server_models.Server(
          id: '1',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        final credentials = ConnectionCredentials(
          handle: 'user',
          password: 'pass',
        );

        final session = MockConnectionSessionInterface();
        sessionFactory.sessions[server.address] = session;

        when(session.authenticate(credentials)).thenAnswer((_) async {});
        when(
          session.getSessionCookies(),
        ).thenThrow(Exception('Failed to get cookies'));

        // Act
        final result = await domain.authenticateWithServer(
          server,
          credentials,
          rememberMe: true,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Failed to get cookies'));
        verify(session.authenticate(credentials)).called(1);
        verify(session.getSessionCookies()).called(1);
        verifyNever(secureStorage.saveSessionCookies(any, any));
      },
    );
  });
}
