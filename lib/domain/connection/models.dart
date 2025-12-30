/// Models for the connection domain
library;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:silo_tavern/services/connection/network.dart';

/// Represents credentials for server authentication
class ConnectionCredentials {
  final String username;
  final String password;

  ConnectionCredentials({required this.username, required this.password});

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
    return {'username': username, 'password': password};
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

abstract class ConnectionSessionFactory {
  ConnectionSessionInterface create(
    String server, {
    List<Cookie>? cookies = const [],
  });
}
