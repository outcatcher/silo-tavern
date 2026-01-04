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

    test('Connect to server with existing session cookies and CSRF token', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );

      final existingCookies = [Cookie('session', 'abc123')];
      const existingCsrfToken = 'existing-csrf-token';

      when(
        secureStorage.loadSessionCookies('1'),
      ).thenAnswer((_) async => existingCookies);
      when(
        secureStorage.loadCsrfToken('1'),
      ).thenAnswer((_) async => existingCsrfToken);

      final session = MockConnectionSessionInterface();
      sessionFactory.sessions[server.address] = session;
      
      // Expect the CSRF token to be set on the session
      when(session.setCsrfToken(existingCsrfToken)).thenReturn(null);

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      // Verify that session cookies and CSRF token were loaded
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verify(secureStorage.loadCsrfToken('1')).called(1);
      
      // Verify that CSRF token was set on the session
      verify(session.setCsrfToken(existingCsrfToken)).called(1);
      
      // Verify that no new CSRF token was obtained
      verifyNever(session.obtainCsrfToken());
      
      // Verify that no CSRF token was saved (since we already had one)
      verifyNever(secureStorage.saveCsrfToken(any, any));
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
      when(session1.obtainCsrfToken()).thenThrow(Exception('CSRF failed'));

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('CSRF failed'));

      // Verify interactions
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verify(session1.obtainCsrfToken()).called(1);
      verifyNever(session1.authenticate(any));
    });

    test('Connect to server succeeds even when authentication would have failed (auth no longer supported)', () async {
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

      // First connect to create the session
      when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => null);
      when(secureStorage.loadCsrfToken('1')).thenAnswer((_) async => null);
      when(session1.obtainCsrfToken()).thenAnswer((_) async {});
      when(session1.getCsrfToken()).thenAnswer((_) => 'test-token');

      await domain.connectToServer(server);

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
      
      final credentials = ConnectionCredentials(handle: 'user', password: 'pass');
      
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

    test('Authenticate with server fails when authentication throws exception', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      
      final credentials = ConnectionCredentials(handle: 'user', password: 'wrong');
      
      final session = MockConnectionSessionInterface();
      sessionFactory.sessions[server.address] = session;
      
      when(session.authenticate(credentials)).thenThrow(Exception('Auth failed'));

      // Act
      final result = await domain.authenticateWithServer(server, credentials);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
      verify(session.authenticate(credentials)).called(1);
    });

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

    test('Obtain CSRF token for server fails when request throws exception', () async {
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
    });

    test('Check server availability returns true for available server', () async {
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
    });

    test('Check server availability returns false when request throws exception', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
      );
      
      final session = MockConnectionSessionInterface();
      sessionFactory.sessions[server.address] = session;
      
      when(session.checkServerAvailability()).thenThrow(Exception('Unavailable'));

      // Act
      final isAvailable = await domain.checkServerAvailability(server);

      // Assert
      expect(isAvailable, isFalse);
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