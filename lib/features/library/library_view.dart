import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/profile/profile_view.dart';
import 'package:book_adapter/features/reader/book_reader_view.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

/// Displays a list of BookItems.
class LibraryView extends ConsumerWidget {
  const LibraryView({ Key? key }) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);

    return Scaffold(
      appBar: AppBar(
        title: Text('Library'.i18n),
        actions: const [
          _AddBookButton(),
          _ProfileButton(),
        ],
      ),
      body: data.books != null
        ? _LibraryListView(books: data.books!)
        : const Center(child: CircularProgressIndicator(key: ValueKey('loading_books'))),
    );
  }
}

class _AddBookButton extends ConsumerWidget {
  const _AddBookButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewController viewController = ref.watch(libraryViewController.notifier);
    return IconButton(
      onPressed: () => viewController.addBooks(context),
      iconSize: 36,
      icon: const Icon(Icons.add_rounded)
    );
  }
}

class _ProfileButton extends ConsumerWidget {
  const _ProfileButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(userChangesProvider);
    final log = Logger();
    return userStreamAsyncValue.when(
      data: (user) {
        return IconButton(
          key: const ValueKey('profile'),
          icon: user != null
                ? _userLoggedIn(user)
                : const Icon(Icons.account_circle),
          onPressed: () {
            // Navigate to the settings page. If the user leaves and returns
            // to the app after it has been killed while running in the
            // background, the navigation stack is restored.
            Navigator.restorablePushNamed(context, ProfileView.routeName);
          },
        );
      },
      loading: (userA) => IconButton(
          key: const ValueKey('profile'),
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.restorablePushNamed(context, ProfileView.routeName);
          },
        ),
      error: (e, st, userA) {
        log.e('Error getting user data', e, st);
        return IconButton(
          key: const ValueKey('profile'),
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.restorablePushNamed(context, ProfileView.routeName);
          },
        );
      },
    );
  }

  Widget _userLoggedIn(User user) {
    return user.photoURL != null 
        ? CircleAvatar(
          backgroundImage:
            NetworkImage(user.photoURL!),
          backgroundColor: Colors.grey,
        )
        : const Icon(Icons.account_circle);
  }
}

class _LibraryListView extends ConsumerWidget {
  const _LibraryListView({
    Key? key,
    required this.books,
  }) : super(key: key);
  final List<Book> books;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return books.isNotEmpty 
      ? ListView.builder(
        // Providing a restorationId allows the ListView to restore the
        // scroll position when a user leaves and returns to the app after it
        // has been killed while running in the background.
        restorationId: 'bookListView',
        itemCount: books.length,
        itemBuilder: (BuildContext context, int index) {
          final book = books[index];
          final imageUrl = book.imageUrl;

          return ListTile(
            title: Text(book.title),
            subtitle: Text(book.authors),
            leading: imageUrl != null 
              ? ClipRRect(child: CachedNetworkImage(imageUrl: imageUrl, width: 40,), borderRadius: BorderRadius.circular(4),)
              : null,
            onTap: () {
              // Navigate to the details page. If the user leaves and returns to
              // the app after it has been killed while running in the
              // background, the navigation stack is restored.
              Navigator.restorablePushNamed(
                context,
                BookReaderView.routeName,
                // Convert the book object to a map so that it can be passed through Navigator
                arguments: book.toMapSerializable(),
              );
            }
          );
        },
      )
      : Center(child: Text("You don't have any books", style: Theme.of(context).textTheme.bodyText2,));
  }
}