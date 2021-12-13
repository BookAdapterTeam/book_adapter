
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../library/data/book_item.dart';

final currentBookProvider = StateProvider<Book?>((_) {
  return null;
});