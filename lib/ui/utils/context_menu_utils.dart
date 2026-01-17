import 'package:flutter/material.dart';

/// Shows a context menu at the specified position
Future<T?> showContextMenu<T>(
  BuildContext context,
  Offset position,
  List<PopupMenuEntry<T>> items,
) async {
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      MediaQuery.of(context).size.width - position.dx,
      MediaQuery.of(context).size.height - position.dy,
    ),
    items: items,
  );
}

/// Builds standard edit menu item
PopupMenuItem<String> buildEditMenuItem() {
  return PopupMenuItem(
    value: 'edit',
    child: Row(
      children: [
        const Icon(Icons.edit, size: 20),
        const SizedBox(width: 8),
        const Text('Edit'),
      ],
    ),
  );
}

/// Builds standard delete menu item
PopupMenuItem<String> buildDeleteMenuItem() {
  return PopupMenuItem(
    value: 'delete',
    child: Row(
      children: [
        const Icon(Icons.delete, size: 20, color: Colors.red),
        const SizedBox(width: 8),
        const Text('Delete', style: TextStyle(color: Colors.red)),
      ],
    ),
  );
}
