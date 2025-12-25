import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/server.dart';
import 'package:silo_tavern/domain/server_service.dart';

import 'utils.dart' as utils;

class ServerListPage extends StatefulWidget {
  final ServerService serverService;

  const ServerListPage({super.key, required this.serverService});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  late List<Server> _servers;

  @override
  void initState() {
    super.initState();
    _servers = List.from(widget.serverService.servers);
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
    });

    // Actually delete from service (non-blocking)
    widget.serverService.removeServer(server.id).catchError((error) {
      // Find the insertion point to restore the server
      final insertIndex = _servers.indexWhere(
        (s) => s.id.compareTo(server.id) > 0,
      );

      // Revert optimistic update on error
      if (mounted) {
        setState(() {
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
                  style: const TextStyle(color: Colors.black, fontSize: 16),
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
      ),
      body: ListView.builder(
        itemCount: _servers.length,
        itemBuilder: (context, index) {
          final server = _servers[index];
          return GestureDetector(
            onLongPressStart: (details) {
              _showContextMenu(context, server, details.globalPosition);
            },
            onSecondaryTapDown: (details) {
              _showContextMenu(context, server, details.globalPosition);
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
                } else if (direction == DismissDirection.endToStart) {
                  // Show delete confirmation dialog for right-to-left swipe
                  final confirmDelete = await _showDeleteConfirmationDialog(
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
                color: Colors.blue,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
              // Delete swipe background (right-to-left drag)
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: server.address.startsWith('https')
                        ? Colors.grey[700]
                        : Colors.grey[500],
                    child: Icon(
                      server.address.startsWith('https')
                          ? Icons.lock
                          : Icons.lock_open,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(server.name),
                  subtitle: Text(server.address),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addServer,
        tooltip: 'Add Server',
        child: const Icon(Icons.add),
      ),
    );
  }
}
