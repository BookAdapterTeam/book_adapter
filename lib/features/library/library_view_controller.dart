import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/controller/library_controller.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/shelf.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryViewController = StateNotifierProvider<LibraryViewController, LibraryViewData>((ref) {
  final bookStreamProvider = ref.watch(firebaseControllerProvider).bookStreamProvider;
  final books = ref.watch(bookStreamProvider);
  final data = LibraryViewData(books: books.data?.value ?? []);
  return LibraryViewController(ref.read, data: data);
});

// State is if the view is loading
class LibraryViewController extends StateNotifier<LibraryViewData> {
  LibraryViewController(this._read, {required LibraryViewData data}) : super(data);

  final Reader _read;

  Future<String?> addBooks() async {
    final res = await _read(libraryControllerProvider).addBooks();
    return res.fold(
      (failure) => failure.message,
      (_) {}
    );
  }

  Future<void> signOut() async {
    await _read(firebaseControllerProvider).signOut();
  }
}

class LibraryViewData {
  final bool isLoading;
  final List<Book> books;
  final List<Shelf> shelves;
  LibraryViewData({
    this.isLoading = false,
    this.books = const [],
    this.shelves = const [],
  });

  LibraryViewData copyWith({
    bool? isLoading,
    List<Book>? books,
    List<Shelf>? shelves,
  }) {
    return LibraryViewData(
      isLoading: isLoading ?? this.isLoading,
      books: books ?? this.books,
      shelves: shelves ?? this.shelves,
    );
  }
}
