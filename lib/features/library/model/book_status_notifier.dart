import 'dart:io' as io;

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:watcher/watcher.dart';

import '../../../controller/storage_controller.dart';
import '../../../service/storage_service.dart';
import '../data/book_item.dart';

final bookStatusProvider = StateNotifierProvider.family
    .autoDispose<BookStatusNotifier, AsyncValue<BookStatus>, Book>((ref, book) {
  final asyncWatchEvent = ref.watch(fileStreamProvider(book));

  final AsyncValue<BookStatus> status = asyncWatchEvent.map(
    data: (data) {
      final changeType = data.value.type;
      switch (changeType) {
        case ChangeType.ADD:
          return const AsyncData(BookStatus.downloaded);
        case ChangeType.MODIFY:
          return const AsyncData(BookStatus.downloaded);
        case ChangeType.REMOVE:
        default:
          return const AsyncData(BookStatus.notDownloaded);
      }
    },
    error: (error) => AsyncError(error),
    loading: (loading) => const AsyncValue.loading(),
  );

  return BookStatusNotifier(
    ref.read,
    book,
    status,
  );
});

class BookStatusNotifier extends StateNotifier<AsyncValue<BookStatus>> {
  BookStatusNotifier(this._read, this.book, AsyncValue<BookStatus> status)
      : super(status) {
      updateStatus();
  }

  final Book book;
  final Reader _read;

  /// Set BookStatus is unknown. Downloaded or not downloaded status will be automatically checked.
  void setLoading() {
    state = const AsyncValue.loading();
    updateStatus();
  }

  /// Set BookStatus as waiting for upload or download
  void setWaiting() {
    state = const AsyncValue.data(BookStatus.waiting);
  }

  /// Set BookStatus as currently downloading the book file
  void setDownloading() {
    state = const AsyncValue.data(BookStatus.downloading);
  }

  /// An error occured during download
  ///
  /// The checksum of the file does not match the saved checksum.
  ///
  /// This could be caused by the download being interrupted, or
  /// the file on the server is corrupted.
  void setErrorDownloading() {
    state = const AsyncValue.data(BookStatus.errorDownloading);
  }

  /// Set the book as currently uploading to the server
  void setUploading() {
    state = const AsyncValue.data(BookStatus.uploading);
  }

  /// Set that an error occured during upload
  void setErrorUploading() {
    state = const AsyncValue.data(BookStatus.errorUploading);
  }

  /// Update the status to whether the book is downloaded or not
  ///
  /// Only updates if `state == const AsyncValue.loading()`
  void updateStatus() {
    if (state != const AsyncLoading<BookStatus>()) return;
    
    final storageService = _read(storageServiceProvider);
    final path = storageService.getAppFilePath(book.filepath);

    // Get file status for this book
    final exists = io.File(path).existsSync();

    if (exists) {
      state = const AsyncData(BookStatus.downloaded);
    } else {
      state = const AsyncData(BookStatus.notDownloaded);
    }
  }
}

enum BookStatus {
  /// The book file is downloaded to this device
  downloaded,

  /// The book file is currrently being downloaded to this device
  downloading,

  /// The book is either waiting to upload or download
  ///
  /// TODO: Change to downloadWaiting
  waiting,

  /// The book file is currently uploading to the server
  uploading,

  /// The book file is not downloaded to this device
  notDownloaded,

  /// An error occured during upload
  ///
  /// The upload was likely interrupted
  errorUploading,

  /// An error occured during download
  ///
  /// The checksum of the file does not match the saved checksum.
  ///
  /// This could be caused by the download being interrupted, or
  /// the file on the server is corrupted.
  errorDownloading,
}
