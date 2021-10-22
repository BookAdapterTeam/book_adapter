import 'dart:io';

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
    final storageService = _read(storageServiceProvider);
    try {
      final files = await storageService.listFiles();
      final filenames = files.map((e) {
        final pathItems = e.path.split('/');
        return pathItems.last;
      }).toList();
      state = state.copyWith(downloadedFiles: filenames);
    } on FileSystemException catch (e, _) {
      state = state.copyWith(downloadedFiles: []);
    }
  }
}
