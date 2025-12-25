// Integration test for ServerStorage using JsonStorage implementations
@Tags(['integration', 'storage'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/domain/server.dart';
import 'package:silo_tavern/services/server_storage.dart';

void main() {
  group('ServerStorage integration tests', () {
    late ServerStorage storage;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final asyncPrefs = SharedPreferencesAsync();
      final secureStorage = const FlutterSecureStorage();

      storage = ServerStorage.fromRawStorage(asyncPrefs, secureStorage);
    });

    testWidgets('ServerStorage CRUD operations', (WidgetTester tester) async {
      // Create a server without authentication
      final server1 = Server(
        id: 'server1',
        name: 'Test Server 1',
        address: 'https://test1.example.com',
        authentication: const AuthenticationInfo.none(),
      );

      // Create a server with authentication
      final server2 = Server(
        id: 'server2',
        name: 'Test Server 2',
        address: 'https://test2.example.com',
        authentication: AuthenticationInfo.credentials(
          username: 'user',
          password: 'pass',
        ),
      );

      // Test createServer
      await storage.createServer(server1);
      await storage.createServer(server2);

      // Test listServers
      final servers = await storage.listServers();
      expect(servers.length, 2);
      expect(servers.map((s) => s.id), containsAll(['server1', 'server2']));

      // Test getServer
      final retrievedServer1 = await storage.getServer('server1');
      expect(retrievedServer1, isNotNull);
      expect(retrievedServer1!.id, 'server1');
      expect(retrievedServer1.name, 'Test Server 1');
      expect(retrievedServer1.address, 'https://test1.example.com');
      expect(retrievedServer1.authentication.useCredentials, false);

      final retrievedServer2 = await storage.getServer('server2');
      expect(retrievedServer2, isNotNull);
      expect(retrievedServer2!.id, 'server2');
      expect(retrievedServer2.name, 'Test Server 2');
      expect(retrievedServer2.address, 'https://test2.example.com');
      expect(retrievedServer2.authentication.useCredentials, true);
      expect(retrievedServer2.authentication.username, 'user');
      expect(retrievedServer2.authentication.password, 'pass');

      // Test updateServer
      final updatedServer1 = Server(
        id: 'server1',
        name: 'Updated Server 1',
        address: 'https://updated1.example.com',
        authentication: AuthenticationInfo.credentials(
          username: 'newuser',
          password: 'newpass',
        ),
      );

      await storage.updateServer(updatedServer1);

      final updatedRetrievedServer1 = await storage.getServer('server1');
      expect(updatedRetrievedServer1, isNotNull);
      expect(updatedRetrievedServer1!.name, 'Updated Server 1');
      expect(updatedRetrievedServer1.address, 'https://updated1.example.com');
      expect(updatedRetrievedServer1.authentication.useCredentials, true);
      expect(updatedRetrievedServer1.authentication.username, 'newuser');
      expect(updatedRetrievedServer1.authentication.password, 'newpass');

      // Test deleteServer
      await storage.deleteServer('server1');

      final afterDeleteServers = await storage.listServers();
      expect(afterDeleteServers.length, 1);
      expect(afterDeleteServers[0].id, 'server2');

      final deletedServer = await storage.getServer('server1');
      expect(deletedServer, isNull);
    });

    testWidgets('ServerStorage save operations', (WidgetTester tester) async {
      // Test createServer with new server
      final newServer = Server(
        id: 'new-server',
        name: 'New Server',
        address: 'https://new.example.com',
        authentication: const AuthenticationInfo.none(),
      );

      await storage.createServer(newServer);

      final retrieved = await storage.getServer('new-server');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'New Server');

      // Test updateServer with existing server
      final updatedServer = Server(
        id: 'new-server',
        name: 'Updated Server',
        address: 'https://updated.example.com',
        authentication: const AuthenticationInfo.none(),
      );

      await storage.updateServer(updatedServer);

      final updatedRetrieved = await storage.getServer('new-server');
      expect(updatedRetrieved, isNotNull);
      expect(updatedRetrieved!.name, 'Updated Server');
    });

    testWidgets('ServerStorage delete operations', (WidgetTester tester) async {
      // Add some servers
      final server1 = Server(
        id: 'clear1',
        name: 'Clear Server 1',
        address: 'https://clear1.example.com',
        authentication: const AuthenticationInfo.none(),
      );

      final server2 = Server(
        id: 'clear2',
        name: 'Clear Server 2',
        address: 'https://clear2.example.com',
        authentication: const AuthenticationInfo.none(),
      );

      await storage.createServer(server1);
      await storage.createServer(server2);

      // Verify servers exist
      final serversBeforeClear = await storage.listServers();
      expect(serversBeforeClear.length, 2);

      // Delete servers individually
      await storage.deleteServer('clear1');
      await storage.deleteServer('clear2');

      // Verify servers are gone
      final serversAfterClear = await storage.listServers();
      expect(serversAfterClear.length, 0);
    });
  });
}
