import 'package:book_adapter/data/user_data.dart';
import 'package:book_adapter/features/library/book_item.dart';
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

  // Update UserData with new list of books
  void setBooks(List<BookItem> books) {
    state = state.copyWith(books: books);
  }
}