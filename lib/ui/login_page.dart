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
  bool _isLoadingCsrf = false;
  String? _csrfError;

  GoRouter get router => widget.router ?? GoRouter.of(context);

  @override
  void initState() {
    super.initState();
    _isLoadingCsrf = false; // Start with loading state disabled
    // Only check CSRF token if needed (e.g., if we detect it's missing)
    // For now, we assume it's already been handled before navigating to this page
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
          onPressed: () => router.go(widget.backUrl ?? '/servers'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isLoadingCsrf
                ? _buildLoadingState()
                : _csrfError != null
                    ? _buildErrorState()
                    : _buildLoginForm(),
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
            onFieldSubmitted: (_) {
              // Trigger login when Enter is pressed in password field
              if (!_isAuthenticating) {
                _handleLogin();
              }
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
              label: Text(
                _isAuthenticating ? 'Logging in...' : 'Login',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Preparing secure connection...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    Future<void> _retryCsrfCheck() async {
      setState(() {
        _isLoadingCsrf = true;
        _csrfError = null;
      });
      
      try {
        // Try to obtain CSRF token for the server
        final result = await widget.connectionDomain.obtainCsrfTokenForServer(
          widget.server,
        );
        
        if (context.mounted) {
          setState(() {
            _isLoadingCsrf = false;
            if (!result.isSuccess) {
              _csrfError = result.errorMessage;
            }
          });
        }
      } catch (e) {
        if (context.mounted) {
          setState(() {
            _isLoadingCsrf = false;
            _csrfError = e.toString();
          });
        }
      }
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to prepare secure connection',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _csrfError ?? 'Unknown error',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _retryCsrfCheck,
            child: const Text('Retry'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => router.go(widget.backUrl ?? '/servers'),
            child: const Text('Back to Servers'),
          ),
        ),
      ],
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
              _getUserFriendlyAuthErrorMessage(result.errorMessage),
              title: 'Login Failed',
            );
          }
        }
      } catch (e) {
        // Unexpected error
        if (context.mounted) {
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
    if (technicalMessage == null || technicalMessage.isEmpty) {
      return 'Authentication failed. Please check your credentials and try again.';
    }

    // Handle common authentication errors
    if (technicalMessage.contains('401') || 
        technicalMessage.contains('Unauthorized') ||
        technicalMessage.contains('invalid credentials') ||
        technicalMessage.contains('Invalid credentials')) {
      return 'Invalid username or password. Please check your credentials and try again.';
    }

    // Handle network connectivity issues
    if (technicalMessage.contains('SocketException') ||
        technicalMessage.contains('Connection refused') ||
        technicalMessage.contains('Failed host lookup')) {
      return 'Unable to connect to the server. Please check your network connection and try again.';
    }

    // Handle timeout errors
    if (technicalMessage.contains('timeout') ||
        technicalMessage.contains('timed out')) {
      return 'Connection timed out. The server may be busy or unreachable. Please try again.';
    }

    // Handle certificate errors
    if (technicalMessage.contains('CERTIFICATE_VERIFY_FAILED') ||
        technicalMessage.contains('HandshakeException')) {
      return 'Security certificate verification failed. Please check that the server\'s SSL/TLS certificate is valid.';
    }

    // Default fallback message
    return 'Authentication failed. Please check your credentials and try again.';
  }
}
