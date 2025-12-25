library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JsonSecureStorage {
  final FlutterSecureStorage _secureStorage;
  final String _keyPrefix;

  JsonSecureStorage(this._secureStorage, this._keyPrefix);

  String _realKey(String key) {
    return '$_keyPrefix/$key';
  }

  Future<Map<String, dynamic>?> get(String key) async {
    final raw = await _secureStorage.read(key: _realKey(key));

    if (raw == null) {
      return null;
    }

    try {
      return json.decode(raw);
    } catch (e) {
      // Return null if JSON is malformed
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> list() async {
    final allData = await _secureStorage.readAll();
    final filteredKeys = allData.keys
        .where((key) => key.startsWith(_keyPrefix))
        .toList();

    final List<Map<String, dynamic>> result = [];

    for (final key in filteredKeys) {
      final jsonString = allData[key];
      if (jsonString != null) {
        try {
          result.add(json.decode(jsonString) as Map<String, dynamic>);
        } catch (e) {
          // Skip malformed JSON
          continue;
        }
      }
    }

    return result;
  }

  Future<void> set(String key, Object value) async {
    try {
      final raw = json.encode(value);
      await _secureStorage.write(key: _realKey(key), value: raw);
    } catch (e) {
      // Silently ignore encoding errors
      // In a real application, you might want to log this
    }
  }

  Future<void> delete(String key) async {
    await _secureStorage.delete(key: _realKey(key));
  }
}

class JsonStorage {
  final SharedPreferencesAsync _prefs;
  final String _keyPrefix;

  JsonStorage(this._prefs, this._keyPrefix);

  String _realKey(String key) {
    return '$_keyPrefix/$key';
  }

  Future<Map<String, dynamic>?> get(String key) async {
    final raw = await _prefs.getString(_realKey(key));

    if (raw == null) {
      return null;
    }

    try {
      return json.decode(raw);
    } catch (e) {
      // Return null if JSON is malformed
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> list() async {
    final allKeys = await _prefs.getKeys();
    allKeys.retainWhere((key) => key.startsWith(_keyPrefix));

    final allData = await _prefs.getAll(allowList: allKeys);
    final List<Map<String, dynamic>> result = [];

    for (final key in allKeys) {
      final jsonString = allData[key] as String;
      try {
        result.add(json.decode(jsonString) as Map<String, dynamic>);
      } catch (e) {
        // Skip malformed JSON
        continue;
      }
    }

    return result;
  }

  Future<void> set(String key, Object value) async {
    try {
      final raw = json.encode(value);
      await _prefs.setString(_realKey(key), raw);
    } catch (e) {
      // Silently ignore encoding errors
      // In a real application, you might want to log this
    }
  }

  Future<void> delete(String key) async {
    await _prefs.remove(_realKey(key));
  }
}
