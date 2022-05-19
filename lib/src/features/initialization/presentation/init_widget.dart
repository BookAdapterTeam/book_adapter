import 'package:book_adapter/firebase_options.dart';
import 'package:book_adapter/src/features/in_app_update/util/toast_utils.dart';
import 'package:book_adapter/src/features/initialization/presentation/loading_page.dart';
import 'package:book_adapter/src/service/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

final providerForInitStream = StreamProvider.autoDispose<String?>((ref) async* {
  yield* _initStream(ref);
});

// TODO: Refactor to use AsyncValue with StateNotifier
Stream<String?> _initStream(Ref ref) async* {
  yield 'Initializing Firebase...';

  // FlutterFire setup: https://firebase.flutter.dev/docs/cli/
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); //.timeout(const Duration(seconds: 5));

  yield 'Initializing Local Database...';
  await ref.watch(storageServiceProvider).init();

  yield null;
}

class InitWidget extends ConsumerWidget {
  const InitWidget({
    Key? key,
    required this.child,
    this.loading,
  }) : super(key: key);

  final Widget child;

  /// Page to show when loading. You should include a Scaffold.
  final Widget Function(String message)? loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(providerForInitStream);
    final log = Logger();

    return asyncValue.map(
      data: (asyncData) {
        final String? message = asyncData.value;
        // Done loading when null is sent
        if (message == null) {
          return child;
        }

        return loading?.call(message) ?? LoadingPage(message: message);
      },
      error: (asyncError) {
        final error = asyncError.error;
        final stackTrace = asyncError.stackTrace;
        if (error is FirebaseException) {
          log.e(
            'Warning: Running in Offline Mode\n'
            '${error.code} - ${error.message}',
            error,
            stackTrace,
          );
          ToastUtils.warning(
            'Warning: Running in Offline Mode',
          );
          return child;
        }

        if (error is MissingPlatformDirectoryException) {
          log.e('${error.message} $error', error, stackTrace);
          return Scaffold(
            body: Center(
              child: Text(
                error.message,
                style: Theme.of(context)
                    .textTheme
                    .headline6!
                    .copyWith(color: Colors.red),
              ),
            ),
          );
        }

        if (error is HiveError) {
          log.e('${error.message} $error', error, stackTrace);
          return Scaffold(
            body: Center(
              child: Text(
                error.message,
                style: Theme.of(context)
                    .textTheme
                    .headline6!
                    .copyWith(color: Colors.red),
              ),
            ),
          );
        }

        log.e(error.toString(), error, stackTrace);
        return Scaffold(
          body: Center(
            child: Text(
              error.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headline6!
                  .copyWith(color: Colors.red),
            ),
          ),
        );
      },
      loading: (loading) {
        return const LoadingPage(message: 'Loading...');
      },
    );
  }
}
