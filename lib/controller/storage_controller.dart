import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:book_adapter/features/parser/epub_service.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
  /// WILL NOT RUN ON WEB
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
  Stream<String> uploadMultipleBooks() async* {
    if (kIsWeb) {
      throw AppException(
          'StorageController.uploadMultipleBooks does not work on web');
    }

    final log = Logger();

    // Open file picker
    final platformFileList = await _read(storageServiceProvider).pickFile(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      allowMultiple: true,
      withReadStream: false,
      withData: false,
      allowCompression: false,
    );

    final filepathList = platformFileList
        .map((file) =>
            file.path!) // Will never be null since this won't run on web
        .toList();

    final List<Map<String, dynamic>> fileMapList = List.empty();

    //1. Get File Hash
    await for (final fileMap in _sendAndReceiveFileHash(filepathList)) {
      final String filepath = fileMap[StorageService.kFilepathKey];
      final String md5 = fileMap[StorageService.kMD5];
      final String sha1 = fileMap[StorageService.kSHA1];
      log.i(
        'Received Hash for ${filepath.split('/').last}: md5 $md5 and sha1 $sha1',
      );

      // 2. Check Firestore for user books with same MD5 and SHA1
      //     -   If book found, stop uploading and show snack bar with message "Book already uploaded",
      final bool exists = await _fileHashExists(md5, sha1);
      if (exists) {
        yield 'File ${filepath.split('/').last} already uploaded';
        continue;
      }

      fileMapList.add(fileMap);
    }

    // TODO(@getBoolean): 2-1. Show number of processing books to UI
    // Save all to Hive box
    //   filename, isDocumentUploaded, isFileUploaded
    // This allows the upload to be resumed on app start (and logged in) if interrupted
    // Update item values when document and file uploaded
    // Remove items from box after upload completed
    for (final fileMap in fileMapList) {
      final String filepath = fileMap[StorageService.kFilepathKey];
      final String md5 = fileMap[StorageService.kMD5];
      final String sha1 = fileMap[StorageService.kSHA1];

      _read(storageServiceProvider).boxAddToUploadQueue(
        filepath,
        md5: md5,
        sha1: sha1,
      );
    }

    for (final fileMap in fileMapList) {
      final String filepath = fileMap[StorageService.kFilepathKey];
      final String md5 = fileMap[StorageService.kMD5];
      final String sha1 = fileMap[StorageService.kSHA1];

      // 3. Grab Book Cover Image
      //     -   If no cover image exists, put null in book document for the cover image url.
      //
      //         In the app, a default image will be shown included in the assets if image url is null
      final coverData = await _read(epubServiceProvider).getCoverImage(
        await io.File(filepath).readAsBytes(),
      );

      // TODO: Upload book file
      // On completion, upload book document and cover image

      // 4. Upload Book File with MD5 and SHA1 in metadata
      final task = await _uploadBookFile(filepath, md5, sha1);
      await task.whenComplete(() {
        // 5. Upload Book Cover Image
        //     -   Don't upload if null
        final coverImageFirebaseStorageUrl = _uploadCoverImage(coverData);

        // 6. Upload Book Document with Cover Image URL, MD5, and SHA1
        final book = _read(epubServiceProvider).uploadFromFile(filepath, md5, sha1);
        _uploadBookDocument(book);

        return null;
      });
    }
  }

  Future<UploadTask> _uploadBookFile(
    String filepath,
    String md5,
    String sha1,
  ) async {
    _read(firebaseServiceProvider).uploadFile(
      contentType: contentType,
      firebaseFileUploadPath: firebaseFilePath,
      localFilePath: localFilePath,
    );
  }

  /// Spawns an isolate and asynchronously sends a list of filenames for it to
  /// read and decode. Waits for the response containing the decoded JSON
  /// before sending the next.
  ///
  /// Returns a stream that emits the byte contents of each file.
  Stream<Map<String, dynamic>> _sendAndReceiveFileHash(
      List<String> filenames) async* {
    final p = ReceivePort();
    await Isolate.spawn(_readAndHashFileService, p.sendPort);

    // Convert the ReceivePort into a StreamQueue to receive messages from the
    // spawned isolate using a pull-based interface. Events are stored in this
    // queue until they are accessed by `events.next`.
    final events = StreamQueue<dynamic>(p);

    // The first message from the spawned isolate is a SendPort. This port is
    // used to communicate with the spawned isolate.
    final SendPort sendPort = await events.next;

    for (var filename in filenames) {
      // Send the next filename to be read and parsed
      sendPort.send(filename);

      // Receive the loaded bytes and upload
      final Map<String, dynamic> message = await events.next;

      // Add the result to the stream returned by this async* function.
      yield message;
    }

    // Send a signal to the spawned isolate indicating that it should exit.
    sendPort.send(null);

    // Dispose the StreamQueue.
    await events.cancel();
  }

  Future<bool> _fileHashExists(String md5, String sha1) async {
    return await _read(firebaseServiceProvider)
        .fileHashExists(md5: md5, sha1: sha1);
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

/// The entrypoint that runs on the spawned isolate. Receives messages from
/// the main isolate, reads the contents of the file, and returns it
Future<void> _readAndHashFileService(SendPort p) async {
  final log = Logger();
  log.i('Spawned isolate started.');

  // Send a SendPort to the main isolate so that it can send JSON strings to
  // this isolate.
  final commandPort = ReceivePort();
  p.send(commandPort.sendPort);

  // Wait for messages from the main isolate.
  await for (final message in commandPort) {
    if (message is String) {
      // Read and decode the file.
      final bytes = await io.File(message).readAsBytes();
      final bytesList = List<int>.from(bytes);

      // 1. Get MD5 and SHA1 of File Bytes
      final md5Hash = md5.convert(bytesList).toString();
      final sha1Hash = sha1.convert(bytesList).toString();

      // Send the result to the main isolate.
      p.send({
        StorageService.kFilepathKey: message,
        StorageService.kMD5: md5Hash,
        StorageService.kSHA1: sha1Hash,
      });
    } else if (message == null) {
      // Exit if the main isolate sends a null message, indicating there are no
      // more files to read and parse.
      break;
    }
  }

  log.i('Spawned isolate finished.');
  Isolate.exit();
}
