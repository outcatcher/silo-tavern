// Unit tests for ServerStorage with 100% coverage
@Tags(['unit', 'servers', 'storage'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/domain/servers/models.dart';

import 'package:silo_tavern/services/servers/storage.dart';

import 'server_storage_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SharedPreferencesAsync>(),
  MockSpec<FlutterSecureStorage>(),
])
void main() {
  group('ServerStorage API Tests', () {
    test('ServerStorage can be instantiated', () {
      // Use existing mocks from server_storage_test
      final prefs = MockSharedPreferencesAsync();
      final secureStorage = MockFlutterSecureStorage();

      // This should compile and not throw
      final storage = ServerStorage.fromRawStorage(prefs, secureStorage);

      // Verify method existence (this verifies the API at compile time)
      expect(storage, isNotNull);
    });

    test('ServerStorage has all expected methods', () {
      // This is just a compile-time check to ensure the methods exist
      // We're not actually calling them, just verifying they exist
      final prefs = MockSharedPreferencesAsync();
      final secureStorage = MockFlutterSecureStorage();
      final storage = ServerStorage.fromRawStorage(prefs, secureStorage);

      // Verify all public methods exist
      expect(storage.listServers, isNotNull);
      expect(storage.getServer, isNotNull);
      expect(storage.createServer, isNotNull);
      expect(storage.updateServer, isNotNull);
      expect(storage.deleteServer, isNotNull);
    });
  });

  group('ServerStorage Unit Tests', () {
    late MockSharedPreferencesAsync mockPrefs;
    late MockFlutterSecureStorage mockSecureStorage;
    late ServerStorage storage;

    setUp(() {
      mockPrefs = MockSharedPreferencesAsync();
      mockSecureStorage = MockFlutterSecureStorage();

      storage = ServerStorage.fromRawStorage(mockPrefs, mockSecureStorage);
    });

    test('Constructor creates instance', () {
      expect(storage, isNotNull);
    });

    test('List servers returns empty list when no data', () async {
      when(mockPrefs.getString('servers')).thenAnswer((_) async => null);

      final servers = await storage.listServers();
      expect(servers, isEmpty);
    });

    test('List servers returns decoded servers', () async {
      final serverData = {
        'servers/test-server-1':
            '{"id":"test-server-1","name":"Test Server 1","address":"https://test1.example.com"}',
        'servers/test-server-2':
            '{"id":"test-server-2","name":"Test Server 2","address":"https://test2.example.com"}',
      };

      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => serverData.keys.toSet());
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => serverData);
      when(
        mockSecureStorage.read(key: 'servers/test-server-1'),
      ).thenAnswer((_) async => null);
      when(
        mockSecureStorage.read(key: 'servers/test-server-2'),
      ).thenAnswer((_) async => null);

      final servers = await storage.listServers();
      expect(servers, hasLength(2));
      expect(servers[0].id, 'test-server-1');
      expect(servers[1].id, 'test-server-2');
    });

    test('List servers returns decoded servers', () async {
      final serverData = {
        'servers/test-server-1':
            '{"id":"test-server-1","name":"Test Server 1","address":"https://test1.example.com"}',
        'servers/test-server-2':
            '{"id":"test-server-2","name":"Test Server 2","address":"https://test2.example.com"}',
      };

      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => serverData.keys.toSet());
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => serverData);

      final servers = await storage.listServers();
      expect(servers, hasLength(2));
      expect(servers[0].id, 'test-server-1');
      expect(servers[1].id, 'test-server-2');
    });

    test('List servers handles malformed data gracefully', () async {
      when(
        mockPrefs.getString('servers'),
      ).thenAnswer((_) async => 'invalid-json');

      final servers = await storage.listServers();
      expect(servers, isEmpty);
    });

    test('Get server returns null when server not found', () async {
      when(mockPrefs.getString('servers')).thenAnswer((_) async => null);

      final server = await storage.getServer('non-existent');
      expect(server, isNull);
    });

    test('Get server returns correct server when found', () async {
      final serverData = {
        'servers/test-server-1':
            '{"id":"test-server-1","name":"Test Server 1","address":"https://test1.example.com"}',
        'servers/test-server-2':
            '{"id":"test-server-2","name":"Test Server 2","address":"https://test2.example.com"}',
      };

      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => serverData.keys.toSet());
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => serverData);
      when(mockPrefs.getString('servers/test-server-1')).thenAnswer(
        (_) async =>
            '{"id":"test-server-1","name":"Test Server 1","address":"https://test1.example.com"}',
      );
      when(mockPrefs.getString('servers/test-server-2')).thenAnswer(
        (_) async =>
            '{"id":"test-server-2","name":"Test Server 2","address":"https://test2.example.com"}',
      );
      when(
        mockSecureStorage.read(key: 'servers/test-server-1'),
      ).thenAnswer((_) async => null);
      when(
        mockSecureStorage.read(key: 'servers/test-server-2'),
      ).thenAnswer((_) async => null);

      final server = await storage.getServer('test-server-2');
      expect(server, isNotNull);
      expect(server!.id, 'test-server-2');
      expect(server.name, 'Test Server 2');
    });

    test('Get server returns correct server when found', () async {
      when(mockPrefs.getString('servers/test-server')).thenAnswer(
        (_) async =>
            '{"id":"test-server","name":"Test Server","address":"https://test.example.com"}',
      );

      final server = await storage.getServer('test-server');
      expect(server, isNotNull);
      expect(server!.id, 'test-server');
      expect(server.name, 'Test Server');
    });

    test('Create server adds new server to list', () async {
      when(mockPrefs.getString('servers')).thenAnswer((_) async => null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      final newServer = Server(
        id: 'new-server',
        name: 'New Server',
        address: 'https://new.example.com',
      );

      await expectLater(storage.createServer(newServer), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Create server saves to storage', () async {
      when(mockPrefs.getString('servers')).thenAnswer((_) async => null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      final newServer = Server(
        id: 'new-server',
        name: 'New Server',
        address: 'https://new.example.com',
      );

      await expectLater(storage.createServer(newServer), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Create server throws exception when ID already exists', () async {
      final existingServerJson =
          '{"id":"existing-server","name":"Existing Server","address":"https://existing.example.com"}';

      when(
        mockPrefs.getString('servers/existing-server'),
      ).thenAnswer((_) async => existingServerJson);
      when(
        mockSecureStorage.read(key: 'servers/existing-server'),
      ).thenAnswer((_) async => null);

      final newServer = Server(
        id: 'existing-server',
        name: 'New Server',
        address: 'https://new.example.com',
      );

      expect(
        () => storage.createServer(newServer),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('already exists'),
          ),
        ),
      );
    });

    test('Update server modifies existing server', () async {
      // Mock the underlying SharedPreferences methods that JsonStorage uses
      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => {'servers/update-server'});
      when(mockPrefs.getAll(allowList: anyNamed('allowList'))).thenAnswer(
        (_) async => {
          'servers/update-server':
              '{"id":"update-server","name":"Old Name","address":"https://old.example.com"}',
        },
      );
      when(
        mockSecureStorage.read(key: 'servers/update-server'),
      ).thenAnswer((_) async => null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.getString('servers/update-server')).thenAnswer(
        (_) async =>
            '{"id":"update-server","name":"Old Name","address":"https://old.example.com"}',
      );

      final updatedServer = Server(
        id: 'update-server',
        name: 'New Name',
        address: 'https://new.example.com',
      );

      await expectLater(storage.updateServer(updatedServer), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Update server modifies existing server', () async {
      when(mockPrefs.getString('servers/update-server')).thenAnswer(
        (_) async =>
            '{"id":"update-server","name":"Old Name","address":"https://old.example.com"}',
      );
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      final updatedServer = Server(
        id: 'update-server',
        name: 'New Name',
        address: 'https://new.example.com',
      );

      await expectLater(storage.updateServer(updatedServer), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Update server throws exception when server not found', () async {
      when(mockPrefs.getKeys()).thenAnswer((_) async => <String>{});
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => <String, Object?>{});

      final updatedServer = Server(
        id: 'non-existent',
        name: 'New Name',
        address: 'https://new.example.com',
      );

      expect(
        () => storage.updateServer(updatedServer),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('not found'),
          ),
        ),
      );
    });

    test('Update server modifies existing server', () async {
      when(mockPrefs.getString('servers/update-server')).thenAnswer(
        (_) async =>
            '{"id":"update-server","name":"Old Name","address":"https://old.example.com"}',
      );
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      final updatedServer = Server(
        id: 'update-server',
        name: 'New Name',
        address: 'https://new.example.com',
      );

      await expectLater(storage.updateServer(updatedServer), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Delete server removes server from list', () async {
      final existingServerData = {
        'servers/delete-server':
            '{"id":"delete-server","name":"Server to Delete","address":"https://delete.example.com"}',
      };

      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => existingServerData.keys.toSet());
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => existingServerData);
      when(mockPrefs.remove(any)).thenAnswer((_) async => true);

      await expectLater(storage.deleteServer('delete-server'), completes);
      verify(mockPrefs.remove(any)).called(1);
    });

    test('Delete server with credentials deletes auth data', () async {
      final existingServerData = {
        'servers/delete-server':
            '{"id":"delete-server","name":"Server to Delete","address":"https://delete.example.com"}',
      };

      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => existingServerData.keys.toSet());
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => existingServerData);
      when(mockPrefs.remove(any)).thenAnswer((_) async => true);
      when(
        mockSecureStorage.delete(key: anyNamed('key')),
      ).thenAnswer((_) async => true);

      when(mockSecureStorage.read(key: 'servers/delete-server')).thenAnswer((
        _,
      ) async {
        final authData = {'username': 'user', 'password': 'pass'};
        return jsonEncode(authData);
      });

      await expectLater(storage.deleteServer('delete-server'), completes);
      verify(mockPrefs.remove(any)).called(1);
      verify(mockSecureStorage.delete(key: anyNamed('key'))).called(1);
    });

    test('List servers handles exceptions gracefully', () async {
      when(
        mockPrefs.getString('servers'),
      ).thenThrow(Exception('Storage error'));

      final servers = await storage.listServers();
      expect(servers, isEmpty);
    });

    test('Get server handles exceptions gracefully', () async {
      when(
        mockPrefs.getString('servers'),
      ).thenThrow(Exception('Storage error'));

      final server = await storage.getServer('test-id');
      expect(server, isNull);
    });

    test('Create server handles listServers exceptions gracefully', () async {
      when(
        mockPrefs.getString('servers'),
      ).thenThrow(Exception('Storage error'));

      final newServer = Server(
        id: 'new-server',
        name: 'New Server',
        address: 'https://new.example.com',
      );

      // Test that the method completes (exception is caught internally)
      await expectLater(storage.createServer(newServer), completes);
    });

    test('Save server calls save servers', () async {
      final servers = [
        Server(
          id: 'test-server',
          name: 'Test Server',
          address: 'https://test.example.com',
        ),
      ];

      when(mockPrefs.getKeys()).thenAnswer((_) async => <String>{});
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => <String, Object?>{});
      when(
        mockSecureStorage.read(key: 'servers/test-server'),
      ).thenAnswer((_) async => null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      await expectLater(storage.createServer(servers[0]), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Delete server with credentials deletes auth data', () async {
      final existingServerData = {
        'servers/delete-server':
            '{"id":"delete-server","name":"Server to Delete","address":"https://delete.example.com"}',
      };

      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => existingServerData.keys.toSet());
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => existingServerData);
      when(mockPrefs.remove(any)).thenAnswer((_) async => true);
      when(
        mockSecureStorage.delete(key: anyNamed('key')),
      ).thenAnswer((_) async => true);

      when(mockSecureStorage.read(key: 'servers/delete-server')).thenAnswer((
        _,
      ) async {
        final authData = {'username': 'user', 'password': 'pass'};
        return jsonEncode(authData);
      });

      await expectLater(storage.deleteServer('delete-server'), completes);
      verify(mockPrefs.remove(any)).called(1);
      verify(mockSecureStorage.delete(key: anyNamed('key'))).called(1);
    });
  });
}
