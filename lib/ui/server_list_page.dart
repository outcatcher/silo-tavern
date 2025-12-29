import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';

import 'utils.dart' as utils;

class ServerListPage extends StatefulWidget {
  final ServerDomain serverDomain;

  const ServerListPage({super.key, required this.serverDomain});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  late List<Server> _servers;
  final Set<String> _deletingServers = {};

  @override
  void initState() {
    super.initState();
    _servers = List.from(widget.serverDomain.servers);
  }

  void _addServer() {
    context.go('/servers/create');
  }

  void _editServer(Server server) async {
    context.go('/servers/edit/${server.id}');
  }

  void _deleteServer(Server server) {
    // Optimistic update - remove from local list immediately
    setState(() {
      _servers.remove(server);
      _deletingServers.add(server.id);
    });

    // Actually delete from service (non-blocking)
    widget.serverDomain
        .removeServer(server.id)
        .then((_) {
          // Remove from deleting set on success
          if (mounted) {
            setState(() {
              _deletingServers.remove(server.id);
            });

            // Show success message
            utils.showSuccessDialog(
              context,
              'Server deleted successfully!',
              title: 'Deleted',
            );
          }
        })
        .catchError((error) {
          // Find the insertion point to restore the server
          final insertIndex = _servers.indexWhere(
            (s) => s.id.compareTo(server.id) > 0,
          );

          // Revert optimistic update on error
          if (mounted) {
            setState(() {
              _deletingServers.remove(server.id);
              if (insertIndex == -1) {
                // Insert at the end if no suitable position found
                _servers.add(server);
              } else {
                // Insert at the correct position to maintain order
                _servers.insert(insertIndex, server);
              }
            });

            utils.showErrorDialog(
              context,
              'Failed to delete server. Please try again.',
              title: 'Delete Failed',
            );
          }
        });
  }

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    Server server,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    const TextSpan(text: 'Delete '),
                    TextSpan(
                      text: server.name,
                      style: const TextStyle(
                        color: Colors.red,
                        backgroundColor: Color(
                          0xFFFFCCCC,
                        ), // Lighter red background
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Cancel
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Delete
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('DELETE'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showContextMenu(
    BuildContext context,
    Server server,
    Offset position,
  ) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        MediaQuery.of(context).size.width - position.dx,
        MediaQuery.of(context).size.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );

    switch (result) {
      case 'edit':
        _editServer(server);
        break;
      case 'delete':
        if (context.mounted) {
          _showDeleteConfirmationDialog(context, server).then((confirmed) {
            if (confirmed) {
              _deleteServer(server);
            }
          });
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SiloTavern - Servers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addServer,
            tooltip: 'Add Server',
            splashRadius: 24.0,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _servers.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  itemCount: _servers.length,
                  itemBuilder: (context, index) {
                    final server = _servers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: GestureDetector(
                        onLongPressStart: (details) {
                          _showContextMenu(
                            context,
                            server,
                            details.globalPosition,
                          );
                        },
                        onSecondaryTapDown: (details) {
                          _showContextMenu(
                            context,
                            server,
                            details.globalPosition,
                          );
                        },
                        child: Dismissible(
                          key: Key(server.id),
                          dismissThresholds: const {
                            DismissDirection.endToStart: 0.2,
                            DismissDirection.startToEnd: 0.2,
                          },
                          onDismissed: (direction) {
                            _deleteServer(server);
                          },
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Handle edit on left-to-right swipe
                              _editServer(server);
                              // Return false to prevent dismissal
                              return false;
                            } else if (direction ==
                                DismissDirection.endToStart) {
                              // Show delete confirmation dialog for right-to-left swipe
                              final confirmDelete =
                                  await _showDeleteConfirmationDialog(
                                    context,
                                    server,
                                  );
                              return confirmDelete;
                            }
                            // Default behavior
                            return false;
                          },
                          // Edit swipe background (left-to-right drag)
                          background: Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.8)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.9),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                          // Delete swipe background (right-to-left drag)
                          secondaryBackground: Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.8)
                                : Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.9),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: _buildServerCard(context, server),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 32),
          Text(
            'No servers configured',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first server to get started',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _addServer,
            icon: const Icon(Icons.add),
            label: const Text('Add Server'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, Server server) {
    final isDeleting = _deletingServers.contains(server.id);
    final isHttps = server.address.startsWith('https');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isHttps ? Colors.grey[700] : Colors.grey[500],
          child: Icon(
            isHttps ? Icons.lock : Icons.lock_open,
            color: Colors.white,
          ),
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
        onTap: () async {
          // Show connecting message
          final snackBar = SnackBar(
            content: const Text('Connecting to server...'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          
          // Connect to the server
          final result = await widget.serverDomain.connectToServer(server);
          
          // Hide the connecting message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (result.isSuccess) {
            // Navigate to under construction page with back URL as query parameter
            context.go(Uri(
              path: '/servers/connect/${server.id}',
              queryParameters: {'backUrl': '/servers'},
            ).toString());
          } else {
            // Show error message
            final errorSnackBar = SnackBar(
              content: Text('Error connecting to server: ${result.errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            );
            ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
          }
        },
      ),
    );
  }
}
