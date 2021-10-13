import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryViewController = StateNotifierProvider<LibraryViewController, LibraryViewData>((ref) {
  final bookStreamProvider = ref.watch(firebaseControllerProvider).bookStreamProvider;
  final collectionsStreamProvider = ref.watch(firebaseControllerProvider).collectionsStreamProvider;

  final books = ref.watch(bookStreamProvider);
  final collections = ref.watch(collectionsStreamProvider);

  final data = LibraryViewData(books: books.asData?.value, collections: collections.asData?.value);
  return LibraryViewController(ref.read, data: data);
});

// State is if the view is loading
class LibraryViewController extends StateNotifier<LibraryViewData> {
  LibraryViewController(this._read, {required LibraryViewData data}) : super(data);

  final Reader _read;

  Future<void> addBooks(BuildContext context) async {
    // Make storage service call to pick books
    final sRes = await _read(storageServiceProvider).pickFile(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      allowMultiple: true,
      withReadStream: true,
    );

    if (sRes.isLeft()) {
      return;
    }

    final platformFiles = sRes.getOrElse(() => []);

    final uploadedBooks = <Book>[];
    for (final file in platformFiles) {
      // Add book to firebase
      final fRes = await _read(firebaseControllerProvider).addBook(file);
      fRes.fold(
        (failure) {
          final snackBar = SnackBar(content: Text(failure.message), duration: const Duration(seconds: 2),);
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        (book) => uploadedBooks.add(book)
      );
    }
  }

  Future<void> deleteBook(String bookId) {
    throw UnimplementedError();
  }

  void selectItem(String id) {
    final selectedItemIds = <String>{...state.selectedItemIds, id};
    state = state.copyWith(selectedItemIds: selectedItemIds);
  }

  void deselectItem(String id) {
    final selectedItemIds = {...state.selectedItemIds};
    selectedItemIds.remove(id);
    state = state.copyWith(selectedItemIds: selectedItemIds);
  }

  void deselectAllItems() {
    state = state.copyWith(selectedItemIds: {});
  }

  Future<void> signOut() async {
    await _read(firebaseControllerProvider).signOut();
  }
}

class LibraryViewData {
  final List<Book>? books;
  final List<BookCollection>? collections;

  /// The ids of all items currently selected. Duplicates are not allowed
  /// 
  /// When merging and some items are a series, the app will get the books in
  /// each series and combine them into a Set.
  /// 
  /// When merging selected books or series, the app will create a set of all
  /// collections each item is in. The created series will be added all of them.
  final Set<String> selectedItemIds;

  bool get isSelecting => selectedItemIds.isNotEmpty;

  int get numberSelected => selectedItemIds.length;

  LibraryViewData({
    this.books,
    this.collections,
    this.selectedItemIds = const <String>{},
  });

  LibraryViewData copyWith({
    List<Book>? books,
    List<BookCollection>? collections,
    Set<String>? selectedItemIds,
  }) {
    return LibraryViewData(
      books: books ?? this.books,
      collections: collections ?? this.collections,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
    );
  }
}
