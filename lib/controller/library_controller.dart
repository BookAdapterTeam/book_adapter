import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:dartz/dartz.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The list of books
final bookListProvider = FutureProvider<List<Book>>((ref) async {
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
 
  Future<Either<Failure, List<Book>>> fetchBooks() async {
    // Make service call and inject results into the model
    final Either<Failure, List<Book>> res = await _ref.read(firebaseControllerProvider).getBooks();
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
 
  Future<Either<Failure, List<Book>>> addBooks() async {
    // Make storage service call to pick books
    final sRes = await _ref.read(storageServiceProvider).pickFile(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      allowMultiple: true,
      withReadStream: true,
    );

    return sRes.fold(
      (failure) => Left(failure),
      (platformFiles) async {
        final List<Book> uploadedBooks = [];
        for (final file in platformFiles) {
          // Add book to firebase
          final Either<Failure, Book> fRes = await _ref.read(firebaseControllerProvider).addBook(file);
          fRes.fold((failure) => null, (book) => uploadedBooks.add(book));
        }
        return Right(uploadedBooks);
      }
    );


  }

  
}