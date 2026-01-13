// Additional unit tests for ServerDomain to improve coverage
@Tags(['unit', 'servers'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/servers/repository.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/common/result.dart';

import 'server_domain_additional_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ServerRepository>(), MockSpec<ConnectionDomain>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Provide dummy values for Result types to avoid Mockito errors
  provideDummy<Result<bool>>(Result.success(true));
  provideDummy<Result<void>>(Result.success(null));
  provideDummy<Result<List<Server>>>(Result.success(<Server>[]));
  provideDummy<Result<Server?>>(Result.success(null));
  
  group('ServerDomain Additional Tests', () {
    late MockServerRepository repository;
    late MockConnectionDomain connectionDomain;
    late ServerDomain service;

    setUp(() {
      repository = MockServerRepository();
      connectionDomain = MockConnectionDomain();
      service = ServerDomain(
        ServerOptions(repository, connectionDomain: connectionDomain),
      );
    });

    group('ServerOptions Tests', () {
      test('ServerOptions constructor assigns properties correctly', () {
        final options = ServerOptions(
          repository,
          connectionDomain: connectionDomain,
        );

        expect(options.repository, repository);
        expect(options.connectionDomain, connectionDomain);
      });
    });

    group('ServerDomain Constructor and Properties', () {
      test('ServerDomain constructor initializes correctly', () {
        expect(service, isNotNull);
      });

      test('ServerDomain connectionDomain getter returns correct instance', () {
        expect(service.connectionDomain, connectionDomain);
      });
    });

    group('ServerDomain Status Update Tests', () {
      test('updateServerStatus updates existing server status', () async {
        // Mock repository for server creation
        when(repository.create(any)).thenAnswer((_) async => Result.success(null));

        // Add a server first
        final server = Server(
          id: 'test-server',
          name: 'Test Server',
          address: 'https://test.example.com',
        );

        await service.addServer(server);

        // Update status
        service.updateServerStatus('test-server', ServerStatus.online);

        final updatedServer = service.findServerById('test-server');
        expect(updatedServer?.status, ServerStatus.online);
      });

      test('updateServerStatus does nothing for non-existent server', () {
        // This should not throw an exception
        expect(
          () => service.updateServerStatus('non-existent', ServerStatus.online),
          returnsNormally,
        );
      });
    });

    group('ServerDomain Check All Servers Tests', () {
      test('checkAllServerStatuses calls callback for each server', () async {
        // Mock repository to return some servers
        when(repository.getAll()).thenAnswer(
          (_) async => Result.success([
            Server(id: '1', name: 'Server 1', address: 'https://server1.com'),
            Server(id: '2', name: 'Server 2', address: 'https://server2.com'),
          ]),
        );

        // Mock connection domain to return true (servers available)
        when(
          connectionDomain.checkServerAvailability(any),
        ).thenAnswer((_) async => Result.success(true));

        // Mock repository methods
        when(repository.create(any)).thenAnswer((_) async => Result.success(null));
        when(repository.update(any)).thenAnswer((_) async => Result.success(null));
        when(repository.delete(any)).thenAnswer((_) async => Result.success(null));

        // Initialize service
        await service.initialize();

        final callbackServers = <Server>[];

        // Check all server statuses
        await service.checkAllServerStatuses((server) {
          callbackServers.add(server);
        });

        // Verify callback was called for each server
        expect(callbackServers, hasLength(2));
        expect(callbackServers.map((s) => s.id), containsAll(['1', '2']));
      });

      test(
        'checkAllServerStatuses handles exception in server check',
        () async {
          // Mock repository to return a server
          when(repository.getAll()).thenAnswer(
            (_) async => Result.success([
              Server(
                id: 'exception-server',
                name: 'Exception Server',
                address: 'https://exception.com',
              ),
            ]),
          );

          // Mock connection domain to throw an exception
          when(
            connectionDomain.checkServerAvailability(any),
          ).thenThrow(Exception('Network error'));

          // Mock repository methods
          when(
            repository.create(argThat(anything)),
          ).thenAnswer((_) async => Result.success(null));
          when(
            repository.update(argThat(anything)),
          ).thenAnswer((_) async => Result.success(null));
          when(
            repository.delete(argThat(anything)),
          ).thenAnswer((_) async => Result.success(null));

          // Initialize service
          await service.initialize();

          final callbackServers = <Server>[];

          // Check all server statuses - should not throw exception
          await service.checkAllServerStatuses((server) {
            callbackServers.add(server);
          });

          // Verify callback was still called despite exception
          expect(callbackServers, hasLength(1));
          expect(callbackServers[0].id, 'exception-server');

          // Verify server status was set to offline due to exception
          final updatedServer = service.findServerById('exception-server');
          expect(updatedServer?.status, ServerStatus.offline);
        },
      );
    });

    group('validateServerConfiguration Tests', () {
      test('validateServerConfiguration allows HTTPS external servers', () {
        final server = Server(
          id: 'secure',
          name: 'Secure Server',
          address: 'https://external.com',
        );

        expect(() => validateServerConfiguration(server), returnsNormally);
      });

      test('validateServerConfiguration allows HTTP local servers', () {
        final server = Server(
          id: 'local',
          name: 'Local Server',
          address: 'http://localhost:8080',
        );

        expect(() => validateServerConfiguration(server), returnsNormally);
      });

      test('validateServerConfiguration rejects HTTP external servers', () {
        final server = Server(
          id: 'insecure',
          name: 'Insecure Server',
          address: 'http://external.com',
        );

        expect(
          () => validateServerConfiguration(server),
          throwsA(
            predicate(
              (e) =>
                  e is ArgumentError &&
                  e.message.contains('HTTPS must be used'),
            ),
          ),
        );
      });
    });
  });
}
