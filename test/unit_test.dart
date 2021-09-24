import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth', () {
    test('Test Login', () async {
      // Sign in.
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'someuid',
        email: 'bob@somedomain.com',
        displayName: 'Bob',
      );
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final result = await auth.signInWithEmailAndPassword(email: 'bob@somedomain.com', password: 'password');
      final user = result.user;
      // ignore: avoid_print
      print(user?.displayName ?? 'Not logged in');
    });

    // TODO: Test signup

    // TODO: Test logout
  });
}