/// Service for handling server connections
///
/// This service manages the connection workflow including:
/// - CSRF token requests
/// - Authentication handling
/// - Token storage
library;

import 'dart:async';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:silo_tavern/domain/connection/models.dart';

abstract class ConnectionSessionInterface {
  Future<void> obtainCsrfToken();
  Future<void> authenticate(ConnectionCredentials? credentials);
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
  String? _csrf;

  ConnectionSession._(this._client);

  @visibleForTesting
  ConnectionSession(this._client);

  /// Obtain CSRF token from the server
  @override
  Future<void> obtainCsrfToken() async {
    try {
      final response = await _client.get('/csrf-token');

      if (response.statusCode == 200) {
        // Handle both string and Map responses
        Map<String, dynamic> jsonResponse;
        if (response.data is String) {
          jsonResponse = jsonDecode(response.data) as Map<String, dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          jsonResponse = response.data as Map<String, dynamic>;
        } else {
          throw Exception('Unexpected response data type: ${response.data.runtimeType}');
        }
        
        // Maintain backward compatibility with existing tests
        // When token is missing, let the cast throw TypeError as expected by tests
        _csrf = jsonResponse['token'] as String;

        _client.options.headers['X-CSRF-Token'] = _csrf;
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
  Future<void> authenticate(ConnectionCredentials? credentials) async {
    try {
      final response = await _client.post(
        '/api/users/login',
        data: credentials?.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ConnectionSession: Failed to authenticate: $e');
      rethrow;
    }
  }
}
