import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/servers/storage.dart';
import '../../utils/network_utils.dart';
import 'models.dart';
import '../connection/domain.dart';

class ServerOptions {
  final ServerStorage storage;
  final ConnectionDomain connectionDomain;

  ServerOptions(this.storage, {required this.connectionDomain});

  factory ServerOptions.fromRawStorage(
    SharedPreferencesAsync prefs,
    FlutterSecureStorage sec, {
    required ConnectionDomain connectionDomain,
  }) {
    return ServerOptions(
      ServerStorage.fromRawStorage(prefs, sec),
      connectionDomain: connectionDomain,
    );
  }
}

class ServerDomain {
  final Map<String, Server> _serversMap = {};
  final ServerStorage _storage;
  final ConnectionDomain _connectionDomain;

  final _serverListLocker = Mutex();

  ServerDomain(ServerOptions options)
    : _storage = options.storage,
      _connectionDomain = options.connectionDomain;

  /// Access to the underlying connection domain
  ConnectionDomain get connectionDomain => _connectionDomain;

  // Initialize the service by loading servers
  Future<void> initialize() async {
    await _reLoadServers();
  }

  // Load servers from persistent storage
  Future<void> _reLoadServers() async {
    _serversMap.clear();

    await _serverListLocker.protect(() async {
      final servers = await _storage.listServers();
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
  Future<void> addServer(Server server) async {
    // Check for duplicate ID
    if (_serversMap.containsKey(server.id)) {
      throw ArgumentError('Server with ID "${server.id}" already exists');
    }

    // Only add server if configuration is allowed
    validateServerConfiguration(server);

    // Add server with 'offline' status
    server.updateStatus(ServerStatus.offline);
    _serversMap[server.id] = server;
    await _serverListLocker.protect(() => _storage.createServer(server));
  }

  // Update an existing server
  Future<void> updateServer(Server updatedServer) async {
    final existingServer = _serversMap[updatedServer.id];
    if (existingServer == null) {
      throw ArgumentError('Server with ID "${updatedServer.id}" does\'t exist');
    }

    // Only add server if configuration is allowed
    validateServerConfiguration(updatedServer);
    // Update server but preserve current status
    final currentStatus = existingServer.status;
    updatedServer.updateStatus(currentStatus);
    _serversMap[updatedServer.id] = updatedServer;
    await _serverListLocker.protect(() => _storage.updateServer(updatedServer));
  }

  // Remove a server by ID
  Future<void> removeServer(String id) async {
    _serversMap.remove(id);
    await _serverListLocker.protect(() => _storage.deleteServer(id));
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
/// Local servers are always allowed
/// Remote servers must be HTTPS
void validateServerConfiguration(Server server) {
  final isHttps = server.address.startsWith('https://');
  final isLocal = NetworkUtils.isLocalAddress(server.address);

  // Local addresses are always allowed
  if (isLocal) {
    return;
  }

  // For remote addresses: must be HTTPS
  if (!isHttps) {
    throw ArgumentError('HTTPS must be used for external servers');
  }
}
