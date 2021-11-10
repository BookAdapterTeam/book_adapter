import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/add_new_collection_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddToCollectionButton extends ConsumerWidget {
  const AddToCollectionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewController = ref.watch(libraryViewControllerProvider.notifier);
    return Builder(builder: (context) {
      return IconButton(
        onPressed: () async {
          // Show popup for user to choose which collection to move the items to
          final List<String>? collectionIds =
              await showModalBottomSheet<List<String>?>(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              // Using Wrap makes the bottom sheet height the height of the content.
              // Otherwise, the height will be half the height of the screen.
              return const ChooseCollectionsBottomSheet();
            },
          );
          if (collectionIds == null || collectionIds.isEmpty) return;
          await viewController.moveItemsToCollections(collectionIds);
        },
        icon: const Icon(Icons.collections_bookmark_rounded),
      );
    });
  }
}

final chosenCollectionsProvider = StateProvider<List<String>>((ref) {
  return [];
});

class ChooseCollectionsBottomSheet extends ConsumerStatefulWidget {
  const ChooseCollectionsBottomSheet({Key? key}) : super(key: key);

  @override
  _ChooseCollectionsBottomSheetState createState() =>
      _ChooseCollectionsBottomSheetState();
}

class _ChooseCollectionsBottomSheetState
    extends ConsumerState<ChooseCollectionsBottomSheet> {
  final List<String> chosenCollections = [];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(libraryViewControllerProvider);
    final collectionList = data.collections;

    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Move to Collection...',
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              AddNewCollectionButton(),
            ],
          ),
          const Divider(
            height: 2,
          ),
          /*TextButton(
            onPressed: () async {
              await showDialog<String>(
                context: context,
                builder: (context) {
                  return const AddNewCollectionDialog();
                }
              );
            },
            child: const Text('+ NEW COLLECTION'),
          ),*/
          // Current collections
          for (final collection in collectionList ?? <BookCollection>[]) ...[
            CheckboxListTile(
              title: Text(collection.name),
              onChanged: (bool? checked) {
                if (checked == null) return;

                if (checked) {
                  chosenCollections.add(collection.id);
                } else {
                  chosenCollections.remove(collection.id);
                }
                setState(() {});
              },
              value: chosenCollections.contains(collection.id),
              activeColor: Theme.of(context).buttonTheme.colorScheme?.primary,
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCEL'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(chosenCollections);
                    },
                    child: const Text('MOVE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
