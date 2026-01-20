import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silo_tavern/common/app_storage.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/repository.dart';
import 'package:silo_tavern/services/connection/network.dart';
import 'package:silo_tavern/services/connection/storage.dart';
import 'package:silo_tavern/services/servers/storage.dart';

@GenerateNiceMocks([
  // Storage mocks
  MockSpec<ServerStorage>(),
  MockSpec<ServerRepository>(),
  MockSpec<ConnectionStorage>(),
  MockSpec<JsonSecureStorage>(),
  MockSpec<SharedPreferencesAsync>(),
  MockSpec<FlutterSecureStorage>(),

  // Domain mocks
  MockSpec<ConnectionDomain>(),
  MockSpec<ConnectionSessionInterface>(),

  // Network mocks
  MockSpec<Dio>(),
  MockSpec<Response>(),
  MockSpec<BaseOptions>(),
  MockSpec<DioException>(),
  MockSpec<RequestOptions>(),
  MockSpec<RequestInterceptorHandler>(),
  MockSpec<ResponseInterceptorHandler>(),
  MockSpec<ErrorInterceptorHandler>(),
])
void main() {}
