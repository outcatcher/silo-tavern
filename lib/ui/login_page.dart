import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/services/connection/models/models.dart';
import 'package:silo_tavern/ui/utils.dart' as utils;

/// Page for authenticating with a server
///
/// Shows a login form with username and password fields
class LoginPage extends StatefulWidget {
  final Server server;
  final String? backUrl;
  final GoRouter? router;
  final ConnectionDomain connectionDomain;

  const LoginPage({
    super.key,
    required this.server,
    this.backUrl,
    this.router,
    required this.connectionDomain,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _username = '';
  late String _password = '';
  bool _obscurePassword = true;
  bool _isAuthenticating = false;

  GoRouter get router => widget.router ?? GoRouter.of(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login to ${widget.server.name}',
          key: ValueKey('loginPageTitle'),
        ),
        leading: IconButton(
          key: const ValueKey('backButton'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => router.go(widget.backUrl ?? '/servers'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server: ${widget.server.address}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const ValueKey('usernameField'),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _username = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('passwordField'),
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _password = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const ValueKey('loginButton'),
                      onPressed: _isAuthenticating ? null : _handleLogin,
                      icon: _isAuthenticating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isAuthenticating ? 'Logging in...' : 'Login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isAuthenticating = true;
      });

      try {
        // Create credentials from form data
        final credentials = ConnectionCredentials(
          handle: _username,
          password: _password,
        );

        // Authenticate with the server
        final result = await widget.connectionDomain.authenticateWithServer(
          widget.server,
          credentials,
        );

        if (result.isSuccess) {
          // Authentication successful - navigate to connect page
          if (context.mounted) {
            router.go(
              Uri(
                path: '/servers/connect/${widget.server.id}',
                queryParameters: {'backUrl': widget.backUrl ?? '/servers'},
              ).toString(),
            );
          }
        } else {
          // Authentication failed - show error
          if (context.mounted) {
            utils.showErrorDialog(
              context,
              result.errorMessage ?? 'Authentication failed',
              title: 'Login Failed',
            );
          }
        }
      } catch (e) {
        // Unexpected error
        if (context.mounted) {
          utils.showErrorDialog(
            context,
            'An unexpected error occurred: $e',
            title: 'Login Error',
          );
        }
      } finally {
        if (context.mounted) {
          setState(() {
            _isAuthenticating = false;
          });
        }
      }
    }
  }
}
