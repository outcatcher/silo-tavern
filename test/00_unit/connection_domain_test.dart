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

    test('Connect to server successfully', () async {
      // Arrange
      final server = server_models.Server(
        id: '1',
        name: 'Test Server',
        address: 'https://test.example.com',
        authentication: server_models.AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      final session1 = MockConnectionSessionInterface();

      sessionFactory.sessions[server.address] = session1;

      when(secureStorage.loadSessionCookies('1')).thenAnswer((_) async => null);
      when(
        session1.obtainCsrfToken(),
      ).thenAnswer((_) async => 'mock-csrf-token');
      // when(session1.authenticate(any)).thenAnswer((_) async {});

      // Act
      final result = await domain.connectToServer(server);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);

      // Verify interactions
      verify(secureStorage.loadSessionCookies('1')).called(1);
      verify(session1.obtainCsrfToken()).called(1);
      verify(
        session1.authenticate(
          argThat(
            predicate<ConnectionCredentials>(
              (creds) => creds.username == 'user' && creds.password == 'pass',
            ),
          ),
        ),
      ).called(1);
    });
  });
}
