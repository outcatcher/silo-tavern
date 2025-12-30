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
    final response = await _client.get('/csrf-token');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.data) as Map<String, dynamic>;
      _csrf = jsonResponse['token'] as String;

      _client.options.headers['X-CSRF-Token'] = _csrf;
    } else {
      throw Exception('Failed to obtain CSRF token: ${response.statusCode}');
    }
  }

  /// Authenticate with the server and obtain session cookies
  @override
  Future<void> authenticate(ConnectionCredentials? credentials) async {
    final response = await _client.post(
      '/api/users/login',
      data: credentials?.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception('Authentication failed: ${response.statusCode}');
    }
  }
}
