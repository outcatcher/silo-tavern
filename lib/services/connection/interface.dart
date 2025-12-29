/// Service interface for connection operations
library;

import '../../domain/connection/models.dart';

abstract class ConnectionServiceInterface {
  /// Obtain CSRF token from the server
  Future<String> obtainCsrfToken(String serverUrl);

  /// Authenticate with the server and obtain session cookies
  Future<void> authenticate(
    String serverUrl,
    String csrfToken,
    ConnectionCredentials credentials,
  );

  /// Disconnect from the server and clear stored tokens/cookies
  Future<void> disconnect(String serverId);

  /// Check if we have valid credentials cached for re-authentication
  bool hasCachedCredentials(String serverId);

  /// Get cached credentials for re-authentication
  ConnectionCredentials? getCachedCredentials(String serverId);
}
