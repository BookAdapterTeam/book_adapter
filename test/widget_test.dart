// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:book_adapter/src/app.dart';
import 'package:book_adapter/src/common_widgets/init_widget.dart';
import 'package:book_adapter/src/controller/firebase_controller.dart';
import 'package:book_adapter/src/features/library/presentation/library_view.dart';
import 'package:book_adapter/src/service/firebase_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'service/mock_firebase_service.dart';

final fakeUserChangesProvider =
    StreamProvider.autoDispose.family<User?, MockUser>((ref, mockUser) async* {
  yield mockUser;
});

// Run the following command
// - `flutter test`
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Use the mock firebase service
    final mockUser = MockUser(
      isAnonymous: false,
      uid: 'someuid',
      email: 'bob@somedomain.com',
      displayName: 'Bob',
    );

    final firestoreInstance = FakeFirebaseFirestore();
    await firestoreInstance.collection('books').add({
      'title': 'Altina the Sword Princess: Volume 1',
      'collectionIds': ['3ZHOkntFl5cPSWh9fDPMlsjMwg92-Default'],
      'authors': 'Yukiya Murasakai, himesuz, Roy Nukia, Kieran Redgewell',
      'fileHash': {
        'collectionName': 'Default',
        'filepath':
            '3ZHOkntFl5cPSWh9fDPMlsjMwg92/Altina the Sword Princess Volume 01 Premium-0bdeb40a-fee5-4445-abc5-41b3a278ddc5.epub',
        'md5': '1ede994103977d122b19a8c36a25af72',
        'sha1': '1904965ff25023cb5cc8ec219fc7598f6bbd75fe'
      },
      'filepath':
          '3ZHOkntFl5cPSWh9fDPMlsjMwg92/Altina the Sword Princess Volume 01 Premium-0bdeb40a-fee5-4445-abc5-41b3a278ddc5.epub',
      'filesize': 39507953,
      'finished': false,
      'firebaseCoverImagePath':
          '3ZHOkntFl5cPSWh9fDPMlsjMwg92/Altina the Sword Princess Volume 01 Premium-0bdeb40a-fee5-4445-abc5-41b3a278ddc5.jpg',
      'id': '0bdeb40a-fee5-4445-abc5-41b3a278ddc5',
      'userId': 'someuid',
    });
    await firestoreInstance.collection('collections').add({
      'name': 'Default',
      'id': 'randid',
      'userId': 'someuid',
    });

    final firebaseService = MockFirebaseService(
      auth: MockFirebaseAuth(mockUser: mockUser, signedIn: true),
      firestore: firestoreInstance,
      storage: MockFirebaseStorage(),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseServiceProvider.overrideWithValue(firebaseService),
        providerForInitStream.overrideWithValue(const AsyncData(null)),
        authStateChangesProvider
            .overrideWithProvider(fakeUserChangesProvider(mockUser)),
        userChangesProvider
            .overrideWithProvider(fakeUserChangesProvider(mockUser)),
      ],
      child: const MyApp(),
    ));

    // The first frame is a loading state.
    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'loading');

    // Re-render.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // No-longer loading
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'not loading');
    expect(find.byType(LibraryView), findsOneWidget, reason: 'not loading');

    // Rendered three ListTiles with the data returned by MockFirebaseService
    await tester.pump();
    // print(tester.allWidgets);
    // expect(find.byType(SliverCollectionsList), findsNothing);
    // await tester.pump();
    // expect(find.byType(SliverCollectionsList), findsOneWidget);
  });
}
