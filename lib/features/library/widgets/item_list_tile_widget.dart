import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ItemListTileWidget extends ConsumerWidget {
  const ItemListTileWidget({
    Key? key,
    required this.item,
    required this.collection,
  }) : super(key: key);

  final Item item;
  final BookCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);

    final isSelected = data.selectedItemIds.contains(item.id);


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 15000),
          color: isSelected ? Colors.white30 : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ItemListTile(collection: collection, item: item),
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
      ),
    );
  }
}

class _ItemListTile extends ConsumerWidget {
  const _ItemListTile({
    Key? key,
    required this.collection,
    required this.item,
  }) : super(key: key);

  final BookCollection collection;
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final LibraryViewController viewController = ref.watch(libraryViewController.notifier);
    final imageUrl = item.imageUrl;
    final subtitle = item.subtitle != null ? Text(item.subtitle!) : null;
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      key: ValueKey(collection.id + item.id),
      title: Text(item.title),
      subtitle: subtitle,
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
    );
  }
}