import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../controller/storage_controller.dart';
import '../../data/constants.dart';
import '../../firebase_options.dart';
import '../../service/storage_service.dart';
import '../in_app_update/update.dart';
import '../in_app_update/util/toast_utils.dart';

final providerForInitStream = StreamProvider<String?>((ref) async* {
  yield 'Initializing Firebase...';
  // FlutterFire setup: https://firebase.flutter.dev/docs/cli/
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); //.timeout(const Duration(seconds: 5));
  yield 'Initializing Local Database...';
  await ref.watch(storageServiceProvider).init();
  yield null;
  // TODO(@getBoolean): Move to home so it only starts when user is logged in
  if (ref.read(storageControllerProvider).loggedIn) {
    unawaited(ref.read(storageControllerProvider).startBookUploadsFromStoredQueue());
  }
});

class InitWidget extends ConsumerWidget {
  const InitWidget({
    Key? key,
    required this.child,
    this.loading,
  }) : super(key: key);

  final Widget child;

  /// Page to show when loading. You should include a Scaffold.
  ///
  /// When `message` is null, the
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

        return loading?.call(message) ?? _LoadingPage(message: message);
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
        return const _LoadingPage(message: 'Loading...');
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            _LoadingMessageWidget(message: message),
          ],
        ),
      ),
    );
  }
}

class _LoadingMessageWidget extends StatelessWidget {
  const _LoadingMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      key: ValueKey(message),
      switchInCurve: Curves.easeInCubic,
      switchOutCurve: Curves.easeOutCubic,
      duration: kTransitionDuration,
      child: Text(message),
    );
  }
}

class UpdateChecker extends StatefulWidget {
  const UpdateChecker({
    Key? key,
    required this.child,
    this.ignoreUpdate = false,
    required this.onIgnore,
    required this.onClose,
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onIgnore;
  final VoidCallback? onClose;
  final bool ignoreUpdate;

  @override
  _UpdateCheckerState createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  final _updateUrl = 'https://www.bookadapter.com/update/update.json';

  @override
  void initState() {
    super.initState();
    if (!widget.ignoreUpdate) {
      UpdateManager.checkUpdate(
        context,
        _updateUrl,
        widget.onIgnore,
        widget.onClose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
