import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silo_tavern/common/network_utils.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/repositories.dart';
import 'package:silo_tavern/domain/result.dart';
import 'package:silo_tavern/services/servers/storage.dart';

import 'models.dart';
import 'repository.dart';

class ServerOptions {
  final ServerRepository repository;
  final ConnectionDomain connectionDomain;

  ServerOptions(this.repository, {required this.connectionDomain});

  factory ServerOptions.fromRawStorage(
    SharedPreferencesAsync prefs,
    FlutterSecureStorage sec, {
    required ConnectionDomain connectionDomain,
  }) {
    final storage = ServerStorage.fromRawStorage(prefs, sec);
    return ServerOptions(storage, connectionDomain: connectionDomain);
  }
}

class ServerDomain {
  final Map<String, Server> _serversMap = {};
  final ServerRepository _repository;
  final ConnectionDomain _connectionDomain;

  final _serverListLocker = Mutex();

  ServerDomain(ServerOptions options)
    : _repository = options.repository,
      _connectionDomain = options.connectionDomain;

  /// Access to the underlying connection domain
  ConnectionDomain get connectionDomain => _connectionDomain;

  // Initialize the service by loading servers
  Future<Result<void>> initialize() async {
    try {
      await _reLoadServers();
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  // Load servers from persistent storage
  Future<void> _reLoadServers() async {
    _serversMap.clear();

    await _serverListLocker.protect(() async {
      final servers = await _repository.getAll();

      // Initialize all loaded servers with 'offline' status
      for (var server in servers) {
        server.updateStatus(ServerStatus.offline);
        _serversMap[server.id] = server;
      }
    });
  }

  // Getter for servers list
  List<Server> get servers {
    final servers = List.from(_serversMap.values);
    servers.sort((a, b) => a.id.compareTo(b.id));

    return List.unmodifiable(servers);
  }

  // Getter for server count
  int get serverCount => _serversMap.length;

  // Add a new server
  Future<Result<void>> addServer(Server server) async {
    try {
      // Check for duplicate ID
      if (_serversMap.containsKey(server.id)) {
        return Result.failure('Server with ID "${server.id}" already exists');
      }

      // Only add server if configuration is allowed
      final validationResult = validateServerConfiguration(server);
      if (validationResult.isFailure) {
        return validationResult;
      }

      // Add server with 'offline' status
      server.updateStatus(ServerStatus.offline);
      _serversMap[server.id] = server;
      await _serverListLocker.protect(() => _repository.create(server));
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  // Update an existing server
  Future<Result<void>> updateServer(Server updatedServer) async {
    try {
      final existingServer = _serversMap[updatedServer.id];
      if (existingServer == null) {
        return Result.failure(
          'Server with ID "${updatedServer.id}" does\'t exist',
        );
      }

      // Only add server if configuration is allowed
      final validationResult = validateServerConfiguration(updatedServer);
      if (validationResult.isFailure) {
        return validationResult;
      }

      // Update server but preserve current status
      final currentStatus = existingServer.status;
      updatedServer.updateStatus(currentStatus);
      _serversMap[updatedServer.id] = updatedServer;
      await _serverListLocker.protect(() => _repository.update(updatedServer));
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  // Remove a server by ID
  Future<Result<void>> removeServer(String id) async {
    try {
      _serversMap.remove(id);
      await _serverListLocker.protect(() => _repository.delete(id));
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  // Find a server by ID
  Server? findServerById(String id) {
    return _serversMap[id];
  }

  // Update server status
  void updateServerStatus(String serverId, ServerStatus status) {
    _serversMap[serverId]?.updateStatus(status);
  }

  Future<void> _checkServerStatus(
    Server server,
    void Function(Server server) serverUpdateCallback,
  ) async {
    try {
      // Update status to loading while checking
      updateServerStatus(server.id, ServerStatus.loading);

      // Check if the server is available
      final result = await _connectionDomain.checkServerAvailability(server);

      // Update status based on availability
      if (result.isSuccess) {
        updateServerStatus(
          server.id,
          result.value! ? ServerStatus.online : ServerStatus.offline,
        );
      } else {
        debugPrint(
          'ServerDomain: Failed to check status for server ${server.id}: ${result.error}',
        );
        updateServerStatus(server.id, ServerStatus.offline);
      }
    } catch (e) {
      debugPrint(
        'ServerDomain: Exception during status check for server ${server.id}: $e',
      );
      updateServerStatus(server.id, ServerStatus.offline);
    } finally {
      serverUpdateCallback(server);
    }
  }

  // Check the availability of all servers.
  // Calls `serverUpdateCallback` for the server as soon as update available.
  Future<void> checkAllServerStatuses(
    void Function(Server server) serverUpdateCallback,
  ) async {
    await _serverListLocker.protect(() async {
      await Future.forEach(_serversMap.values, (srv) async {
        await _checkServerStatus(srv, serverUpdateCallback);
      });
    });
  }
}

/// Validates if a server configuration is allowed based on security rules
/// Local servers are always allowedve
/// Remote servers must be HTTPS
Result<void> validateServerConfiguration(Server server) {
  final isHttps = server.address.startsWith('https://');
  final isLocal = NetworkUtils.isLocalAddress(server.address);

  // Local addresses are always allowed
  if (isLocal) {
    return Result.success(null);
  }

  // For remote addresses: must be HTTPS
  if (!isHttps) {
    return Result.failure('HTTPS must be used for external servers');
  }

  return Result.success(null);
}
