import 'dart:async';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:watcher/watcher.dart';

import '../data/app_exception.dart';
import '../data/file_hash.dart';
import '../features/library/data/book_item.dart';
import '../features/library/data/item.dart';
import '../features/parser/epub_parse_controller.dart';
import '../service/isolate_service.dart';
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
  static const _uuid = Uuid();

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
  Stream<String> uploadMultipleBooks([
    String collectionName = 'Default',
  ]) async* {
    if (kIsWeb) {
      throw AppException(
          'StorageController.uploadMultipleBooks does not work on web');
    }

    final userId = _read(firebaseControllerProvider).currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
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

    // TODO(@getBoolean): Upload book queue and support immediate reading
    /**
     * Add bookFileUploaded and bookCoverUploaded to Book()
     * uploadQueue = BookUploadQueue<BookUpload>()
     *   BookUpload(id, localFilePath, uploadStatus) // localFilePath is the path to the file copied to the app directory
     * 
     * For all selected files
     *   Copy book to app directory
     *   Upload Firestore document with temporary values (filename, use placeholder local cover image asset, bookFileUploaded & bookCoverUploaded set to false)
     *     Cover image on older app versions will load from url, newer app versions will see the url and use the image stored on the device already
     *   Add BookUpload to uploadQueue
     * ****
     * In BookUploadQueue.processing()
     * while queue.isNotEmpty
     *   Load book into memory
     *   Get Book title, author, etc
     *   Update Firebase book document with title, author, etc
     *   Get Book cover
     *   Copy book cover to local book folder
     *   Update Firebase book document with relativeCoverImagePath
     *   Start cover image upload
     *     When finished, update Firestore document book's bookCoverUploaded to true
     *   Start book file upload
     *     When finished, update Firestore document book's bookFileUploaded to true
     * ****
     * In LibraryView
     *   if books' bookCoverUploaded is false, don't show image
     * 
     *   If book cover image exists on device
     *     Load file into memory from path appDirectoryPath + book's relativeCoverImagePath
     *     Show image in UI
     *   else
     *     Download cover image from Firebase at path specified in book's relativeCoverImagePath
     *     Show image in UI
     *     Save cover image to device local app directory at path appDirectoryPath + relativeCoverImagePath
     */

    final filepathList = platformFileList
        .map((file) =>
            file.path!) // Will never be null since this won't run on web
        .toList();

    // Exit if no files chosen
    if (filepathList.isEmpty) return;

    final List<FileHash> fileHashList = [];

    //1. Get File Hash
    final stream = IsolateService.sendListAndReceiveStream<String, FileHash>(
      filepathList,
      receiveAndReturnService: IsolateService.readAndHashFileService,
    );
    await for (final fileHash in stream) {
      final String filepath = fileHash.filepath;
      final String md5 = fileHash.md5;
      final String sha1 = fileHash.sha1;
      log.i(
        'Received Hash for ${filepath.split('/').last}: md5 $md5 and sha1 $sha1',
      );

      // 2. Check Firestore for user books with same MD5 and SHA1
      //     -   If book found, dont upload and show snack bar with message "Book already uploaded",
      final bool exists =
          await _read(firebaseControllerProvider).fileHashExists(md5, sha1);
      if (exists) {
        yield 'File ${filepath.split('/').last} already uploaded';
        continue;
      }

      fileHashList.add(fileHash);
    }

    // TODO(@getBoolean): 2-1. Show number of processing books to UI
    // TODO(@getBoolean): 2-2. Upload books in book upload queue on app start.
    // Save all to Hive box
    //   filename, isDocumentUploaded, isFileUploaded
    // This allows the upload to be resumed on app start (and logged in) if interrupted
    // Update item values when document and file uploaded
    // Remove items from box after upload completed
    for (final fileHash in fileHashList) {
      final String filepath = fileHash.filepath;

      log.i('${filepath.split('/').last} Queued For Upload');

      unawaited(_read(storageServiceProvider).boxAddToUploadQueue(
        filepath,
        fileHash: fileHash,
      ));
    }

    log.i('Starting Uploading of Books');
    for (final fileHash in fileHashList) {
      final String cacheFilepath = fileHash.filepath;

      log.i('Read As Bytes: ${cacheFilepath.split('/').last}');
      final bytes = await io.File(cacheFilepath).readAsBytes();
      log.i('Read As Bytes Done: ${cacheFilepath.split('/').last}');

      // 3. Grab Book Cover Image
      //     -   If no cover image exists, put null in book document for the cover image url.
      //
      //         In the app, a default image will be shown included in the assets if image url is null
      log.i('Reading Cover: ${cacheFilepath.split('/').last}');
      final coverData = await _read(epubServiceProvider).getCoverImage(bytes);
      log.i('Reading Cover Done: ${cacheFilepath.split('/').last}');

      // 4. Upload Book File with MD5 and SHA1 in metadata
      // On completion, upload book document and cover image

      final id = _uuid.v4();
      final firebaseFilepath = _read(epubServiceProvider).getFirebaseFilepath(
        cacheFilePath: cacheFilepath,
        id: id,
        userId: userId,
      );
      final firebaseFileHash = fileHash.copyWith(filepath: firebaseFilepath);

      log.i('Starting File Upload:  ${cacheFilepath.split('/').last}');
      final task = await _read(firebaseControllerProvider).uploadBookData(
        userId: userId,
        bytes: bytes,
        firebaseFilepath: firebaseFilepath,
        fileHash: firebaseFileHash,
      );
      if (task == null) {
        log.i('Unable to upload file: ${cacheFilepath.split('/').last}');
        yield 'Unable to upload file: ${cacheFilepath.split('/').last}';
        unawaited(_read(storageServiceProvider)
            .boxRemoveFromUploadQueue(cacheFilepath));
        continue;
      }

      await task.whenComplete(() async {
        log.i('Finished File Upload: ${cacheFilepath.split('/').last}');
        unawaited(_read(storageServiceProvider)
            .boxSetFileUploadedInUploadQueue(cacheFilepath));

        // 5. Upload Book Cover Image
        //     -   Don't upload if null
        //     -   If upload fails, set cover image path to null
        final String coverFilename = _read(epubServiceProvider)
            .getCoverFilename(cacheFilepath, id, 'jpg');
        String? coverImageFirebaseFilepath = '$userId/$coverFilename';
        try {
          log.i(
              'Starting File Upload:  ${coverImageFirebaseFilepath.split('/').last}');
          final uploadTask = coverData == null
              ? null
              : await _read(firebaseControllerProvider).uploadCoverImage(
                  firebaseFilepath: coverImageFirebaseFilepath,
                  bytes: coverData,
                );
          await uploadTask;
          log.i(
              'Finished File Upload: ${coverImageFirebaseFilepath.split('/').last}');
        } on Exception catch (e, st) {
          log.i(
              'Unable to upload file: ${coverImageFirebaseFilepath.split('/').last}');
          log.w(e.toString(), e, st);
          coverImageFirebaseFilepath = null;
        }

        // 6. Upload Book Document with Cover Image Filepath, MD5, and SHA1
        final parsedBook = await _read(epubServiceProvider).parseDetails(
          bytes,
          cacheFilePath: cacheFilepath,
          collectionName: collectionName,
          userId: userId,
          id: id,
        );

        final book = parsedBook.copyWith(
          fileHash: firebaseFileHash,
          firebaseCoverImagePath: coverImageFirebaseFilepath,
        );

        await _read(firebaseControllerProvider).uploadBookDocument(book);
        await _read(storageServiceProvider)
            .boxSetDocumentUploadedInUploadQueue(cacheFilepath);
      });
    }
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
