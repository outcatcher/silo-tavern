import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';
import 'package:uuid/v7.dart';

import 'utils.dart' as utils;
import 'utils/form_validators.dart';

enum PageMode { create, edit }

class ServerCreationPage extends StatefulWidget {
  final ServerDomain serverDomain;
  final Server? initialServer;
  final GoRouter? router;

  const ServerCreationPage({
    super.key,
    required this.serverDomain,
    this.initialServer,
    this.router,
  });

  @override
  State<ServerCreationPage> createState() => _ServerCreationPageState();
}

class _ServerCreationPageState extends State<ServerCreationPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name = '';
  late String _url = '';

  // Validation error states
  String? _nameError;
  String? _urlError;

  GoRouter get router => widget.router ?? GoRouter.of(context);

  @override
  void initState() {
    super.initState();
    // Initialize with initial server data if provided (for editing)
    if (widget.initialServer != null) {
      final server = widget.initialServer!;
      _name = server.name;
      _url = server.address;
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
          key: const ValueKey('backButton'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            router.go('/servers');
          },
          splashRadius: 24.0,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        actions: [
          IconButton(
            key: const ValueKey('saveButton'),
            icon: Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () async {
              // Trigger real-time validation for all fields
              setState(() {
                // Validate name
                if (_name.isEmpty) {
                  _nameError = 'Please enter a server name';
                } else {
                  _nameError = null;
                }

                // Validate URL
                if (_url.isEmpty) {
                  _urlError = 'Please enter a server URL';
                } else if (!RegExp(r'^https?:\/\/').hasMatch(_url)) {
                  _urlError = 'Please enter a valid URL (http:// or https://)';
                } else {
                  _urlError = null;
                }
              });

              // If real-time validation passed, proceed with form validation
              if (_nameError == null &&
                  _urlError == null &&
                  _formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // Create temporary server to validate configuration
                final tempServer = Server(
                  id: widget.initialServer?.id ?? UuidV7().generate(),
                  name: _name,
                  address: _url,
                );

                // Validate server configuration
                final result = validateServerConfiguration(tempServer);
                if (result.isFailure) {
                  // Show error dialog
                  utils.showErrorDialog(
                    context,
                    'Please use HTTPS with authentication for remote servers.',
                    title: 'Invalid Configuration',
                  );
                  return;
                }

                // Save the server data directly
                if (widget.initialServer != null) {
                  // Update existing server
                  final result = await widget.serverDomain.updateServer(
                    tempServer,
                  );
                  if (result.isFailure) {
                    utils.showErrorDialog(
                      context,
                      'Failed to save server. Please try again.',
                      title: 'Save Failed',
                    );
                  }

                  // Navigate back to the server list after successful update
                  if (context.mounted) {
                    router.go('/servers');
                  }

                  return;
                }

                // Add new server
                await widget.serverDomain.addServer(tempServer);
                if (context.mounted) {
                  utils.showSuccessDialog(
                    context,
                    'Server added successfully!',
                    title: 'Success',
                  );
                  router.go('/servers');
                }
              }
            },
            splashRadius: 24.0,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '* Required fields',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('serverNameField'),
                      initialValue: _name,
                      decoration: InputDecoration(
                        labelText: 'Server Name *',
                        errorText: _nameError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _name = value;
                          // Real-time validation
                          if (value.isEmpty) {
                            _nameError = 'Please enter a server name';
                          } else {
                            _nameError = null;
                          }
                        });
                      },
                      validator: (value) {
                        return FormValidators.notEmpty(
                          value,
                          fieldName: 'server name',
                        );
                      },
                      onSaved: (value) {
                        _name = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('serverUrlField'),
                      initialValue: _url,
                      decoration: InputDecoration(
                        labelText: 'Server URL *',
                        errorText: _urlError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _url = value;
                          // Real-time validation
                          if (value.isEmpty) {
                            _urlError = 'Please enter a server URL';
                          } else if (!RegExp(r'^https?:\/\/').hasMatch(value)) {
                            _urlError =
                                'Please enter a valid URL (http:// or https://)';
                          } else {
                            _urlError = null;
                          }
                        });
                      },
                      validator: (value) {
                        return FormValidators.validUrl(value);
                      },
                      onSaved: (value) {
                        _url = value!;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Authentication fields removed - handled in login page
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
