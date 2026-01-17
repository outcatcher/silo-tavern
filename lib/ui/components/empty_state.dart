import 'package:flutter/material.dart';

/// A reusable empty state widget
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final IconData icon;

  const EmptyState({
    super.key,
    this.title = 'No items found',
    this.message = 'Add your first item to get started',
    this.buttonText = 'Add Item',
    required this.onButtonPressed,
    this.icon = Icons.inbox,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            key: const ValueKey('addServerButton'),
            onPressed: onButtonPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
