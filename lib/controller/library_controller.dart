import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:dartz/dartz.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final libraryControllerProvider = Provider<LibraryController>((ref) {
  return LibraryController(ref);
});

class LibraryController {
  LibraryController(this._ref);
  final ProviderRef _ref;
 
  Future<Either<Failure, List<BookItem>>> refresh() async {
    // Make service call and inject results into the model
    final Either<Failure, List<BookItem>> res = await _ref.read(firebaseServiceProvider).getBooks();
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