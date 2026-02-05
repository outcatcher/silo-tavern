import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/ui/utils.dart';

/// Cache for authentication checks to improve performance
final Map<String, bool> _authCache = {};

/// Clear the authentication cache (use when logging out or when auth state changes)
void clearAuthCache() {
  _authCache.clear();
}

/// Clear the authentication cache for testing
void clearAuthCacheForTesting() {
  _authCache.clear();
}

/// Redirect function to guard server routes requiring authentication
Future<String?> serverAuthGuard({
  required BuildContext context,
  required GoRouterState state,
  required ServerDomain serverDomain,
  required ConnectionDomain connectionDomain,
}) async {
  final serverId = state.pathParameters['id'];
  if (serverId == null) {
    return defaultPage; // Redirect to server list if no server ID
  }

  // Check memory cache first (fastest)
  if (_authCache.containsKey(serverId)) {
    return _authCache[serverId]! ? null : defaultPage;
  }

  // Find the server
  final server = serverDomain.findServerById(serverId);
  if (server == null) {
    return defaultPage; // Redirect to server list if server not found
  }

  // Check if there's a valid session for this server
  final hasSession = connectionDomain.hasExistingSession(server);

  // If no existing session, check for persistent session
  bool hasPersistentSession = false;
  if (!hasSession) {
    hasPersistentSession = await connectionDomain.hasPersistentSession(server);
  }

  final hasValidSession = hasSession || hasPersistentSession;

  // Cache the result for performance
  _authCache[serverId] = hasValidSession;

  // Return null to proceed or redirect path
  return hasValidSession ? null : defaultPage;
}
