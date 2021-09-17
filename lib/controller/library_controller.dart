import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/book_item.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final libraryControllerProvider = Provider<LibraryController>((ref) {
  return LibraryController(ref);
});

class LibraryController {
  LibraryController(this._ref);
  final ProviderRef _ref;
 
  Future<Either<Failure, List<BookItem>>> refresh() async {
    // Make service call and inject results into the model
    
    try {
      // TODO: Implement Firebase call
      // final List<BookItem> books = await firebaseService.getBooks();
      await Future.delayed(const Duration(seconds: 1));
      const List<BookItem> books = [
        BookItem(name: 'Book 0', id: '0'),
        BookItem(name: 'Book 1', id: '1'),
        BookItem(name: 'Book 2', id: '2'),
      ];

      // Get the user model and override the books
      final UserModelNotifier userModel = _ref.read(userModelProvider.notifier);
      userModel.setBooks(books);
      
      // Return our books to the caller in case they care
      return Future.value(const Right(books));
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? 'Unknown Firebase Exception'));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception'));
    }
  } 
}