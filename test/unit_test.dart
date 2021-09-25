import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'mock_firebase_service.dart';
class MockUserCredential extends Mock implements UserCredential {}
class MockitoFirebaseAuth extends Mock implements FirebaseAuth {}

// Run the following command
// - `flutter test`
void main() {
  group('Auth', () {
    test('Test Login', () async {
      // Set up mock user account
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'someuid',
        email: 'bob@somedomain.com',
        displayName: 'Bob',
      );

      // Use the mock firebase service
      final firebaseService = MockFirebaseService(firebaseAuth: MockFirebaseAuth(mockUser: mockUser));
      final container = ProviderContainer(
        overrides: [
          firebaseServiceProvider.overrideWithValue(firebaseService),
        ],
      );
      final firebaseController = container.read(firebaseControllerProvider);

      // Mock sign in.
      expect(
        await firebaseController.signIn(email: 'bob@somedomain.com', password: 'password'),
        Right(mockUser)
      );
    });

    // TODO: Test signup
    // FirebaseAuth mock does not support mocking creating a user, need to figure out another solution to test

    test('Test Logout', () async {
      // Use the mock firebase service logged in
      final firebaseService = MockFirebaseService(firebaseAuth: MockFirebaseAuth(signedIn: true));
      final container = ProviderContainer(
        overrides: [
          firebaseServiceProvider.overrideWithValue(firebaseService),
        ],
      );
      final firebaseController = container.read(firebaseControllerProvider);

      // Mock sign out
      await firebaseController.signOut();
    });
  });
}