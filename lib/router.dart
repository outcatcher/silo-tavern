import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';

class AppRouter {
  final ServerDomain serverDomain;

  AppRouter({required this.serverDomain});

  late final GoRouter router = GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/servers'),
      GoRoute(
        path: '/servers',
        name: 'servers',
        builder: (context, state) => ServerListPage(serverDomain: serverDomain),
      ),
      GoRoute(
        path: '/servers/create',
        name: 'serverCreate',
        builder: (context, state) =>
            ServerCreationPage(serverDomain: serverDomain),
      ),
      GoRoute(
        path: '/servers/edit/:id',
        name: 'serverEdit',
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          final server = serverDomain.findServerById(serverId);
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
            serverDomain: serverDomain,
            initialServer: server,
          );
        },
      ),
      GoRoute(
        path: '/servers/connect/:id',
        name: 'serverConnect',
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          final server = serverDomain.findServerById(serverId);
          if (server == null) {
            // Navigate back if server not found
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/servers');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return UnderConstructionPage(title: server.name);
        },
      ),
    ],
  );
}
