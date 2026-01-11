import 'package:flutter/material.dart';
import 'package:silo_tavern/domain/servers/models.dart';

/// A reusable server card widget
class ServerCard extends StatelessWidget {
  final Server server;
  final bool isDeleting;
  final VoidCallback onTap;
  final bool isHttps;

  const ServerCard({
    super.key,
    required this.server,
    this.isDeleting = false,
    required this.onTap,
    required this.isHttps,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status icon and color
    IconData statusIcon;
    Color statusColor;

    switch (server.status) {
      case ServerStatus.loading:
        statusIcon = Icons.hourglass_bottom;
        statusColor = Colors.orange;
        break;
      case ServerStatus.online:
        statusIcon = Icons.circle;
        statusColor = Colors.green;
        break;
      case ServerStatus.offline:
        statusIcon = Icons.circle;
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: isHttps ? Colors.grey[700] : Colors.grey[500],
              child: Icon(
                isHttps ? Icons.lock : Icons.lock_open,
                color: Colors.white,
              ),
            ),
            // Status indicator overlay
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 16),
              ),
            ),
          ],
        ),
        title: Text(
          server.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          server.address,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: isDeleting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        onTap: onTap,
      ),
    );
  }
}
