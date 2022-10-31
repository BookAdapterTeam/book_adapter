import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddBookButton extends ConsumerWidget {
  const AddBookButton({Key? key, required this.onAdd}) : super(key: key);

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: 'Add a book',
        onPressed: onAdd.call,
        iconSize: 28,
        icon: const Icon(Icons.add),
      );
}
