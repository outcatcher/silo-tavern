import 'package:silo_tavern/domain/servers/models.dart';

/// Repository interface for server data operations
/// This abstracts the data access layer from the domain layer
abstract class ServerRepository {
  /// Get all servers
  Future<List<Server>> getAll();

  /// Get a server by its ID
  Future<Server?> getById(String id);

  /// Create a new server
  Future<void> create(Server server);

  /// Update an existing server
  Future<void> update(Server server);

  /// Delete a server by its ID
  Future<void> delete(String id);
}
