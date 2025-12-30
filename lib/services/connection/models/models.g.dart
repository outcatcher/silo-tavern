// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CSRFTokenResponse _$CSRFTokenResponseFromJson(Map<String, dynamic> json) =>
    _CSRFTokenResponse(token: json['token'] as String);

Map<String, dynamic> _$CSRFTokenResponseToJson(_CSRFTokenResponse instance) =>
    <String, dynamic>{'token': instance.token};

_ConnectionCredentials _$ConnectionCredentialsFromJson(
  Map<String, dynamic> json,
) => _ConnectionCredentials(
  handle: json['handle'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$ConnectionCredentialsToJson(
  _ConnectionCredentials instance,
) => <String, dynamic>{
  'handle': instance.handle,
  'password': instance.password,
};
