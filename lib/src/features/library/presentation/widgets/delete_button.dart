import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeleteButton extends ConsumerWidget {
  const DeleteButton({
    Key? key,
    required this.onDelete,
  }) : super(key: key);

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: 'Delete',
        icon: const Icon(Icons.delete),
        onPressed: () async {
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remove Downloads'),
              content: const Text(
                'Are you sure you remove the downloads of all selected books?',
              ),
//               title: const Text('Permanently Delete Selected Items'),
//               content: const Text('''
// Are you sure you want to permanently delete all selected Books and Series?

// Any books inside a selected series will also be deleted.

// This cannot be undone!
// '''),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('REMOVE'),
                ),
              ],
            ),
          );
          if (shouldDelete == null || !shouldDelete) return;
          onDelete.call();
        },
      );
}
