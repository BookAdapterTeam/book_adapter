import 'dart:async';
import 'dart:collection';

import 'package:book_adapter/controller/storage_controller.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/model/user_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

/// A queue that will process the items in the queue
/// whenever it is not empty
final queueBookProvider = StateNotifierProvider.autoDispose<QueueNotifier<Book>,
    QueueNotifierData<Book>>((ref) {
  final storageController = ref.read(storageControllerProvider);
  final userModel = ref.read(userModelProvider.notifier);
  final data = QueueNotifierData<Book>(queueListItems: [], queue: Queue());

  return QueueNotifier(
    data: data,
    processItem: (book) => storageController.downloadFile(
      book,
      whenDone: (filename) => userModel.addDownloadedFilename(filename),
    ),
  );
});

/// A queue utility class that can be of any type
///
/// Arguments:
/// - `processItem` A function that takes an argument of
/// the same type as the class and runs code using it,
/// such as downloading a file and saving it to the device.
class QueueNotifier<T> extends StateNotifier<QueueNotifierData<T>> {
  QueueNotifier({required QueueNotifierData<T> data, required this.processItem})
      : super(data);

  bool processing = false;
  final log = Logger();

  /// A function that takes an item of the specified type
  /// and runs code using it.
  final FutureOr<void> Function(T) processItem;

  /// Add an item to the queue immediately
  void addToQueue(T item) {
    final bool isEmpty = state.queue.isEmpty;
    state.queue.add(item);
    state.queueListItems.add(item);

    // Start downloading
    if (isEmpty) process();
  }

  /// Process the items in the queue
  Future<void> process() async {
    // Do not call process() while it is already running
    if (processing) return;

    processing = true;
    while (state.queue.isNotEmpty) {
      log.i('\nCurrent ${T.toString()} Queue: ${state.queueListItems}');

      // Process the item, for example: download a file
      // and save to device storage
      final item = state.queue.removeFirst();
      log.i('Processing ${T.toString()}: ${item.toString()}');
      await processItem(item);

      // Remove from the list after processing
      state.queueListItems.remove(item);
    }
    log.i('\n${T.toString()} Queue is empty\n');
    processing = false;
  }
}

class QueueNotifierData<T> {
  /// Items are removed right before processing starts
  final Queue<T> queue;

  /// Items either in the queue or currently being processed
  final List<T> queueListItems;

  QueueNotifierData({required this.queue, required this.queueListItems});
}
