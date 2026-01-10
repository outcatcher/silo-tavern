import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/ui/login_page.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';
import 'package:silo_tavern/ui/server_list_page.dart';
import 'package:silo_tavern/ui/under_construction_page.dart';
import 'package:silo_tavern/ui/utils.dart';

class Domains {
  ServerDomain servers;
  ConnectionDomain connections;

  Domains({required this.servers, required this.connections});
}

GoRouter appRouter(Domains domains) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (_, _) => defaultPage),
      GoRoute(
        path: '/servers',
        name: 'servers',
        builder: (context, state) => ServerListPage(
          serverDomain: domains.servers,
          connectionDomain: domains.connections,
        ),
      ),
      GoRoute(
        path: '/servers/create',
        name: 'serverCreate',
        builder: (context, state) =>
            ServerCreationPage(serverDomain: domains.servers),
      ),
      GoRoute(
        path: '/servers/edit/:id',
        name: 'serverEdit',
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          final server = domains.servers.findServerById(serverId);
          if (server == null) {
            // Navigate back if server not found
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(defaultPage);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ServerCreationPage(
            serverDomain: domains.servers,
            initialServer: server,
          );
        },
      ),
      GoRoute(
        path: '/servers/connect/:id',
        name: 'serverConnect',
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          final server = domains.servers.findServerById(serverId);
          if (server == null) {
            // Navigate back if server not found
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(defaultPage);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Get back URL from query parameters or default to '/servers'
          final backUrl = state.uri.queryParameters['backUrl'] ?? defaultPage;
          return UnderConstructionPage(
            title: 'Connect to Server',
            backUrl: backUrl,
          );
        },
      ),
      GoRoute(
        path: '/servers/login/:id',
        name: 'serverLogin',
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          final server = domains.servers.findServerById(serverId);
          if (server == null) {
            // Navigate back if server not found
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(defaultPage);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Get back URL from query parameters or default to defaultPage
          final backUrl = state.uri.queryParameters['backUrl'] ?? defaultPage;
          return LoginPage(
            server: server,
            backUrl: backUrl,
            connectionDomain: domains.connections,
          );
        },
      ),
    ],
  );
}
