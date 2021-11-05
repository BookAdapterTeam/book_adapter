import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/add_book_button.dart';
import 'package:book_adapter/features/library/widgets/add_to_collection_button.dart';
import 'package:book_adapter/features/library/widgets/item_list_tile_widget.dart';
import 'package:book_adapter/features/library/widgets/merge_to_series.dart';
import 'package:book_adapter/features/library/widgets/profile_button.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:logger/logger.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sticky_headers/sticky_headers.dart';

/// Displays a list of BookItems.
class LibraryView extends ConsumerWidget {
  const LibraryView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.watch(userModelProvider.notifier);
    return FutureBuilder<void>(
        future: userModel.setDownloadedFilenames(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                  'Error occurred when listing files on the device\n + ${snapshot.error.toString()}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return const Scaffold(
              body: LibraryScrollView(),
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}

class MergeIntoSeriesButton extends ConsumerWidget {
  const MergeIntoSeriesButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewController viewController =
        ref.watch(libraryViewControllerProvider.notifier);
    final selectedItems =
        ref.watch(libraryViewControllerProvider.select((data) => data.selectedItems));
    final log = Logger();

    return IconButton(
      tooltip: 'Merge to series',
      onPressed: () async {
        final seriesName = await showDialog<String>(
            context: context,
            builder: (context) {
              // Could sort the list before using choosig the title.
              // Without soring, it will use the title of the first book selected.
              // final selectedItemsList = selectedItems.toList()
              //   ..sort((a, b) => a.title.compareTo(b.title));
              // final initialText = selectedItemsList.first.title;
              final initialText = selectedItems.first.title;
              return AddNewSeriesDialog(
                initialText: initialText,
              );
            });
        if (seriesName == null) return;
        final res = await viewController.mergeIntoSeries(seriesName);

        res.fold(
          (failure) {
            final snackBar = SnackBar(
              content: Text(failure.message),
              duration: const Duration(seconds: 2),
            );
            log.e(failure.message);
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
          (_) => null,
        );
      },
      // onPressed: () => viewController.mergeIntoSeries(),
      icon: const Icon(Icons.merge_type),
    );
  }
}

class LibraryScrollView extends HookConsumerWidget {
  const LibraryScrollView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewControllerProvider);
    final LibraryViewController viewController =
        ref.watch(libraryViewControllerProvider.notifier);
    final scrollController = useScrollController();
    final log = Logger();

    final notSelectingAppBar = SliverAppBar(
      key: const ValueKey('normal_app_bar'),
      title: Text('Library'.i18n),
      // pinned: true,
      floating: true,
      snap: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        const AddBookButton(),
        IconButton(
          tooltip: 'Add a new collection',
          onPressed: () async {
            final collectionName = await showDialog<String>(
                context: context,
                builder: (context) {
                  return const AddNewCollectionDialog();
                });
            if (collectionName == null) return;

            final viewController = ref.read(libraryViewControllerProvider.notifier);
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
          icon: const Icon(Icons.bookmark_add),
        ),
        const ProfileButton(),
      ],
    );

    final isSelectingAppBar = SliverAppBar(
      key: const ValueKey('selecting_app_bar'),
      title: Text('Selected: ${data.numberSelected}'),
      pinned: true,
      backgroundColor: Colors.black12,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 3.0,
      leading: BackButton(
        onPressed: () => viewController.deselectAllItems(),
      ),
      actions: [
        const AddToCollectionButton(),

        // TODO: Button is disabled a series is selected until remove series cloud function is implemented, delete old series
        // Disable button until more than one book selected so that the user does not create series with only one book in it
        if (!data.hasSeries && data.selectedItems.length > 1)
          const MergeIntoSeriesButton(),

        // DeleteButton(),
      ],
    );

    final appBar = data.isSelecting ? isSelectingAppBar : notSelectingAppBar;

    final collections = (data.collections ?? [])
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAnimatedSwitcher(
          child: appBar,
          duration: const Duration(milliseconds: 250),
        ),

        // List of collections
        SliverImplicitlyAnimatedList<BookCollection>(
          items: collections,
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
    // TODO: replace with sticky_and_expandable_list
    return StickyHeader(
      key: ValueKey(collection.id),
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
      content: BookCollectionList(
        key: ValueKey(collection.id + 'BookCollectionList'),
        collection: collection,
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
    final LibraryViewData data = ref.watch(libraryViewControllerProvider);
    final LibraryViewController viewController =
        ref.watch(libraryViewControllerProvider.notifier);

    // Get the  list of books in the collection. It will not show books in a series, only the series itself
    final List<Item> items = data.getCollectionItems(collection.id);

    return ImplicitlyAnimatedList<Item>(
      padding: const EdgeInsets.only(bottom: 16, top: 4, left: 8, right: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: booksBuilder,
      removeItemBuilder: (context, animation, oldItem) =>
          removeItemBuilder(context, animation, oldItem, viewController, data),
    );
  }

  Widget removeItemBuilder(
      BuildContext context,
      Animation<double> animation,
      Item oldItem,
      LibraryViewController viewController,
      LibraryViewData data) {
    final isSelected = data.selectedItems.contains(oldItem);

    if (isSelected) {
      viewController.deselectItem(oldItem);
    }

    return FadeTransition(
      opacity: animation,
      key: ValueKey(collection.id + oldItem.id + 'FadeTransition'),
      child: ItemListTileWidget(
        key: ValueKey(collection.id + oldItem.id + 'ItemListWidget'),
        item: oldItem,
      ),
    );
  }

  Widget booksBuilder(
      BuildContext context, Animation<double> animation, Item item, int index) {
    return SizeFadeTransition(
      sizeFraction: 0.7,
      curve: Curves.easeInOut,
      animation: animation,
      child: ItemListTileWidget(
        key: ValueKey(collection.id + item.id + 'ItemListWidget'),
        item: item,
      ),
    );
  }
}
