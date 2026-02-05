import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/router/auth_guard.dart';
import 'package:silo_tavern/ui/login_page.dart';
import 'package:silo_tavern/ui/server_creation_page.dart';
import 'package:silo_tavern/ui/server_dashboard_page.dart';
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
      GoRoute(
        path: '/servers/:id/dashboard',
        name: 'serverDashboard',
        redirect: (context, state) async {
          return await serverAuthGuard(
            context: context,
            state: state,
            serverDomain: domains.servers,
            connectionDomain: domains.connections,
          );
        },
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

          return ServerDashboardPage(
            serverId: server.id,
            serverName: server.name,
            connectionDomain: domains.connections,
            serverDomain: domains.servers,
          );
        },
      ),
      GoRoute(
        path: '/under-construction',
        name: 'underConstruction',
        builder: (context, state) {
          final title =
              state.uri.queryParameters['title'] ?? 'Under Construction';
          final backUrl = state.uri.queryParameters['backUrl'];
          return UnderConstructionPage(title: title, backUrl: backUrl);
        },
      ),
    ],
  );
}
