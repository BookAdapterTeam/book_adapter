import 'dart:async';
import 'dart:io';

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

final storageControllerProvider =
    Provider.autoDispose<StorageController>((ref) {
  final firebaseController = ref.watch(firebaseControllerProvider);
  final storageService = ref.watch(storageServiceProvider);

  return StorageController(
    firebaseController: firebaseController,
    storageService: storageService,
  );
});

class StorageController {
  StorageController({
    required FirebaseController firebaseController,
    required StorageService storageService,
  })  : _firebaseController = firebaseController,
        _storageService = storageService;

  final FirebaseController _firebaseController;
  final StorageService _storageService;
  final log = Logger();

  void downloadFile(Book book,
      {required FutureOr<void> Function(String) whenDone}) {
    final appBookAdaptPath = _storageService.appBookAdaptPath;
    final task = _firebaseController.downloadFile(
        book.filepath, '$appBookAdaptPath/${book.filepath}');
    // ignore: unawaited_futures
    task.whenComplete(() async => await whenDone(book.filename));
  }

  List<String> getDownloadedFilenames() {
    final String? userId = _firebaseController.currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    try {
      final filesPaths = _storageService.listFiles(userId: userId);
      return filesPaths.map((file) {
        return file.path.split('/').last;
      }).toList();
    } on FileSystemException catch (e, st) {
      log.e(e.message, e, st);
      return [];
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return [];
    }
  }
}
