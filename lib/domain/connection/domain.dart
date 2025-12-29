/// Connection domain for managing server connections
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';

import '../servers/models.dart' as server_models;
import '../../services/connection/interface.dart';
import 'models.dart';

class ConnectionOptions {
  final ConnectionServiceInterface connectionService;
  final FlutterSecureStorage secureStorage;

  ConnectionOptions({
    required this.connectionService,
    required this.secureStorage,
  });
}

class ConnectionDomain {
  final ConnectionServiceInterface _connectionService;
  final FlutterSecureStorage _secureStorage;
  
  // In-memory cache for credentials to support re-authentication
  final Map<String, ConnectionCredentials> _credentialCache = {};
  
  // Mutex to ensure thread-safe operations
  final Mutex _mutex = Mutex();

  ConnectionDomain(ConnectionOptions options)
    : _connectionService = options.connectionService,
      _secureStorage = options.secureStorage;

  /// Connect to a server using server model from server domain
  Future<ConnectionResult> connectToServer(server_models.Server server) async {
    return _mutex.protect(() async {
      try {
        // Step 1: Obtain CSRF token
        final csrfToken = await _connectionService.obtainCsrfToken(server.address);
        
        // Step 2: Authenticate if credentials are provided
        if (server.authentication.useCredentials) {
          final credentials = ConnectionCredentials(
            username: server.authentication.username,
            password: server.authentication.password,
          );
          
          await _connectionService.authenticate(
            server.address,
            csrfToken,
            credentials,
          );
          
          // Cache credentials for potential re-authentication
          _credentialCache[server.id] = credentials;
        }
        
        return ConnectionResult.success();
      } catch (e) {
        return ConnectionResult.failure(e.toString());
      }
    });
  }

  /// Get an authenticated client for making requests to the server
  Future<AuthenticatedClient> getAuthenticatedClient(String serverId, String baseUrl) async {
    // In a real implementation, this would return a client with
    // CSRF headers and cookies pre-configured
    return AuthenticatedClient(serverId: serverId, baseUrl: baseUrl);
  }

  /// Disconnect from a server and clear all stored tokens/cookies
  Future<void> disconnect(String serverId) async {
    await _mutex.protect(() async {
      await _connectionService.disconnect(serverId);
      _credentialCache.remove(serverId);
    });
  }

  /// Attempt to re-authenticate with cached credentials
  Future<ConnectionResult> reauthenticate(String serverId, String serverUrl) async {
    return _mutex.protect(() async {
      try {
        // Check if we have cached credentials
        if (!_connectionService.hasCachedCredentials(serverId) && 
            !_credentialCache.containsKey(serverId)) {
          return ConnectionResult.failure('No cached credentials available for re-authentication');
        }

        // Get credentials from cache
        final credentials = _credentialCache[serverId];
        if (credentials == null) {
          return ConnectionResult.failure('No cached credentials available for re-authentication');
        }

        // Obtain new CSRF token
        final csrfToken = await _connectionService.obtainCsrfToken(serverUrl);
        
        // Re-authenticate with the server
        await _connectionService.authenticate(
          serverUrl,
          csrfToken,
          credentials,
        );
        
        return ConnectionResult.success();
      } catch (e) {
        return ConnectionResult.failure('Re-authentication failed: ${e.toString()}');
      }
    });
  }

  /// Check if we're connected to a server
  Future<bool> isConnected(String serverId) async {
    // In a real implementation, this would check if we have valid tokens/cookies
    return _connectionService.hasCachedCredentials(serverId) || _credentialCache.containsKey(serverId);
  }
}