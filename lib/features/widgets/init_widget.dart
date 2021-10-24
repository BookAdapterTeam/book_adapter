import 'package:book_adapter/service/storage_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InitFirebase extends StatelessWidget {
  const InitFirebase({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();
    return FutureBuilder(
      future: _initialization,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Firebase Initialization Failed'),
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

class InitStorageService extends ConsumerWidget {
  const InitStorageService({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(storageServiceProvider).init(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Storage Initialization Failed'),
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
