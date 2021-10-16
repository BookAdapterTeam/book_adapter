import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryViewController = StateNotifierProvider<LibraryViewController, LibraryViewData>((ref) {
  final firebaseController = ref.watch(firebaseControllerProvider);
  final bookStreamProvider = firebaseController.bookStreamProvider;
  final collectionsStreamProvider = firebaseController.collectionsStreamProvider;
  final seriesStreamProvider = firebaseController.seriesStreamProvider;

  final books = ref.watch(bookStreamProvider);
  final collections = ref.watch(collectionsStreamProvider);
  final series = ref.watch(seriesStreamProvider);

  final data = LibraryViewData(books: books.asData?.value, collections: collections.asData?.value, series: series.asData?.value);
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

  Future<bool> mergeIntoSeries([String? name]) async {
    final firebaseController = _read(firebaseControllerProvider);

    // Get the list of all books selected, including books in a series
    final items = state.selectedItems;

    final List<Book> mergeBooks = _convertItemsToBooks(items);

    // Put series in collections the book was in
    // TODO: Get input from user to decide collection
    mergeBooks.sort((a, b) => a.title.compareTo(b.title));
    final Set<String> collectionIds = {};
    for (final book in mergeBooks) {
      collectionIds.addAll(book.collectionIds);
    }


    try {
      // Create a new series with the title with the first item in the list
      const defaultImage = 'https://st4.depositphotos.com/14953852/24787/v/600/depositphotos_247872612-stock-illustration-no-image-available-icon-vector.jpg';
      final series = await firebaseController.addSeries(name: name ?? items.first.title, imageUrl: items.first.imageUrl ?? defaultImage);

      await firebaseController.addBooksToSeries(books: mergeBooks, series: series, collectionIds: collectionIds);
      deselectAllItems();
    } on AppException catch (e) {
      debugPrint('${e.message ?? e.toString()} ${e.code}');
    } on Exception catch (e) {
      debugPrint(e.toString());
    }

    return true;
  }

  List<Book> _convertItemsToBooks(Set<Item> items) {
    final List<Book> mergeBooks = [];
    for (final item in items) {
      if (item is Book) {
        mergeBooks.add(item);
      } else if (item is Series) {
        final books = state.books;
        if (books == null) break;
        
        mergeBooks.addAll(books.where((book) => book.seriesId == item.id).toList());
      }
    }
    return mergeBooks;
  }
}

class LibraryViewData {
  final List<Book>? books;
  final List<BookCollection>? collections;
  final List<Series>? series;

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
    this.series,
  });

  List<Item> getCollectionItems(String collectionId) {
    final List<Item> items = books?.where((book) => book.collectionIds.contains(collectionId))
      .toList() ?? [];
    // Remove books with a seriesId
    items.removeWhere((item) {
      if (item is Book) {
        return item.hasSeries;
      }
      return false;
    });

    // Add series objects to items if it is in this collection
    final seriesList = series;
    List<Item> seriesInCollection = [];
    if (seriesList != null) {
      seriesInCollection = seriesList.where((s) => s.collectionIds.contains(collectionId)).toList();
    }
    final List<Item> allBooks = [
      ...items,
      ...seriesInCollection
    ];


    allBooks.sort((a, b) => a.title.compareTo(b.title));
    return allBooks;
  }

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
