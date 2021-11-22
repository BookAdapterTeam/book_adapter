import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddNewCollectionButton extends ConsumerWidget {
  const AddNewCollectionButton({Key? key, required this.onAddNewCollection})
      : super(key: key);

  final void Function(String) onAddNewCollection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onAddNewCollection.call(collectionName);
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
      title: const Text('Add New Book Collection'),
      actions: [
        TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Collection name',
            border: UnderlineInputBorder(),
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
