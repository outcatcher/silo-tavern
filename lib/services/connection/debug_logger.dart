import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uuid/v6.dart';

const xRequestId = 'X-Request-Id';

class DebugLogger extends Interceptor {
  @visibleForTesting
  final Map<String, DateTime> pastRequests = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final xRequestIdVal = UuidV6().generate();
    options.headers[xRequestId] = xRequestIdVal;
    pastRequests[xRequestIdVal] = DateTime.timestamp();

    debugPrint('Started request $xRequestIdVal');

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final xRequestIdVal = err.requestOptions.headers[xRequestId];
    final jsonBody = jsonEncode(err.requestOptions.data);
    debugPrint(
      'Error on request ($xRequestIdVal):\n'
      'Path: ${err.requestOptions.path}\n'
      'Query Params: ${err.requestOptions.queryParameters}\n'
      'Request Body: $jsonBody\n'
      'Headers: ${err.requestOptions.headers}\n'
      'Error: ${err.error.toString()}',
    );

    super.onError(err, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final xRequestIdVal = response.requestOptions.headers[xRequestId];
    final passed = pastRequests[xRequestIdVal]
        ?.difference(DateTime.timestamp())
        .abs();

    debugPrint(
      '($xRequestIdVal) ${response.requestOptions.method} ${response.requestOptions.path} in ${passed.toString()}',
    );

    super.onResponse(response, handler);
  }
}
