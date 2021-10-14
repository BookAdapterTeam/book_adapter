import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/add_book_button.dart';
import 'package:book_adapter/features/library/widgets/profile_button.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sticky_headers/sticky_headers.dart';

/// Displays a list of BookItems.
class LibraryView extends ConsumerWidget {
  const LibraryView({ Key? key }) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shadowColor: Colors.white70,
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
        ),// List of collections
        SliverImplicitlyAnimatedList<BookCollection>(
          items: data.collections ?? [],
          areItemsTheSame: (a, b) => a.id == b.id,
          itemBuilder: (context, animation, collection, index) => collectionsBuilder(context, animation, collection, index, scrollController),
        ),
      ],
    );
  }

  Widget collectionsBuilder(BuildContext context, Animation<double> animation, BookCollection collection, int index, ScrollController controller) {
    return StickyHeader(
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
      content: BookCollectionList(collection: collection),
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
      key: ValueKey(collection.id),
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: booksBuilder,
      removeItemBuilder: (context, animation, oldItem) => removeItemBuilder(context, animation, oldItem, viewController, data),
    );
  }

  Widget removeItemBuilder(BuildContext context, Animation<double> animation, Item oldItem, LibraryViewController viewController, LibraryViewData data) {
    final imageUrl = oldItem.imageUrl;
    final subtitle = oldItem.subtitle;
    final isSelected = data.selectedItemIds.contains(oldItem.id);

    if (isSelected) {
      viewController.deselectItem(oldItem.id);
    }
    
    return FadeTransition(
      opacity: animation,
      child: ListTile(
        key: ValueKey(collection.id + oldItem.id),
        title: Text(oldItem.title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        leading: imageUrl != null 
          ? ClipRRect(child: CachedNetworkImage(imageUrl: imageUrl, width: 40,), borderRadius: BorderRadius.circular(4),)
          : null,
      )
    );
  }

  Widget booksBuilder(BuildContext context, Animation<double> animation, Item item, int index) {
    return SizeFadeTransition(
      sizeFraction: 0.7,
      curve: Curves.easeInOut,
      animation: animation,
      child: ItemListWidget(
        item: item,
      ),
    );
  }
}

class ItemListWidget extends ConsumerWidget {
  const ItemListWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final LibraryViewController viewController = ref.watch(libraryViewController.notifier);

    final imageUrl = item.imageUrl;
    final subtitle = item.subtitle;
    final isSelected = data.selectedItemIds.contains(item.id);

    final Widget? image = imageUrl != null 
      ? ClipRRect(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 40,
          ),
          borderRadius: BorderRadius.circular(4),
        )
      : null;


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Card(
        margin: EdgeInsets.zero,
        color: isSelected ? Colors.white30 : null,
        elevation: 0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              key: ValueKey(item.id),
              title: Text(item.title),
              subtitle: subtitle != null ? Text(subtitle) : null,
              leading: image,
              onLongPress: () => viewController.selectItem(item.id),
              onTap: () {
                if (isSelected) {
                  return viewController.deselectItem(item.id);
                }
            
            
                if (data.isSelecting) {
                  return viewController.selectItem(item.id);
                }
            
                // Navigate to the reader page or series page depending on item type.
                Navigator.restorablePushNamed(
                  context,
                  item.routeTo,
                  arguments: item.toMapSerializable(),
                );
              },
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).canvasColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}