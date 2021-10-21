import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ItemListTileWidget extends ConsumerWidget {
  const ItemListTileWidget({
    Key? key,
    required this.item,
    this.disableSelect = false,
  }) : super(key: key);

  final Item item;
  final bool disableSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);

    final isSelected = data.selectedItems.contains(item);

    final tile = item is Book
        ? _ItemListTile(
            item: item,
            disableSelect: disableSelect,
            isBook: true,
          )
        : Stack(
            children: [
              _ItemListTile(
                item: item,
                disableSelect: disableSelect,
                isBook: false,
              ),
              const Positioned(
                  left: 0, bottom: 0, child: Icon(Icons.collections_bookmark)),
            ],
          );

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
              tile,
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
    required this.item,
    required this.disableSelect,
    required this.isBook,
  }) : super(key: key);

  final Item item;
  final bool disableSelect;
  final bool isBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final LibraryViewController viewController =
        ref.watch(libraryViewController.notifier);
    final imageUrl = item.imageUrl;
    final subtitle = item.subtitle != null ? Text(item.subtitle!) : null;
    final isSelected = data.selectedItems.contains(item);

    final Widget? image = imageUrl != null
        ? ClipRRect(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 40,
            ),
            borderRadius: BorderRadius.circular(4),
          )
        : null;

    if (item is Book) {
      final book = item as Book;
      final statusFtr = viewController.getBookStatus(book);
      return FutureBuilder<BookStatus>(
        future: statusFtr,
        initialData: BookStatus.unknown,
        builder: (BuildContext context, AsyncSnapshot<BookStatus> snapshot) {
          final Widget? trailing;
          final BookStatus bookStatus;

          if (snapshot.hasError) {
            // Could not determine
            bookStatus = BookStatus.unknown;
          } else if (snapshot.connectionState == ConnectionState.done) {
            bookStatus = snapshot.data ?? BookStatus.unknown;
            final Widget? icon;
            final VoidCallback? onPressed;

            switch (bookStatus) {
              case BookStatus.downloaded:
                icon = const Icon(Icons.download_done_outlined);
                onPressed = null;
                break;
              case BookStatus.downloading:
                icon = const Icon(Icons.downloading_outlined);
                onPressed = null;
                break;
              case BookStatus.uploading:
                // Upside down downloading icon because I can't find own for uploading
                icon = Transform.rotate(
                  angle: 180,
                  child: const Icon(Icons.downloading_outlined),
                );
                onPressed = null;
                break;
              case BookStatus.notDownloaded:
                icon = const Icon(Icons.download);
                onPressed = () => viewController.downloadBook(book);
                break;
              case BookStatus.errorUploading:
                icon = const Icon(
                  Icons.replay,
                  color: Colors.red,
                );
                onPressed = () {
                  // TODO: Make firebase call to try upload book again
                };
                break;
              case BookStatus.errorDownloading:
                icon = const Icon(
                  Icons.replay,
                  color: Colors.red,
                );
                onPressed = () {
                  // TODO: Make firebase call to try download book again. Delete file if it exists (could be corrupt or partial)
                };
                break;
              case BookStatus.unknown:
                icon = null;
                onPressed = null;
                break;
            }
            trailing = icon != null
                ? IconButton(
                    onPressed: onPressed,
                    icon: icon,
                  )
                : null;

            // Return done getting book status
            return _CustomListTileWidget(
                item: item,
                subtitle: subtitle,
                leading: image,
                trailing: trailing,
                disableSelect: disableSelect,
                isSelected: isSelected);
          }

          // Return when book status is still loading
          return _CustomListTileWidget(
              item: item,
              subtitle: subtitle,
              leading: image,
              trailing: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.circle),
              ),
              disableSelect: disableSelect,
              isSelected: isSelected);
        },
      );
    }

    // Return when tile is not a book (its a series)
    return _CustomListTileWidget(
        item: item,
        subtitle: subtitle,
        leading: image,
        disableSelect: disableSelect,
        isSelected: isSelected);
  }
}

class _CustomListTileWidget extends ConsumerWidget {
  const _CustomListTileWidget({
    Key? key,
    required this.item,
    required this.subtitle,
    required this.leading,
    this.trailing,
    required this.disableSelect,
    required this.isSelected,
  }) : super(key: key);

  final Item item;
  final Text? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool disableSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryViewData data = ref.watch(libraryViewController);
    final LibraryViewController viewController =
        ref.watch(libraryViewController.notifier);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        item.title,
        maxLines: subtitle == null ? 3 : 2,
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(overflow: TextOverflow.ellipsis),
      ),
      subtitle: subtitle,
      minLeadingWidth: 0,
      leading: leading,
      trailing: trailing,
      onLongPress: () {
        if (disableSelect) return;

        viewController.selectItem(item);
      },
      onTap: () {
        if (isSelected) {
          return viewController.deselectItem(item);
        }

        if (data.isSelecting && !disableSelect) {
          return viewController.selectItem(item);
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
