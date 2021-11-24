import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/controller/storage_controller.dart';
import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/data/user_data.dart';
import 'package:book_adapter/features/in_app_update/util/toast_utils.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/model/queue_model.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

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

  Future<void> addBooks() async {
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
          log.e(failure.message);
          ToastUtils.error(failure.message);
        },
        (book) => uploadedBooks.add(book),
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

  Future<void> unmergeSeries() async {
    final selectedSeries = state.selectedSeries;
    state = state.copyWith(selectedItems: {});
    for (final series in selectedSeries) {
      final booksInSeries = state.getSeriesItems(series.id);
      await _read(firebaseControllerProvider).unmergeSeries(
        series: series,
        books: booksInSeries,
      );
    }
  }

  // Pass in Reader because was getting an error after unmerging then merging a series
  // _AssertionError ('package:riverpod/src/framework/provider_base.dart': Failed assertion: line 645 pos 7: '_debugDidChangeDependency == false': Cannot use ref functions after the dependency of a provider changed but before the provider rebuilt)
  Future<Either<Failure, void>> mergeIntoSeries(
    Reader read, [
    String? name,
  ]) async {
    // Get the list of all books selected, including books in a series
    final items = state.selectedItems;

    // final selectedSeries = state.selectedSeries;

    final List<Book> mergeBooks = _convertItemsToBooks(items);

    // Put series in collections the book was in
    // TODO: Get input from user to decide collection
    mergeBooks
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final Set<String> collectionIds = {};
    for (final book in mergeBooks) {
      collectionIds.addAll(book.collectionIds);
    }
    deselectAllItems();

    try {
      // Create a new series with the title with the first item in the list
      const defaultImage =
          'https://st4.depositphotos.com/14953852/24787/v/600/depositphotos_247872612-stock-illustration-no-image-available-icon-vector.jpg';
      final series = await read(firebaseControllerProvider).addSeries(
          name: name ?? items.first.title,
          imageUrl: items.first.imageUrl ?? defaultImage);

      await read(firebaseControllerProvider).addBooksToSeries(
          books: mergeBooks, series: series, collectionIds: collectionIds);
      // TODO: Delete old series items. For now, merging series is disabled

      // for (final collectionId in collectionIds) {
      //   await firebaseController.removeSeries(collectionId);
      // }
      return const Right(null);
    } on AppException catch (e, st) {
      log.e('${e.message ?? e.toString()} ${e.code}', e, st);
      return Left(Failure(e.message ?? e.toString()));
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return Left(Failure(e.toString()));
    }
  }

  List<Book> _convertItemsToBooks(Set<Item> items) {
    final List<Book> mergeBooks = [];
    for (final item in items) {
      if (item is Book) {
        mergeBooks.add(item);
      } else if (item is Series) {
        final books = state.books;
        if (books == null) break;

        mergeBooks
            .addAll(books.where((book) => book.seriesId == item.id).toList());
      }
    }
    return mergeBooks;
  }

  /// Remove a collection
  ///
  /// Items in the collection are not deleted
  Future<Failure?> removeBookCollection(BookCollection collection) async {
    try {
      final collectionItems = state.getCollectionItems(collection.id);
      // Remove file
      await _read(firebaseControllerProvider).removeCollection(
        collection: collection,
        collectionItems: collectionItems,
      );
    } catch (e, st) {
      log.e(e.toString, e, st);
      return Failure(e.toString());
    }
  }

  Future<Failure?> deleteBookDownloads() async {
    final selectedBooks = state.allSelectedBooks;

    try {
      state = state.copyWith(selectedItems: {});
      // Remove file
      await _read(storageControllerProvider)
          .deleteBooks(selectedBooks.toList());
    } catch (e, st) {
      log.e(e.toString, e, st);
      return Failure(e.toString());
    }
  }

  Future<Failure?> deleteBooksPermanently() async {
    final selectedItems = state.selectedItems;
    try {
      state = state.copyWith(selectedItems: {});
      // Remove books
      await _read(storageControllerProvider).deleteItemsPermanently(
        itemsToDelete: selectedItems.toList(),
        allBooks: state.books ?? [],
      );
    } catch (e, st) {
      log.e(e.toString, e, st);
      return Failure(e.toString());
    }
  }

  Future<void> moveItemsToCollections(List<String> collectionIds) async {
    final firebaseController = _read(firebaseControllerProvider);
    final items = state.selectedItems;
    await firebaseController.setItemsCollections(
      items: items.toList(),
      collectionIds: collectionIds,
    );
  }

  Future<Either<Failure, BookCollection>> addNewCollection(String name) async {
    final bool foundCollection = collectionExist(name);
    if (foundCollection) {
      return Left(Failure('Collection Already Exists'));
    }
    await _read(firebaseControllerProvider).addCollection(name);
    return await _read(firebaseControllerProvider).addCollection(name);
  }

  bool collectionExist(String name) {
    final collections = state.collections;
    final names = collections!.map((collection) => collection.name);
    return names.contains(name);
  }

  Future<Either<Failure, void>> queueDownloadBook(Book book) async {
    // TODO: Fix only able to download one book at a time

    try {
      // TODO: Check that book is not already downloaded
      final bool isDownloaded = await _read(storageControllerProvider)
              .isBookDownloaded(book.filename) ??
          false;

      if (isDownloaded) {
        return Left(Failure('Book has already been downloaded'));
      }

      // Check if file exists on server before downloading
      final bool existsInFirebase =
          await _read(firebaseControllerProvider).fileExists(book.filepath);

      if (!existsInFirebase) {
        return Left(Failure('Could not find file on server'));
      }

      _read(userModelProvider.notifier).queueDownload(book);
      return const Right(null);
    } on AppException catch (e) {
      log.e(e.toString());
      return Left(Failure(e.message ?? e.toString()));
    } on Exception catch (e) {
      log.e(e.toString());
      return Left(Failure(e.toString()));
    }
  }

  Future<Failure?> queueDownloadBooks() async {
    try {
      // Check if file exists on server before downloading
      final selectedBooks = state.allSelectedBooks.toList();
      state = state.copyWith(selectedItems: {});
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

  /// Get the current status of a book to determine what icon to show on the book tile
  ///
  /// TODO: Determine if the book is uploading, or an error downloading/uploading
  // BookStatus getBookStatus(Book book) {
  //   final BookStatus status;
  //   if (state.queueData.queueListItems.contains(book)) {
  //     status = BookStatus.downloading;
  //   } else {
  //     final bool exists = state.userData.downloadedFiles
  //             ?.contains(book.filepath.split('/').last) ??
  //         false;

  //     if (exists) {
  //       status = BookStatus.downloaded;
  //     } else {
  //       status = BookStatus.notDownloaded;
  //     }
  //   }
  //   return status;
  // }
}

enum BookStatus {
  downloaded,
  downloading,
  waiting,
  uploading,
  notDownloaded,
  errorUploading,
  errorDownloading,
  unknown,
}

class LibraryViewData {
  final List<Book>? books;
  final List<String>? downloadingBooks;
  final List<BookCollection>? collections;
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
    List<BookCollection>? collections,
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

  /// Get the current status of a book to determine what icon to show on the book tile
  ///
  /// TODO: Determine if the book is uploading, or an error downloading/uploading
  BookStatus getBookStatus(Book book) {
    final BookStatus status;
    if (queueData.queue
        .toSet()
        .difference(queueData.queueListItems.toSet())
        .contains(book)) {
      // TODO: Fix, this function doesn't get called when queueData gets updated
      status = BookStatus.downloading;
    } else if (queueData.queueListItems
        .toSet()
        .difference(queueData.queue.toSet())
        .contains(book)) {
      // TODO: Fix, this function doesn't get called when queueData gets updated
      status = BookStatus.waiting;
    } else {
      final bool exists =
          userData.downloadedFiles?.contains(book.filepath.split('/').last) ??
              false;

      if (exists) {
        status = BookStatus.downloaded;
      } else {
        status = BookStatus.notDownloaded;
      }
    }
    return status;
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

  Set<Book> get allSelectedBooks {
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
