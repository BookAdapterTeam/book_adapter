import 'package:book_adapter/src/features/library/data/book_item.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final currentBookProvider = StateProvider<Book?>((_) {
  return null;
});
