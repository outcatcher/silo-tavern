import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/utils/app_storage.dart';

class ConnectionStorage {
  final JsonSecureStorage _secureStorage;

  static const String _sessionKeyPrefix = 'sessions';

  ConnectionStorage(JsonSecureStorage secureStorage)
    : _secureStorage = secureStorage;

  factory ConnectionStorage.defaultInstance(FlutterSecureStorage sec) {
    return ConnectionStorage(JsonSecureStorage(sec, _sessionKeyPrefix));
  }

  Future<void> saveSessionCookies(String serverId, List<Cookie> cookies) async {
    _secureStorage.set(serverId, cookies);
  }

  Future<List<Cookie>?> loadSessionCookies(String serverId) async {
    final jsonData = await _secureStorage.get(serverId);
    if (jsonData == null) {
      return null;
    }

    final cookiesFromStorage = (jsonDecode(jsonData) as List)
        .map(
          (e) => Cookie(e['name'], e['value'])
            ..domain = e['domain']
            ..path = e['path']
            ..expires = e['expires'] != null
                ? DateTime.parse(e['expires'])
                : null,
        )
        .toList();

    return cookiesFromStorage;
  }
}
