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

class ConnectionDomain {
  final ConnectionSessionFactory sessionFactory;
  final ConnectionStorage secureStorage;

  final Map<String, ConnectionSessionInterface> _sessions = {};

  ConnectionDomain({required this.sessionFactory, required this.secureStorage});

  factory ConnectionDomain.defaultInstance(FlutterSecureStorage sec) {
    return ConnectionDomain(
      sessionFactory: DefaultConnectionFactory(),
      secureStorage: ConnectionStorage.defaultInstance(sec),
    );
  }

  /// Get an authenticated client for making requests to the server
  ConnectionSessionInterface? getClient(String serverId) {
    return _sessions[serverId];
  }

  /// Authenticate with a server using the provided credentials
  Future<ConnectionResult> authenticateWithServer(
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
        await secureStorage.saveSessionCookies(server.id, cookies);
      }

      // Authentication successful
      return ConnectionResult.success();
    } catch (e) {
      debugPrint(
        'ConnectionDomain: Failed to authenticate with server ${server.id}: $e',
      );
      return ConnectionResult.failure(e.toString());
    }
  }

  /// Obtain a CSRF token for a server
  Future<ConnectionResult> obtainCsrfTokenForServer(
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
        await secureStorage.saveCsrfToken(server.id, token);
      }

      return ConnectionResult.success();
    } catch (e) {
      debugPrint(
        'ConnectionDomain: Failed to obtain CSRF token for server ${server.id}: $e',
      );
      return ConnectionResult.failure(e.toString());
    }
  }

  /// Check if a server is available by making a GET request to the root path
  Future<bool> checkServerAvailability(server_models.Server server) async {
    try {
      // Create a temporary session to check availability
      final session = sessionFactory.create(server.address);
      return await session.checkServerAvailability();
    } catch (e) {
      debugPrint('Failed to check server availability for ${server.id}: $e');
      return false;
    }
  }

  /// Check if a server session already exists
  bool hasExistingSession(server_models.Server server) {
    return _sessions.containsKey(server.id);
  }

  /// Check if a server has a persistent session
  Future<bool> hasPersistentSession(server_models.Server server) async {
    try {
      final cookies = await secureStorage.loadSessionCookies(server.id);
      return cookies != null && cookies.isNotEmpty;
    } catch (e) {
      debugPrint('ConnectionDomain: Failed to check for persistent session for server ${server.id}: $e');
      return false;
    }
  }

  /// Test-only method to add a session to the domain
  @visibleForTesting
  void testOnlyAddSession(String serverId, ConnectionSessionInterface session) {
    _sessions[serverId] = session;
  }
}
