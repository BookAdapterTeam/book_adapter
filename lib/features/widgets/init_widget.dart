import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../controller/firebase_controller.dart';
import '../../controller/storage_controller.dart';
import '../../data/constants.dart';
import '../../service/storage_service.dart';
import '../in_app_update/update.dart';
import '../in_app_update/util/toast_utils.dart';

final providerForInitStream = StreamProvider<String?>((ref) async* {
  yield 'Initializing Firebase...';
  await Firebase.initializeApp().timeout(const Duration(seconds: 5));
  yield 'Initializing Local Database...';
  await ref.watch(storageServiceProvider).init();
  yield null;
  unawaited(ref.read(storageControllerProvider).startBookUploads());
});

class InitWidget extends ConsumerWidget {
  const InitWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  Widget buildLoading(String? message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              key: ValueKey(message ?? ''),
              switchInCurve: Curves.easeInCubic,
              switchOutCurve: Curves.easeOutCubic,
              duration: kTransitionDuration,
              child: Text(message ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(providerForInitStream);
    final log = Logger();

    return asyncValue.map(
      data: (asyncData) {
        String? message = asyncData.value;
        if (message == null) {
          final userStreamAsyncValue = ref.watch(authStateChangesProvider);
          final user = userStreamAsyncValue.asData?.value;
          message = 'Authenticating...';
          if (user != null) return child;
        }

        return buildLoading(message);
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
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                AnimatedSwitcher(
                  key: ValueKey('Loading...'),
                  switchInCurve: Curves.easeInCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  duration: kTransitionDuration,
                  child: Text('Loading...'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UpdateChecker extends StatefulWidget {
  const UpdateChecker({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  _UpdateCheckerState createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  final _updateUrl = 'https://www.bookadapter.com/update/update.json';

  @override
  void initState() {
    super.initState();
    UpdateManager.checkUpdate(context, _updateUrl);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
