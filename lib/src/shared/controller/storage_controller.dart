import 'dart:async';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:watcher/watcher.dart';

import '../../exceptions/app_exception.dart';
import '../../features/library/data/book_item.dart';
import '../../features/library/data/item.dart';
import '../../features/library/model/book_status_notifier.dart';
import '../../service/storage_service.dart';
import '../data/file_hash.dart';
import 'epub_parse_controller.dart';
import 'firebase_controller.dart';

final fileStreamProvider = StreamProvider.family.autoDispose<WatchEvent, Book>((ref, book) async* {
  final stream = ref.watch(directorySteamProvider.stream);

  /// Yield the events for this file
  await for (final event in stream) {
    if (event.path.split('/').last == book.filename) {
      yield event;
    }
  }
});

final directorySteamProvider = StreamProvider.autoDispose<WatchEvent>((ref) async* {
  final storageController = ref.watch(storageControllerProvider);
  final watcher = DirectoryWatcher(storageController.getUserDirectory());

  // Parse the value received and emit a Message instance\
  await for (final event in watcher.events) {
    yield event;
  }
});

final storageControllerProvider =
    Provider.autoDispose<StorageController>((ref) => StorageController(ref.read));

class StorageController {
  StorageController(this._read);

  final Reader _read;
  static const _uuid = Uuid();

  bool get loggedIn => _read(firebaseControllerProvider).currentUser == null ? false : true;

