/// Models for the connection domain
import 'package:flutter/foundation.dart';

/// Represents credentials for server authentication
class ConnectionCredentials {
  final String username;
  final String password;

  ConnectionCredentials({
    required this.username,
    required this.password,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionCredentials &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(username, password);

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  factory ConnectionCredentials.fromJson(Map<String, dynamic> json) {
    return ConnectionCredentials(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
}

/// Result of a connection attempt
class ConnectionResult {
  final bool isSuccess;
  final String? errorMessage;

  ConnectionResult.success() : isSuccess = true, errorMessage = null;

  ConnectionResult.failure(this.errorMessage) : isSuccess = false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionResult &&
        other.isSuccess == isSuccess &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(isSuccess, errorMessage);
}

/// Wrapper for an authenticated HTTP client
class AuthenticatedClient {
  final String serverId;
  final String baseUrl;

  AuthenticatedClient({
    required this.serverId,
    required this.baseUrl,
  });

  // In a real implementation, this would contain the actual HTTP client
  // with CSRF headers and cookies pre-configured
}