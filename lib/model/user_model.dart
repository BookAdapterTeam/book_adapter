import 'dart:io';

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/data/user_data.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userModelProvider = StateNotifierProvider<UserModel, UserData>((ref) {
  const userData = UserData();

  return UserModel(ref.read, userData);
});

class UserModel extends StateNotifier<UserData> {
  UserModel(this._read, UserData data) : super(data);

  final Reader _read;

  // Update UserData with new list of books
  // void setBooks(List<Book> books) {
  //   state = state.copyWith(books: books);
  // }

  // // Update UserData with new book
  // void addBook(Book book) {
  //   state = state.copyWith(books: [...?state.books, book]);
  // }

  // // Update UserData with new book
  // void deleteBook(Book book) {
  //   state = state.copyWith(books: [
  //     for (final loopBook in state.books ?? [])
  //      if (book != loopBook) loopBook,
  //   ]);
  // }

  Future<void> setDownloadedFiles() async {
    final firebaseController = _read(firebaseControllerProvider);
    final storageService = _read(storageServiceProvider);

    final String? userId = firebaseController.currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    try {
      final filesPaths = storageService.listFiles(userId: userId);
      final filenames = filesPaths.map((file) {
        return file.path.split('/').last;
      }).toList();
      state = state.copyWith(downloadedFiles: filenames);
    } on FileSystemException catch (e, _) {
      state = state.copyWith(downloadedFiles: []);
    }
  }

  void addDownloadedFile(String filename) {
    state = state.copyWith(downloadedFiles: [
      ...?state.downloadedFiles,
      filename,
    ]);
  }
}
