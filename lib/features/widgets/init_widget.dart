import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class InitWidget extends StatelessWidget {
  const InitWidget({Key? key, required this.child}) : super(key: key);

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
