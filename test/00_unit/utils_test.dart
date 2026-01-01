// Unit tests for utility functions
@Tags(['unit', 'utils'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/utils/network_utils.dart';

void main() {
  group('NetworkUtils Tests', () {
    test('Localhost addresses are identified as local', () {
      expect(NetworkUtils.isLocalAddress('http://localhost:8000'), isTrue);
      expect(NetworkUtils.isLocalAddress('https://localhost:3000'), isTrue);
      expect(NetworkUtils.isLocalAddress('http://LOCALHOST'), isTrue);
    });

    test('Loopback addresses are identified as local', () {
      expect(NetworkUtils.isLocalAddress('http://127.0.0.1:8000'), isTrue);
      expect(NetworkUtils.isLocalAddress('https://127.0.0.1'), isTrue);
      expect(NetworkUtils.isLocalAddress('http://127.255.255.255'), isTrue);
    });

    test('Private IP ranges are identified as local', () {
      // 10.x.x.x range
      expect(NetworkUtils.isLocalAddress('http://10.0.0.1:8000'), isTrue);
      expect(NetworkUtils.isLocalAddress('https://10.255.255.255'), isTrue);
      // 172.16-31.x.x range
      expect(NetworkUtils.isLocalAddress('http://172.16.0.1:8000'), isTrue);
      expect(NetworkUtils.isLocalAddress('https://172.31.255.255'), isTrue);
      expect(NetworkUtils.isLocalAddress('http://172.20.10.5'), isTrue);

      // 192.168.x.x range
      expect(NetworkUtils.isLocalAddress('http://192.168.1.1:8000'), isTrue);
      expect(NetworkUtils.isLocalAddress('https://192.168.0.100'), isTrue);

      // Additional private ranges
      expect(
        NetworkUtils.isLocalAddress('http://100.64.0.1:8000'),
        isTrue,
      ); // Shared address space
      expect(
        NetworkUtils.isLocalAddress('http://169.254.1.100'),
        isTrue,
      ); // Link-local
      expect(
        NetworkUtils.isLocalAddress('http://192.0.2.5'),
        isTrue,
      ); // Documentation
    });

    test('Boundary cases for private IP ranges', () {
      // Test boundary values for 172.16-31 range
      expect(
        NetworkUtils.isLocalAddress('http://172.15.255.255'),
        isFalse,
      ); // Just outside range
      expect(
        NetworkUtils.isLocalAddress('http://172.16.0.0'),
        isTrue,
      ); // Start of range
      expect(
        NetworkUtils.isLocalAddress('http://172.31.255.255'),
        isTrue,
      ); // End of range
      expect(
        NetworkUtils.isLocalAddress('http://172.32.0.0'),
        isFalse,
      ); // Just outside range

      // Test boundary values for 10.x.x.x range
      expect(NetworkUtils.isLocalAddress('http://10.0.0.0'), isTrue);
      expect(NetworkUtils.isLocalAddress('http://10.255.255.255'), isTrue);

      // Test boundary values for 192.168.x.x range
      expect(NetworkUtils.isLocalAddress('http://192.168.0.0'), isTrue);
      expect(NetworkUtils.isLocalAddress('http://192.168.255.255'), isTrue);
    });

    test('IPv6 addresses are handled correctly', () {
      // IPv6 loopback
      expect(NetworkUtils.isLocalAddress('http://[::1]:8000'), isTrue);
      expect(NetworkUtils.isLocalAddress('https://[::1]'), isTrue);

      // IPv6 unique local addresses
      expect(NetworkUtils.isLocalAddress('http://[fc00::1]:8000'), isTrue);
      expect(
        NetworkUtils.isLocalAddress(
          'https://[fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff]',
        ),
        isTrue,
      );

      // IPv6 global addresses
      expect(NetworkUtils.isLocalAddress('http://[2001:db8::1]:8000'), isFalse);
      expect(
        NetworkUtils.isLocalAddress('https://[2001:4860:4860::8888]'),
        isFalse,
      );
    });

    test('External addresses are not identified as local', () {
      expect(NetworkUtils.isLocalAddress('http://example.com'), isFalse);
      expect(NetworkUtils.isLocalAddress('https://google.com:443'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://8.8.8.8'), isFalse);
      expect(NetworkUtils.isLocalAddress('https://1.1.1.1'), isFalse);

      // Non-local private-like addresses
      expect(NetworkUtils.isLocalAddress('http://172.15.0.1'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://172.32.0.1'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://11.0.0.1'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://192.169.0.1'), isFalse);
    });

    test('Domain name resolution works correctly', () {
      // localhost is always local
      expect(NetworkUtils.isLocalAddress('http://localhost'), isTrue);
      expect(NetworkUtils.isLocalAddress('http://localhost:3000'), isTrue);

      // Other domains are not local
      expect(NetworkUtils.isLocalAddress('http://example.com'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://google.com'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://github.com'), isFalse);
    });

    test('Malformed URLs are handled gracefully', () {
      expect(NetworkUtils.isLocalAddress('not-a-url'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://'), isFalse);
      expect(NetworkUtils.isLocalAddress(''), isFalse);
      expect(NetworkUtils.isLocalAddress('http://.'), isFalse);
    });

    group('Server Configuration Validation Tests', () {
      test(
        'Local servers are always allowed regardless of protocol or authentication',
        () {
          // HTTP local servers
          final httpLocalNoAuth = Server(
            id: '1',
            name: 'Local HTTP no Auth',
            address: 'http://localhost:8000',
          );

          final httpLocalWithAuth = Server(
            id: '2',
            name: 'Local HTTP with Auth',
            address: 'http://127.0.0.1:3000',
          );

          // HTTPS local servers
          final httpsLocalNoAuth = Server(
            id: '3',
            name: 'Local HTTPS no Auth',
            address: 'https://localhost:443',
          );

          final httpsLocalWithAuth = Server(
            id: '4',
            name: 'Local HTTPS with Auth',
            address: 'https://192.168.1.100:443',
          );

          expect(
            () => validateServerConfiguration(httpLocalNoAuth),
            returnsNormally,
          );
          expect(
            () => validateServerConfiguration(httpLocalWithAuth),
            returnsNormally,
          );
          expect(
            () => validateServerConfiguration(httpsLocalNoAuth),
            returnsNormally,
          );
          expect(
            () => validateServerConfiguration(httpsLocalWithAuth),
            returnsNormally,
          );
        },
      );

      test('Remote HTTPS servers with authentication are allowed', () {
        final httpsRemoteWithAuth = Server(
          id: '1',
          name: 'Remote HTTPS with Auth',
          address: 'https://example.com:443',

        );

        expect(
          () => validateServerConfiguration(httpsRemoteWithAuth),
          returnsNormally,
        );
      });

      test('Remote HTTPS servers without authentication are allowed', () {
        final httpsRemoteNoAuth = Server(
          id: '1',
          name: 'Remote HTTPS no Auth',
          address: 'https://secure.example.com',

        );

        expect(
          () => validateServerConfiguration(httpsRemoteNoAuth),
          returnsNormally,
        );
      });

      test('Remote HTTP servers with authentication are forbidden', () {
        final httpRemoteWithAuth = Server(
          id: '1',
          name: 'Remote HTTP with Auth',
          address: 'http://external.com',

        );

        expect(
          () => validateServerConfiguration(httpRemoteWithAuth),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Remote HTTP servers without authentication are forbidden', () {
        final httpRemoteNoAuth = Server(
          id: '1',
          name: 'Remote HTTP no Auth',
          address: 'http://external.com',

        );

        expect(
          () => validateServerConfiguration(httpRemoteNoAuth),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Edge cases for server validation', () {
        // HTTP server on boundary local network without auth - should be allowed
        final httpBoundaryLocalNoAuth = Server(
          id: '1',
          name: 'Boundary Local HTTP no Auth',
          address: 'http://10.0.0.1:8000',

        );
        expect(
          () => validateServerConfiguration(httpBoundaryLocalNoAuth),
          returnsNormally,
        );

        // HTTP server on IPv6 localhost without auth - should be allowed
        final httpIPv6LocalNoAuth = Server(
          id: '2',
          name: 'IPv6 Local HTTP no Auth',
          address: 'http://[::1]:8000',

        );
        expect(
          () => validateServerConfiguration(httpIPv6LocalNoAuth),
          returnsNormally,
        );

        // HTTPS server on external IPv4 without auth - should be allowed
        final httpsExternalIPv4NoAuth = Server(
          id: '3',
          name: 'External IPv4 HTTPS no Auth',
          address: 'https://8.8.8.8:443',

        );
        expect(
          () => validateServerConfiguration(httpsExternalIPv4NoAuth),
          returnsNormally,
        );

        // HTTPS server on external IPv6 with auth - should be allowed
        final httpsExternalIPv6WithAuth = Server(
          id: '4',
          name: 'External IPv6 HTTPS with Auth',
          address: 'https://[2001:db8::1]:443',

        );
        expect(
          () => validateServerConfiguration(httpsExternalIPv6WithAuth),
          returnsNormally,
        );

        // HTTP server on external IPv6 with auth - should be forbidden
        final httpExternalIPv6WithAuth = Server(
          id: '5',
          name: 'External IPv6 HTTP with Auth',
          address: 'http://[2001:db8::1]:8000',

        );
        expect(
          () => validateServerConfiguration(httpExternalIPv6WithAuth),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
