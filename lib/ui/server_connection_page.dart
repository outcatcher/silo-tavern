import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:silo_tavern/domain/servers/models.dart';
import 'package:silo_tavern/domain/servers/domain.dart';

import 'utils.dart' as utils;

/// Page for connecting to a server
///
/// Shows connection progress and status
class ServerConnectionPage extends StatefulWidget {
  final Server server;
  final ServerDomain serverDomain;
  final String? backUrl;

  const ServerConnectionPage({
    super.key,
    required this.server,
    required this.serverDomain,
    this.backUrl,
  });

  @override
  State<ServerConnectionPage> createState() => _ServerConnectionPageState();
}

class _ServerConnectionPageState extends State<ServerConnectionPage> {
  bool _isConnecting = false;
  String _statusMessage = 'Connecting to server...';
  ServerStatus _currentStatus = ServerStatus.loading;

  GoRouter get router => GoRouter.of(context);

  @override
  void initState() {
    super.initState();
    // Start connection automatically when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToServer();
    });
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to server...';
      _currentStatus = ServerStatus.loading;
    });

    try {
      final result = await widget.serverDomain.connectToServer(widget.server);

      if (result.isSuccess) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Connected successfully!';
          _currentStatus = ServerStatus.active;
        });

        // Show success and navigate to main server list after a delay
        if (mounted) {
          utils.showSuccessDialog(
            context,
            'Connected to ${widget.server.name} successfully!',
            title: 'Connected',
          );
          // Use a timer to delay navigation after dialog is shown
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              router.go(widget.backUrl ?? '/servers');
            }
          });
        }
      } else {
        setState(() {
          _isConnecting = false;
          _statusMessage = result.errorMessage ?? 'Connection failed';
          _currentStatus = ServerStatus.unavailable;
        });

        // Show error
        if (mounted) {
          utils.showErrorDialog(
            context,
            result.errorMessage ?? 'Failed to connect to server',
            title: 'Connection Failed',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'Connection error: ${e.toString()}';
        _currentStatus = ServerStatus.unavailable;
      });

      // Show error
      if (mounted) {
        utils.showErrorDialog(
          context,
          'Error connecting to server: ${e.toString()}',
          title: 'Connection Error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connecting to ${widget.server.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => router.go(widget.backUrl ?? '/servers'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status icon
                _buildStatusIcon(),
                const SizedBox(height: 32),

                // Status message
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Progress indicator
                if (_isConnecting) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Please wait...'),
                ],

                const SizedBox(height: 32),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToServer,
                    child: Text(_isConnecting ? 'Connecting...' : 'Retry'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => router.go(widget.backUrl ?? '/servers'),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_currentStatus) {
      case ServerStatus.loading:
        return const Icon(
          Icons.hourglass_bottom,
          size: 64,
          color: Colors.orange,
        );
      case ServerStatus.ready:
        return const Icon(
          Icons.radio_button_unchecked,
          size: 64,
          color: Colors.grey,
        );
      case ServerStatus.unavailable:
        return const Icon(Icons.error_outline, size: 64, color: Colors.red);
      case ServerStatus.active:
        return const Icon(Icons.check_circle, size: 64, color: Colors.green);
    }
  }
}
