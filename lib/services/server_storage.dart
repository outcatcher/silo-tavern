library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/server.dart';

part 'server_models.dart';

class ServerStorage {
  static const String _serversKeyPrefix = 'servers';

  final SharedPreferencesAsync _prefs;
  final FlutterSecureStorage _secureStorage;

  ServerStorage(this._prefs, this._secureStorage);

  /// Load all servers from persistent storage
  Future<List<Server>> listServers() async {
    final serversRaw = await _prefs.getAll();
    final serverIDs = await _prefs.getKeys();
    final authsRaw = await _secureStorage.readAll();

    final List<Server> servers = [];

    for (final id in serverIDs) {
      final serverAuth = authFromJson(authsRaw[id]);
      final server = _ServiceServer.fromJson(
        serversRaw[id] as Map<String, dynamic>,
      );

      servers.add(server.toDomain(serverAuth));
    }

    return servers;
  }

  /// Get a specific server by ID
  Future<Server?> getServer(String id) async {
    final auth = await _getAuth(id);
    final server = (await _getServer(id)).toDomain(auth);

    return server;
  }

  /// Create a new server
  Future<void> createServer(Server server) async {
    if (await _prefs.containsKey(server.id)) {
      throw Exception('Server with ID ${server.id} already exists');
    }

    final serviceServer = _ServiceServer.fromDomain(server);

    final serverJson = jsonEncode(serviceServer.toJson());
    await _prefs.setString(server.id, serverJson);

    await _setAuth(server.id, server.authentication);
  }

  /// Update an existing server
  Future<void> updateServer(Server server) async {
    final _ = await _getServer(server.id); // throws error if not found

    final serviceServer = _ServiceServer(
      id: server.id,
      name: server.name,
      address: server.address,
    );

    final serverJson = jsonEncode(serviceServer.toJson());
    await _prefs.setString(server.id, serverJson);

    await _setAuth(server.id, server.authentication);
  }

  /// Delete a server and its credentials from storage
  Future<void> deleteServer(String serverId) async {
    await _secureStorage.delete(key: serverId);
    await _prefs.remove(serverId);
  }

  /// Get service server by ID (throws exception if not found)
  Future<_ServiceServer> _getServer(String serverId) async {
    final existingJSON = await _prefs.getString(serverId);

    if (existingJSON == null) {
      throw Exception('Server with ID $serverId not found');
    }

    return _ServiceServer.fromJson(
      jsonDecode(existingJSON) as Map<String, dynamic>,
    );
  }

  /// Set authentication for a server
  Future<void> _setAuth(String id, AuthenticationInfo auth) async {
    if (!auth.useCredentials) {
      return;
    }

    final authData = {'username': auth.username, 'password': auth.password};
    final authJSON = jsonEncode(authData);
    await _secureStorage.write(key: id, value: authJSON);
  }

  /// Set authentication for a server
  Future<AuthenticationInfo> _getAuth(String id) async {
    final authJSON = await _secureStorage.read(key: id);

    return authFromJson(authJSON);
  }

  AuthenticationInfo authFromJson(String? raw) {
    if (raw == null) {
      return AuthenticationInfo.none();
    }

    final Map<String, dynamic> authMap = jsonDecode(raw);
    return AuthenticationInfo.credentials(
      username: authMap['username'],
      password: authMap['password'],
    );
  }
}
