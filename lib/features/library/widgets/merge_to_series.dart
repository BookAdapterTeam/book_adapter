import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AddNewSeriesDialog extends HookWidget {
  const AddNewSeriesDialog({Key? key, this.initialText}) : super(key: key);
  final String? initialText;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(text: initialText);
    return AlertDialog(
      title: const Text('Enter the Name of the Series'),
      actions: [
        TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Series name',
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
