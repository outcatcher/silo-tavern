import 'package:flutter/material.dart';
import 'package:silo_tavern/domain/server.dart';

enum PageMode { create, edit }

class ServerCreationPage extends StatefulWidget {
  final Server? initialServer;

  const ServerCreationPage({super.key, this.initialServer});

  @override
  State<ServerCreationPage> createState() => _ServerCreationPageState();
}

enum AuthenticationType { none, credentials }

class _ServerCreationPageState extends State<ServerCreationPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _url;
  AuthenticationType _authType = AuthenticationType.none;
  late String _username;
  late String _password;

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
    } else {
      // Default values for new server
      _name = '';
      _url = '';
      _username = '';
      _password = '';
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
            Navigator.of(context).pop(); // Cancel
          },
          splashRadius: 24.0, // Increase touch target size
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // Return the new server data to the previous screen
                Navigator.of(context).pop(
                  Server(
                    id:
                        widget.initialServer?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _name,
                    address: _url,
                    isActive:
                        widget.initialServer?.isActive ??
                        false, // Preserve active status for edits
                    authentication: _authType == AuthenticationType.credentials
                        ? AuthenticationInfo.credentials(
                            username: _username,
                            password: _password,
                          )
                        : const AuthenticationInfo.none(),
                  ),
                );
              }
            },
            splashRadius: 24.0, // Increase touch target size
          ),
        ],
      ),
      body: Padding(
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
                const Text.rich(
                  TextSpan(
                    text: 'Server Name',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(
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
                const Text.rich(
                  TextSpan(
                    text: 'Server URL',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _url,
                  decoration: const InputDecoration(
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
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
                if (_authType == AuthenticationType.credentials) ...[
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(
                      text: 'User Handle',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _username,
                    decoration: const InputDecoration(
                      hintText: 'username',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    validator: (value) {
                      if (_authType == AuthenticationType.credentials &&
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
                  const Text.rich(
                    TextSpan(
                      text: 'Password',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    validator: (value) {
                      if (_authType == AuthenticationType.credentials &&
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
