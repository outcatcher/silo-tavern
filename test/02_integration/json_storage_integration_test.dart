// Integration tests for JsonStorage using real SharedPreferences
@Tags(['integration', 'storage'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silo_tavern/utils/app_storage.dart';

void main() {
  group('JsonStorage integration tests', () {
    late JsonStorage storage;

    setUp(() async {
      // Initialize shared preferences for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      // Clear all preferences before each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Create adapter for SharedPreferencesAsync
      storage = JsonStorage(
        _SharedPreferencesAsyncAdapter(prefs),
        'test_prefix',
      );
    });

    testWidgets('JsonStorage full workflow', (WidgetTester tester) async {
      final Map<String, dynamic> expected1 = {'name': 'John', 'age': 30};
      final Map<String, dynamic> expected2 = {'name': 'Jane', 'age': 25};

      // Test setting values
      await storage.set('key1', expected1);
      await storage.set('key2', expected2);

      // Test getting values
      final result1 = await storage.get('key1');
      expect(result1, expected1);

      final result2 = await storage.get('key2');
      expect(result2, expected2);

      // Test listing all values
      final listResult = await storage.list();
      expect(listResult.length, 2);

      // Check if the maps are equivalent (using predicate matcher)
      expect(listResult, contains(equals(expected1)));
      expect(listResult, contains(equals(expected2)));

      // Test getting non-existent key
      final nonExistent = await storage.get('nonexistent');
      expect(nonExistent, null);

      // Test deleting a key
      await storage.delete('key1');

      // Verify deletion worked
      final deletedResult = await storage.get('key1');
      expect(deletedResult, null);

      // Verify list only contains remaining item
      final listAfterDelete = await storage.list();
      expect(listAfterDelete.length, 1);

      expect(listAfterDelete, contains(equals(expected2)));
    });
  });
}

// Adapter to bridge synchronous SharedPreferences with async interface
class _SharedPreferencesAsyncAdapter implements SharedPreferencesAsync {
  final SharedPreferences _prefs;

  _SharedPreferencesAsyncAdapter(this._prefs);

  @override
  Future<void> clear({Set<String>? allowList}) async {
    if (allowList != null) {
      for (final key in allowList) {
        await _prefs.remove(key);
      }
    } else {
      await _prefs.clear();
    }
  }

  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async {
    final result = <String, Object?>{};
    final keys = allowList ?? _prefs.getKeys();
    for (final key in keys) {
      // Try to get the string value (our JSON storage only uses strings)
      final value = _prefs.getString(key);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<Set<String>> getKeys({Set<String>? allowList}) async {
    final allKeys = _prefs.getKeys();
    if (allowList != null) {
      return allKeys.where((key) => allowList.contains(key)).toSet();
    }
    return allKeys;
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<bool> remove(String key) async {
    return _prefs.remove(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    return _prefs.setString(key, value);
  }

  // Default implementations for unused methods
  @override
  Future<bool> containsKey(String key) async => _prefs.containsKey(key);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<double?> getDouble(String key) async => _prefs.getDouble(key);

  @override
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  @override
  Future<List<String>?> getStringList(String key) async =>
      _prefs.getStringList(key);

  @override
  Future<bool> setBool(String key, bool value) async =>
      _prefs.setBool(key, value);

  @override
  Future<bool> setDouble(String key, double value) async =>
      _prefs.setDouble(key, value);

  @override
  Future<bool> setInt(String key, int value) async => _prefs.setInt(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) async =>
      _prefs.setStringList(key, value);
}
