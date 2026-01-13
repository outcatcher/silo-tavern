import 'package:silo_tavern/common/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';

/// Repository interface for server data operations
/// This abstracts the data access layer from the domain layer
abstract class ServerRepository {
  /// Get all servers
  Future<Result<List<Server>>> getAll();

  /// Get a server by its ID
  Future<Result<Server?>> getById(String id);

  /// Create a new server
  Future<Result<void>> create(Server server);

  /// Update an existing server
  Future<Result<void>> update(Server server);

  /// Delete a server by its ID
  Future<Result<void>> delete(String id);
}
