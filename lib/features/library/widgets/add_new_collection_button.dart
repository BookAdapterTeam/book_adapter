import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class AddNewCollectionButton extends ConsumerWidget {
  const AddNewCollectionButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Logger log = Logger();
    return Semantics(
      onLongPressHint: 'Add a new collection',
      child: TextButton.icon(
        icon: const Text('ADD'),
        onPressed: () async {
          final collectionName = await showDialog<String>(
              context: context,
              builder: (context) {
                return const AddNewCollectionDialog();
              });
          if (collectionName == null) return;

          final viewController =
              ref.read(libraryViewControllerProvider.notifier);
          final res = await viewController.addNewCollection(collectionName);
          res.fold(
            (failure) {
              final snackBar = SnackBar(
                content: Text(failure.message),
                duration: const Duration(seconds: 2),
              );
              log.e(failure.message);
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            (collection) {
              final snackBar = SnackBar(
                content: Text('Successfully created ${collection.name}'),
                duration: const Duration(seconds: 2),
              );
              log.i('Successfully created ${collection.name}');
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          );
        },
        label: const Icon(Icons.bookmark_add),
      ),
    );
  }
}

class AddNewCollectionDialog extends HookWidget {
  const AddNewCollectionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    return AlertDialog(
      title: const Text('Create New Collection'),
      actions: [
        TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Collection name',
            border: OutlineInputBorder(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                final collectionName = textController.text;
                Navigator.of(context).pop(collectionName);
              },
              child: const Text('CREATE'),
            ),
          ],
        ),
      ],
    );
  }
}
