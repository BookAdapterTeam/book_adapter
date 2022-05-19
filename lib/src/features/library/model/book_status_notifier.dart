import 'dart:io' as io;

import 'package:book_adapter/src/features/library/data/book_item.dart';
import 'package:book_adapter/src/features/library/model/book_status_enum.dart';
import 'package:book_adapter/src/service/storage_service.dart';
import 'package:book_adapter/src/shared/controller/storage_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:watcher/watcher.dart';

final bookStatusProvider = StateNotifierProvider.family
    .autoDispose<BookStatusNotifier, AsyncValue<BookStatus>, Book>((ref, book) {
  final asyncWatchEvent = ref.watch(fileStreamProvider(book));

  final AsyncValue<BookStatus> status = asyncWatchEvent.map(
    data: (fileChangeData) {
      final changeType = fileChangeData.value.type;
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
    error: AsyncError.new,
    loading: (loading) => const AsyncLoading(),
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

  /// Set BookStatus is unknown. Downloaded or not downloaded
  /// status will be automatically checked.
  void setLoading() {
    state = const AsyncValue.loading();
    updateStatus();
  }

  /// Set BookStatus as waiting to download
  void setDownloadWaiting() {
    state = const AsyncValue.data(BookStatus.downloadWaiting);
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
