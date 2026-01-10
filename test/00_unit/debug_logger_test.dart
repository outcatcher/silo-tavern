// Unit tests for DebugLogger
@Tags(['unit', 'connection'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/services/connection/debug_logger.dart';

import 'debug_logger_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<RequestOptions>(),
  MockSpec<Response>(),
  MockSpec<DioException>(),
  MockSpec<RequestInterceptorHandler>(),
  MockSpec<ResponseInterceptorHandler>(),
  MockSpec<ErrorInterceptorHandler>(),
])
void main() {
  group('DebugLogger Tests', () {
    late DebugLogger logger;

    setUp(() {
      logger = DebugLogger();
    });

    group('onRequest', () {
      test('sets X-Request-Id header and tracks request', () {
        // Arrange
        final mockOptions = MockRequestOptions();
        final mockHandler = MockRequestInterceptorHandler();
        final headers = <String, dynamic>{};

        when(mockOptions.headers).thenReturn(headers);

        // Act
        logger.onRequest(mockOptions, mockHandler);

        // Assert
        // Verify X-Request-Id header is set
        expect(headers.containsKey(xRequestId), isTrue);
        expect(headers[xRequestId], isNotNull);
        expect(headers[xRequestId], isNotEmpty);

        // Verify request is tracked
        expect(logger.pastRequests.containsKey(headers[xRequestId]), isTrue);
        expect(logger.pastRequests[headers[xRequestId]], isNotNull);

        // Verify handler is called
        verify(mockHandler.next(mockOptions)).called(1);
      });
    });

    group('onResponse', () {
      test('processes response without error', () {
        // Arrange
        final mockResponse = MockResponse();
        final mockRequestOptions = MockRequestOptions();
        final mockHandler = MockResponseInterceptorHandler();
        final requestId = 'test-request-id';
        final headers = <String, dynamic>{};
        headers[xRequestId] = requestId;

        when(mockResponse.requestOptions).thenReturn(mockRequestOptions);
        when(mockRequestOptions.headers).thenReturn(headers);

        // Pre-populate pastRequests to test timing calculation
        logger.pastRequests[requestId] = DateTime.now();

        // Act & Assert: Should not throw
        expect(
          () => logger.onResponse(mockResponse, mockHandler),
          returnsNormally,
        );

        // Verify handler is called
        verify(mockHandler.next(mockResponse)).called(1);
      });

      test('handles response with missing request id', () {
        // Arrange
        final mockResponse = MockResponse();
        final mockRequestOptions = MockRequestOptions();
        final mockHandler = MockResponseInterceptorHandler();
        final headers = <String, dynamic>{};

        when(mockResponse.requestOptions).thenReturn(mockRequestOptions);
        when(mockRequestOptions.headers).thenReturn(headers);

        // Act & Assert: Should not throw even with missing request id
        expect(
          () => logger.onResponse(mockResponse, mockHandler),
          returnsNormally,
        );

        // Verify handler is called
        verify(mockHandler.next(mockResponse)).called(1);
      });
    });

    group('onError', () {
      test('processes error without throwing', () {
        // Arrange
        final mockError = MockDioException();
        final mockRequestOptions = MockRequestOptions();
        final mockHandler = MockErrorInterceptorHandler();
        final requestId = 'test-request-id';
        final headers = <String, dynamic>{};
        headers[xRequestId] = requestId;
        const path = '/test-path';
        final queryParameters = <String, dynamic>{};
        queryParameters['param'] = 'value';
        final requestBody = <String, dynamic>{};
        requestBody['key'] = 'value';
        final requestHeaders = <String, dynamic>{};
        requestHeaders['Authorization'] = 'Bearer token';

        when(mockError.requestOptions).thenReturn(mockRequestOptions);
        when(mockRequestOptions.headers).thenReturn(headers);
        when(mockRequestOptions.path).thenReturn(path);
        when(mockRequestOptions.queryParameters).thenReturn(queryParameters);
        when(mockRequestOptions.data).thenReturn(requestBody);
        when(mockRequestOptions.headers).thenReturn(requestHeaders);
        when(mockError.error).thenReturn(Exception('Test error'));

        // Act & Assert: Should not throw
        expect(() => logger.onError(mockError, mockHandler), returnsNormally);

        // Verify handler is called
        verify(mockHandler.next(mockError)).called(1);
      });

      test('handles error with null request body', () {
        // Arrange
        final mockError = MockDioException();
        final mockRequestOptions = MockRequestOptions();
        final mockHandler = MockErrorInterceptorHandler();
        final requestId = 'test-request-id';
        final headers = <String, dynamic>{};
        headers[xRequestId] = requestId;

        when(mockError.requestOptions).thenReturn(mockRequestOptions);
        when(mockRequestOptions.headers).thenReturn(headers);
        when(mockRequestOptions.path).thenReturn('/test-path');
        when(
          mockRequestOptions.queryParameters,
        ).thenReturn(<String, dynamic>{});
        when(mockRequestOptions.data).thenReturn(null);
        when(mockRequestOptions.headers).thenReturn(<String, dynamic>{});
        when(mockError.error).thenReturn(Exception('Test error'));

        // Act & Assert: Should not throw even with null request body
        expect(() => logger.onError(mockError, mockHandler), returnsNormally);

        // Verify handler is called
        verify(mockHandler.next(mockError)).called(1);
      });
    });
  });
}
