// Unit tests for ServerStorage with 100% coverage
@Tags(['unit', 'servers', 'storage'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/domain/servers/models.dart';

import 'package:silo_tavern/services/servers/storage.dart';

import 'mocks.mocks.dart';

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
      expect(storage.getAll, isNotNull);
      expect(storage.getById, isNotNull);
      expect(storage.create, isNotNull);
      expect(storage.update, isNotNull);
      expect(storage.delete, isNotNull);
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

    test('Get all servers returns empty list when no data', () async {
      when(mockPrefs.getKeys()).thenAnswer((_) async => <String>{});

      final result = await storage.getAll();
      expect(result, isEmpty);
    });

    test('Get all servers returns decoded servers', () async {
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

      final result = await storage.getAll();
      expect(result, hasLength(2));
      expect(result[0].id, 'test-server-1');
      expect(result[1].id, 'test-server-2');
    });

    test('Get server by ID returns null when server not found', () async {
      when(mockPrefs.getKeys()).thenAnswer((_) async => <String>{});

      final result = await storage.getById('non-existent');
      expect(result, isNull);
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

      final result = await storage.getById('test-server-2');
      expect(result, isNotNull);
      expect(result!.id, 'test-server-2');
      expect(result.name, 'Test Server 2');
    });

    test('Get server returns correct server when found with credentials', () async {
      final serverData = {
        'servers/test-server':
            '{"id":"test-server","name":"Test Server","address":"https://test.example.com"}',
      };

      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => serverData.keys.toSet());
      when(
        mockPrefs.getAll(allowList: anyNamed('allowList')),
      ).thenAnswer((_) async => serverData);
      when(mockPrefs.getString('servers/test-server')).thenAnswer(
        (_) async =>
            '{"id":"test-server","name":"Test Server","address":"https://test.example.com"}',
      );
      when(mockSecureStorage.read(key: 'servers/test-server')).thenAnswer(
        (_) async => jsonEncode({'username': 'user', 'password': 'pass'}),
      );

      final result = await storage.getById('test-server');
      expect(result, isNotNull);
      expect(result!.id, 'test-server');
      expect(result.name, 'Test Server');
    });

    test('Create server saves to storage', () async {
      when(mockPrefs.getKeys()).thenAnswer((_) async => <String>{});
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(
        mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async {});

      final newServer = Server(
        id: 'new-server',
        name: 'New Server',
        address: 'https://new.example.com',
      );

      await expectLater(storage.create(newServer), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Create server throws exception when ID already exists', () async {
      when(
        mockPrefs.getKeys(),
      ).thenAnswer((_) async => {'servers/existing-server'});
      when(mockPrefs.getString('servers/existing-server')).thenAnswer(
        (_) async =>
            '{"id":"existing-server","name":"Existing Server","address":"https://existing.example.com"}',
      );

      final newServer = Server(
        id: 'existing-server',
        name: 'New Server',
        address: 'https://new.example.com',
      );

      expect(
        () => storage.create(newServer),
        throwsA(predicate((e) => e is ArgumentError)),
      );
    });

    test('Update server modifies existing server', () async {
      // Mock the underlying SharedPreferences methods that JsonStorage uses
      when(mockPrefs.getString('servers/update-server')).thenAnswer(
        (_) async =>
            '{"id":"update-server","name":"Old Name","address":"https://old.example.com"}',
      );
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(
        mockSecureStorage.read(key: 'servers/update-server'),
      ).thenAnswer((_) async => null);

      final updatedServer = Server(
        id: 'update-server',
        name: 'New Name',
        address: 'https://new.example.com',
      );

      await expectLater(storage.update(updatedServer), completes);
      verify(mockPrefs.setString(any, any)).called(1);
    });

    test('Update server throws exception when server not found', () async {
      when(mockPrefs.getKeys()).thenAnswer((_) async => <String>{});

      final updatedServer = Server(
        id: 'non-existent',
        name: 'New Name',
        address: 'https://new.example.com',
      );

      expect(
        () => storage.update(updatedServer),
        throwsA(predicate((e) => e is ArgumentError)),
      );
    });

    test('Delete server removes server', () async {
      when(
        mockPrefs.remove('servers/delete-server'),
      ).thenAnswer((_) async => true);

      await expectLater(storage.delete('delete-server'), completes);
      verify(mockPrefs.remove('servers/delete-server')).called(1);
    });

    test('Delete server with credentials deletes auth data', () async {
      when(
        mockPrefs.remove('servers/delete-server'),
      ).thenAnswer((_) async => true);
      when(
        mockSecureStorage.delete(key: 'servers/delete-server'),
      ).thenAnswer((_) async {});

      await expectLater(storage.delete('delete-server'), completes);
      verify(mockPrefs.remove('servers/delete-server')).called(1);
      verify(mockSecureStorage.delete(key: 'servers/delete-server')).called(1);
    });
  });
}
