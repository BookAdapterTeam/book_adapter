import 'package:book_adapter/commands/refresh_command.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/book_item.dart';
import 'package:book_adapter/features/library/book_item_details_view.dart';
import 'package:book_adapter/features/settings/settings_view.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Displays a list of BookItems.
class LibraryView extends ConsumerWidget {
  const LibraryView({ Key? key }) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch returns the value exposed by a provider and rebuild the widget when that value changes.
    // final userData = ref.watch(userModelProvider);
    // final List<BookItem> books = userData.books;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Library'.i18n),
        actions: [
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
      // To work with lists that may contain a large number of items, it’s best
      // to use the ListView.builder constructor.
      //
      // In contrast to the default ListView constructor, which requires
      // building all Widgets up front, the ListView.builder constructor lazily
      // builds Widgets as they’re scrolled into view.
      body: FutureBuilder<Either<Failure, List<BookItem>>>(
        future: ref.read(refreshCommandProvider).run(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final resp = snapshot.data!;
            return resp.fold(
              (failure) => Center(child: Text(failure.message),),
              (books) => hasBooks(books),
            );
            // return const Center(child: Text('done'),);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(),);
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unknown Error'),);
          }

          return const Center(child: CircularProgressIndicator(),);
        }
      ),
    );
  }

  ListView hasBooks(List<BookItem> books) {
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