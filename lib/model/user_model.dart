import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/user_data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userModelProvider = StateNotifierProvider<UserModelNotifier, UserData>((ref) {
  const userData = UserData(
    books: [],
  );

  return UserModelNotifier(userData);
});

class UserModelNotifier extends StateNotifier<UserData> {
  UserModelNotifier(UserData data) : super(data);

  // Put functions here using copyWith to change data

  // TODO: Add functions such as currentUser for authentication

  // Update UserData with new list of books
  void setBooks(List<BookItem> books) {
    state = state.copyWith(books: books);
  }
}