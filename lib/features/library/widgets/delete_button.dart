import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeleteButton extends ConsumerWidget {
  const DeleteButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Delete',
      icon: const Icon(Icons.delete),
      onPressed: () async {
        final bool? shouldDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Remove Downloads'),
              content: const Text(
                  'Are you sure you remove the downloads of all selected books?'),
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
            );
          },
        );
        if (shouldDelete == null) return;
        if (!shouldDelete) return;

        await ref
            .read(libraryViewControllerProvider.notifier)
            .deleteBookDownloads(context);
      },
    );
  }
}
