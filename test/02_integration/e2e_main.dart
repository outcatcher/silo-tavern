import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/router.dart';
import 'package:silo_tavern/services/servers/storage.dart';
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
  final serverDomain = ServerDomain(E2EServerOptions(prefs, secureStorage));
  await serverDomain.initialize();

  runApp(SiloTavernApp(serverDomain: serverDomain));
}

class SiloTavernApp extends StatefulWidget {
  final ServerDomain serverDomain;

  const SiloTavernApp({super.key, required this.serverDomain});

  @override
  State<SiloTavernApp> createState() => _SiloTavernAppState();
}

class _SiloTavernAppState extends State<SiloTavernApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(serverDomain: widget.serverDomain);
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
