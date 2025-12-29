import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page displayed when a server connection is successful
///
/// Shows an "under construction" message with the server name as title
class UnderConstructionPage extends StatelessWidget {
  final String serverName;

  const UnderConstructionPage({super.key, required this.serverName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serverName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/servers'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Construction-themed icon
            Icon(
              Icons.construction,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            
            // Under construction text
            const Text(
              'Under Construction',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Additional message
            const Text(
              'This feature is currently being developed',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}