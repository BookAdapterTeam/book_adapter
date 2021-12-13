import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:watcher/watcher.dart';

import '../data/app_exception.dart';
import '../features/library/data/book_item.dart';
import '../features/library/data/item.dart';
import '../model/user_model.dart';
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

  ValueListenable<Box<bool>> get downloadedBooksValueListenable =>
      _read(storageServiceProvider).downloadedBooksValueListenable;

  String getUserDirectory() {
    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
    return _read(storageServiceProvider).getAppFilePath(userId);
  }

  Future<void> downloadFile(
    Book book, {
    required FutureOr<void> Function(String) whenDone,
  }) async {
    final appBookAdaptPath =
        _read(storageServiceProvider).appBookAdaptDirectory.path;
    final task = _read(firebaseControllerProvider)
        .downloadFile(book.filepath, '$appBookAdaptPath/${book.filepath}');

    await task.whenComplete(() async {
      await _read(storageServiceProvider).setFileDownloaded(book.filename);
      await whenDone(book.filename);
    });
  }

  Future<void> setFileDownloaded(String filename) async {
    await _read(storageServiceProvider).setFileDownloaded(filename);
    _read(userModelProvider.notifier).addDownloadedFilename(filename);
  }

  Future<void> setFileNotDownloaded(String filename) async {
    await _read(storageServiceProvider).setFileNotDownloaded(filename);
    _read(userModelProvider.notifier).removeDownloadedFilename(filename);
  }

  Future<List<String>> updateDownloadedFilenameList() async {
    await _read(storageServiceProvider).clearDownloadedBooksCache();
    final downloadedFilenameList = getDownloadedFilenames();
    for (final filename in downloadedFilenameList) {
      await _read(storageServiceProvider).setFileDownloaded(filename);
    }
    return downloadedFilenameList;
  }

  /// Get the list of files on downloaded to the device
  ///
  /// Returns a list of string filenames
  List<String> getDownloadedFilenames() {
    final String? userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    try {
      final filesPaths =
          _read(storageServiceProvider).listFiles(userId: userId);
      return filesPaths.map((file) => file.path.split('/').last).toList();
    } on io.FileSystemException catch (e, st) {
      log.e(e.message, e, st);
      return [];
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return [];
    }
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
        await _read(firebaseControllerProvider).deleteItemsPermanently(
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
        await io.File(fullFilePath).delete();
        deletedFilenames.add(filename);
        await setFileNotDownloaded(filename);
      } else {
        deletedFilenames.add(filename);
        await setFileNotDownloaded(filename);
      }
    }
    return deletedFilenames;
  }

  Future<List<int>> getBookData(Book book) async {
    final bookPath =
        _read(storageServiceProvider).getAppFilePath(book.filepath);

    return await _read(storageServiceProvider).getFileInMemory(bookPath);
  }

  Future<bool?> isBookDownloaded(String filename) async {
    final isDownloaded =
        _read(storageServiceProvider).isBookDownloaded(filename);
    if (isDownloaded == null) {
      await _read(storageServiceProvider).setFileNotDownloaded(filename);
    }
    return isDownloaded ?? false;
  }
}
