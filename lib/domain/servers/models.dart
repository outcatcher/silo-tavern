class Server {
  final String id;
  final String name;
  final String address;
  final AuthenticationInfo authentication;

  Server({
    required this.id,
    required this.name,
    required this.address,
    this.authentication = const AuthenticationInfo.none(),
  });
}

class AuthenticationInfo {
  final bool useCredentials;
  final String username;
  final String password;

  const AuthenticationInfo.credentials({
    required this.username,
    required this.password,
  }) : useCredentials = true;

  const AuthenticationInfo.none()
    : useCredentials = false,
      username = '',
      password = '';

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

/// Result of a server connection attempt
class ServerConnectionResult {
  final bool isSuccess;
  final Server server;
  final String? errorMessage;

  ServerConnectionResult.success(this.server)
    : isSuccess = true,
      errorMessage = null;

  ServerConnectionResult.failure(this.server, this.errorMessage)
    : isSuccess = false;
}
