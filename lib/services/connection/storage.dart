import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/common/app_storage.dart';
import 'package:silo_tavern/domain/connection/repository.dart';

class ConnectionStorage implements ConnectionRepository {
  final JsonSecureStorage _secureStorage;

  static const String _sessionKeyPrefix = 'sessions';
  static const String _csrfTokenKeySuffix = '_csrf_token';

  ConnectionStorage(this._secureStorage);

  factory ConnectionStorage.defaultInstance(FlutterSecureStorage sec) {
    return ConnectionStorage(JsonSecureStorage(sec, _sessionKeyPrefix));
  }

  @override
  Future<void> saveSessionCookies(String serverId, List<Cookie> cookies) async {
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

    await _secureStorage.set(serverId, cookieData);
  }

  @override
  Future<List<Cookie>?> loadSessionCookies(String serverId) async {
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
  }

  @override
  Future<void> saveCsrfToken(String serverId, String token) async {
    final key = '$serverId$_csrfTokenKeySuffix';
    await _secureStorage.set(key, token);
  }

  @override
  Future<String?> loadCsrfToken(String serverId) async {
    final key = '$serverId$_csrfTokenKeySuffix';
    final token = await _secureStorage.get(key);
    return token is String ? token : null;
  }

  @override
  Future<void> deleteCsrfToken(String serverId) async {
    final key = '$serverId$_csrfTokenKeySuffix';
    await _secureStorage.delete(key);
  }
}
