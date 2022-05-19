import 'package:book_adapter/src/exceptions/app_exception.dart';
import 'package:book_adapter/src/features/auth/data/user_data.dart';
import 'package:book_adapter/src/features/library/data/book_item.dart';
import 'package:book_adapter/src/model/queue_model.dart';
import 'package:book_adapter/src/shared/controller/firebase_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userModelProvider =
    StateNotifierProvider.autoDispose<UserModel, UserData>((ref) {
  final books = ref.watch(bookStreamProvider);
  final userData = UserData(books: books.asData?.value);

  return UserModel(ref.read, userData);
});

class UserModel extends StateNotifier<UserData> {
  UserModel(this._read, UserData data) : super(data);

  final Reader _read;

  /// Qeue a new book download
  void queueDownload(Book book) {
    final downloadQueueNotifier = _read(queueBookProvider.notifier);
    // Queue download
    downloadQueueNotifier.addToQueue(book);
  }

  List<Book> get downloadQueue {
    return _read(queueBookProvider).queueListItems;
  }

  Future<void> updateDownloadedFilenames() async {
    final firebaseController = _read(firebaseControllerProvider);

    final String? userId = firebaseController.currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }
  }
}
