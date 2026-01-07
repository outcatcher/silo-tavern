/// Service for handling server connections
///
/// This service manages the connection workflow including:
/// - CSRF token requests
/// - Authentication handling
/// - Token storage
library;

import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:silo_tavern/domain/connection/models.dart';
import 'package:silo_tavern/services/connection/debug_logger.dart';
import 'package:silo_tavern/services/connection/models/models.dart';

abstract class ConnectionSessionInterface {
  Future<void> obtainCsrfToken();
  Future<void> authenticate(ConnectionCredentials credentials);
  Future<bool> checkServerAvailability();

  void setCsrfToken(String token);
  String? getCsrfToken();
}

class DefaultConnectionFactory implements ConnectionSessionFactory {
  @override
  ConnectionSessionInterface create(
    String serverURL, {
    List<Cookie>? cookies = const [],
  }) {
    final cookieJar = CookieJar();
    cookieJar.saveFromResponse(Uri.parse(serverURL), cookies ?? const []);

    final cookieManager = CookieManager(cookieJar);
    final dio = Dio(
      BaseOptions(baseUrl: serverURL, contentType: 'application/json'),
    );

    dio.interceptors.add(cookieManager);
    dio.interceptors.add(DebugLogger());

    return ConnectionSession._(dio);
  }
}

class ConnectionSession implements ConnectionSessionInterface {
  final Dio _client;

  ConnectionSession._(this._client);

  @visibleForTesting
  ConnectionSession(this._client);

  /// Obtain CSRF token from the server
  @override
  Future<void> obtainCsrfToken() async {
    try {
      final response = await _client.get('/csrf-token');
      final tokenData = CSRFTokenResponse.fromJson(response.data);

      _client.options.headers['X-CSRF-Token'] = tokenData.token;
    } on DioException catch (e) {
      debugPrint('Failed to obtain CSRF: ${e.response}');
      rethrow;
    } catch (e) {
      debugPrint('Uncaught exception during obtaining CSRF: $e');
      rethrow;
    }
  }

  /// Set CSRF token in the client headers
  @override
  void setCsrfToken(String token) {
    _client.options.headers['X-CSRF-Token'] = token;
  }

  /// Get CSRF token from the client headers
  @override
  String? getCsrfToken() {
    return _client.options.headers['X-CSRF-Token'] as String?;
  }

  /// Authenticate with the server and obtain session cookies
  @override
  Future<void> authenticate(ConnectionCredentials credentials) async {
    try {
      await _client.post('/api/users/login', data: credentials);
    } on DioException catch (e) {
      debugPrint('Failed to authenticate: ${e.response}');
      rethrow;
    } catch (e) {
      debugPrint('Uncaught exception during authentication: $e');
      rethrow;
    }
  }

  /// Check if the server is available by making a GET request to the root path
  @override
  Future<bool> checkServerAvailability() async {
    try {
      // Make a GET request to the root path without following redirects
      await _client.get(
        '/',
        options: Options(
          followRedirects: false,
          // coverage:ignore-start
          validateStatus: (status) => status != null && status < 400,
          // coverage:ignore-end
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // Any response (even 4xx or 5xx) indicates the server is reachable
      return true;
    } on DioException catch (e) {
      debugPrint('Server availability check failed: $e');
      // If we get a response (even an error response), the server is reachable
      if (e.type == DioExceptionType.badResponse) {
        return true;
      }
      // If there's no response, the server is likely unreachable
      return false;
    } catch (e) {
      debugPrint('Uncaught exception during server availability check: $e');
      return false;
    }
  }
}
