import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/common/app_storage.dart';
import 'package:silo_tavern/domain/connection/repository.dart';
import 'package:silo_tavern/common/result.dart';

class ConnectionStorage implements ConnectionRepository {
  final JsonSecureStorage _secureStorage;

  static const String _sessionKeyPrefix = 'sessions';
  static const String _csrfTokenKeySuffix = '_csrf_token';

  ConnectionStorage(this._secureStorage);

  factory ConnectionStorage.defaultInstance(FlutterSecureStorage sec) {
    return ConnectionStorage(JsonSecureStorage(sec, _sessionKeyPrefix));
  }

  @override
  Future<Result<void>> saveSessionCookies(
    String serverId,
    List<Cookie> cookies,
  ) async {
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

      await _secureStorage.set(serverId, cookieData);
      return Result.success(null);
    } catch (e) {
      debugPrint(
        'ConnectionStorage: Failed to save session cookies for server $serverId: $e',
      );
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<Cookie>?>> loadSessionCookies(String serverId) async {
    try {
      final cookieData = await _secureStorage.get(serverId);
      if (cookieData == null) {
        return Result.success(null);
      }

      if (cookieData is! List) {
        return Result.success(null);
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

      return Result.success(cookiesFromStorage);
    } catch (e) {
      debugPrint(
        'ConnectionStorage: Failed to load session cookies for server $serverId: $e',
      );
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> saveCsrfToken(String serverId, String token) async {
    try {
      final key = '$serverId$_csrfTokenKeySuffix';
      await _secureStorage.set(key, token);
      return Result.success(null);
    } catch (e) {
      debugPrint(
        'ConnectionStorage: Failed to save CSRF token for server $serverId: $e',
      );
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<String?>> loadCsrfToken(String serverId) async {
    try {
      final key = '$serverId$_csrfTokenKeySuffix';
      final token = await _secureStorage.get(key);
      return Result.success(token is String ? token : null);
    } catch (e) {
      debugPrint(
        'ConnectionStorage: Failed to load CSRF token for server $serverId: $e',
      );
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteCsrfToken(String serverId) async {
    try {
      final key = '$serverId$_csrfTokenKeySuffix';
      await _secureStorage.delete(key);
      return Result.success(null);
    } catch (e) {
      debugPrint(
        'ConnectionStorage: Failed to delete CSRF token for server $serverId: $e',
      );
      return Result.failure(e.toString());
    }
  }
}
