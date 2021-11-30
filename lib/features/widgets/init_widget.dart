import 'package:book_adapter/features/in_app_update/update.dart';
import 'package:book_adapter/features/in_app_update/util/toast_utils.dart';
import 'package:book_adapter/features/widgets/async_value_widget.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class InitFirebaseWidget extends ConsumerWidget {
  const InitFirebaseWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Future<FirebaseApp> _initialization =
        Firebase.initializeApp().timeout(const Duration(seconds: 5));
    final log = Logger();
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (BuildContext context, AsyncSnapshot<FirebaseApp> snapshot) {
        if (snapshot.hasError) {
          log.e('Warning: Running in Offline Mode', snapshot.error,
              snapshot.stackTrace);
          ToastUtils.waring(
            'Warning: Running in Offline Mode - ${snapshot.error.toString()}',
          );
          return child;
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return child;
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class InitStorageServiceWidget extends ConsumerWidget {
  const InitStorageServiceWidget({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(storageServiceInitProvider);
    final log = Logger();

    return AsyncValueWidget(
      value: asyncValue,
      data: (_) => child,
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) {
        log.e(e.toString(), e, st);
        return Scaffold(
          body: Center(
            child: Text(
              e.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headline6!
                  .copyWith(color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}

class InitDownloadedFilesWidget extends ConsumerWidget {
  const InitDownloadedFilesWidget({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(updateDownloadedFilesProvider);
    final log = Logger();

    return AsyncValueWidget(
      value: asyncValue,
      data: (_) => child,
      loading: () => child,
      error: (e, st) {
        log.e(e.toString(), e, st);
        ToastUtils.error(e.toString());
        return child;
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

final hiveInitFutureProvider = FutureProvider<void>((ref) async {
  await Hive.initFlutter('BookAdapterData');
});

class InitHiveWidget extends ConsumerWidget {
  const InitHiveWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(hiveInitFutureProvider);
    final log = Logger();

    return AsyncValueWidget(
      value: asyncValue,
      data: (_) => child,
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) {
        log.e(e.toString(), e, st);
        return Scaffold(
          body: Center(
            child: Text(
              e.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headline6!
                  .copyWith(color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
