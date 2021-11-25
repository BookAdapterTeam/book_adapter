import 'dart:ui';

import 'package:book_adapter/controller/storage_controller.dart';
import 'package:book_adapter/data/constants.dart';
import 'package:book_adapter/features/in_app_update/util/toast_utils.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/item_list_tile_widget.dart';
import 'package:book_adapter/features/library/widgets/overflow_library_appbar_popup_menu_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:logger/logger.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SeriesView extends HookConsumerWidget {
  const SeriesView({Key? key}) : super(key: key);

  static const routeName = '/series';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic> bookMap =
        ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    final series = Series.fromMapFirebase(bookMap);
    final data = ref.watch(libraryViewControllerProvider);
    final storageController = ref.watch(storageControllerProvider);

    final books = data.books?.where((book) {
      return series.id == book.seriesId;
    }).toList();
    books?.sort((a, b) => a.title.compareTo(b.title));

    final imageUrl = series.imageUrl;

    final scrollController = useScrollController();

    // ignore: prefer_const_constructors
    return Scaffold(
      // appBar: AppBar(title: const Text('Series'),),
      // ignore: prefer_const_constructors
      body: ValueListenableBuilder(
          valueListenable: storageController.downloadedBooksValueListenable,
          builder: (context, Box<bool> isDownloadedBox, _) {
            return CustomScrollView(
              controller: scrollController,
              slivers: [
                _SliverBackgroundAppBar(
                    imageUrl: imageUrl, series: series, books: books!),
                SliverImplicitlyAnimatedList<Book>(
                  items: books,
                  itemBuilder: (
                    context,
                    animation,
                    item,
                    index,
                  ) {
                    return itemBuilder(
                      context,
                      animation,
                      item,
                      index,
                      books,
                      isDownloadedBox,
                    );
                  },
                  areItemsTheSame: (oldItem, newItem) {
                    return oldItem.id == newItem.id;
                  },
                ),
              ],
            );
          }),
    );
  }

  Widget itemBuilder(BuildContext context, Animation<double> animation,
      Book item, int index, List<Book>? books, Box<bool> isDownloadedBox) {
    return ItemListTileWidget(
      item: item,
      disableSelect: false,
      isDownloaded: isDownloadedBox.get(item.filename) ?? false,
    );
  }
}

class _SliverBackgroundAppBar extends ConsumerWidget {
  const _SliverBackgroundAppBar({
    Key? key,
    required this.imageUrl,
    required this.series,
    required this.books,
  }) : super(key: key);

  final String? imageUrl;
  final Series series;
  final List<Book> books;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewController = ref.watch(libraryViewControllerProvider.notifier);
    final bool isSelecting = ref.watch(libraryViewControllerProvider
        .select((controller) => controller.isSelecting));
    final int numberSelected = ref.watch(libraryViewControllerProvider
        .select((controller) => controller.numberSelected));
    final log = Logger();

    return SliverStack(
      children: [
        SliverAppBar(
          expandedHeight: 250,
          stretch: true,
          flexibleSpace: imageUrl != null ? _buildFlexibleSpace() : null,
          actions: [
            PopupMenuButton(
              offset: const Offset(0, kToolbarHeight),
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) {
                return <PopupMenuEntry>[
                  PopupMenuItem(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.merge_type),
                        SizedBox(
                          width: 8,
                        ),
                        Text('unmerge'),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ref
                          .read(libraryViewControllerProvider.notifier)
                          .unmergeSeries(series);
                    },
                  ),
                ];
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(9.0),
                ),
              ),
            ),
          ],
        ),
        if (isSelecting)
          SliverAppBar(
            key: const ValueKey('selecting_series_app_bar'),
            pinned: true,
            title: Text('Selected: $numberSelected'),
            // backgroundColor: Theme.of(context).buttonTheme.colorScheme?.primary,
            backgroundColor: kSelectingAppBarColor,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            elevation: 3.0,
            leading: BackButton(
              onPressed: () => viewController.deselectAllItems(),
            ),
            actions: [
              OverflowLibraryAppBarPopupMenuButton(
                onRemoveDownloads: () async {
                  final failure = await ref
                      .read(libraryViewControllerProvider.notifier)
                      .deleteBookDownloads();
                  if (failure == null) return;

                  ToastUtils.error(failure.message);
                },
                onDeletePermanently: () async {
                  final failure = await ref
                      .read(libraryViewControllerProvider.notifier)
                      .deleteBooksPermanently();
                  if (failure == null) return;

                  ToastUtils.error(failure.message);
                },
                onDownload: () async {
                  final failure = await ref
                      .read(libraryViewControllerProvider.notifier)
                      .queueDownloadBooks();
                  if (failure == null) return;

                  log.e(failure.message);
                  final SnackBar snackBar = SnackBar(
                    content: Text(failure.message),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
              ),
            ],
          ),
      ],
    );
  }

  FlexibleSpaceBar _buildFlexibleSpace() {
    return FlexibleSpaceBar(
      title: Text(series.title),
      stretchModes: const <StretchMode>[
        StretchMode.zoomBackground,
        StretchMode.blurBackground,
        StretchMode.fadeTitle,
      ],
      background: _buildBackground(),
    );
  }

  Stack _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: CachedNetworkImage(
              fit: BoxFit.fitWidth,
              imageUrl: imageUrl!,
              width: 40,
            ), // Widget that is blurred
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.0, 0.5),
              end: Alignment.center,
              colors: <Color>[
                Color(0x60000000),
                Color(0x00000000),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