  Stream<String> startBookUploadsFromStoredQueue() async* {
    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    if (_read(storageServiceProvider).uploadQueueBox == null) {
      await _read(storageServiceProvider).initQueueBox(userId);
    }

    final log = Logger();
    final fileHashList = _read(storageServiceProvider).uploadQueueFileHashList;
    await for (final message in handleUploadFromFileHashList(fileHashList)) {
      // Messages are only received if a book upload fails
      log.i(message);
      yield message;
    }
  }

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
  Stream<String> pickAndUploadMultipleBooks([
    String collectionName = 'Default',
  ]) async* {
    if (kIsWeb) {
      throw AppException('StorageController.uploadMultipleBooks does not work on web');
    }

    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    if (_read(storageServiceProvider).uploadQueueBox == null) {
      await _read(storageServiceProvider).initQueueBox(userId);
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

    final filePathList = platformFileList
        .map((file) => file.path!) // Will never be null since this won't run on web
        .toList();

    // Exit if no files chosen
    if (filePathList.isEmpty) return;

    //1. Get file hashes and filter out files that have already been uploaded
    final fileHashStream = _read(storageServiceProvider).hashFileList(filePathList);
    final fileHashList = <FileHash>[];
    await for (final fileHash in fileHashStream) {
      final filepath = fileHash.filepath;
      final md5 = fileHash.md5;
      final sha1 = fileHash.sha1;
      log.i(
        'Received Hash for ${filepath.split('/').last}: '
        'md5 $md5 and sha1 $sha1',
      );

      // 2. Check Firestore for user books with same MD5 and SHA1
      //     -   If book found, dont upload and show snack bar with message
      //         "Book already uploaded",
      final exists = await _read(firebaseControllerProvider).fileHashExists(md5, sha1);
      if (exists) {
        yield 'File already uploaded: ${filepath.split('/').last}';
        continue;
      }

      fileHashList.add(fileHash.copyWith(collectionName: collectionName));
    }

    // Save all to Hive box with filepath and filehash
    // This allows the upload to be resumed on app start
    //   (and logged in) if interrupted
    // Update item values when document and file uploaded
    // Remove items from box after upload completed
    _read(storageServiceProvider).saveToUploadQueueBox(fileHashList);

    log.i('Starting Uploading of Books');
    await for (final message in handleUploadFromFileHashList(fileHashList)) {
      yield message;
    }
  }

  /// Upload books in file hash list and return a stream of files
  /// that could not be uploaded
  ///
  /// TODO(@getBoolean): Display streamed messages in UI
  Stream<String> handleUploadFromFileHashList(
    List<FileHash> fileHashList,
  ) async* {
    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    final log = Logger();
    for (final fileHash in fileHashList) {
      final cacheFilepath = fileHash.filepath;
      final cachedFilename = cacheFilepath.split('/').last;

      // TODO(@getBoolean): Check for duplicates

      final bool fileExists;
      try {
        fileExists =
            await _read(firebaseControllerProvider).fileHashExists(fileHash.md5, fileHash.sha1);
      } on FirebaseException catch (e, st) {
        log.i('Unable to check for duplicates: "$cachedFilename"', e, st);
        yield 'Unable to check for duplicates: "$cachedFilename"';
        continue;
      }

      if (fileExists) {
        log.i('File already uploaded: $cachedFilename');
        yield 'File already uploaded: "$cachedFilename"';
      }

      log.i('Read As Bytes: $cachedFilename');
      final Uint8List bytes;
      try {
        bytes = await io.File(cacheFilepath).readAsBytes();
      } on io.IOException catch (e, st) {
        log.i(
          'Unable to upload file "$cachedFilename", '
          'it may not exist',
          e,
          st,
        );
        yield 'Unable to upload file "$cachedFilename", '
            'it may not exist';
        unawaited(_read(storageServiceProvider).boxRemoveFromUploadQueue(cacheFilepath));
        continue;
      }
      log.i('Read As Bytes Done: $cachedFilename');

      // 3. Grab Book Cover Image
      //     -   If no cover image exists, put null in book document for
      //         the cover image url.
      //
      //         In the app, a default image will be shown included in
      //         the assets if image url is null
      // ignore: cascade_invocations
      log.i('Reading Cover: $cachedFilename');
      final coverData = await _read(epubServiceProvider).getCoverImage(bytes);
      log.i('Reading Cover Done: $cachedFilename');

      // 4. Upload Book File with MD5 and SHA1 in metadata
      // On completion, upload book document and cover image

      final id = _uuid.v4();
      final firebaseFilepath = _read(epubServiceProvider).getRelativeFilepath(
        cacheFilePath: cacheFilepath,
        id: id,
        userId: userId,
      );
      final firebaseFileHash = fileHash.copyWith(filepath: firebaseFilepath);

      // TODO(@getBoolean): Copy book data to device
      // TODO(@getBoolean): Upload book details document and cover image first
      log.i('Starting File Upload:  $cachedFilename');
      final uploadBookTask = await _read(firebaseControllerProvider).uploadBookData(
        userId: userId,
        bytes: bytes,
        firebaseFilepath: firebaseFilepath,
        fileHash: firebaseFileHash,
      );
      if (uploadBookTask == null) {
        log.i('Unable to upload file: $cachedFilename');
        yield 'Unable to upload file: $cachedFilename';
        // TODO(@getBoolean): Show upload error in UI also
        unawaited(_read(storageServiceProvider).boxRemoveFromUploadQueue(cacheFilepath));
        continue;
      }

      await uploadBookTask.whenComplete(() async {
        log.i('Finished File Upload: $cachedFilename');
        unawaited(_read(storageServiceProvider).boxSetFileUploadedInUploadQueue(cacheFilepath));

        // 5. Upload Book Cover Image
        //     -   Don't upload if null
        //     -   If upload fails, set cover image path to null
        final coverFilename = _read(epubServiceProvider).getCoverFilename(cacheFilepath, id, 'jpg');
        String? coverImageFirebaseFilepath = '$userId/$coverFilename';
        final coverImageFirebaseFilename = coverImageFirebaseFilepath.split('/').last;
        try {
          log.i('Starting File Upload:  '
              '$coverImageFirebaseFilename');
          final uploadTask = coverData == null
              ? null
              : await _read(firebaseControllerProvider).uploadCoverImage(
                  firebaseFilepath: coverImageFirebaseFilepath,
                  bytes: coverData,
                );
          await uploadTask;
          log.i('Finished File Upload: '
              '$coverImageFirebaseFilename');
        } on Exception catch (e, st) {
          log.w('Unable to upload file: $coverImageFirebaseFilename : $e', e, st);
          coverImageFirebaseFilepath = null;
        }

        // 6. Upload Book Document with Cover Image Filepath, MD5, and SHA1
        final parsedBook = await _read(epubServiceProvider).parseDetails(
          bytes,
          cacheFilePath: cacheFilepath,
          collectionName: fileHash.collectionName,
          userId: userId,
          id: id,
        );

        final book = parsedBook.copyWith(
          fileHash: firebaseFileHash,
          firebaseCoverImagePath: coverImageFirebaseFilepath,
        );

        await _read(firebaseControllerProvider).uploadBookDocument(book);
        await _read(storageServiceProvider).boxSetDocumentUploadedInUploadQueue(cacheFilepath);
      });
    }
  }

  Future<void> downloadBookFile(
    Book book, {
    FutureOr<void> Function(String)? whenDone,
  }) async {
    final log = Logger();
    final appBookAdaptPath = _read(storageServiceProvider).appBookAdaptDirectory.path;
    final task = _read(firebaseControllerProvider)
        .downloadFile(book.filepath, '$appBookAdaptPath/${book.filepath}');

    try {
      await task.whenComplete(() async {
        await whenDone?.call(book.filename);
      });
    } on FirebaseException catch (e, st) {
      log.e(
        '[StorageController.downloadBookFile] ${e.code}-${e.message}',
        e,
        st,
      );
      _read(bookStatusProvider(book).notifier).setErrorDownloading();
    } on Exception catch (e, st) {
      log.e('[StorageController.downloadBookFile] ${e.toString()}', e, st);
      _read(bookStatusProvider(book).notifier).setErrorDownloading();
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
    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
    final deletedFirebaseBooks = _read(firebaseControllerProvider).deleteItemsPermanently(
      itemsToDelete: itemsToDelete,
      allBooks: allBooks,
    );
    final deletedFirebaseFilenameList = deletedFirebaseBooks.map((item) => item.filename).toList();
    await deleteFiles(filenameList: deletedFirebaseFilenameList);
  }

  // Delete downloaded books files from device if they are removed
  // from Firebase Storage
  Future<List<String>> deleteFiles({required List<String> filenameList}) async {
    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    final deletedFilenames = <String>[];

    for (final filename in filenameList) {
      final fullFilePath =
          _read(storageServiceProvider).getPathFromFilename(userId: userId, filename: filename);

      final exists =
          await _read(storageServiceProvider).appFileExists(userId: userId, filename: filename);
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
    final bookPath = _read(storageServiceProvider).getAppFilePath(book.filepath);

    return _read(storageServiceProvider).getFileInMemory(bookPath);
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
