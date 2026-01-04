class Server {
  final String id;
  final String name;
  final String address;
  ServerStatus status;

  Server({
    required this.id,
    required this.name,
    required this.address,
    this.status = ServerStatus.offline,
  });

  void updateStatus(ServerStatus newStatus) {
    status = newStatus;
  }
}

/// Represents the connection status of a server
enum ServerStatus {
  /// Server is being tested
  loading,

  /// Server is online and available
  online,

  /// Server is offline or unreachable
  offline,
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
