import 'package:mutex/mutex.dart';

import '../services/server_storage.dart';
import '../utils/network_utils.dart';
import 'server.dart';

class ServerOptions {
  final ServerStorage storage;

  ServerOptions(this.storage);
}

class ServerService {
  final List<Server> _servers = [];
  final ServerStorage _storage;

  final locker = Mutex();

  ServerService(ServerOptions options) : _storage = options.storage;

  // Factory constructor for async initialization
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
    NetworkUtils.validateServerConfiguration(server);

    _servers.add(server);
    await locker.protect(() => _storage.createServer(server));
  }

  // Update an existing server
  Future<void> updateServer(Server updatedServer) async {
    final index = _servers.indexWhere((s) => s.id == updatedServer.id);
    if (index == -1) {
      return;
    }

    // Only add server if configuration is allowed
    NetworkUtils.validateServerConfiguration(updatedServer);
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
}
