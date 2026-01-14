library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silo_tavern/common/app_storage.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/repository.dart';

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
  Future<List<Server>> getAll() async {
    final serversData = await _storage.list();

    final List<Server> servers = [];

    for (final serverData in serversData) {
      final server = _ServiceServer.fromJson(serverData);
      servers.add(server.toDomain());
    }

    return servers;
  }

  /// Get a specific server by ID
  @override
  Future<Server?> getById(String id) async {
    final serverData = await _storage.get(id);
    if (serverData == null) {
      return null;
    }

    final server = _ServiceServer.fromJson(serverData);
    return server.toDomain();
  }

  /// Create a new server
  @override
  Future<void> create(Server server) async {
    final existing = await _storage.get(server.id);
    if (existing != null) {
      throw ArgumentError('Server with ID ${server.id} already exists');
    }

    final serviceServer = _ServiceServer.fromDomain(server);
    await _storage.set(server.id, serviceServer.toJson());
  }

  /// Update an existing server
  @override
  Future<void> update(Server server) async {
    final existing = await _storage.get(server.id);
    if (existing == null) {
      throw ArgumentError('Server with ID ${server.id} not found');
    }

    final serviceServer = _ServiceServer.fromDomain(server);
    await _storage.set(server.id, serviceServer.toJson());
  }

  /// Delete a server and its credentials from storage
  @override
  Future<void> delete(String serverId) async {
    await _storage.delete(serverId);
    await _secureStorage.delete(serverId);
  }
}
