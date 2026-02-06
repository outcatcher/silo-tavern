import 'package:cookie_jar/cookie_jar.dart';

/// Repository interface for connection data operations
/// This abstracts the data access layer from the domain layer
abstract class ConnectionRepository {
  /// Save session cookies for a server
  Future<void> saveSessionCookies(String serverId, List<Cookie> cookies);

  /// Load session cookies for a server
  Future<List<Cookie>?> loadSessionCookies(String serverId);

  /// Delete session cookies for a server
  Future<void> deleteSessionCookies(String serverId);

  /// Save CSRF token for a server
  Future<void> saveCsrfToken(String serverId, String token);

  /// Load CSRF token for a server
  Future<String?> loadCsrfToken(String serverId);

  /// Delete CSRF token for a server
  Future<void> deleteCsrfToken(String serverId);
}
