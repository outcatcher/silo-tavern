import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/domain/server_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = SharedPreferencesAsync();
  final secureStorage = const FlutterSecureStorage();

  final serverService = ServerService(
    ServerOptions.fromRawStorage(prefs, secureStorage),
  );
  await serverService.initialize();

  runApp(SiloTavernApp(serverService: serverService));
}

class SiloTavernApp extends StatelessWidget {
  final ServerService serverService;

  const SiloTavernApp({super.key, required this.serverService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiloTavern',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ServerListPage(serverService: serverService),
    );
  }
}
