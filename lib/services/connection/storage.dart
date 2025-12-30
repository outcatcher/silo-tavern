import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/utils/app_storage.dart';

class ConnectionStorage {
  final JsonSecureStorage _secureStorage;

  static const String _sessionKeyPrefix = 'sessions';

  ConnectionStorage(this._secureStorage);

  factory ConnectionStorage.defaultInstance(FlutterSecureStorage sec) {
    return ConnectionStorage(JsonSecureStorage(sec, _sessionKeyPrefix));
  }

  Future<void> saveSessionCookies(String serverId, List<Cookie> cookies) async {
    try {
      final cookieData = cookies.map((cookie) {
        return {
          'name': cookie.name,
          'value': cookie.value,
          'domain': cookie.domain,
          'path': cookie.path,
          if (cookie.expires != null)
            'expires': cookie.expires!.toIso8601String(),
        };
      }).toList();

      _secureStorage.set(serverId, cookieData);
    } catch (e) {
      debugPrint(
        'ConnectionStorage: Failed to save session cookies for server $serverId: $e',
      );
      rethrow;
    }
  }

  Future<List<Cookie>?> loadSessionCookies(String serverId) async {
    try {
      final cookieData = await _secureStorage.get(serverId);
      if (cookieData == null) {
        return null;
      }

      if (cookieData is! List) {
        return null;
      }

      final cookiesFromStorage = cookieData
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
    } catch (e) {
      debugPrint(
        'ConnectionStorage: Failed to load session cookies for server $serverId: $e',
      );
      return null;
    }
  }
}
