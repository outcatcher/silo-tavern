part of 'server_storage.dart';

/// Service-level server model that decouples from domain models
/// This model contains only the data needed for persistence
class _ServiceServer {
  final String id;
  final String name;
  final String address;

  _ServiceServer({required this.id, required this.name, required this.address});

  /// Convert from domain Server to service Server
  factory _ServiceServer.fromDomain(Server server, String? credentialsId) {
    return _ServiceServer(
      id: server.id,
      name: server.name,
      address: server.address,
    );
  }

  /// Create a copy with new credentialsId
  _ServiceServer copyWith({String? credentialsId}) {
    return _ServiceServer(id: id, name: name, address: address);
  }

  /// Convert to map for JSON serialization
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'address': address};
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
