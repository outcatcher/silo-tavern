library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/servers/models.dart';
import '../../domain/servers/repository.dart';
import '../../common/app_storage.dart';
import '../../common/result.dart';

part 'models.dart';

class ServerStorage implements ServerRepository {
  static const String _serversKeyPrefix = 'servers';

  final JsonStorage _storage;
  final JsonSecureStorage _secureStorage;

  ServerStorage(JsonStorage prefs, JsonSecureStorage secureStorage)
    : _storage = prefs,
      _secureStorage = secureStorage;

  factory ServerStorage.fromRawStorage(
    SharedPreferencesAsync prefs,
    FlutterSecureStorage sec,
  ) {
    return ServerStorage(
      JsonStorage(prefs, _serversKeyPrefix),
      JsonSecureStorage(sec, _serversKeyPrefix),
    );
  }

  /// Load all servers from persistent storage
  @override
  Future<Result<List<Server>>> getAll() async {
    try {
      final serversData = await _storage.list();

      final List<Server> servers = [];

      for (final serverData in serversData) {
        final server = _ServiceServer.fromJson(serverData);
        servers.add(server.toDomain());
      }

      return Result.success(servers);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Get a specific server by ID
  @override
  Future<Result<Server?>> getById(String id) async {
    try {
      final serverData = await _storage.get(id);
      if (serverData == null) {
        return Result.success(null);
      }

      final server = _ServiceServer.fromJson(serverData);
      return Result.success(server.toDomain());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Create a new server
  @override
  Future<Result<void>> create(Server server) async {
    try {
      final existing = await _storage.get(server.id);
      if (existing != null) {
        return Result.failure('Server with ID ${server.id} already exists');
      }

      final serviceServer = _ServiceServer.fromDomain(server);
      await _storage.set(server.id, serviceServer.toJson());
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Update an existing server
  @override
  Future<Result<void>> update(Server server) async {
    try {
      final existing = await _storage.get(server.id);
      if (existing == null) {
        return Result.failure('Server with ID ${server.id} not found');
      }

      final serviceServer = _ServiceServer.fromDomain(server);
      await _storage.set(server.id, serviceServer.toJson());
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Delete a server and its credentials from storage
  @override
  Future<Result<void>> delete(String serverId) async {
    try {
      await _storage.delete(serverId);
      await _secureStorage.delete(serverId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
