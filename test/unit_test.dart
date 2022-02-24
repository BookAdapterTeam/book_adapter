import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'service/mock_firebase_service.dart';

class MockUserCredential extends Mock implements UserCredential {}

class MockitoFirebaseAuth extends Mock implements FirebaseAuth {}

// Run the following command
// - `flutter test`
void main() {
  // TODO: Fix broken tests, all tests don't currently work
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
      final firebaseService = MockFirebaseService(
        auth: MockFirebaseAuth(mockUser: mockUser),
        firestore: FakeFirebaseFirestore(),
        storage: MockFirebaseStorage(),
      );

      // Mock sign in.
      final userCred = await firebaseService.signIn(
              email: 'bob@somedomain.com', password: 'password');
      
      expect(
          userCred.isRight(),
          true);
    });

    // TODO: Test signup
    // FirebaseAuth mock does not support mocking creating a user,
    // need to figure out another solution to test

    test('Test Logout', () async {
      // Use the mock firebase service logged in
      final firebaseService = MockFirebaseService(
        auth: MockFirebaseAuth(signedIn: true),
        firestore: FakeFirebaseFirestore(),
        storage: MockFirebaseStorage(),
      );

      // Mock sign out
      await firebaseService.signOut();
    });
  });
}
