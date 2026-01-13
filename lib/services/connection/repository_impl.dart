import 'package:cookie_jar/cookie_jar.dart';
import 'package:silo_tavern/common/result.dart';
import 'package:silo_tavern/domain/connection/repository.dart';
import 'package:silo_tavern/services/connection/storage.dart';

/// Implementation of ConnectionRepository that wraps ConnectionStorage
class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionStorage _storage;

  ConnectionRepositoryImpl(this._storage);

  @override
  Future<Result<void>> saveSessionCookies(String serverId, List<Cookie> cookies) async {
    try {
      await _storage.saveSessionCookies(serverId, cookies);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<Cookie>?>> loadSessionCookies(String serverId) async {
    try {
      final cookies = await _storage.loadSessionCookies(serverId);
      return Result.success(cookies);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> saveCsrfToken(String serverId, String token) async {
    try {
      await _storage.saveCsrfToken(serverId, token);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<String?>> loadCsrfToken(String serverId) async {
    try {
      final token = await _storage.loadCsrfToken(serverId);
      return Result.success(token);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteCsrfToken(String serverId) async {
    try {
      await _storage.deleteCsrfToken(serverId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}