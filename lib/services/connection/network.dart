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
import 'package:silo_tavern/services/connection/models/models.dart';

abstract class ConnectionSessionInterface {
  Future<void> obtainCsrfToken();
  Future<void> authenticate(ConnectionCredentials credentials);
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
    final dio = Dio(BaseOptions(baseUrl: serverURL));

    dio.interceptors.add(cookieManager);

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

      if (response.statusCode == 200) {
        // CSRF token response should always be JSON
        final tokenData = CSRFTokenResponse.fromJson(response.data);

        _client.options.headers['X-CSRF-Token'] = tokenData.token;
      } else {
        throw Exception('Failed to obtain CSRF token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ConnectionSession: Failed to obtain CSRF token: $e');
      rethrow;
    }
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
}
