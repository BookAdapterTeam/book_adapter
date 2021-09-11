import 'package:book_adapter/commands/base_command.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/book_item.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final refreshCommandProvider = Provider<RefreshBooksCommand>((ref) {
  return RefreshBooksCommand(ref);
});

class RefreshBooksCommand extends BaseCommand {
  RefreshBooksCommand(ProviderRef ref) : super(ref);

 
  Future<Either<Failure, List<BookItem>>> run() async {
    // Make service call and inject results into the model
    
    try {
      // TODO: Implement Firebase call
      // final List<BookItem> books = await firebaseService.getBooks();
      const List<BookItem> books = [
        BookItem(name: 'Book 0', id: '0'),
        BookItem(name: 'Book 1', id: '1'),
        BookItem(name: 'Book 2', id: '2'),
      ];
      userModelNotifier.setBooks(books);
       
      // Return our posts to the caller in case they care
      return Future.value(const Right(books));
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? 'Unknown Firebase Exception'));
    }
  } 
}