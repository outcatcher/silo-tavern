import 'server.dart';
import '../utils/network_utils.dart';

class ServerService {
  final List<Server> _servers = [
    Server(
      id: '1',
      name: 'Production Server',
      address: 'https://prod.example.com',
      authentication: AuthenticationInfo.credentials(
        username: "user",
        password: "pass",
      ),
    ),
    Server(
      id: '2',
      name: 'Staging Server',
      address: 'https://staging.example.com',
      authentication: AuthenticationInfo.credentials(
        username: "user",
        password: "pass",
      ),
    ),
    Server(
      id: '3',
      name: 'Development Server',
      address: 'http://localhost:8000',
    ),
  ];

  // Getter for servers list
  List<Server> get servers => List.unmodifiable(_servers);

  // Add a new server
  void addServer(Server server) {
    // Check for duplicate ID
    if (_servers.any((s) => s.id == server.id)) {
      throw ArgumentError('Server with ID "${server.id}" already exists');
    }

    // Only add server if configuration is allowed
    if (NetworkUtils.isServerConfigurationAllowed(server)) {
      _servers.add(server);
    } else {
      throw ArgumentError(
        'Server addition not allowed: Remote servers must use HTTPS and authentication',
      );
    }
  }

  // Update an existing server
  void updateServer(Server updatedServer) {
    final index = _servers.indexWhere((s) => s.id == updatedServer.id);
    if (index == -1) {
      return;
    }

    // Only update server if configuration is allowed
    if (NetworkUtils.isServerConfigurationAllowed(updatedServer)) {
      _servers[index] = updatedServer;
    } else {
      throw ArgumentError(
        'Server update not allowed: Remote servers must use HTTPS and authentication',
      );
    }
  }

  // Remove a server by ID
  void removeServer(String id) {
    _servers.removeWhere((server) => server.id == id);
  }

  // Find a server by ID
  Server? findServerById(String id) {
    try {
      return _servers.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get server count
  int get serverCount => _servers.length;
}
