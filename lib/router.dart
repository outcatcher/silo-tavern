import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';
import 'package:silo_tavern/domain/server_service.dart';

class AppRouter {
  final ServerService serverService;

  AppRouter({required this.serverService});

  late final GoRouter router = GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/servers'),
      GoRoute(
        path: '/servers',
        name: 'servers',
        builder: (context, state) =>
            ServerListPage(serverService: serverService),
      ),
      GoRoute(
        path: '/servers/create',
        name: 'serverCreate',
        builder: (context, state) =>
            ServerCreationPage(serverService: serverService),
      ),
      GoRoute(
        path: '/servers/edit/:id',
        name: 'serverEdit',
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          final server = serverService.findServerById(serverId);
          if (server == null) {
            // Navigate back if server not found
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/servers');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ServerCreationPage(
            serverService: serverService,
            initialServer: server,
          );
        },
      ),
    ],
  );
}
