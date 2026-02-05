import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/domain.dart';

/// Server dashboard page shown after successful server authentication
///
/// Provides navigation to personas, characters, and continue functionality
/// with proper back navigation and logout controls
class ServerDashboardPage extends StatelessWidget {
  final String serverId;
  final String serverName;
  final ConnectionDomain? connectionDomain;
  final ServerDomain? serverDomain;
  final GoRouter? router;

  const ServerDashboardPage({
    super.key,
    required this.serverId,
    required this.serverName,
    this.connectionDomain,
    this.serverDomain,
    this.router,
  });

  @override
  Widget build(BuildContext context) {
    final routerInstance = router ?? GoRouter.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(serverName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => routerInstance.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, routerInstance),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildMenuButton(
                  context,
                  title: 'Personas',
                  icon: Icons.people,
                  onTap: () => _navigateToUnderConstruction(
                    context,
                    routerInstance,
                    'Personas',
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  title: 'Characters',
                  icon: Icons.person,
                  onTap: () => _navigateToUnderConstruction(
                    context,
                    routerInstance,
                    'Characters',
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuButton(
                  context,
                  title: 'Continue',
                  icon: Icons.play_arrow,
                  onTap: () => _navigateToUnderConstruction(
                    context,
                    routerInstance,
                    'Continue',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a menu button with consistent styling
  Widget _buildMenuButton(
    BuildContext context,
    {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios),
        ],
      ),
    );
  }

  /// Navigates to under construction page with back navigation support
  void _navigateToUnderConstruction(
    BuildContext context,
    GoRouter routerInstance,
    String featureName,
  ) {
    final backUrl = '/servers/$serverId/dashboard';
    routerInstance.go(
      '/under-construction?title=$featureName&backUrl=$backUrl',
    );
  }

  /// Handles logout functionality
  void _handleLogout(BuildContext context, GoRouter routerInstance) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (serverDomain != null && connectionDomain != null) {
        final server = serverDomain!.findServerById(serverId);
        if (server != null) {
          await connectionDomain!.logoutFromServer(server);
        }
      }
      
      // Navigate to server list
      routerInstance.go('/');
    });
  }
}