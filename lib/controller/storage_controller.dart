import 'dart:async';
import 'dart:io' as io;

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

final storageControllerProvider =
    Provider.autoDispose<StorageController>((ref) {
  final firebaseController = ref.watch(firebaseControllerProvider);
  final storageService = ref.watch(storageServiceProvider);

  return StorageController(
    firebaseController: firebaseController,
    storageService: storageService,
  );
});

class StorageController {
  StorageController({
    required FirebaseController firebaseController,
    required StorageService storageService,
  })  : _firebaseController = firebaseController,
        _storageService = storageService;

  final FirebaseController _firebaseController;
  final StorageService _storageService;
  final log = Logger();

  ValueListenable<Box<bool>> get downloadedBooksValueListenable =>
      _storageService.downloadedBooksValueListenable;

  void downloadFile(
    Book book, {
    required FutureOr<void> Function(String) whenDone,
  }) {
    final appBookAdaptPath = _storageService.appBookAdaptDirectory.path;
    final task = _firebaseController.downloadFile(
        book.filepath, '$appBookAdaptPath/${book.filepath}');
    // ignore: unawaited_futures
    task.whenComplete(() async {
      await _storageService.setBookDownloaded(book.filename);
      await whenDone(book.filename);
    });
  }

  List<String> updateDownloadedFiles() {
    final downloadedFiles = getDownloadedFilenames();
    downloadedFiles.forEach(_storageService.setBookDownloaded);
    return downloadedFiles;
  }

  /// Get the list of files on downloaded to the device
  ///
  /// Returns a list of string filenames
  List<String> getDownloadedFilenames() {
    final String? userId = _firebaseController.currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    try {
      final filesPaths = _storageService.listFiles(userId: userId);
      return filesPaths.map((file) {
        return file.path.split('/').last;
      }).toList();
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
    final deletedBooks = await _firebaseController.deleteItemsPermanently(
      itemsToDelete: itemsToDelete,
      allBooks: allBooks,
    );
    await deleteDeletedBookFiles(deletedBooks.map((item) => item.filename).toList());
  }

  // Delete downloaded books files from device if they are removed from Firebase Storage
  Future<List<String>> deleteDeletedBookFiles(List<String> filenames) async {
    final String? userId = _firebaseController.currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
    final deletedFilenames = <String>[];
    final firebaseFilesnames = await _firebaseController.listFilenames();
    for (final filename in filenames) {
      if (!firebaseFilesnames.contains(filename)) {
        final fullFilePath = _storageService.getPathFromFilename(
            userId: userId, filename: filename);
        await io.File(fullFilePath).delete();
        deletedFilenames.add(filename);
      }
    }
    return deletedFilenames;
  }

  Future<List<int>> getBookData(Book book) async {
    final bookPath = _storageService.getAppFilePath(book.filepath);

    return await _storageService.getFileInMemory(bookPath);
  }

  Future<void> deleteBooks(List<Book> books) async {
    for (final book in books) {
      final bookPath = _storageService.getAppFilePath(book.filepath);
      await _storageService.deleteFile(bookPath);
      await _storageService.setBookNotDownloaded(book.filename);
    }
  }

  Future<bool?> isBookDownloaded(String bookId) async {
    final isDownloaded = _storageService.isBookDownloaded(bookId);
    if (isDownloaded == null) {
      await _storageService.setBookNotDownloaded(bookId);
    }
    return isDownloaded ?? false;
  }
}
