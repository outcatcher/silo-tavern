library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/servers/models.dart';
import '../../utils/app_storage.dart';

part 'models.dart';

class ServerStorage {
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
  Future<List<Server>> listServers() async {
    final serversData = await _storage.list();

    final List<Server> servers = [];

    for (final serverData in serversData) {
      final id = serverData['id'] as String;
      final authData = await _secureStorage.get(id);
      final auth = _authFromJson(authData);

      final server = _ServiceServer.fromJson(serverData);
      servers.add(server.toDomain(auth));
    }

    return servers;
  }

  /// Get a specific server by ID
  Future<Server?> getServer(String id) async {
    final serverData = await _storage.get(id);
    if (serverData == null) {
      return null;
    }

    final authData = await _secureStorage.get(id);
    final auth = _authFromJson(authData);
    final server = _ServiceServer.fromJson(serverData);

    return server.toDomain(auth);
  }

  /// Create a new server
  Future<void> createServer(Server server) async {
    final existing = await _storage.get(server.id);
    if (existing != null) {
      throw Exception('Server with ID ${server.id} already exists');
    }

    final serviceServer = _ServiceServer.fromDomain(server);
    await _storage.set(server.id, serviceServer.toJson());

    if (server.authentication.useCredentials) {
      await _secureStorage.set(server.id, server.authentication.toJson());
    }
  }

  /// Update an existing server
  Future<void> updateServer(Server server) async {
    final existing = await _storage.get(server.id);
    if (existing == null) {
      throw Exception('Server with ID ${server.id} not found');
    }

    final serviceServer = _ServiceServer.fromDomain(server);
    await _storage.set(server.id, serviceServer.toJson());

    if (server.authentication.useCredentials) {
      await _secureStorage.set(server.id, server.authentication.toJson());
    } else {
      // If not using credentials, delete any existing auth data
      await _secureStorage.delete(server.id);
    }
  }

  /// Delete a server and its credentials from storage
  Future<void> deleteServer(String serverId) async {
    await _storage.delete(serverId);
    await _secureStorage.delete(serverId);
  }

  AuthenticationInfo _authFromJson(Map<String, dynamic>? data) {
    if (data == null) {
      return AuthenticationInfo.none();
    }

    return AuthenticationInfo.credentials(
      username: data['username'] as String,
      password: data['password'] as String,
    );
  }
}
