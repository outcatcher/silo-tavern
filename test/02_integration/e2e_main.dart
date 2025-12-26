import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/domain/server_service.dart';
import 'package:silo_tavern/router.dart';
import 'package:silo_tavern/services/server_storage.dart';
import 'package:silo_tavern/utils/app_storage.dart';

// Custom ServerStorage that uses E2E-specific prefixes
class E2EServerStorage extends ServerStorage {
  E2EServerStorage(SharedPreferencesAsync prefs, FlutterSecureStorage sec)
      : super(
          JsonStorage(prefs, 'e2e_servers'),
          JsonSecureStorage(sec, 'e2e_servers'),
        );
}

// Custom ServerOptions for E2E tests
class E2EServerOptions extends ServerOptions {
  E2EServerOptions(SharedPreferencesAsync prefs, FlutterSecureStorage sec)
      : super(E2EServerStorage(prefs, sec));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = SharedPreferencesAsync();
  final secureStorage = const FlutterSecureStorage();

  // Use isolated storage for E2E tests with different prefixes
  final serverService = ServerService(
    E2EServerOptions(prefs, secureStorage),
  );
  await serverService.initialize();

  runApp(SiloTavernApp(serverService: serverService));
}

class SiloTavernApp extends StatefulWidget {
  final ServerService serverService;

  const SiloTavernApp({super.key, required this.serverService});

  @override
  State<SiloTavernApp> createState() => _SiloTavernAppState();
}

class _SiloTavernAppState extends State<SiloTavernApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(serverService: widget.serverService);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SiloTavern',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _appRouter.router,
    );
  }
}