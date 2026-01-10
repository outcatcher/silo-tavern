import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = SharedPreferencesAsync();
  final secureStorage = const FlutterSecureStorage();

  final connectionDomain = ConnectionDomain.defaultInstance(secureStorage);

  final serverDomain = ServerDomain(
    ServerOptions.fromRawStorage(
      prefs,
      secureStorage,
      connectionDomain: connectionDomain,
    ),
  );
  await serverDomain.initialize();

  final router = appRouter(
    Domains(servers: serverDomain, connections: connectionDomain),
  );

  runApp(SiloTavernApp(serverDomain: serverDomain, router: router));
}

class SiloTavernApp extends StatefulWidget {
  final ServerDomain serverDomain;
  final GoRouter router;

  const SiloTavernApp({
    super.key,
    required this.serverDomain,
    required this.router,
  });

  @override
  State<SiloTavernApp> createState() => _SiloTavernAppState();
}

class _SiloTavernAppState extends State<SiloTavernApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: widget.router,
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
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                elevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                child: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: _isDarkMode
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
