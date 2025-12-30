import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.g.dart';
part 'models.freezed.dart';

@freezed
abstract class CSRFTokenResponse with _$CSRFTokenResponse {
  const factory CSRFTokenResponse({required String token}) = _CSRFTokenResponse;

  factory CSRFTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$CSRFTokenResponseFromJson(json);
}

/// Represents credentials for server authentication
@freezed
abstract class ConnectionCredentials with _$ConnectionCredentials {
  const factory ConnectionCredentials({
    required String handle,
    required String password,
  }) = _ConnectionCredentials;

  factory ConnectionCredentials.fromJson(Map<String, dynamic> json) =>
      _$ConnectionCredentialsFromJson(json);
}
