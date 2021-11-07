import 'package:book_adapter/features/in_app_update/update.dart';
import 'package:book_adapter/features/widgets/async_value_widget.dart';
import 'package:book_adapter/service/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InitFirebaseWidget extends ConsumerWidget {
  const InitFirebaseWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();
    return FutureBuilder(
      future: _initialization,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Firebase Initialization Failed: ${snapshot.error}'),
            ),
          );
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

class InitStorageWidget extends ConsumerWidget {
  const InitStorageWidget({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(storageInitProvider);

    return AsyncValueWidget(
      value: asyncValue,
      data: (_) => child,
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) {
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
