import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widget/hooks.dart';
import 'package:book_adapter/features/library/widget/selectable_item_widget.dart';
import 'package:book_adapter/features/profile/profile_view.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:logger/logger.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'select_grid_page.dart';

/// Displays a list of BookItems.
class LibraryView extends ConsumerWidget {
  const LibraryView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SafeArea(child: LibraryScrollView()),
    );
  }
}

class _AddBookButton extends ConsumerWidget {
  const _AddBookButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewController viewController =
        ref.watch(libraryViewController.notifier);
    return IconButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectGridPage())),
        iconSize: 36,
        icon: const Icon(Icons.add_rounded));
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
            backgroundImage: NetworkImage(user.photoURL!),
            backgroundColor: Colors.grey,
          )
        : const Icon(Icons.account_circle);
  }
}

class LibraryScrollView extends HookConsumerWidget {
  const LibraryScrollView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final scrollController = useScrollController();
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAppBar(
          title: Text('Library'.i18n),
          floating: true,
          snap: true,
          actions: const [
            _AddBookButton(),
            _ProfileButton(),
          ],
        ),
        // List of collections
        SliverImplicitlyAnimatedList<BookCollection>(
          items: data.collections ?? [],
          areItemsTheSame: (a, b) => a.id == b.id,
          itemBuilder: (context, animation, collection, index) =>
              collectionsBuilder(
                  context, animation, collection, index, scrollController),
        ),
      ],
    );
  }

  Widget collectionsBuilder(BuildContext context, Animation<double> animation,
      BookCollection collection, int index, ScrollController controller) {

    return StickyHeader(
      controller: controller,
      header: Container(
        height: 50.0,
        color: Colors.blueGrey[700],
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Text(
          collection.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      content: BookGridView(collection: collection),
    );
      // content: BookCollectionList(collection: collection),
      // );
  }

  
}

class BookGridView extends HookConsumerWidget {
  const BookGridView({ Key? key, required this.collection }) : super(key: key);
  final BookCollection collection;
  final urlImage = 'https://99designs-start-attachments.imgix.net/alchemy-pictures/2016%2F02%2F12%2F00%2F05%2F05%2F910db405-6bd4-4a5d-bce7-c2e3135dc5e6%2F449070_WAntoneta_55908c_killing.png?auto=format&ch=Width%2CDPR&fm=png&w=600&h=600';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final items = data.books
            ?.where((book) => book.collectionIds.contains(collection.id))
            .toList() ?? [];
    items.sort((a, b) => a.title.compareTo(b.title));

    final dragSelectController = useDragSelectGridViewController();

    return DragSelectGridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridController: dragSelectController,
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.8/3.92
      ),
      itemBuilder: (context, index, isSelected) => SelectableItemWidget(
        url: items[index].imageUrl ?? urlImage,
        isSelected: isSelected,
      ),
    );
  }
}

class BookCollectionList extends HookConsumerWidget {
  const BookCollectionList({Key? key, required this.collection})
      : super(key: key);
  final BookCollection collection;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final items = data.books
            ?.where((book) => book.collectionIds.contains(collection.id))
            .toList() ??
        [];
    items.sort((a, b) => a.title.compareTo(b.title));

    return ImplicitlyAnimatedList<Item>(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      key: ValueKey(collection.id),
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: booksBuilder,
      removeItemBuilder: removeItemBuilder,
    );
  }

  Widget removeItemBuilder(
      BuildContext context, Animation<double> animation, Item oldItem) {
    final imageUrl = oldItem.imageUrl;
    final subtitle = oldItem.subtitle;
    return FadeTransition(
        opacity: animation,
        child: ListTile(
          key: ValueKey(collection.id + oldItem.id),
          title: Text(oldItem.title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          leading: imageUrl != null
              ? ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 40,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
        ));
  }

  Widget booksBuilder(
      BuildContext context, Animation<double> animation, Item item, int index) {
    final imageUrl = item.imageUrl;
    final subtitle = item.subtitle;
    return SizeFadeTransition(
      sizeFraction: 0.7,
      curve: Curves.easeInOut,
      animation: animation,
      child: ListTile(
          key: ValueKey(item.id),
          title: Text(item.title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          leading: imageUrl != null
              ? ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 40,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          onTap: () {
            // Navigate to the details page. If the user leaves and returns to
            // the app after it has been killed while running in the
            // background, the navigation stack is restored.
            Navigator.restorablePushNamed(
              context,
              item.routeTo,
              // Convert the book object to a map so that it can be passed through Navigator
              arguments: item.toMapSerializable(),
            );
          }),
    );
  }
}