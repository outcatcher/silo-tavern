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
  final List<Server> _servers = [];
  final ServerStorage _storage;
  final ConnectionDomain _connectionDomain;

  final locker = Mutex();

  ServerDomain(ServerOptions options)
    : _storage = options.storage,
      _connectionDomain = options.connectionDomain;

  // Initialize the service by loading servers
  Future<void> initialize() async {
    await _reLoadServers();
  }

  // Load servers from persistent storage
  Future<void> _reLoadServers() async {
    _servers.clear();

    await locker.protect(() async {
      _servers.addAll(await _storage.listServers());
    });
  }

  // Getter for servers list
  List<Server> get servers => List.unmodifiable(_servers);

  // Getter for server count
  int get serverCount => _servers.length;

  // Add a new server
  Future<void> addServer(Server server) async {
    // Check for duplicate ID
    if (_servers.any((s) => s.id == server.id)) {
      throw ArgumentError('Server with ID "${server.id}" already exists');
    }

    // Only add server if configuration is allowed
    validateServerConfiguration(server);

    _servers.add(server);
    await locker.protect(() => _storage.createServer(server));
  }

  // Update an existing server
  Future<void> updateServer(Server updatedServer) async {
    final index = _servers.indexWhere((s) => s.id == updatedServer.id);
    if (index == -1) {
      throw ArgumentError('Server with ID "${updatedServer.id}" does\'t exist');
    }

    // Only add server if configuration is allowed
    validateServerConfiguration(updatedServer);
    _servers[index] = updatedServer;
    await locker.protect(() => _storage.updateServer(updatedServer));
  }

  // Remove a server by ID
  Future<void> removeServer(String id) async {
    _servers.removeWhere((server) => server.id == id);
    await locker.protect(() => _storage.deleteServer(id));
  }

  // Find a server by ID
  Server? findServerById(String id) {
    try {
      return _servers.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  // Connect to a server
  Future<ServerConnectionResult> connectToServer(Server server) async {
    try {
      // Use the connection domain to connect to the server
      final result = await _connectionDomain.connectToServer(server);

      if (result.isSuccess) {
        // Connection successful
        return ServerConnectionResult.success(server);
      } else {
        // Connection failed
        return ServerConnectionResult.failure(
          server,
          result.errorMessage ?? 'Unknown error',
        );
      }
    } catch (e) {
      // Connection failed
      return ServerConnectionResult.failure(server, e.toString());
    }
  }
}

/// Validates if a server configuration is allowed based on security rules
/// Local servers are always allowed
/// Remote servers must be HTTPS and have authentication
void validateServerConfiguration(Server server) {
  final isHttps = server.address.startsWith('https://');
  final hasAuthentication = server.authentication.useCredentials;
  final isLocal = NetworkUtils.isLocalAddress(server.address);

  // Local addresses are always allowed
  if (isLocal) {
    return;
  }

  // For remote addresses: must be HTTPS AND have authentication
  if (!isHttps) {
    throw ArgumentError('HTTPS must be used for external servers');
  }

  if (!hasAuthentication) {
    throw ArgumentError('Authentication must be used for external servers');
  }
}
