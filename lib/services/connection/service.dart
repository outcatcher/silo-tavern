/// Service for handling server connections
///
/// This service manages the connection workflow including:
/// - CSRF token requests
/// - Authentication handling
/// - Token storage
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/connection/models.dart';

class ConnectionService {
  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  // In-memory cache for credentials to support re-authentication
  final Map<String, ConnectionCredentials> _credentialCache = {};

  ConnectionService(this._secureStorage, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Obtain CSRF token from the server
  Future<String> obtainCsrfToken(String serverUrl) async {
    final uri = Uri.parse(serverUrl).resolve('/csrf-token');
    final response = await _httpClient.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonResponse['token'] as String;
    } else {
      throw Exception('Failed to obtain CSRF token: ${response.statusCode}');
    }
  }

  /// Authenticate with the server and obtain session cookies
  Future<void> authenticate(
    String serverUrl,
    String csrfToken,
    ConnectionCredentials credentials,
  ) async {
    final uri = Uri.parse(serverUrl).resolve('/api/users/login');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'X-CSRF-Token': csrfToken,
      },
      body: jsonEncode({
        'handle': credentials.username,
        'password': credentials.password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Authentication failed: ${response.statusCode}');
    }

    // Store session cookies from the response
    final host = Uri.parse(serverUrl).host;
    final cookies = _extractCookiesFromHeaders(response.headers);

    if (cookies.isNotEmpty) {
      await _secureStorage.write(
        key: 'session_cookies_$host',
        value: jsonEncode(cookies),
      );
    }
  }

  /// Disconnect from the server and clear stored tokens/cookies
  Future<void> disconnect(String serverId) async {
    // Clear stored tokens/cookies
    _credentialCache.remove(serverId);
    // In a real implementation, we might also want to call a logout endpoint
  }

  /// Check if we have valid credentials cached for re-authentication
  bool hasCachedCredentials(String serverId) {
    return _credentialCache.containsKey(serverId);
  }

  /// Get cached credentials for re-authentication
  ConnectionCredentials? getCachedCredentials(String serverId) {
    return _credentialCache[serverId];
  }

  /// Extract cookies from HTTP response headers
  Map<String, String> _extractCookiesFromHeaders(Map<String, String> headers) {
    final cookies = <String, String>{};
    final cookieHeader = headers['set-cookie'];

    if (cookieHeader != null) {
      // Parse cookies from the Set-Cookie header
      final cookieParts = cookieHeader.split(',');
      for (final part in cookieParts) {
        final cookiePair = part.split(';').first.trim();
        if (cookiePair.contains('=')) {
          final keyValue = cookiePair.split('=');
          if (keyValue.length == 2) {
            cookies[keyValue[0]] = keyValue[1];
          }
        }
      }
    }

    return cookies;
  }
}
