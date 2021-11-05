

import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddBookButton extends ConsumerWidget {
  const AddBookButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewController viewController = ref.watch(libraryViewControllerProvider.notifier);
    return IconButton(
      tooltip: 'Add a book',
      onPressed: () => viewController.addBooks(context),
      iconSize: 28,
      icon: const Icon(Icons.add),
    );
  }
}