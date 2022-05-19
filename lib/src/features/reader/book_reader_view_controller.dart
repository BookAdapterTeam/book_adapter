import 'package:book_adapter/src/data/failure.dart';
import 'package:book_adapter/src/shared/controller/firebase_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

final readerViewControllerProvider =
    StateNotifierProvider.autoDispose<ReaderViewController, ReaderViewData>(
        (ref) {
  final data = ReaderViewData();
  return ReaderViewController(ref.read, data: data);
});

// State is if the view is loading
class ReaderViewController extends StateNotifier<ReaderViewData> {
  ReaderViewController(this._read, {required ReaderViewData data})
      : super(data);

  final Reader _read;
  final log = Logger();

  Future<Failure?> saveLastReadLocation(
    String cfi, {
    required String bookId,
  }) async {
    final firebaseController = _read(firebaseControllerProvider);
    try {
      await firebaseController.saveLastCfiLocation(cfi: cfi, bookId: bookId);
      return null;
    } on FirebaseException catch (e, st) {
      log.e(e.message ?? e.toString(), e, st);
      return Failure(e.message ?? e.toString());
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      return Failure(e.toString());
    }
  }
}

class ReaderViewData {}
