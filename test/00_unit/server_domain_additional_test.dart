// Additional unit tests for ServerDomain to improve coverage
@Tags(['unit', 'servers'])
library;

import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/result.dart';

import 'mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Provide dummy value for Result<bool> to avoid Mockito errors
  provideDummy<Result<bool>>(Result.success(true));
  group('ServerDomain Additional Tests', () {
    late MockServerStorage storage;
    late MockConnectionDomain connectionDomain;
    late ServerDomain service;

    setUp(() {
      storage = MockServerStorage();
      connectionDomain = MockConnectionDomain();
      service = ServerDomain(
        ServerOptions(storage, connectionDomain: connectionDomain),
      );
    });

    group('ServerOptions Tests', () {
      test('ServerOptions constructor assigns properties correctly', () {
        final options = ServerOptions(
          storage,
          connectionDomain: connectionDomain,
        );

        expect(options.repository, storage);
        expect(options.connectionDomain, connectionDomain);
      });

      test('ServerOptions.fromRawStorage factory constructor works', () {
        final prefs = MockSharedPreferencesAsync();
        final sec = MockFlutterSecureStorage();
        final connectionDomain = MockConnectionDomain();

        // This test primarily checks that the factory constructor doesn't throw
        expect(
          () => ServerOptions.fromRawStorage(
            prefs,
            sec,
            connectionDomain: connectionDomain,
          ),
          returnsNormally,
        );
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
        // Mock storage for server creation
        when(storage.create(any)).thenAnswer((_) async {});

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

    group('ServerDomain Error Handling Tests', () {
      test('initialize handles repository error correctly', () async {
        // Create mocks that will throw exceptions
        final errorStorage = MockServerStorage();
        final connectionDomain = MockConnectionDomain();
        when(errorStorage.getAll()).thenThrow(Exception('Storage error'));

        final errorService = ServerDomain(
          ServerOptions(errorStorage, connectionDomain: connectionDomain),
        );

        final result = await errorService.initialize();
        verify(errorStorage.getAll()).called(1);
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Storage error'));
      });

      test('_reLoadServers handles repository error correctly', () async {
        // Create mocks that will throw exceptions
        final errorStorage = MockServerStorage();
        final connectionDomain = MockConnectionDomain();
        when(errorStorage.getAll()).thenThrow(Exception('Storage error'));

        final errorService = ServerDomain(
          ServerOptions(errorStorage, connectionDomain: connectionDomain),
        );

        // We can't directly call the private _reLoadServers method, but we can
        // test the initialize method which calls it
        final result = await errorService.initialize();
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Storage error'));
      });

      test('addServer handles repository error correctly', () async {
        // Create mocks
        final errorStorage = MockServerStorage();
        final connectionDomain = MockConnectionDomain();
        when(errorStorage.create(any)).thenThrow(Exception('Create error'));

        final errorService = ServerDomain(
          ServerOptions(errorStorage, connectionDomain: connectionDomain),
        );

        final server = Server(
          id: 'error-server',
          name: 'Error Server',
          address: 'https://error.example.com',
        );

        final result = await errorService.addServer(server);
        expect(result.isSuccess, false);
        expect(result.error, contains('Create error'));

        // Server will still be in the map due to the implementation design
        expect(errorService.findServerById('error-server'), isNotNull);
      });

      test('updateServer handles repository error correctly', () async {
        // Create mocks
        final errorStorage = MockServerStorage();
        final connectionDomain = MockConnectionDomain();
        when(errorStorage.create(any)).thenAnswer((_) async {});
        when(errorStorage.update(any)).thenThrow(Exception('Update error'));
        when(errorStorage.getAll()).thenAnswer((_) async => []);

        final errorService = ServerDomain(
          ServerOptions(errorStorage, connectionDomain: connectionDomain),
        );

        // Initialize the service
        await errorService.initialize();

        // First add a server
        final server = Server(
          id: 'update-server',
          name: 'Update Server',
          address: 'https://update.example.com',
        );

        final addResult = await errorService.addServer(server);
        expect(addResult.isSuccess, true);
        expect(errorService.findServerById('update-server'), isNotNull);

        // Try to update the server - this should fail
        final updatedServer = Server(
          id: 'update-server',
          name: 'Updated Server',
          address: 'https://updated.example.com',
        );

        final result = await errorService.updateServer(updatedServer);
        expect(result.isSuccess, false);
        expect(result.error, contains('Update error'));

        // Server will still be updated in the map due to the implementation design
        final existingServer = errorService.findServerById('update-server');
        expect(existingServer, isNotNull);
        // The server will have the updated data since the implementation updates the map first
        expect(existingServer!.name, 'Updated Server');
      });

      test('removeServer handles repository error correctly', () async {
        // Create mocks
        final errorStorage = MockServerStorage();
        final connectionDomain = MockConnectionDomain();
        when(errorStorage.create(any)).thenAnswer((_) async {});
        when(errorStorage.delete(any)).thenThrow(Exception('Delete error'));
        when(errorStorage.getAll()).thenAnswer((_) async => []);

        final errorService = ServerDomain(
          ServerOptions(errorStorage, connectionDomain: connectionDomain),
        );

        // Initialize the service
        await errorService.initialize();

        // First add a server
        final server = Server(
          id: 'delete-server',
          name: 'Delete Server',
          address: 'https://delete.example.com',
        );

        final addResult = await errorService.addServer(server);
        expect(addResult.isSuccess, true);
        expect(errorService.findServerById('delete-server'), isNotNull);

        // Try to remove the server - this should fail
        final result = await errorService.removeServer('delete-server');
        expect(result.isSuccess, false);
        expect(result.error, contains('Delete error'));

        // Server will still be removed from the map due to the implementation design
        expect(errorService.findServerById('delete-server'), isNull);
      });
    });

    group('ServerDomain Check All Servers Tests', () {
      test('checkAllServerStatuses calls callback for each server', () async {
        // Mock storage to return some servers
        when(storage.getAll()).thenAnswer(
          (_) async => [
            Server(id: '1', name: 'Server 1', address: 'https://server1.com'),
            Server(id: '2', name: 'Server 2', address: 'https://server2.com'),
          ],
        );

        // Mock connection domain to return true (servers available)
        when(
          connectionDomain.checkServerAvailability(any),
        ).thenAnswer((_) async => Result.success(true));

        // Mock storage protect method
        when(storage.create(any)).thenAnswer((_) async {});
        when(storage.update(any)).thenAnswer((_) async {});
        when(storage.delete(any)).thenAnswer((_) async {});

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
          // Mock storage to return a server
          when(storage.getAll()).thenAnswer(
            (_) async => [
              Server(
                id: 'exception-server',
                name: 'Exception Server',
                address: 'https://exception.com',
              ),
            ],
          );

          // Mock connection domain to throw an exception
          when(
            connectionDomain.checkServerAvailability(any),
          ).thenThrow(Exception('Network error'));

          // Mock storage protect method
          when(storage.create(argThat(anything))).thenAnswer((_) async {});
          when(storage.update(argThat(anything))).thenAnswer((_) async {});
          when(storage.delete(argThat(anything))).thenAnswer((_) async {});

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

      test(
        'checkAllServerStatuses handles connection domain error result',
        () async {
          // Mock storage to return a server
          when(storage.getAll()).thenAnswer(
            (_) async => [
              Server(
                id: 'result-error-server',
                name: 'Result Error Server',
                address: 'https://result-error.com',
              ),
            ],
          );

          // Mock connection domain to return failure result
          when(
            connectionDomain.checkServerAvailability(any),
          ).thenAnswer((_) async => Result.failure('Connection failed'));

          // Mock storage protect method
          when(storage.create(argThat(anything))).thenAnswer((_) async {});
          when(storage.update(argThat(anything))).thenAnswer((_) async {});
          when(storage.delete(argThat(anything))).thenAnswer((_) async {});

          // Initialize service
          await service.initialize();

          final callbackServers = <Server>[];

          // Capture debug print calls
          final debugPrints = <String>[];
          final originalDebugPrint = debugPrint;
          debugPrint = (String? message, {int? wrapWidth}) {
            if (message != null) debugPrints.add(message);
          };

          // Check all server statuses
          await service.checkAllServerStatuses((server) {
            callbackServers.add(server);
          });

          // Restore debugPrint
          debugPrint = originalDebugPrint;

          // Verify callback was called
          expect(callbackServers, hasLength(1));
          expect(callbackServers[0].id, 'result-error-server');

          // Verify server status was set to offline due to error result
          final updatedServer = service.findServerById('result-error-server');
          expect(updatedServer?.status, ServerStatus.offline);

          // Verify debug print was called
          expect(debugPrints, isNotEmpty);
          expect(debugPrints.first, contains('Failed to check status'));
        },
      );

      test(
        'checkAllServerStatuses handles exception in _checkServerStatus',
        () async {
          // Mock storage to return a server
          when(storage.getAll()).thenAnswer(
            (_) async => [
              Server(
                id: 'check-exception-server',
                name: 'Check Exception Server',
                address: 'https://check-exception.com',
              ),
            ],
          );

          // Mock connection domain to throw an exception
          when(
            connectionDomain.checkServerAvailability(any),
          ).thenThrow(Exception('Network error'));

          // Mock storage protect method
          when(storage.create(argThat(anything))).thenAnswer((_) async {});
          when(storage.update(argThat(anything))).thenAnswer((_) async {});
          when(storage.delete(argThat(anything))).thenAnswer((_) async {});

          // Initialize service
          await service.initialize();

          final callbackServers = <Server>[];

          // Capture debug print calls
          final debugPrints = <String>[];
          final originalDebugPrint = debugPrint;
          debugPrint = (String? message, {int? wrapWidth}) {
            if (message != null) debugPrints.add(message);
          };

          // Check all server statuses
          await service.checkAllServerStatuses((server) {
            callbackServers.add(server);
          });

          // Restore debugPrint
          debugPrint = originalDebugPrint;

          // Verify callback was called
          expect(callbackServers, hasLength(1));
          expect(callbackServers[0].id, 'check-exception-server');

          // Verify server status was set to offline due to exception
          final updatedServer = service.findServerById(
            'check-exception-server',
          );
          expect(updatedServer?.status, ServerStatus.offline);

          // Verify debug print was called
          expect(debugPrints, isNotEmpty);
          expect(debugPrints.first, contains('Exception during status check'));
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

        final result = validateServerConfiguration(server);
        expect(result.isSuccess, isTrue);
      });

      test('validateServerConfiguration allows HTTP local servers', () {
        final server = Server(
          id: 'local',
          name: 'Local Server',
          address: 'http://localhost:8080',
        );

        final result = validateServerConfiguration(server);
        expect(result.isSuccess, isTrue);
      });

      test('validateServerConfiguration rejects HTTP external servers', () {
        final server = Server(
          id: 'insecure',
          name: 'Insecure Server',
          address: 'http://external.com',
        );

        final result = validateServerConfiguration(server);
        expect(result.isSuccess, isFalse);
        expect(result.error, 'HTTPS must be used for external servers');
      });
    });
  });
}
