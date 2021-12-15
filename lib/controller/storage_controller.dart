import 'dart:async';
import 'dart:io' as io;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:watcher/watcher.dart';

import '../data/app_exception.dart';
import '../features/library/data/book_item.dart';
import '../features/library/data/item.dart';
import '../service/storage_service.dart';
import 'firebase_controller.dart';

final fileStreamProvider =
    StreamProvider.family.autoDispose<WatchEvent, Book>((ref, book) async* {
  final stream = ref.watch(directorySteamProvider.stream);

  /// Yield the events for this file
  await for (final event in stream) {
    if (event.path.split('/').last == book.filename) {
      yield event;
    }
  }
});

final directorySteamProvider =
    StreamProvider.autoDispose<WatchEvent>((ref) async* {
  final storageController = ref.watch(storageControllerProvider);
  final watcher = DirectoryWatcher(storageController.getUserDirectory());

  // Parse the value received and emit a Message instance\
  await for (final event in watcher.events) {
    yield event;
  }
});

final storageControllerProvider =
    Provider.autoDispose<StorageController>((ref) {
  return StorageController(ref.read);
});

class StorageController {
  StorageController(this._read);

  final Reader _read;
  final log = Logger();

  String getUserDirectory() {
    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
    return _read(storageServiceProvider).getAppFilePath(userId);
  }

  /// Add a list of new books
  /// 
  /// Get book status
  ///
  /// Family StateNotifierProvider `StateNotifierProvider.family<AsyncValue<BookStatus>, Book>`
  /// - Pass in book id
  /// - Default value is `AsyncValue.loading()`  // Dont show logo if loading
  /// - Get File Status with pub package watcher
  ///
  ///     - Only update state if it is `AsyncValue.loading(), BookStatus.downloaded, or BookStatus.notDownloaded`
  ///
  ///     - Run if `AsyncValue` set to `loading()`
  ///
  /// - Manually set `downloading, waiting, uploading, errorUploading, errorDownloading`
  /// - with methods and callbacks
  ///
  /// - Returns type `AsyncValue<BookStatus>`
  ///
  /// Use new Dart isolate groups, create a new isolate in the books group for every book
  /// 
  /// 0. Add placeholder document first with only filename and upload waiting icon
  /// 1. Create Isolate 1
  /// 2. Pass list of book filepaths to Isolate 1
  /// 3. Isolate 1 uses compute() to create a new isolate in same group for every book to upload
  ///
  ///     a. Each compute is passed the book filepath
  ///
  ///     b. The following is performed in the new isolate (Parsing and Uploading the Book)
  ///
  /// Parsing and Uploading the Book
  /// 1. Get MD5 and SHA1 of File Contents
  /// 2. Check Firestore for user books with same MD5 and SHA1
  ///     -   If book found, stop uploading and show snack bar with message "Book already uploaded",
  /// 3. Grab Book Cover Image
  ///     -   If no cover image exists, put null in book document for the cover image url.
  ///
  ///         In the app, a default image will be shown included in the assets if image url is null
  /// 4. Upload Book Cover Image
  ///     -   Don't upload if null
  /// 5. Upload Book Document with Cover Image URL, MD5, and SHA1
  /// 6. Upload Book File with MD5 and SHA1 in metadata
  Future<void> uploadMultipleBooks() async {

  }

  Future<void> downloadBookFile(
    Book book, {
    FutureOr<void> Function(String)? whenDone,
    FutureOr<TaskSnapshot> Function(TaskSnapshot, StackTrace)? handleError,
  }) async {
    final appBookAdaptPath =
        _read(storageServiceProvider).appBookAdaptDirectory.path;
    final task = _read(firebaseControllerProvider)
        .downloadFile(book.filepath, '$appBookAdaptPath/${book.filepath}');

    await task.whenComplete(() async {
      await whenDone?.call(book.filename);
    });
  }

  /// Delete a library item permamently
  ///
  /// Arguments
  /// `items` - Items to be deleted
  Future<void> deleteItemsPermanently({
    required List<Item> itemsToDelete,
    required List<Book> allBooks,
  }) async {
    final String? userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
    final deletedFirebaseBooks =
        _read(firebaseControllerProvider).deleteItemsPermanently(
      itemsToDelete: itemsToDelete,
      allBooks: allBooks,
    );
    final deletedFirebaseFilenameList =
        deletedFirebaseBooks.map((item) => item.filename).toList();
    await deleteFiles(filenameList: deletedFirebaseFilenameList);
  }

  // Delete downloaded books files from device if they are removed from Firebase Storage
  Future<List<String>> deleteFiles({required List<String> filenameList}) async {
    final String? userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    final deletedFilenames = <String>[];

    for (final filename in filenameList) {
      final fullFilePath = _read(storageServiceProvider)
          .getPathFromFilename(userId: userId, filename: filename);

      final exists = await _read(storageServiceProvider)
          .appFileExists(userId: userId, filename: filename);
      if (exists) {
        unawaited(io.File(fullFilePath).delete());
        deletedFilenames.add(filename);
      } else {
        deletedFilenames.add(filename);
      }
    }
    return deletedFilenames;
  }

  Future<List<int>> getBookData(Book book) async {
    final bookPath =
        _read(storageServiceProvider).getAppFilePath(book.filepath);

    return await _read(storageServiceProvider).getFileInMemory(bookPath);
  }

  bool fileExists(String filename) {
    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    return _read(storageServiceProvider).appFileExistsSync(
      userId: userId,
      filename: filename,
    );
  }
}
