import 'package:silo_tavern/common/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/repository.dart';
import 'package:silo_tavern/services/servers/storage.dart';

/// Implementation of ServerRepository that wraps ServerStorage
class ServerRepositoryImpl implements ServerRepository {
  final ServerStorage _storage;

  ServerRepositoryImpl(this._storage);

  @override
  Future<Result<List<Server>>> getAll() async {
    try {
      final servers = await _storage.listServers();
      return Result.success(servers);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<Server?>> getById(String id) async {
    try {
      final server = await _storage.getServer(id);
      return Result.success(server);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> create(Server server) async {
    try {
      await _storage.createServer(server);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> update(Server server) async {
    try {
      await _storage.updateServer(server);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _storage.deleteServer(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}