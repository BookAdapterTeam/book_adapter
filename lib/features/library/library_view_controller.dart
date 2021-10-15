import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
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

  void selectItem(Item item) {
    final selectedItems = <Item>{...state.selectedItems, item};
    state = state.copyWith(selectedItems: selectedItems);
  }

  void deselectItem(Item item) {
    final selectedItems = {...state.selectedItems};
    selectedItems.remove(item);
    state = state.copyWith(selectedItems: selectedItems);
  }

  void deselectAllItems() {
    state = state.copyWith(selectedItems: {});
  }

  Future<void> signOut() async {
    await _read(firebaseControllerProvider).signOut();
  }
}

class LibraryViewData {
  final List<Book>? books;
  final List<BookCollection>? collections;
  final List<Series> series;

  /// The ids of all items currently selected. Duplicates are not allowed
  /// 
  /// When merging and some items are a series, the app will get the books in
  /// each series and combine them into a Set.
  /// 
  /// When merging selected books or series, the app will create a set of all
  /// collections each item is in. The created series will be added all of them.
  final Set<Item> selectedItems;

  bool get isSelecting => selectedItems.isNotEmpty;

  int get numberSelected => selectedItems.length;

  LibraryViewData({
    this.books,
    this.collections,
    this.selectedItems = const <Item>{},
    this.series = const <Series>[]
  });

  LibraryViewData copyWith({
    List<Book>? books,
    List<BookCollection>? collections,
    Set<Item>? selectedItems,
    List<Series>? series,
  }) {
    return LibraryViewData(
      books: books ?? this.books,
      collections: collections ?? this.collections,
      selectedItems: selectedItems ?? this.selectedItems,
      series: series ?? this.series,
    );
  }
}
