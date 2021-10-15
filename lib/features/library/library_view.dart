import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/add_book_button.dart';
import 'package:book_adapter/features/library/widgets/item_list_tile_widget.dart';
import 'package:book_adapter/features/library/widgets/profile_button.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sticky_headers/sticky_headers.dart';

/// Displays a list of BookItems.
class LibraryView extends StatelessWidget {
  const LibraryView({ Key? key }) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LibraryScrollView(),
    );
  }
}



class LibraryScrollView extends HookConsumerWidget {
  const LibraryScrollView({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final LibraryViewController viewController = ref.watch(libraryViewController.notifier);
    final scrollController = useScrollController();

    final notSelectingAppBar = SliverAppBar(
      title: Text('Library'.i18n),
      floating: true,
      snap: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: const [
        AddBookButton(),
        ProfileButton(),
      ],
    );

    final isSelectingAppBar = SliverAppBar(
      title: Text('Selected: ${data.numberSelected}'),
      floating: true,
      snap: true,
      backgroundColor: Colors.black12,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 3.0,
      leading: BackButton(
        onPressed: () => viewController.deselectAllItems(),
      ),
      actions: [
        // TODO: Add to Collections Button
        IconButton(onPressed: () {}, icon: const Icon(Icons.collections_bookmark_rounded),),
        // TODO: Merge into Series Button

        IconButton(onPressed: () {}, icon: const Icon(Icons.merge_type),),
      ],
    );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAnimatedSwitcher(
          child: data.isSelecting
            ? isSelectingAppBar
            : notSelectingAppBar,
          duration: const Duration(microseconds: 15000),
        ),
        
        // List of collections
        SliverImplicitlyAnimatedList<BookCollection>(
          items: data.collections ?? [],
          areItemsTheSame: (a, b) => a.id == b.id,
          itemBuilder: (context, animation, collection, index) 
              => collectionsBuilder(context, animation, collection, index, scrollController),
        ),
      ],
    );
  }

  Widget collectionsBuilder(BuildContext context, Animation<double> animation, BookCollection collection, int index, ScrollController controller) {
    return StickyHeader(
      key: ValueKey(collection.id),
      controller: controller,
      header: Container(
        height: 50.0,
        color: Colors.blueGrey[700],
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Text(collection.name,
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
  const BookCollectionList({ Key? key, required this.collection }) : super(key: key);

  final BookCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final LibraryViewController viewController = ref.watch(libraryViewController.notifier);

    final items = data.books?.where((book) => book.collectionIds.contains(collection.id))
      .toList() ?? [];
    items.sort((a, b) => a.title.compareTo(b.title));

    return ImplicitlyAnimatedList<Item>(
      padding: const EdgeInsets.only(bottom: 16, top: 4, left: 8, right: 8),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: booksBuilder,
      removeItemBuilder: (context, animation, oldItem) => removeItemBuilder(context, animation, oldItem, viewController, data),
    );
  }

  Widget removeItemBuilder(BuildContext context, Animation<double> animation, Item oldItem, LibraryViewController viewController, LibraryViewData data) {
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
        collection: collection,
      ),
    );
  }

  Widget booksBuilder(BuildContext context, Animation<double> animation, Item item, int index) {
    return SizeFadeTransition(
      sizeFraction: 0.7,
      curve: Curves.easeInOut,
      animation: animation,
      child: ItemListTileWidget(
        key: ValueKey(collection.id + item.id + 'ItemListWidget'),
        item: item,
        collection: collection,
      ),
    );
  }
}

