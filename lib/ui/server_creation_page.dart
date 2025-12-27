import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/server.dart';
import 'package:silo_tavern/utils/network_utils.dart';
import 'package:silo_tavern/domain/server_service.dart';
import 'package:uuid/v7.dart';

import 'utils.dart' as utils;

enum PageMode { create, edit }

class ServerCreationPage extends StatefulWidget {
  final ServerService serverService;
  final Server? initialServer;

  const ServerCreationPage({
    super.key,
    required this.serverService,
    this.initialServer,
  });

  @override
  State<ServerCreationPage> createState() => _ServerCreationPageState();
}

enum AuthenticationType { none, credentials }

class _ServerCreationPageState extends State<ServerCreationPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name = '';
  late String _url = '';
  AuthenticationType _authType = AuthenticationType.none;
  late String _username = '';
  late String _password = '';

  @override
  void initState() {
    super.initState();
    // Initialize with initial server data if provided (for editing)
    if (widget.initialServer != null) {
      final server = widget.initialServer!;
      _name = server.name;
      _url = server.address;
      _authType = server.authentication.useCredentials
          ? AuthenticationType.credentials
          : AuthenticationType.none;
      _username = server.authentication.username;
      _password = server.authentication.password;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialServer != null ? 'Edit Server' : 'Add New Server',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/servers');
          },
          splashRadius: 24.0, // Increase touch target size
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // Create temporary server to validate configuration
                final tempServer = Server(
                  id: widget.initialServer?.id ?? UuidV7().generate(),
                  name: _name,
                  address: _url,
                  authentication: _authType == AuthenticationType.credentials
                      ? AuthenticationInfo.credentials(
                          username: _username,
                          password: _password,
                        )
                      : const AuthenticationInfo.none(),
                );

                // Validate server configuration
                try {
                  NetworkUtils.validateServerConfiguration(tempServer);
                } catch (e) {
                  // Show error dialog
                  if (mounted) {
                    utils.showErrorDialog(
                      context,
                      'Remote servers must use HTTPS and authentication. Local servers can use any configuration.',
                      title: 'Configuration Not Allowed',
                    );
                  }
                  return;
                }

                // Save the server data directly
                try {
                  if (widget.initialServer != null) {
                    // Update existing server
                    await widget.serverService.updateServer(tempServer);
                    // Navigate back to the server list after successful update
                    if (context.mounted) {
                      context.go('/servers');
                    }
                  } else {
                    // Add new server
                    await widget.serverService.addServer(tempServer);
                    if (context.mounted) {
                      utils.showSuccessDialog(
                        context,
                        'Server "${tempServer.name}" has been successfully added.',
                        title: 'Server Added',
                      );
                      context.go('/servers');
                    }
                  }
                } catch (error) {
                  log('failed to save server', error: error);

                  if (context.mounted) {
                    final action = widget.initialServer != null
                        ? 'update'
                        : 'add';
                    utils.showErrorDialog(
                      context,
                      'Failed to $action server "${tempServer.name}". Please try again.',
                      title:
                          'Server ${widget.initialServer != null ? 'Update' : 'Add'} Failed',
                    );
                  }
                }
              }
            },
            splashRadius: 24.0, // Increase touch target size
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '* Required fields',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                        labelText: 'Server Name *',
                        hintText: 'Example',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a server name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _url,
                      decoration: const InputDecoration(
                        labelText: 'Server URL *',
                        hintText: 'https://example.com:8000',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a server URL';
                        }
                        // Basic URL validation
                        if (!RegExp(r'^https?:\/\/').hasMatch(value)) {
                          return 'Please enter a valid URL (http:// or https://)';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _url = value!;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Authentication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Localhost servers can use any configuration. Remote servers must use HTTPS with authentication.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioGroup<AuthenticationType>(
                          groupValue: _authType,
                          onChanged: (AuthenticationType? value) {
                            setState(() {
                              _authType = value!;
                            });
                          },
                          child: Column(
                            children: [
                              RadioListTile<AuthenticationType>(
                                title: const Text('None'),
                                value: AuthenticationType.none,
                              ),
                              RadioListTile<AuthenticationType>(
                                title: const Text('Credentials'),
                                value: AuthenticationType.credentials,
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: _authType == AuthenticationType.credentials
                              ? null
                              : 0,
                          child: _authType == AuthenticationType.credentials
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: _username,
                                      decoration: const InputDecoration(
                                        labelText: 'User Handle *',
                                        hintText: 'username',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_authType ==
                                                AuthenticationType
                                                    .credentials &&
                                            (value == null || value.isEmpty)) {
                                          return 'Please enter a username';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _username = value!;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: _password,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password *',
                                        hintText: '••••••••',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_authType ==
                                                AuthenticationType
                                                    .credentials &&
                                            (value == null || value.isEmpty)) {
                                          return 'Please enter a password';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _password = value!;
                                      },
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
