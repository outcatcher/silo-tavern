/// Connection domain for managing server connections
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/domain/servers/models.dart' as server_models;
import 'package:silo_tavern/services/connection/models/models.dart';
import 'package:silo_tavern/services/connection/network.dart';
import 'package:silo_tavern/services/connection/storage.dart';

import 'models.dart';
import 'repository.dart';
import '../repositories.dart';
import '../../common/result.dart';

class ConnectionDomain {
  final ConnectionSessionFactory sessionFactory;
  final ConnectionRepository _repository;

  final Map<String, ConnectionSessionInterface> _sessions = {};

  ConnectionDomain({required this.sessionFactory, required ConnectionRepository repository})
    : _repository = repository;

  factory ConnectionDomain.defaultInstance(FlutterSecureStorage sec) {
    final storage = ConnectionStorage.defaultInstance(sec);
    return ConnectionDomain(
      sessionFactory: DefaultConnectionFactory(),
      repository: ConnectionRepositoryImpl(storage),
    );
  }

  /// Get an authenticated client for making requests to the server
  ConnectionSessionInterface? getClient(String serverId) {
    return _sessions[serverId];
  }

  /// Authenticate with a server using the provided credentials
  Future<Result<void>> authenticateWithServer(
    server_models.Server server,
    ConnectionCredentials credentials, {
    bool rememberMe = false,
  }) async {
    try {
      // Get or create a session for this server
      final session =
          _sessions[server.id] ?? sessionFactory.create(server.address);
      _sessions[server.id] = session;

      // Perform authentication
      await session.authenticate(credentials);

      // If rememberMe is true, save session cookies to secure storage
      if (rememberMe) {
        final cookies = await session.getSessionCookies();
        final result = await _repository.saveSessionCookies(server.id, cookies);
        if (result.isFailure) {
          debugPrint('ConnectionDomain: Failed to save session cookies: ${result.error}');
        }
      }

      // Authentication successful
      return Result.success(null);
    } catch (e) {
      debugPrint(
        'ConnectionDomain: Failed to authenticate with server ${server.id}: $e',
      );
      return Result.failure(e.toString());
    }
  }

  /// Obtain a CSRF token for a server
  Future<Result<void>> obtainCsrfTokenForServer(
    server_models.Server server,
  ) async {
    try {
      // Get or create a session for this server
      final session =
          _sessions[server.id] ?? sessionFactory.create(server.address);
      _sessions[server.id] = session;

      // Obtain CSRF token
      await session.obtainCsrfToken();

      // Save the obtained CSRF token
      final token = session.getCsrfToken();
      if (token != null) {
        final result = await _repository.saveCsrfToken(server.id, token);
        if (result.isFailure) {
          debugPrint('ConnectionDomain: Failed to save CSRF token: ${result.error}');
        }
      }

      return Result.success(null);
    } catch (e) {
      debugPrint(
        'ConnectionDomain: Failed to obtain CSRF token for server ${server.id}: $e',
      );
      return Result.failure(e.toString());
    }
  }

  /// Check if a server is available by making a GET request to the root path
  Future<Result<bool>> checkServerAvailability(
    server_models.Server server,
  ) async {
    try {
      // Create a temporary session to check availability
      final session = sessionFactory.create(server.address);
      final isAvailable = await session.checkServerAvailability();
      return Result.success(isAvailable);
    } catch (e) {
      debugPrint('Failed to check server availability for ${server.id}: $e');
      return Result.failure(e.toString());
    }
  }

  /// Check if a server session already exists
  bool hasExistingSession(server_models.Server server) {
    return _sessions.containsKey(server.id);
  }

  /// Check if a server has a persistent session
  Future<bool> hasPersistentSession(server_models.Server server) async {
    try {
      final result = await _repository.loadSessionCookies(server.id);
      if (result.isFailure) {
        debugPrint(
          'ConnectionDomain: Failed to load session cookies for server ${server.id}: ${result.error}',
        );
        return false;
      }
      
      final cookies = result.value;
      return cookies != null && cookies.isNotEmpty;
    } catch (e) {
      debugPrint(
        'ConnectionDomain: Failed to check for persistent session for server ${server.id}: $e',
      );
      return false;
    }
  }

  /// Test-only method to add a session to the domain
  @visibleForTesting
  void testOnlyAddSession(String serverId, ConnectionSessionInterface session) {
    _sessions[serverId] = session;
  }
}
