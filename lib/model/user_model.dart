import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userModelProvider = StateNotifierProvider<UserModelNotifier, UserData>((ref) {
  final userStreamAsyncValue = ref.watch(userChangesProvider);
  final user = userStreamAsyncValue.data?.value;
  
  final userData = UserData(currentUser: user);

  return UserModelNotifier(userData);
});

class UserModelNotifier extends StateNotifier<UserData> {
  UserModelNotifier(UserData data) : super(data);

  // Put functions here using copyWith to change data

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], [idTokenChanges] or [userChanges] to
  /// subscribe to updates.
  User? get currentUser {
    return state.currentUser;
  }

  // Update UserData with new list of books
  void setBooks(List<BookItem> books) {
    state = state.copyWith(books: books);
  }
}