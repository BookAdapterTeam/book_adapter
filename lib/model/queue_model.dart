import 'dart:async';
import 'dart:collection';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

import '../controller/storage_controller.dart';
import '../features/library/data/book_item.dart';
import '../features/library/data/item.dart';

/// A queue that will process the items in the queue
/// whenever it is not empty
final queueBookProvider = StateNotifierProvider.autoDispose<QueueNotifier<Book>,
    QueueNotifierData<Book>>((ref) {
  final storageController = ref.read(storageControllerProvider);
  final data = QueueNotifierData<Book>(
    queueListItems: [],
    queue: Queue(),
  );

  return QueueNotifier<Book>(
    data: data,
    processItem: (book) async => await storageController.downloadFile(
      book,
      whenDone: (filename) async {
        await ref.read(storageControllerProvider).setFileDownloaded(filename);
      },
    ),
  );
});

/// A queue utility class that can be of any type
///
/// Arguments:
/// - `processItem` A function that takes an argument of
/// the same type as the class and runs code using it,
/// such as downloading a file and saving it to the device.
class QueueNotifier<T extends Item>
    extends StateNotifier<QueueNotifierData<T>> {
  QueueNotifier({
    required QueueNotifierData<T> data,
    required this.processItem,
  }) : super(data);

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
    log.i(
        'Updated Book Queue: ${state.queueListItems.map((item) => item.title)}');

    // Start downloading
    if (isEmpty) process();
  }

  /// Process the items in the queue
  Future<void> process() async {
    // Do not call process() while it is already running
    if (processing) return;

    processing = true;
    while (state.queue.isNotEmpty) {
      log.i(
          'Current Book Queue: ${state.queueListItems.map((item) => item.title)}');

      // Process the item, for example: download a file
      // and save to device storage
      final item = state.queue.removeFirst();
      log.i('Processing Book: ${item.title}');
      await processItem(item);

      // Remove from the list after processing
      state.queueListItems.remove(item);
    }
    log.i('Book Queue is empty');
    processing = false;
  }
}

class QueueNotifierData<T> {
  /// Items are removed right before processing starts
  final Queue<T> queue;

  /// Items either in the queue or currently being processed
  final List<T> queueListItems;

  QueueNotifierData({required this.queue, required this.queueListItems});

  QueueNotifierData<T> copyWith({
    Queue<T>? queue,
    List<T>? queueListItems,
  }) {
    return QueueNotifierData<T>(
      queue: queue ?? this.queue,
      queueListItems: queueListItems ?? this.queueListItems,
    );
  }
}
