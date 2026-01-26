import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';

import 'utils.dart' as utils;
import 'components/loading_dialog.dart';
import 'components/server_card.dart';
import 'components/empty_state.dart';
import 'utils/context_menu_utils.dart';

class ServerListPage extends StatefulWidget {
  final ServerDomain serverDomain;
  final ConnectionDomain connectionDomain;
  final GoRouter? router;

  const ServerListPage({
    super.key,
    required this.serverDomain,
    required this.connectionDomain,
    this.router,
  });

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  late List<Server> _servers;
  final Set<String> _deletingServers = {};

  GoRouter get router => widget.router ?? GoRouter.of(context);

  @override
  void initState() {
    super.initState();
    _servers = List.from(widget.serverDomain.servers);

    // Check server statuses when the page loads
    _checkServerStatuses();
  }

  void _checkServerStatuses() async {
    await widget.serverDomain.checkAllServerStatuses((s) {
      final index = _servers.lastIndexWhere((srv) => srv.id == s.id);
      setState(() {
        _servers[index].status = s.status;
      });
    });
  }

  void _addServer() {
    router.go('/servers/create');
  }

  void _editServer(Server server) async {
    router.go('/servers/edit/${server.id}');
  }

  void _deleteServer(Server server) {
    // Optimistic update - remove from local list immediately
    setState(() {
      _servers.removeWhere((s) => s.id == server.id);
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
                server.updateStatus(ServerStatus.offline);
                _servers.add(server);
              } else {
                // Insert at the correct position to maintain order
                server.updateStatus(ServerStatus.offline);
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
    final result = await showContextMenu(context, position, [
      buildEditMenuItem(),
      buildDeleteMenuItem(),
    ]);

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
        title: const Text(
          'SiloTavern - Servers',
          key: ValueKey('serverListTitle'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            key: ValueKey('addServerIcon'),
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
                          child: ServerCard(
                            server: server,
                            isDeleting: _deletingServers.contains(server.id),
                            isHttps: server.address.startsWith('https'),
                            onTap: () async {
                              // Show a loading dialog immediately while obtaining CSRF token in background
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return LoadingDialog(
                                    message: 'Preparing secure connection...',
                                  );
                                },
                              );

                              try {
                                final Result<void> result = await widget
                                    .connectionDomain
                                    .obtainCsrfTokenForServer(server);

                                // Close the dialog
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }

                                // Check if the operation was successful
                                if (result.isSuccess) {
                                  // Check if there's a persistent session before navigating to login
                                  if (await widget.connectionDomain
                                      .hasPersistentSession(server)) {
                                    // Skip login and go directly to connect page
                                    if (context.mounted) {
                                      router.go(
                                        Uri(
                                          path: '/servers/connect/${server.id}',
                                          queryParameters: {
                                            'backUrl': '/servers',
                                          },
                                        ).toString(),
                                      );
                                    }
                                  } else {
                                    // Navigate to login page with back URL as query parameter
                                    if (context.mounted) {
                                      router.go(
                                        Uri(
                                          path: '/servers/login/${server.id}',
                                          queryParameters: {
                                            'backUrl': '/servers',
                                          },
                                        ).toString(),
                                      );
                                    }
                                  }
                                } else {
                                  // Show error if CSRF token retrieval failed
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _getUserFriendlyErrorMessage(
                                            result.error ?? 'Operation failed',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                // Close the dialog
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }

                                // Show error if an exception occurred
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _getUserFriendlyErrorMessage(
                                          e.toString(),
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
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
    return EmptyState(
      title: 'No servers configured',
      message: 'Add your first server to get started',
      buttonText: 'Add Server',
      onButtonPressed: _addServer,
      icon: Icons.storage_outlined,
    );
  }

  /// Converts technical error messages to user-friendly messages
  String _getUserFriendlyErrorMessage(String? technicalMessage) {
    return utils.getUserFriendlyErrorMessage(technicalMessage);
  }
}
