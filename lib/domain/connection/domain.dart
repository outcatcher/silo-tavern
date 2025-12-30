/// Connection domain for managing server connections
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/services/connection/network.dart';
import 'package:silo_tavern/services/connection/storage.dart';

import '../servers/models.dart' as server_models;
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

    await session.obtainCsrfToken();

    if (server.authentication.useCredentials) {
      final credentials = ConnectionCredentials(
        username: server.authentication.username,
        password: server.authentication.password,
      );

      try {
        await session.authenticate(credentials);

        return ConnectionResult.success();
      } catch (e) {
        return ConnectionResult.failure(e.toString());
      }
    }

    return ConnectionResult.success();
  }

  /// Get an authenticated client for making requests to the server
  ConnectionSessionInterface? getClient(String serverId) {
    return _sessions[serverId];
  }
}
