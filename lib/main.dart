import 'package:flutter/material.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/domain/server_service.dart';

void main() {
  runApp(const SiloTavernApp());
}

class SiloTavernApp extends StatelessWidget {
  const SiloTavernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiloTavern',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ServerListPage(serverService: ServerService()),
    );
  }
}
