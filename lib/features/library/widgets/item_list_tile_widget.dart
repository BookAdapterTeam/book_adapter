import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../controller/storage_controller.dart';
import '../../../data/constants.dart';
import '../../reader/current_book.dart';
import '../data/book_item.dart';
import '../data/item.dart';
import '../data/series_item.dart';
import '../library_view_controller.dart';
import '../model/book_status_notifier.dart';

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
    final LibraryViewData data = ref.watch(libraryViewControllerProvider);

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
                duration: kTransitionDuration,
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
          duration: kTransitionDuration,
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
      duration: kTransitionDuration,
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
    final LibraryViewData data = ref.watch(libraryViewControllerProvider);
    final imageUrl = item.imageUrl;
    final firebaseCoverImagePath = item.firebaseCoverImagePath;
    final subtitle = item.subtitle != null ? Text(item.subtitle!) : null;
    final isSelected = data.selectedItems.contains(item);
    final bookStatus =
        item is Book ? ref.watch(bookStatusProvider(item as Book)) : null;

    final bool legacyImage = imageUrl != null && firebaseCoverImagePath == null;
    final asyncV = firebaseCoverImagePath == null
        ? null
        : ref.watch(fileUrlProvider(firebaseCoverImagePath));

    final Widget? image = legacyImage
        ? ClipRRect(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 40,
            ),
            borderRadius: BorderRadius.circular(4),
          )
        : asyncV?.when(
            data: (data) => ClipRRect(
              child: CachedNetworkImage(
                imageUrl: data,
                width: 40,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            error: (error, st) {
              log.e(error.toString(), error, st);
              return const Icon(
                Icons.error_outline,
                size: 40,
              );
            },
            loading: () => const SizedBox(
              width: 40,
            ),
          );

    if (item is Book) {
      final book = item as Book;
      final Widget? trailing;
      final Widget? icon = bookStatus?.map<Widget?>(
        data: (data) {
          final bookStatus = data.value;
          switch (bookStatus) {
            case BookStatus.downloaded:
              return null;
            case BookStatus.downloading:
              return const Icon(Icons.downloading_outlined);
            case BookStatus.downloadWaiting:
              return const Icon(Icons.circle_outlined);
            case BookStatus.notDownloaded:
              return const Icon(Icons.cloud_outlined);
            case BookStatus.errorDownloading:
              // TODO: Find better icon
              return const Icon(Icons.error_outline);
          }
        },
        error: (error) => const Icon(Icons.error_outline),
        loading: (loading) => const CircularProgressIndicator(),
      );
      final VoidCallback? onPressed = bookStatus?.map<VoidCallback?>(
        data: (data) {
          final bookStatus = data.value;
          switch (bookStatus) {
            case BookStatus.downloaded:
              return null;
            case BookStatus.downloading:
              return () {
                // TODO: Cancel download after download starts
              };
            case BookStatus.downloadWaiting:
              return () {
                // TODO: Cancel download before download starts
              };
            case BookStatus.notDownloaded:
              return null;
            case BookStatus.errorDownloading:
              return () {
                // TODO: Make firebase call to try download book again. Delete file if it exists (could be corrupt or partial)
              };
          }
        },
        error: (error) => null,
        loading: (loading) => null,
      );

      final isSelecting = data.isSelecting;

      trailing = icon == null
          ? SizedBox(width: IconTheme.of(context).size)
          : IconButton(
              key: ValueKey('ListTile Button' +
                  book.id +
                  isSelected.toString() +
                  bookStatus.toString() +
                  icon.toString()),
              onPressed: isSelecting ? null : onPressed,
              icon: icon,
            );

      return _CustomListTileWidget(
        item: item,
        subtitle: subtitle,
        leading: image,
        trailing: AnimatedSwitcher(
          switchInCurve: Curves.easeInCubic,
          switchOutCurve: Curves.easeOutCubic,
          duration: kTransitionDuration,
          child: trailing,
        ),
        disableSelect: disableSelect,
        isSelected: isSelected,
        status: bookStatus?.asData?.value,
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
    final LibraryViewData data = ref.watch(libraryViewControllerProvider);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(kCornerRadius),
        ),
      ),
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

        ref.read(libraryViewControllerProvider.notifier).selectItem(item);
      },
      onTap: () async {
        if (isSelected) {
          return ref
              .read(libraryViewControllerProvider.notifier)
              .deselectItem(item);
        }

        if (data.isSelecting && !disableSelect) {
          return ref
              .read(libraryViewControllerProvider.notifier)
              .selectItem(item);
        }

        if (item is Series) {
          Navigator.restorablePushNamed(
            context,
            item.routeTo,
            arguments: item.toMapSerializable(),
          );
          return;
        }

        if (item is Book &&
            ref
                .read(storageControllerProvider)
                .fileExists((item as Book).filename)) {
          final controller = ref.read(currentBookProvider.state);
          controller.state = item as Book;
          Navigator.restorablePushNamed(
            context,
            item.routeTo,
          );
          return;
        }

        if (item is Book && status == BookStatus.notDownloaded) {
          try {
            final failure = await ref
                .read(libraryViewControllerProvider.notifier)
                .queueDownloadBook(item as Book);
            if (failure == null) return;

            log.e(failure.message);
            final SnackBar snackBar = SnackBar(
              content: Text(failure.message),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
