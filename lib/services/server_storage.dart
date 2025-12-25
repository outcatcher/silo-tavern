library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../domain/server.dart';

part 'server_models.dart';

class ServerStorage {
  static const String _serversKey = 'servers';
  static const String _authPrefix = 'auth_';

  final SharedPreferencesAsync _prefs;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid = const Uuid();

  ServerStorage(this._prefs, this._secureStorage);
  ServerStorage.persistent()
    : _prefs = SharedPreferencesAsync(),
      _secureStorage = FlutterSecureStorage();

  /// Load all servers from persistent storage
  Future<List<Server>> listServers() async {
    try {
      final serversJson = await _prefs.getString(_serversKey);
      if (serversJson == null) {
        return <Server>[];
      }

      final List<dynamic> serversData = jsonDecode(serversJson);

      final servers = <Server>[];
      for (final serverData in serversData) {
        final data = _ServiceServer.fromJson(
          serverData as Map<String, dynamic>,
        );

        // Load authentication info if credentialsId exists
        AuthenticationInfo auth = const AuthenticationInfo.none();
        auth = await _loadAuthentication(data.credentialsId);

        final server = Server(
          id: data.id,
          name: data.name,
          address: data.address,
          authentication: auth,
        );
        servers.add(server);
      }

      return servers;
    } catch (e) {
      // Return empty list if any error occurs
      return <Server>[];
    }
  }

  /// Get a specific server by ID
  Future<Server?> getServer(String id) async {
    try {
      final servers = await listServers();
      return servers.firstWhere((server) => server.id == id);
    } catch (e) {
      // Return null if server not found or any other error occurs
      return null;
    }
  }

  /// Create a new server
  Future<void> createServer(Server server) async {
    try {
      final servers = await listServers();
      // Check if server with same ID already exists
      if (servers.any((s) => s.id == server.id)) {
        throw Exception('Server with ID ${server.id} already exists');
      }
      servers.add(server);
      await _saveAllServers(servers);
    } catch (e) {
      // Re-throw the exception to be handled by the caller
      throw Exception('Failed to create server: $e');
    }
  }

  Future<_ServiceServer> _getServer(String serverId) async {
    final existingJSON = await _prefs.getString(serverId);

    if (existingJSON == null) {
      throw Exception('Server with ID $serverId not found');
    }

    return _ServiceServer.fromJson(jsonDecode(existingJSON));
  }

  Future<AuthenticationInfo> _getAuth(String serverId) async {
    final authJson = await _secureStorage.read(key: serverId);
    if (authJson == null) {
      return AuthenticationInfo.none();
    }

    final authData = jsonDecode(authJson) as Map<String, dynamic>;
    return AuthenticationInfo.credentials(
      username: authData['username'],
      password: authData['password'],
    );
  }

  Future<void> _setAuth(String id, AuthenticationInfo auth) async {
    if (auth == AuthenticationInfo.none()) {
      return;
    }

    final authJSON = jsonEncode(auth);
    await _secureStorage.write(key: id, value: authJSON);
  }

  /// Update an existing server
  Future<void> updateServer(Server server) async {
    final _ = await _getServer(server.id); // throws error if not found
    final updated = _ServiceServer(
      id: server.id,
      address: server.address,
      name: server.name,
    );

    final updatedJSON = jsonEncode(updated);

    await _prefs.setString(server.id, updatedJSON);

    await _setAuth(server.id, server.authentication);
  }

  /// Save authentication info to secure storage
  Future<String> _saveAuthentication(AuthenticationInfo auth) async {
    try {
      final credentialsId = _uuid.v4();
      final authData = {'username': auth.username, 'password': auth.password};

      await _secureStorage.write(
        key: '$_authPrefix$credentialsId',
        value: jsonEncode(authData),
      );

      return credentialsId;
    } catch (e) {
      // Re-throw the exception to be handled by the caller
      throw Exception('Failed to save authentication: $e');
    }
  }

  /// Save all servers to persistent storage
  Future<void> _saveAllServers(List<Server> servers) async {
    try {
      // Convert servers to service model format
      final serviceServers = <_ServiceServer>[];
      final credentialsIds =
          <String, String>{}; // Map of serverId to credentialsId

      for (final server in servers) {
        String? credentialsId;

        // Save authentication info if credentials exist
        if (server.authentication.useCredentials) {
          credentialsId = await _saveAuthentication(server.authentication);
          credentialsIds[server.id] = credentialsId;
        }

        // Find existing credentialsId if server already had one
        final existingServiceServer = await _findServiceServer(server.id);
        final serviceServer = _ServiceServer(
          id: server.id,
          name: server.name,
          address: server.address,
        );

        serviceServers.add(serviceServer);
      }

      // Serialize and save servers data
      final serversJson = jsonEncode(
        serviceServers.map((s) => s.toJson()).toList(),
      );

      await _prefs.setString(_serversKey, serversJson);
    } catch (e) {
      // Re-throw the exception to be handled by the caller
      throw Exception('Failed to save servers: $e');
    }
  }

  /// Find a service server by ID
  Future<_ServiceServer?> _findServiceServer(String id) async {
    try {
      final serversJson = await _prefs.getString(_serversKey);
      if (serversJson == null) {
        return null;
      }

      final List<dynamic> serversData = jsonDecode(serversJson);
      for (final serverData in serversData) {
        final data = _ServiceServer.fromJson(
          serverData as Map<String, dynamic>,
        );
        if (data.id == id) {
          return data;
        }
      }

      return null;
    } catch (e) {
      // Return null if any error occurs
      return null;
    }
  }

  /// Load authentication info from secure storage
  Future<AuthenticationInfo> _loadAuthentication(String? credentialsId) async {
    try {
      if (credentialsId == null) {
        return const AuthenticationInfo.none();
      }

      final authJson = await _secureStorage.read(
        key: '$_authPrefix$credentialsId',
      );

      if (authJson == null) {
        return const AuthenticationInfo.none();
      }

      final authData = jsonDecode(authJson) as Map<String, dynamic>;
      return AuthenticationInfo.credentials(
        username: authData['username'],
        password: authData['password'],
      );
    } catch (e) {
      // Return none if any error occurs
      return const AuthenticationInfo.none();
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    // Clear shared preferences
    await _prefs.remove(_serversKey);
  }

  /// Helper to check if server data contains credentials reference
  bool serverDataContainsCredentials(Server server) {
    // This is a simplified check - in practice we'd need to track this better
    return server.authentication.useCredentials;
  }

  /// Delete a server and its credentials from storage
  Future<void> deleteServer(String serverId) async {
    try {
      // Load existing servers
      final servers = await listServers();

      // Find the server to delete
      final serverToDelete = servers.firstWhereOrNull(
        (server) => server.id == serverId,
      );

      // If server has credentials, delete them
      if (serverToDelete != null &&
          serverToDelete.authentication.useCredentials) {
        // We need to find the credentials ID to delete it
        final serviceServer = await _findServiceServer(serverId);
        if (serviceServer?.credentialsId != null) {
          await _secureStorage.delete(
            key: '$_authPrefix${serviceServer!.credentialsId}',
          );
        }
      }

      // Remove the server from the list and save
      final updatedServers = servers
          .where((server) => server.id != serverId)
          .toList();
      await _saveAllServers(updatedServers);
    } catch (e) {
      // Re-throw the exception to be handled by the caller
      throw Exception('Failed to delete server: $e');
    }
  }
}

extension on Iterable<Server> {
  Server? firstWhereOrNull(bool Function(Server) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
