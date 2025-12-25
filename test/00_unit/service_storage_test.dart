// Unit tests for universal storage
@Tags(['unit', 'storage'])
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silo_tavern/utils/app_storage.dart';

import 'server_storage_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SharedPreferencesAsync>(),
  MockSpec<FlutterSecureStorage>(),
])
void main() {
  group('JsonStorage tests', () {
    late MockSharedPreferencesAsync mockPrefs;
    late JsonStorage storage;

    setUp(() {
      mockPrefs = MockSharedPreferencesAsync();
      storage = JsonStorage(mockPrefs, "testPrefix");
    });

    test('get returns decoded JSON when key exists', () async {
      final Map<String, dynamic> expected = {"testField": "testValue"};
      when(
        mockPrefs.getString('testPrefix/123'),
      ).thenAnswer((realInvocation) async => '{"testField": "testValue"}');

      final actual = await storage.get("123");

      expect(actual, expected);
      verify(mockPrefs.getString('testPrefix/123')).called(1);
    });

    test('get returns null when key does not exist', () async {
      when(
        mockPrefs.getString('testPrefix/nonexistent'),
      ).thenAnswer((realInvocation) async => null);

      final actual = await storage.get("nonexistent");

      expect(actual, null);
      verify(mockPrefs.getString('testPrefix/nonexistent')).called(1);
    });

    test('get returns null when JSON is malformed', () async {
      when(
        mockPrefs.getString('testPrefix/badjson'),
      ).thenAnswer((realInvocation) async => '{"invalid": json}');

      final actual = await storage.get("badjson");

      expect(actual, null);
      verify(mockPrefs.getString('testPrefix/badjson')).called(1);
    });

    test('list returns all items with prefix', () async {
      final allKeys = <String>{
        'testPrefix/key1',
        'testPrefix/key2',
        'other/key3',
      };
      final filteredKeys = <String>{'testPrefix/key1', 'testPrefix/key2'};
      final allData = <String, Object?>{
        'testPrefix/key1': '{"field1": "value1"}',
        'testPrefix/key2': '{"field2": "value2"}',
      };

      when(mockPrefs.getKeys()).thenAnswer((_) async => allKeys);
      when(
        mockPrefs.getAll(allowList: filteredKeys),
      ).thenAnswer((_) async => allData);

      final result = await storage.list();

      expect(result, [
        {'field1': 'value1'},
        {'field2': 'value2'},
      ]);
      verify(mockPrefs.getKeys()).called(1);
      verify(mockPrefs.getAll(allowList: filteredKeys)).called(1);
    });

    test('list returns empty list when no items with prefix', () async {
      final allKeys = <String>{'other/key1', 'another/key2'};
      final allData = <String, Object?>{};

      when(mockPrefs.getKeys()).thenAnswer((_) async => allKeys);
      when(
        mockPrefs.getAll(allowList: <String>{}),
      ).thenAnswer((_) async => allData);

      final result = await storage.list();

      expect(result, []);
      verify(mockPrefs.getKeys()).called(1);
      verify(mockPrefs.getAll(allowList: <String>{})).called(1);
    });

    test('list skips malformed JSON entries', () async {
      final allKeys = <String>{
        'testPrefix/key1',
        'testPrefix/key2',
        'testPrefix/key3',
      };
      final filteredKeys = <String>{
        'testPrefix/key1',
        'testPrefix/key2',
        'testPrefix/key3',
      };
      final allData = <String, Object?>{
        'testPrefix/key1': '{"field1": "value1"}',
        'testPrefix/key2': '{"invalid": json}',
        'testPrefix/key3': '{"field3": "value3"}',
      };

      when(mockPrefs.getKeys()).thenAnswer((_) async => allKeys);
      when(
        mockPrefs.getAll(allowList: filteredKeys),
      ).thenAnswer((_) async => allData);

      final result = await storage.list();

      expect(result, [
        {'field1': 'value1'},
        {'field3': 'value3'},
      ]);
      verify(mockPrefs.getKeys()).called(1);
      verify(mockPrefs.getAll(allowList: filteredKeys)).called(1);
    });

    test('set encodes and stores JSON', () async {
      const key = 'testKey';
      final value = {'field': 'value'};
      const encodedValue = '{"field":"value"}';

      when(
        mockPrefs.setString('testPrefix/$key', encodedValue),
      ).thenAnswer((_) async => true);

      await storage.set(key, value);

      verify(mockPrefs.setString('testPrefix/$key', encodedValue)).called(1);
    });

    test('set handles encoding errors gracefully', () async {
      const key = 'testKey';
      final value = {
        'field': DateTime.now(),
      }; // DateTime is not JSON serializable by default

      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // This should not throw an exception
      await storage.set(key, value);

      // When encoding fails, setString should not be called
      verifyNever(mockPrefs.setString('testPrefix/$key', any));
    });

    test('delete removes item', () async {
      const key = 'testKey';

      when(mockPrefs.remove('testPrefix/$key')).thenAnswer((_) async => true);

      await storage.delete(key);

      verify(mockPrefs.remove('testPrefix/$key')).called(1);
    });
  });
  group('JsonSecureStorage tests', () {
    late MockFlutterSecureStorage mockSecureStorage;
    late JsonSecureStorage storage;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      storage = JsonSecureStorage(mockSecureStorage, "testPrefix");
    });

    test('get returns decoded JSON when key exists', () async {
      final Map<String, dynamic> expected = {"testField": "testValue"};
      when(
        mockSecureStorage.read(key: 'testPrefix/123'),
      ).thenAnswer((realInvocation) async => '{"testField": "testValue"}');

      final actual = await storage.get("123");

      expect(actual, expected);
      verify(mockSecureStorage.read(key: 'testPrefix/123')).called(1);
    });

    test('get returns null when key does not exist', () async {
      when(
        mockSecureStorage.read(key: 'testPrefix/nonexistent'),
      ).thenAnswer((realInvocation) async => null);

      final actual = await storage.get("nonexistent");

      expect(actual, null);
      verify(mockSecureStorage.read(key: 'testPrefix/nonexistent')).called(1);
    });

    test('get returns null when JSON is malformed', () async {
      when(
        mockSecureStorage.read(key: 'testPrefix/badjson'),
      ).thenAnswer((realInvocation) async => '{"invalid": json}');

      final actual = await storage.get("badjson");

      expect(actual, null);
      verify(mockSecureStorage.read(key: 'testPrefix/badjson')).called(1);
    });

    test('list returns all items with prefix', () async {
      final allData = <String, String>{
        'testPrefix/key1': '{"field1": "value1"}',
        'testPrefix/key2': '{"field2": "value2"}',
        'other/key3': '{"field3": "value3"}',
      };

      when(mockSecureStorage.readAll()).thenAnswer((_) async => allData);

      final result = await storage.list();

      expect(result, [
        {'field1': 'value1'},
        {'field2': 'value2'},
      ]);
      verify(mockSecureStorage.readAll()).called(1);
    });

    test('list returns empty list when no items with prefix', () async {
      final allData = <String, String>{
        'other/key1': '{"field1": "value1"}',
        'another/key2': '{"field2": "value2"}',
      };

      when(mockSecureStorage.readAll()).thenAnswer((_) async => allData);

      final result = await storage.list();

      expect(result, []);
      verify(mockSecureStorage.readAll()).called(1);
    });

    test('list skips malformed JSON entries', () async {
      final allData = <String, String>{
        'testPrefix/key1': '{"field1": "value1"}',
        'testPrefix/key2': '{"invalid": json}',
        'testPrefix/key3': '{"field3": "value3"}',
      };

      when(mockSecureStorage.readAll()).thenAnswer((_) async => allData);

      final result = await storage.list();

      expect(result, [
        {'field1': 'value1'},
        {'field3': 'value3'},
      ]);
      verify(mockSecureStorage.readAll()).called(1);
    });

    test('set encodes and stores JSON', () async {
      const key = 'testKey';
      final value = {'field': 'value'};
      const encodedValue = '{"field":"value"}';

      when(
        mockSecureStorage.write(key: 'testPrefix/$key', value: encodedValue),
      ).thenAnswer((_) async => ());

      await storage.set(key, value);

      verify(
        mockSecureStorage.write(key: 'testPrefix/$key', value: encodedValue),
      ).called(1);
    });

    test('set handles encoding errors gracefully', () async {
      const key = 'testKey';
      final value = {
        'field': DateTime.now(),
      }; // DateTime is not JSON serializable by default

      when(
        mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      ).thenAnswer((_) async => ());

      // This should not throw an exception
      await storage.set(key, value);

      // When encoding fails, write should not be called
      verifyNever(
        mockSecureStorage.write(
          key: 'testPrefix/$key',
          value: anyNamed('value'),
        ),
      );
    });

    test('delete removes item', () async {
      const key = 'testKey';

      when(
        mockSecureStorage.delete(key: 'testPrefix/$key'),
      ).thenAnswer((_) async => ());

      await storage.delete(key);

      verify(mockSecureStorage.delete(key: 'testPrefix/$key')).called(1);
    });
  });
}
