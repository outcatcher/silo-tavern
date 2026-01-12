import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/connection/domain.dart';
import 'package:silo_tavern/common/result.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/services/connection/models/models.dart';
import 'package:silo_tavern/ui/utils.dart' as utils;
import 'package:silo_tavern/ui/utils/form_validators.dart';

/// Page for authenticating with a server
///
/// Shows a login form with username and password fields and a "Remember me" checkbox
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
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isAuthenticating = false;

  GoRouter get router => widget.router ?? GoRouter.of(context);

  @override
  void initState() {
    super.initState();
    // No need to check for existing session here since it's checked in server list page
  }

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
          onPressed: () => router.go(widget.backUrl ?? utils.defaultPage),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
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
            onFieldSubmitted: (_) {
              // Move focus to password field when Enter is pressed
              FocusScope.of(context).nextFocus();
            },
            validator: (value) {
              return FormValidators.validUsername(value);
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
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
            onFieldSubmitted: (_) {
              // Trigger login when Enter is pressed in password field
              if (!_isAuthenticating) {
                _handleLogin();
              }
            },
            validator: (value) {
              return FormValidators.validPassword(value);
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            key: const ValueKey('rememberMeCheckbox'),
            title: const Text('Remember me'),
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),
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
        final Result<void> result = await widget.connectionDomain
            .authenticateWithServer(
              widget.server,
              credentials,
              rememberMe: _rememberMe,
            );

        if (result.isSuccess) {
          // Authentication successful - navigate to connect page
          if (context.mounted) {
            router.go(
              Uri(
                path: '/servers/connect/${widget.server.id}',
                queryParameters: {
                  'backUrl': widget.backUrl ?? utils.defaultPage,
                },
              ).toString(),
            );
          }
        } else {
          // Authentication failed - show error
          if (mounted) {
            utils.showErrorDialog(
              context,
              _getUserFriendlyAuthErrorMessage(
                result.error ?? 'Authentication failed',
              ),
              title: 'Login Failed',
            );
          }
        }
      } catch (e) {
        // Unexpected error
        if (mounted) {
          utils.showErrorDialog(
            context,
            _getUserFriendlyAuthErrorMessage(e.toString()),
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

  /// Converts technical authentication error messages to user-friendly messages
  String _getUserFriendlyAuthErrorMessage(String? technicalMessage) {
    return utils.getFriendlyAuthErrorMessage(technicalMessage);
  }
}
