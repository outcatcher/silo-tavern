part of 'server_storage.dart';

/// Service-level server model that decouples from domain models
/// This model contains only the data needed for persistence
class _ServiceServer {
  final String id;
  final String name;
  final String address;

  _ServiceServer({required this.id, required this.name, required this.address});

  /// Convert to map for JSON serialization
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'address': address};
  }

  /// Convert to map for JSON serialization
  Server toDomain(AuthenticationInfo auth) {
    return Server(address: address, id: id, name: name, authentication: auth);
  }

  factory _ServiceServer.fromDomain(Server server) {
    return _ServiceServer(
      id: server.id,
      address: server.address,
      name: server.name,
    );
  }

  /// Create from JSON map
  factory _ServiceServer.fromJson(Map<String, dynamic> json) {
    return _ServiceServer(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }
}
