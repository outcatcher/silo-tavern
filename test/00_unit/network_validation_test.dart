// Unit tests for network validation functionality
@Tags(['unit', 'network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:silo_tavern/domain/server.dart';
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
      expect(NetworkUtils.isLocalAddress('http://100.64.0.1:8000'), isTrue); // Shared address space
      expect(NetworkUtils.isLocalAddress('http://169.254.1.100'), isTrue); // Link-local
      expect(NetworkUtils.isLocalAddress('http://192.0.2.5'), isTrue); // Documentation
    });

    test('External addresses are not identified as local', () {
      expect(NetworkUtils.isLocalAddress('http://example.com'), isFalse);
      expect(NetworkUtils.isLocalAddress('https://google.com:443'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://8.8.8.8'), isFalse);
      
      // Non-local private-like addresses
      expect(NetworkUtils.isLocalAddress('http://172.15.0.1'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://172.32.0.1'), isFalse);
    });

    test('Domain name resolution works correctly', () {
      // localhost is always local
      expect(NetworkUtils.isLocalAddress('http://localhost'), isTrue);
      expect(NetworkUtils.isLocalAddress('http://localhost:3000'), isTrue);
      
      // Other domains are not local
      expect(NetworkUtils.isLocalAddress('http://example.com'), isFalse);
      expect(NetworkUtils.isLocalAddress('http://google.com'), isFalse);
    });
  });

  group('Server Configuration Validation Tests', () {
    test('HTTPS servers are always allowed regardless of authentication', () {
      final httpsNoAuth = Server(
        id: '1',
        name: 'HTTPS Server',
        address: 'https://example.com',
        authentication: const AuthenticationInfo.none(),
      );

      final httpsWithAuth = Server(
        id: '2',
        name: 'HTTPS Server with Auth',
        address: 'https://secure.example.com',
        authentication: AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      expect(NetworkUtils.isServerConfigurationAllowed(httpsNoAuth), isTrue);
      expect(NetworkUtils.isServerConfigurationAllowed(httpsWithAuth), isTrue);
    });

    test('HTTP servers with authentication are allowed for external addresses', () {
      final httpWithAuth = Server(
        id: '1',
        name: 'HTTP Server with Auth',
        address: 'http://external.com',
        authentication: AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      expect(NetworkUtils.isServerConfigurationAllowed(httpWithAuth), isTrue);
    });

    test('HTTP servers without authentication are rejected for external addresses', () {
      final httpNoAuth = Server(
        id: '1',
        name: 'HTTP Server no Auth',
        address: 'http://external.com',
        authentication: const AuthenticationInfo.none(),
      );

      expect(NetworkUtils.isServerConfigurationAllowed(httpNoAuth), isFalse);
    });

    test('HTTP servers without authentication are allowed for local addresses', () {
      final localhostServer = Server(
        id: '1',
        name: 'Localhost Server',
        address: 'http://localhost:8000',
        authentication: const AuthenticationInfo.none(),
      );

      final ipServer = Server(
        id: '2',
        name: 'IP Server',
        address: 'http://127.0.0.1:3000',
        authentication: const AuthenticationInfo.none(),
      );

      final localNetworkServer = Server(
        id: '3',
        name: 'Local Network Server',
        address: 'http://192.168.1.100:8080',
        authentication: const AuthenticationInfo.none(),
      );

      expect(NetworkUtils.isServerConfigurationAllowed(localhostServer), isTrue);
      expect(NetworkUtils.isServerConfigurationAllowed(ipServer), isTrue);
      expect(NetworkUtils.isServerConfigurationAllowed(localNetworkServer), isTrue);
    });

    test('HTTP servers with authentication are allowed for local addresses', () {
      final localhostServerWithAuth = Server(
        id: '1',
        name: 'Localhost Server with Auth',
        address: 'http://localhost:8000',
        authentication: AuthenticationInfo.credentials(
          username: 'admin',
          password: 'secret',
        ),
      );

      expect(NetworkUtils.isServerConfigurationAllowed(localhostServerWithAuth), isTrue);
    });
  });
}