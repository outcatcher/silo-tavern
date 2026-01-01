class Server {
  final String id;
  final String name;
  final String address;
  ServerStatus status;

  Server({
    required this.id,
    required this.name,
    required this.address,
    this.status = ServerStatus.ready,
  });

  void updateStatus(ServerStatus newStatus) {
    status = newStatus;
  }
}

/// Represents the connection status of a server
enum ServerStatus {
  /// Server is being tested or connected to
  loading,

  /// Server is configured but not yet connected
  ready,

  /// Server is unreachable or connection failed
  unavailable,

  /// Server is successfully connected and active
  active,
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
