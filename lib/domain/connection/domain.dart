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

  /// Connect to a server using server model from server domain
  Future<ConnectionResult> connectToServer(server_models.Server server) async {
    final existingCookies = await secureStorage.loadSessionCookies(server.id);

    final session = sessionFactory.create(
      server.address,
      cookies: existingCookies,
    );
    _sessions[server.id] = session;

    // Restoring session
    if (existingCookies != null) {
      return ConnectionResult.success();
    }

    try {
      await session.obtainCsrfToken();
    } catch (e) {
      debugPrint(
        'ConnectionDomain: Failed to obtain CSRF token for server ${server.id}: $e',
      );
      return ConnectionResult.failure(e.toString());
    }

    // Authentication is no longer supported
    return ConnectionResult.success();
  }

  /// Get an authenticated client for making requests to the server
  ConnectionSessionInterface? getClient(String serverId) {
    return _sessions[serverId];
  }

  /// Shallow authentication method for testing purposes
  /// This method does nothing and always returns success
  Future<ConnectionResult> authenticateWithServer(
    server_models.Server server,
    ConnectionCredentials credentials,
  ) async {
    // This is a shallow implementation for testing purposes
    // In a real implementation, this would perform actual authentication
    return ConnectionResult.success();
  }

  /// Shallow CSRF token method for testing purposes
  /// This method does nothing and always returns success
  Future<ConnectionResult> obtainCsrfTokenForServer(
    server_models.Server server,
  ) async {
    // This is a shallow implementation for testing purposes
    // In a real implementation, this would obtain a CSRF token
    return ConnectionResult.success();
  }
}
