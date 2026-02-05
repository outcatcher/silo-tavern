import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/ui/server_dashboard_page.dart';
import 'package:silo_tavern/ui/utils.dart';

/// Wrapper widget to handle authentication checks for server dashboard
class ServerDashboardWrapper extends StatefulWidget {
  final Server server;
  final ConnectionDomain connectionDomain;
  final ServerDomain serverDomain;
  final GoRouter router;

  const ServerDashboardWrapper({
    super.key,
    required this.server,
    required this.connectionDomain,
    required this.serverDomain,
    required this.router,
  });

  @override
  State<ServerDashboardWrapper> createState() => _ServerDashboardWrapperState();
}

class _ServerDashboardWrapperState extends State<ServerDashboardWrapper> {
  bool? _hasValidSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Check if there's a valid session for this server
    final hasSession = widget.connectionDomain.hasExistingSession(widget.server);
    
    // If no existing session, check for persistent session
    bool hasPersistentSession = false;
    if (!hasSession) {
      hasPersistentSession = await widget.connectionDomain.hasPersistentSession(widget.server);
    }
    
    if (mounted) {
      setState(() {
        _hasValidSession = hasSession || hasPersistentSession;
        _isLoading = false;
      });
      
      // Redirect to server list if no valid session exists
      if (!_hasValidSession!) {
        widget.router.go(defaultPage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authentication'),
            ],
          ),
        ),
      );
    }
    
    if (!_hasValidSession!) {
      // This shouldn't happen since we redirect above, but just in case
      return const Scaffold(
        body: Center(
          child: Text('Access denied'),
        ),
      );
    }
    
    return ServerDashboardPage(
      serverId: widget.server.id,
      serverName: widget.server.name,
      connectionDomain: widget.connectionDomain,
      serverDomain: widget.serverDomain,
    );
  }
}