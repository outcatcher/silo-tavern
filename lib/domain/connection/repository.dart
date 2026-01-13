import 'package:silo_tavern/common/result.dart';
import 'package:cookie_jar/cookie_jar.dart';

/// Repository interface for connection data operations
/// This abstracts the data access layer from the domain layer
abstract class ConnectionRepository {
  /// Save session cookies for a server
  Future<Result<void>> saveSessionCookies(String serverId, List<Cookie> cookies);

  /// Load session cookies for a server
  Future<Result<List<Cookie>?>> loadSessionCookies(String serverId);

  /// Save CSRF token for a server
  Future<Result<void>> saveCsrfToken(String serverId, String token);

  /// Load CSRF token for a server
  Future<Result<String?>> loadCsrfToken(String serverId);

  /// Delete CSRF token for a server
  Future<Result<void>> deleteCsrfToken(String serverId);
}