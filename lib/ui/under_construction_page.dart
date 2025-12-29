import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page displayed when a feature is under construction
///
/// Shows an "under construction" message with a customizable title and back navigation
class UnderConstructionPage extends StatelessWidget {
  final String title;
  final String? backUrl;

  const UnderConstructionPage({super.key, required this.title, this.backUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(backUrl ?? '/'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Construction-themed icon
            Icon(
              Icons.construction,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),

            // Under construction text
            const Text(
              'Under Construction',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Additional message
            const Text(
              'This feature is currently being developed',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
