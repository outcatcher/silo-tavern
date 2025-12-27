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
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(serverService: widget.serverService);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SiloTavern',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _appRouter.router,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _toggleTheme,
                backgroundColor: _isDarkMode 
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                child: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
