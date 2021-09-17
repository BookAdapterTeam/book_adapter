import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/features/library/book_item_details_view.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/settings/settings_view.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Displays a list of BookItems.
class LibraryView extends ConsumerWidget {
  const LibraryView({ Key? key }) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(userModelProvider).books;
    final isLoading = ref.watch(libraryViewController);
    final viewController = ref.watch(libraryViewController.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'.i18n),
        actions: [
          IconButton(
            icon: isLoading ? const CircularProgressIndicator(
              color: Colors.white,
            ) : const Icon(Icons.refresh),
            onPressed: () {
              viewController.refreshBooks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to the settings page. If the user leaves and returns
              // to the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: hasBooks(books),
    );
  }

  Widget hasBooks(List<BookItem> books) {
    return ListView.builder(
      // Providing a restorationId allows the ListView to restore the
      // scroll position when a user leaves and returns to the app after it
      // has been killed while running in the background.
      restorationId: 'bookListView',
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        final book = books[index];

        return ListTile(
          title: Text('Book: ${book.name}'),
          subtitle: Text('ID: ${book.id}'),
          leading: const CircleAvatar(
            // Display the Flutter Logo image asset.
            foregroundImage: AssetImage('assets/images/flutter_logo.png'),
          ),
          onTap: () {
            // Navigate to the details page. If the user leaves and returns to
            // the app after it has been killed while running in the
            // background, the navigation stack is restored.
            Navigator.restorablePushNamed(
              context,
              BookItemDetailsView.routeName,
              // Convert the book object to a map so that it can be passed through Navigator
              arguments: book.toMap(),
            );
          }
        );
      },
    );
  }
}