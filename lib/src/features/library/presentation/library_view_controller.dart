import 'package:book_adapter/src/controller/firebase_controller.dart';
import 'package:book_adapter/src/controller/storage_controller.dart';
import 'package:book_adapter/src/data/failure.dart';
import 'package:book_adapter/src/exceptions/app_exception.dart';
import 'package:book_adapter/src/features/auth/data/user_data.dart';
import 'package:book_adapter/src/features/library/data/book_collection.dart';
import 'package:book_adapter/src/features/library/data/book_item.dart';
import 'package:book_adapter/src/features/library/data/item.dart';
import 'package:book_adapter/src/features/library/data/series_item.dart';
import 'package:book_adapter/src/features/library/model/book_status_enum.dart';
import 'package:book_adapter/src/features/library/model/book_status_notifier.dart';
import 'package:book_adapter/src/model/queue_model.dart';
import 'package:book_adapter/src/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

final fileUrlProvider =
    FutureProvider.family<String, String>((ref, firebasePath) async {
  return ref
      .read(libraryViewControllerProvider.notifier)
      .getFileDownloadUrl(firebasePath);
});

final libraryViewControllerProvider =
    StateNotifierProvider.autoDispose<LibraryViewController, LibraryViewData>(
        (ref) {
  final books = ref.watch(bookStreamProvider);
  final collections = ref.watch(collectionsStreamProvider);
  final series = ref.watch(seriesStreamProvider);
  final userData = ref.watch(userModelProvider);
  final queueData = ref.watch(queueBookProvider);

  final data = LibraryViewData(
    books: books.asData?.value,
    collections: collections.asData?.value,
    series: series.asData?.value,
    userData: userData,
    queueData: queueData,
  );
  return LibraryViewController(ref.read, data: data);
});

// State is if the view is loading
class LibraryViewController extends StateNotifier<LibraryViewData> {
  LibraryViewController(this._read, {required LibraryViewData data})
      : super(data);

  final Reader _read;
  final log = Logger();

