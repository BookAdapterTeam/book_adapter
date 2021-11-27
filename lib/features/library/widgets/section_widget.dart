import 'package:book_adapter/controller/storage_controller.dart';
import 'package:book_adapter/data/constants.dart';
// ignore: unused_import
import 'package:book_adapter/features/in_app_update/util/toast_utils.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/collection_section.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sticky_and_expandable_list/sticky_and_expandable_list.dart';

import 'item_list_tile_widget.dart';

class SectionWidget extends StatefulWidget {
  final CollectionSection section;
  final ExpandableSectionContainerInfo containerInfo;
  final VoidCallback onStateChanged;
  final bool hideHeader;

  const SectionWidget({
    Key? key,
    required this.section,
    required this.containerInfo,
    required this.onStateChanged,
    required this.hideHeader,
  }) : super(key: key);

  @override
  _SectionWidgetState createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<SectionWidget>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.5);
  late AnimationController _controller;

  late Animation _iconTurns;

  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _iconTurns =
        _controller.drive(_halfTween.chain(CurveTween(curve: Curves.easeIn)));
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));

    if (widget.section.isSectionExpanded()) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.containerInfo
      ..header = _buildHeader(context)
      ..content = _buildContent(context);
    return ExpandableSectionContainer(
      info: widget.containerInfo,
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (widget.hideHeader) return Container();
    return Consumer(builder: (_, ref, __) {
      return Container(
        color: Colors.blueGrey[700],
        child: ListTile(
          title: Text(
            widget.section.header,
          ),
          leading: RotationTransition(
            turns: _iconTurns as Animation<double>,
            child: const Icon(
              Icons.expand_more,
              color: Colors.white70,
            ),
          ),
          minLeadingWidth: 0,
          // Add pop up menu with option for removing the collection
          trailing: widget.section.header == 'Default'
              ? null
              : PopupMenuButton(
                  offset: const Offset(0, kToolbarHeight),
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) {
                    return <PopupMenuEntry>[
                      PopupMenuItem(
                        onTap: () async {
                          final bool? shouldDelete =
                              await Future<bool?>.delayed(
                            const Duration(),
                            () => showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Remove Collection'),
                                  content: const Text(
                                      'Are you sure you want to remove this collection? Items inside the collection will not be deleted.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(
                                        'REMOVE',
                                        style: DefaultTextStyle.of(context)
                                            .style
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.redAccent,
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                          if (shouldDelete == null || !shouldDelete) return;
                          final collection = widget.section.collection;
                          final failure = await ref
                              .read(libraryViewControllerProvider.notifier)
                              .removeBookCollection(collection);

                          if (failure == null) return;

                          ToastUtils.error(failure.message);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete),
                            SizedBox(
                              width: 8,
                            ),
                            Text('Remove Collection'),
                          ],
                        ),
                      ),
                    ];
                  },
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(kCornerRadius),
                    ),
                  ),
                ),
          onTap: _onTap,
        ),
      );
    });
  }

  void _onTap() {
    widget.section.setSectionExpanded(!widget.section.isSectionExpanded());
    if (widget.section.isSectionExpanded()) {
      widget.onStateChanged();
      _controller.forward();
    } else {
      _controller.reverse().then((_) {
        widget.onStateChanged();
      });
    }
  }

  Widget _buildContent(BuildContext context) {
    final childDelegate = widget.containerInfo.childDelegate;
    if (childDelegate != null) {
      final items = widget.section.getItems();
      return SizeTransition(
        sizeFactor: _heightFactor,
        child: ImplicitlyAnimatedList<Item>(
          padding: const EdgeInsets.only(bottom: 16, top: 4, left: 8, right: 8),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          items: items,
          areItemsTheSame: (a, b) => a.id == b.id,
          itemBuilder: _booksBuilder,
          removeItemBuilder: (context, animation, oldItem) =>
              removeItemBuilder(context, animation, oldItem),
        ),
      );
    }
    return Container();
  }

  Widget _booksBuilder(
    BuildContext context,
    Animation<double> animation,
    Item item,
    int index,
  ) {
    return Consumer(
      builder: (_, ref, __) {
        return ValueListenableBuilder(
          valueListenable: ref
              .read(storageControllerProvider)
              .downloadedBooksValueListenable,
          builder: (_, Box<bool> isDownloadedBox, __) {
            return SizeFadeTransition(
              key: ValueKey(
                  widget.section.header + item.id + 'SizeFadeTransition'),
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: animation,
              child: ItemListTileWidget(
                key: ValueKey(
                    widget.section.header + item.id + 'ItemListWidget'),
                item: item,
                isDownloaded: item is Book
                    ? isDownloadedBox.get(item.filename) ?? false
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget removeItemBuilder(
    BuildContext context,
    Animation<double> animation,
    Item oldItem,
  ) =>
      Consumer(
        builder: (_, ref, __) {
          final data = ref.read(libraryViewControllerProvider);
          final isSelected = data.selectedItems.contains(oldItem);
          if (isSelected) {
            ref
                .read(libraryViewControllerProvider.notifier)
                .deselectItem(oldItem);
          }

          return ValueListenableBuilder(
            valueListenable: ref
                .read(storageControllerProvider)
                .downloadedBooksValueListenable,
            builder: (_, Box<bool> isDownloadedBox, __) {
              return FadeTransition(
                opacity: animation,
                key: ValueKey(
                    widget.section.header + oldItem.id + 'FadeTransition'),
                child: ItemListTileWidget(
                  key: ValueKey(
                      widget.section.header + oldItem.id + 'ItemListWidget'),
                  item: oldItem,
                  isDownloaded: oldItem is Book
                      ? isDownloadedBox.get(oldItem.filename) ?? false
                      : null,
                ),
              );
            },
          );
        },
      );
}
