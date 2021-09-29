import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:dartz/dartz.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The list of books
final bookListProvider = FutureProvider<List<BookItem>>((ref) async {
  // Obtains the controller instance
  final libraryController = ref.watch(libraryControllerProvider);

  // Fetch the books and expose them to the UI.
  final res = await libraryController.fetchBooks();
  
  return res.fold(
    (failure) => [],
    (books) => books,
  );
});

final libraryControllerProvider = Provider<LibraryController>((ref) {
  return LibraryController(ref);
});

class LibraryController {
  LibraryController(this._ref);
  final ProviderRef _ref;
 
  Future<Either<Failure, List<BookItem>>> fetchBooks() async {
    // Make service call and inject results into the model
    final Either<Failure, List<BookItem>> res = await _ref.read(firebaseControllerProvider).getBooks();
    return res.fold(
      // Firebase call to get the updated books failed
      (failure) {
        return Left(failure);
      },
      // Success, list of books received
      (books) {
        final UserModelNotifier userModel = _ref.read(userModelProvider.notifier);
        userModel.setBooks(books);
        return Right(books);
      }
    );
  }

  
}