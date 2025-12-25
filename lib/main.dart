import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:silo_tavern/domain/server_service.dart';
import 'package:silo_tavern/router.dart';

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
