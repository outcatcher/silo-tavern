import 'server.dart';

class ServerService {
  final List<Server> _servers = [
    Server(
      id: '1',
      name: 'Production Server',
      address: 'prod.example.com',
      isActive: true,
    ),
    Server(
      id: '2',
      name: 'Staging Server',
      address: 'staging.example.com',
      isActive: false,
    ),
    Server(
      id: '3',
      name: 'Development Server',
      address: 'dev.example.com',
      isActive: true,
    ),
  ];

  // Getter for servers list
  List<Server> get servers => List.unmodifiable(_servers);

  // Add a new server
  void addServer(Server server) {
    _servers.add(server);
  }

  // Update an existing server
  void updateServer(Server updatedServer) {
    final index = _servers.indexWhere((s) => s.id == updatedServer.id);
    if (index != -1) {
      _servers[index] = updatedServer;
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