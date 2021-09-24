import 'package:book_adapter/controller/library_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryViewController =
    StateNotifierProvider<LibraryViewController, bool>((ref) {
  return LibraryViewController(ref.read);
});

// State is if the view is loading
class LibraryViewController extends StateNotifier<bool> {
  LibraryViewController(this._read) : super(false);

  final Reader _read;

  refreshBooks() async {
    state = true;
    await _read(libraryControllerProvider).fetchBooks();
    state = false;
  }
}