  Stream<String> addBooks() async* {
    await for (final message
        in _read(storageControllerProvider).pickAndUploadMultipleBooks()) {
      log.i(message);
      yield message;
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

  /// Unmerge series
  ///
  /// Use optional `series` argument to unmerge the specified series
  ///
  /// Ommit `series` to unmerge all selected series
  Future<void> unmergeSeries([Series? series]) async {
    if (series == null) {
      // Unmerge all selected series items
      final selectedSeries = state.selectedSeries;
      deselectAllItems();
      for (final selectedSeries in selectedSeries) {
        final booksInSeries = state.getSeriesItems(selectedSeries.id);
        await _read(firebaseControllerProvider).unmergeSeries(
          series: selectedSeries,
          books: booksInSeries,
        );
      }
    } else {
      // Unmerge a specific series
      final booksInSeries = state.getSeriesItems(series.id);
      await _read(firebaseControllerProvider).unmergeSeries(
        series: series,
        books: booksInSeries,
      );
    }
  }

  // Pass in Reader because was getting an error after
  //     unmerging then merging a series
  // `_AssertionError ('package:riverpod/src/framework/provider_base.dart': Failed assertion: line 645 pos 7: '_debugDidChangeDependency == false': Cannot use ref functions after the dependency of a provider changed but before the provider rebuilt)`
  Future<Either<Failure, Series>> mergeIntoSeries(
    Reader read, [
    String? name,
  ]) async {
    // Get the list of all books selected, including books in a series
    final selectedBooks = state.allSelectedBooksWithBooksInSeries.toList();
    final selectedSeries = state.selectedSeries.toList();
    deselectAllItems();

    // final selectedSeries = state.selectedSeries;

    // Put series in collections the book was in
    // TODO: Get input from user to decide collection
    selectedBooks
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    selectedSeries
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    try {
      final series = await read(firebaseControllerProvider).mergeToSeries(
        selectedBooks: selectedBooks,
        selectedSeries: selectedSeries,
        name: name,
      );
      return Right(series);
    } on AppException catch (e, st) {
      log.e('${e.message ?? e.toString()} ${e.code}', e, st);
      return Left(Failure(e.message ?? e.toString()));
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return Left(Failure(e.toString()));
    }
  }

  /// Remove a collection
  ///
  /// Items in the collection are not deleted
  Future<Failure?> removeBookCollection(AppCollection collection) async {
    try {
      final collectionItems = state.getCollectionItems(collection.id);
      // Remove file
      await _read(firebaseControllerProvider).removeCollection(
        collection: collection,
        collectionItems: collectionItems,
      );

      return null;
    } catch (e, st) {
      log.e(e.toString, e, st);
      return Failure(e.toString());
    }
  }

  Future<Failure?> deleteBookDownloads() async {
    final selectedBooks = state.allSelectedBooksWithBooksInSeries;

    try {
      deselectAllItems();
      // Remove file
      final selectedFilenameList =
          selectedBooks.map((book) => book.filename).toList();
      await _read(storageControllerProvider)
          .deleteFiles(filenameList: selectedFilenameList);

      return null;
    } catch (e, st) {
      log.e(e.toString, e, st);
      return Failure(e.toString());
    }
  }

  Future<Failure?> deleteBooksPermanently() async {
    final selectedItems = state.selectedItems;
    try {
      deselectAllItems();
      // Remove books
      await _read(storageControllerProvider).deleteItemsPermanently(
        itemsToDelete: selectedItems.toList(),
        allBooks: state.books ?? [],
      );

      return null;
    } catch (e, st) {
      log.e(e.toString, e, st);
      return Failure(e.toString());
    }
  }

  Future<Failure?> moveItemsToCollections(List<String> collectionIds) async {
    try {
      final items = state.selectedItems;
      await _read(firebaseControllerProvider).setItemsCollections(
        items: items.toList(),
        collectionIds: collectionIds,
      );

      return null;
    } on FirebaseException catch (e, st) {
      log.e(e.code + e.message.toString(), e, st);
      return FirebaseFailure(e.message.toString(), e.code);
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return Failure(e.toString());
    }
  }

  Future<Either<Failure, AppCollection>> addNewCollection(String name) async {
    final bool foundCollection = collectionExist(name);
    if (foundCollection) {
      return Left(Failure('Collection Already Exists'));
    }

    return _read(firebaseControllerProvider).addCollection(name);
  }

  bool collectionExist(String name) {
    final collections = state.collections;
    final names = collections!.map((collection) => collection.name);
    return names.contains(name);
  }

  Future<String> getFileDownloadUrl(String firebasePath) async {
    return _read(firebaseControllerProvider).getFileDownloadUrl(firebasePath);
  }

  Future<Failure?> queueDownloadBook(Book book) async {
    // TODO: Fix only able to download one book at a time

    try {
      // Check that book is not already downloaded
      final bookStatus = _read(bookStatusProvider(book)).asData?.value;

      if (bookStatus == BookStatus.downloaded) {
        return Failure('Book has already been downloaded');
      }

      // Check if file exists on server before downloading
      final bool existsInFirebase =
          await _read(firebaseControllerProvider).fileExists(book.filepath);

      if (!existsInFirebase) {
        return Failure('Could not find file on server');
      }

      _read(userModelProvider.notifier).queueDownload(book);
      return null;
    } on AppException catch (e, st) {
      log.e(e.toString(), e, st);
      return Failure(e.message ?? e.toString());
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return Failure(e.toString());
    }
  }

  Future<Failure?> queueDownloadBooks() async {
    try {
      // Check if file exists on server before downloading
      final selectedBooks = state.allSelectedBooksWithBooksInSeries.toList();
      deselectAllItems();
      for (final book in selectedBooks) {
        await queueDownloadBook(book);
      }
      return null;
    } on AppException catch (e) {
      log.e(e.toString());
      return Failure(e.message ?? e.toString());
    } on Exception catch (e) {
      log.e(e.toString());
      return Failure(e.toString());
    }
  }
}

class LibraryViewData {
  final List<Book>? books;
  final List<String>? downloadingBooks;
  final List<AppCollection>? collections;
  final List<Series>? series;
  final QueueNotifierData<Book> queueData;

  final UserData userData;

  /// The ids of all items currently selected. Duplicates are not allowed
  ///
  /// When merging and some items are a series, the app will get the books in
  /// each series and combine them into a Set.
  ///
  /// When merging selected books or series, the app will create a set of all
  /// collections each item is in. The created series will be added all of them.
  final Set<Item> selectedItems;

  /// True if the user has selected a series
  bool get hasSeries => selectedSeries.isNotEmpty;

  /// Set of series that are selected by the user
  Set<Series> get selectedSeries => selectedItems.whereType<Series>().toSet();

  bool get isSelecting => selectedItems.isNotEmpty;

  int get numberSelected => selectedItems.length;

  LibraryViewData({
    this.books,
    this.downloadingBooks,
    this.collections,
    this.selectedItems = const <Item>{},
    this.series,
    required this.userData,
    required this.queueData,
  });

  LibraryViewData copyWith({
    List<Book>? books,
    List<AppCollection>? collections,
    Set<Item>? selectedItems,
    List<Series>? series,
    UserData? userData,
    QueueNotifierData<Book>? queueData,
  }) {
    return LibraryViewData(
      books: books ?? this.books,
      collections: collections ?? this.collections,
      selectedItems: selectedItems ?? this.selectedItems,
      series: series ?? this.series,
      userData: userData ?? this.userData,
      queueData: queueData ?? this.queueData,
    );
  }

  List<Item> getCollectionItems(String collectionId) {
    final List<Item> items = books
            ?.where((book) => book.collectionIds.contains(collectionId))
            .toList() ??
        [];
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
      seriesInCollection = seriesList
          .where((s) => s.collectionIds.contains(collectionId))
          .toList();
    }
    final List<Item> allBooks = [...items, ...seriesInCollection];

    allBooks
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return allBooks;
  }

  List<Book> getSeriesItems(String seriesId) {
    final List<Book> items =
        books?.where((book) => book.seriesId == seriesId).toList() ?? [];

    items
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return items;
  }

  /// Get the selected book items including the books inside a series
  Set<Book> get allSelectedBooksWithBooksInSeries {
    final Set<Book> books = {};
    for (final item in selectedItems) {
      if (item is Book) {
        books.add(item);
      } else if (item is Series) {
        final seriesBooks =
            this.books?.where((book) => book.seriesId == item.id).toList() ??
                [];
        books.addAll(seriesBooks);
      }
    }
    return books;
  }
}
