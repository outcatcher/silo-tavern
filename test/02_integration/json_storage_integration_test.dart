// Integration tests for JsonStorage using real SharedPreferences
@Tags(['integration', 'storage'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silo_tavern/utils/app_storage.dart';
import 'package:silo_tavern/utils/testing_storage.dart';

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
        SharedPreferencesAsyncAdapter(prefs),
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
