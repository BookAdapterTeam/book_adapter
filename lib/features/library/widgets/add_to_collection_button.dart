import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/library_view_controller.dart';
import 'package:book_adapter/features/library/widgets/add_new_collection_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class AddToCollectionButton extends ConsumerWidget {
  const AddToCollectionButton({
    Key? key,
    required this.onMove,
  }) : super(key: key);

  final Function(List<String>) onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = Logger();
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
            return ChooseCollectionsBottomSheet(
              onAddNewCollection: (collectionName) async {
                final viewController =
                    ref.read(libraryViewControllerProvider.notifier);
                final res =
                    await viewController.addNewCollection(collectionName);
                res.fold(
                  (failure) {
                    final snackBar = SnackBar(
                      content: Text(failure.message),
                      duration: const Duration(seconds: 2),
                    );
                    log.e(failure.message);
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  (collection) {
                    final snackBar = SnackBar(
                      content: Text('Successfully created ${collection.name}'),
                      duration: const Duration(seconds: 2),
                    );
                    log.i('Successfully created ${collection.name}');
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                );
              },
            );
          },
        );
        if (collectionIds == null || collectionIds.isEmpty) return;
        onMove.call(collectionIds);
      },
      icon: const Icon(Icons.collections_bookmark_rounded),
    );
  }
}

final chosenCollectionsProvider = StateProvider<List<String>>((ref) {
  return [];
});

class ChooseCollectionsBottomSheet extends ConsumerStatefulWidget {
  const ChooseCollectionsBottomSheet(
      {Key? key, required this.onAddNewCollection})
      : super(key: key);

  final void Function(String) onAddNewCollection;

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
            children: [
              const Flexible(
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
              AddNewCollectionButton(
                  onAddNewCollection: widget.onAddNewCollection),
            ],
          ),
          const Divider(
            height: 2,
          ),
          // Current collections
          for (final collection in collectionList ?? <AppCollection>[]) ...[
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
