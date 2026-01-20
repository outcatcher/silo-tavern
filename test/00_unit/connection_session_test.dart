// Unit tests for ConnectionSession
@Tags(['unit', 'connection'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:silo_tavern/services/connection/models/models.dart';
import 'package:silo_tavern/services/connection/network.dart';

import 'mocks.mocks.dart';

void main() {
  group('ConnectionSession Tests', () {
    late MockDio mockDio;
    late ConnectionSession session;

    setUp(() {
      mockDio = MockDio();
      session = ConnectionSession(
        mockDio,
      ); // Using the @visibleForTesting constructor
    });

    group('obtainCsrfToken', () {
      test('Successfully obtains CSRF token and sets header', () async {
        // Arrange
        final mockResponse = MockResponse();
        final responseData = {'token': 'abc123xyz'};

        when(mockDio.get('/csrf-token')).thenAnswer((_) async => mockResponse);
        when(mockResponse.statusCode).thenReturn(200);
        when(mockResponse.data).thenReturn(responseData);

        // Mock the options property
        final baseOptions = BaseOptions();
        when(mockDio.options).thenReturn(baseOptions);

        // Act
        await session.obtainCsrfToken();

        // Assert
        verify(mockDio.get('/csrf-token')).called(1);

        // Verify that the CSRF token was set in the headers
        expect(baseOptions.headers['X-CSRF-Token'], equals('abc123xyz'));
      });

      test(
        'Throws exception when CSRF token request fails with non-200 status',
        () async {
          // Arrange
          when(mockDio.get('/csrf-token')).thenThrow(
            DioException(
              response: MockResponse(),
              requestOptions: RequestOptions(path: '/csrf-token'),
            ),
          );

          // Act & Assert
          expect(
            () => session.obtainCsrfToken(),
            throwsA(predicate((e) => e is DioException)),
          );

          verify(mockDio.get('/csrf-token')).called(1);
        },
      );

      test(
        'Throws exception when CSRF token request throws DioError',
        () async {
          // Arrange
          when(mockDio.get('/csrf-token')).thenThrow(
            DioException(requestOptions: RequestOptions(path: '/csrf-token')),
          );

          // Act & Assert
          expect(
            () => session.obtainCsrfToken(),
            throwsA(predicate((e) => e is DioException)),
          );

          verify(mockDio.get('/csrf-token')).called(1);
        },
      );

      test('Throws exception when response data is not a Map', () async {
        // Arrange
        final mockResponse = MockResponse();

        when(mockDio.get('/csrf-token')).thenAnswer((_) async => mockResponse);
        when(mockResponse.statusCode).thenReturn(200);
        when(mockResponse.data).thenReturn('invalid data type');

        // Act & Assert
        expect(
          () => session.obtainCsrfToken(),
          throwsA(
            predicate(
              (e) =>
                  e is TypeError &&
                  e.toString().contains(
                    'type \'String\' is not a subtype of type \'Map<String, dynamic>\'',
                  ),
            ),
          ),
        );

        verify(mockDio.get('/csrf-token')).called(1);
      });

      test(
        'Throws exception when token field is missing from response',
        () async {
          // Arrange
          final mockResponse = MockResponse();
          final responseData = {'message': 'success'}; // Missing 'token' field

          when(
            mockDio.get('/csrf-token'),
          ).thenAnswer((_) async => mockResponse);
          when(mockResponse.statusCode).thenReturn(200);
          when(mockResponse.data).thenReturn(responseData);

          // Act & Assert
          expect(
            () => session.obtainCsrfToken(),
            throwsA(
              predicate(
                (e) =>
                    e is TypeError &&
                    e.toString().contains(
                      'type \'Null\' is not a subtype of type \'String\'',
                    ),
              ),
            ),
          );

          verify(mockDio.get('/csrf-token')).called(1);
        },
      );
    });

    group('authenticate', () {
      test('Successfully authenticates with valid credentials', () async {
        // Arrange
        final mockResponse = MockResponse();
        final credentials = ConnectionCredentials(
          handle: 'testuser',
          password: 'testpass',
        );

        when(
          mockDio.post('/api/users/login', data: anyNamed('data')),
        ).thenAnswer((_) async => mockResponse);
        when(mockResponse.statusCode).thenReturn(200);

        // Act
        await session.authenticate(credentials);

        // Assert
        verify(
          mockDio.post('/api/users/login', data: anyNamed('data')),
        ).called(1);
      });

      test(
        'Throws exception when authentication fails with non-200 status',
        () async {
          // Arrange
          final credentials = ConnectionCredentials(
            handle: 'testuser',
            password: 'wrongpass',
          );

          when(
            mockDio.post('/api/users/login', data: anyNamed('data')),
          ).thenThrow(
            DioException(
              response: MockResponse(),
              requestOptions: RequestOptions(path: '/api/users/login'),
            ),
          );

          // Act & Assert
          expect(
            () => session.authenticate(credentials),
            throwsA(predicate((e) => e is DioException)),
          );

          verify(
            mockDio.post('/api/users/login', data: anyNamed('data')),
          ).called(1);
        },
      );

      test(
        'Throws exception when authentication request throws DioError',
        () async {
          // Arrange
          final credentials = ConnectionCredentials(
            handle: 'testuser',
            password: 'testpass',
          );

          when(
            mockDio.post('/api/users/login', data: anyNamed('data')),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/api/users/login'),
            ),
          );

          // Act & Assert
          expect(
            () => session.authenticate(credentials),
            throwsA(predicate((e) => e is DioException)),
          );

          verify(
            mockDio.post('/api/users/login', data: anyNamed('data')),
          ).called(1);
        },
      );

      test('Handles unexpected exception during authentication', () async {
        // Arrange
        final credentials = ConnectionCredentials(
          handle: 'testuser',
          password: 'testpass',
        );

        when(
          mockDio.post('/api/users/login', data: anyNamed('data')),
        ).thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => session.authenticate(credentials),
          throwsA(predicate((e) => e is Exception)),
        );

        verify(
          mockDio.post('/api/users/login', data: anyNamed('data')),
        ).called(1);
      });
    });

    group('setCsrfToken', () {
      test('Sets CSRF token in client headers', () async {
        // Arrange
        final baseOptions = BaseOptions();
        when(mockDio.options).thenReturn(baseOptions);
        const token = 'test-csrf-token';

        // Act
        session.setCsrfToken(token);

        // Assert
        expect(baseOptions.headers['X-CSRF-Token'], equals(token));
      });
    });

    group('getCsrfToken', () {
      test('Returns CSRF token from client headers', () async {
        // Arrange
        final baseOptions = BaseOptions();
        baseOptions.headers['X-CSRF-Token'] = 'test-csrf-token';
        when(mockDio.options).thenReturn(baseOptions);

        // Act
        final token = session.getCsrfToken();

        // Assert
        expect(token, equals('test-csrf-token'));
      });

      test('Returns null when no CSRF token is set', () async {
        // Arrange
        final baseOptions = BaseOptions();
        when(mockDio.options).thenReturn(baseOptions);

        // Act
        final token = session.getCsrfToken();

        // Assert
        expect(token, isNull);
      });
    });

    group('checkServerAvailability', () {
      test('Returns true when server responds successfully', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(mockResponse.statusCode).thenReturn(200);

        when(
          mockDio.get('/', options: anyNamed('options')),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await session.checkServerAvailability();

        // Assert
        expect(result, isTrue);
        verify(mockDio.get('/', options: anyNamed('options'))).called(1);
      });

      test('Returns true when server responds with error status', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(mockResponse.statusCode).thenReturn(404);

        when(
          mockDio.get('/', options: anyNamed('options')),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await session.checkServerAvailability();

        // Assert
        expect(result, isTrue);
        verify(mockDio.get('/', options: anyNamed('options'))).called(1);
      });

      test('Returns false when server is unreachable', () async {
        // Arrange
        when(mockDio.get('/', options: anyNamed('options'))).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/'),
          ),
        );

        // Act
        final result = await session.checkServerAvailability();

        // Assert
        expect(result, isFalse);
        verify(mockDio.get('/', options: anyNamed('options'))).called(1);
      });

      test('Returns true when server responds with bad response', () async {
        // Arrange
        when(mockDio.get('/', options: anyNamed('options'))).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: '/'),
          ),
        );

        // Act
        final result = await session.checkServerAvailability();

        // Assert
        expect(result, isTrue);
        verify(mockDio.get('/', options: anyNamed('options'))).called(1);
      });

      test('Returns false when unexpected exception occurs', () async {
        // Arrange
        when(
          mockDio.get('/', options: anyNamed('options')),
        ).thenThrow(Exception('Unexpected error'));

        // Act
        final result = await session.checkServerAvailability();

        // Assert
        expect(result, isFalse);
        verify(mockDio.get('/', options: anyNamed('options'))).called(1);
      });
    });
  });

  group('DefaultConnectionFactory', () {
    test('Creates ConnectionSession with proper configuration', () async {
      // Act
      final factory = DefaultConnectionFactory();
      final session = factory.create('https://test.example.com');

      // Assert
      expect(session, isNotNull);
      expect(session, isA<ConnectionSessionInterface>());
    });

    test('Creates ConnectionSession with existing cookies', () async {
      // Act
      final factory = DefaultConnectionFactory();
      final session = factory.create(
        'https://test.example.com',
        cookies: [], // Empty cookies list
      );

      // Assert
      expect(session, isNotNull);
      expect(session, isA<ConnectionSessionInterface>());
    });
  });
}
