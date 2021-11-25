// ignore_for_file: prefer_const_constructors

import 'package:book_adapter/data/constants.dart';
import 'package:book_adapter/features/in_app_update/util/toast_utils.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/collection_section.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/add_book_button.dart';
import 'package:book_adapter/features/library/widgets/add_to_collection_button.dart';
import 'package:book_adapter/features/library/widgets/merge_to_series.dart';
import 'package:book_adapter/features/library/widgets/overflow_library_appbar_popup_menu_button.dart';
import 'package:book_adapter/features/library/widgets/profile_button.dart';
import 'package:book_adapter/features/library/widgets/section_widget.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:sticky_and_expandable_list/sticky_and_expandable_list.dart';

/// Displays a list of BookItems.
class LibraryView extends ConsumerWidget {
  const LibraryView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: LibraryScrollView(),
    );
  }
}

class MergeIntoSeriesButton extends ConsumerWidget {
  const MergeIntoSeriesButton({
    Key? key,
    required this.onMerge,
    required this.isDisabled,
  }) : super(key: key);

  final Function(String) onMerge;

  final bool isDisabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Merge to series',
      onPressed: isDisabled
          ? null
          : () async {
              final seriesName = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    // Could sort the list before using choosig the title.
                    // Without soring, it will use the title of the first book selected.
                    // final selectedItemsList = selectedItems.toList()
                    //   ..sort((a, b) => a.title.compareTo(b.title));
                    // final initialText = selectedItemsList.first.title;
                    final initialText = ref
                        .read(libraryViewControllerProvider)
                        .selectedItems
                        .first
                        .title;
                    return AddNewSeriesDialog(
                      initialText: initialText,
                    );
                  });
              if (seriesName == null) return;
              onMerge.call(seriesName);
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
        AddBookButton(
          onAdd: () =>
              ref.read(libraryViewControllerProvider.notifier).addBooks(),
        ),
        const ProfileButton(),
      ],
    );

    final isSelectingAppBar = SliverAppBar(
      key: const ValueKey('selecting_app_bar'),
      title: Text('Selected: ${data.numberSelected}'),
      pinned: true,
      backgroundColor: kSelectingAppBarColor,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 3.0,
      leading: BackButton(
        onPressed: () => viewController.deselectAllItems(),
      ),
      actions: [
        AddToCollectionButton(
          onMove: (List<String> collectionIds) async {
            await ref
                .read(libraryViewControllerProvider.notifier)
                .moveItemsToCollections(collectionIds);
          },
        ),

        // Disable button until more than one book selected so that the user does not create series with only one book in it
        MergeIntoSeriesButton(
          isDisabled: data.selectedItems.length <= 1,
          onMerge: (seriesName) async {
            final res = await ref
                .read(libraryViewControllerProvider.notifier)
                .mergeIntoSeries(ref.read, seriesName);

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
        ),
        // Example usage of Unmerge button
        // TextButton(
        //   onPressed: !data.hasSeries
        //       ? null
        //       : () async {
        //           await ref
        //               .read(libraryViewControllerProvider.notifier)
        //               .unmergeSeries();
        //         },
        //   child: const Text('Unmerge'),
        // ),
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
    );

    final appBar = data.isSelecting ? isSelectingAppBar : notSelectingAppBar;

    final collections = (data.collections ?? [])
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final List<AppCollection> filteredCollections = [];
    for (final col in collections) {
      if (data.getCollectionItems(col.id).isNotEmpty) {
        filteredCollections.add(col);
      }
    }

    final sectionList = filteredCollections.map((collection) {
      return CollectionSection(
        expanded: true,
        items: data.getCollectionItems(collection.id),
        header: collection.name,
      );
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAnimatedSwitcher(
            child: appBar,
            duration: const Duration(milliseconds: 250),
          ),

          // List of collections
          SliverCollectionsList(sectionList: sectionList),
        ],
      ),
    );
  }
}

/// Collection List View
/// 
/// Collection headers can be expanded and the top header is pinned to the screen
/// 
/// The implementation is based on the below examples.
/// 
/// https://github.com/tp7309/flutter_sticky_and_expandable_list/blob/master/example/lib/example_custom_section_animation.dart
/// 
/// https://github.com/tp7309/flutter_sticky_and_expandable_list/blob/master/example/lib/example_custom_section.dart
class SliverCollectionsList extends StatefulWidget {
  const SliverCollectionsList({
    Key? key,
    required this.sectionList,
  }) : super(key: key);

  final List<CollectionSection> sectionList;

  @override
  State<SliverCollectionsList> createState() => _SliverCollectionsListState();
}

class _SliverCollectionsListState extends State<SliverCollectionsList> {
  @override
  Widget build(BuildContext context) {
    return SliverExpandableList(
      builder: SliverExpandableChildDelegate<Item, CollectionSection>(
        sectionList: widget.sectionList,
        sectionBuilder: _buildSection,
        itemBuilder: (context, sectionIndex, itemIndex, index) {
          final Item item = widget.sectionList[sectionIndex].items[itemIndex];
          return ListTile(
            leading: CircleAvatar(
              child: Text('$index'),
            ),
            title: Text(item.title),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, ExpandableSectionContainerInfo containerInfo) {
    return SectionWidget(
      section: widget.sectionList[containerInfo.sectionIndex],
      containerInfo: containerInfo,
      onStateChanged: () {
        //notify ExpandableListView that expand state has changed.
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      },
    );
  }
}

class BookCollectionHeader extends ConsumerWidget {
  const BookCollectionHeader({
    Key? key,
    required this.collection,
  }) : super(key: key);

  final AppCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onLongPress: () async {
        final bool? shouldDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Remove collection'),
              content: Text(
                collection.name != 'Default'
                    ? 'Are you sure you remove the this collection? Items in this collection will not be deleted. After the collection is removed, any items without a collection will be moved to the default collection.'
                    : 'The default collection cannot be removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: collection.name != 'Default'
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: Text(
                    'REMOVE',
                    style: DefaultTextStyle.of(context).style.copyWith(
                          fontWeight: FontWeight.w500,
                          color: collection.name != 'Default'
                              ? Colors.redAccent
                              : Theme.of(context).disabledColor,
                        ),
                  ),
                ),
              ],
            );
          },
        );
        if (shouldDelete == null || !shouldDelete) return;

        final failure = await ref
            .read(libraryViewControllerProvider.notifier)
            .removeBookCollection(collection);

        if (failure == null) return;

        ToastUtils.error(failure.message);
      },
      child: Container(
        height: 50.0,
        color: Colors.blueGrey[700],
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Text(
          collection.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}