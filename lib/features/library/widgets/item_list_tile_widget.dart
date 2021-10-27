import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

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

    final isBook = item is Book;

    final tile = isBook
        ? _ItemListTile(
            key: ValueKey('ItemListTile' + item.id + isSelected.toString()),
            item: item,
            disableSelect: disableSelect,
            isBook: true,
          )
        : Stack(
            children: [
              AnimatedSwitcher(
                switchInCurve: Curves.easeInCubic,
                switchOutCurve: Curves.easeOutCubic,
                duration: const Duration(milliseconds: 250),
                child: _ItemListTile(
                  key: ValueKey(
                      'ItemListTile' + item.id + isSelected.toString()),
                  item: item,
                  disableSelect: disableSelect,
                  isBook: false,
                ),
              ),
              const Positioned(
                  left: 0, bottom: 0, child: Icon(Icons.collections_bookmark)),
            ],
          );

    final child = Padding(
      key: ValueKey('ItemListTileWidget Padding' +
          item.id +
          isSelected.toString() +
          isBook.toString() +
          disableSelect.toString()),
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

    return AnimatedSwitcher(
      switchInCurve: Curves.easeInCubic,
      switchOutCurve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 250),
      child: child,
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
    final log = Logger();
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
      final BookStatus bookStatus = data.getBookStatus(book);
      final Widget? trailing;
      final Widget? icon;
      final VoidCallback? onPressed;
      final isSelecting = data.isSelecting;

      switch (bookStatus) {
        case BookStatus.downloaded:
          icon = const Icon(Icons.download_done_outlined);
          onPressed = null;
          break;
        case BookStatus.downloading:
          icon = const Icon(Icons.downloading_outlined);
          onPressed = () {
            // TODO: Cancel download after download starts
          };
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
          onPressed = () async {
            try {
              final res = await viewController.queueDownloadBook(book);
              res.fold(
                (failure) {
                  log.e(failure.message);
                  final SnackBar snackBar = SnackBar(
                    content: Text(failure.message),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                (r) => null,
              );
            } on Exception catch (e) {
              log.e(e.toString());
              final SnackBar snackBar = SnackBar(
                content: Text(e.toString()),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          };
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
        case BookStatus.waiting:
          icon = const Icon(
            Icons.stop_circle,
          );
          onPressed = () {
            // TODO: Cancel download before download starts
          };
          break;
        case BookStatus.unknown:
          icon = null;
          onPressed = null;
          break;
      }
      trailing = icon != null
          ? IconButton(
              key: ValueKey('ListTile Button' +
                  book.id +
                  isSelected.toString() +
                  bookStatus.toString() +
                  icon.toString()),
              onPressed: isSelecting ? null : onPressed,
              icon: icon,
            )
          : null;

      return _CustomListTileWidget(
        item: item,
        subtitle: subtitle,
        leading: image,
        trailing: AnimatedSwitcher(
          switchInCurve: Curves.easeInCubic,
          switchOutCurve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 250),
          child: trailing,
        ),
        disableSelect: disableSelect,
        isSelected: isSelected,
        status: bookStatus,
      );
    }

    // Return when tile is not a book (its a series)
    return _CustomListTileWidget(
      item: item,
      subtitle: subtitle,
      leading: image,
      disableSelect: disableSelect,
      isSelected: isSelected,
    );
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
    this.status,
  }) : super(key: key);

  final Item item;
  final Text? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool disableSelect;
  final bool isSelected;
  final BookStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = Logger();
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
      onTap: () async {
        if (isSelected) {
          return viewController.deselectItem(item);
        }

        if (data.isSelecting && !disableSelect) {
          return viewController.selectItem(item);
        }

        if (status == BookStatus.downloaded || item is Series) {
          Navigator.restorablePushNamed(
            context,
            item.routeTo,
            arguments: item.toMapSerializable(),
          );
          return;
        }
        
        if (status == BookStatus.notDownloaded && item is Book) {
          try {
            final res = await viewController.queueDownloadBook(item as Book);
            res.fold(
              (failure) {
                log.e(failure.message);
                final SnackBar snackBar = SnackBar(
                  content: Text(failure.message),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              (_) => null,
            );
            return;
          } on Exception catch (e) {
            log.e(e.toString());
            final SnackBar snackBar = SnackBar(
              content: Text(e.toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            return;
          }
        }
        
      },
    );
  }
}
