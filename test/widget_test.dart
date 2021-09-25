// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:book_adapter/app.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'mock_firebase_service.dart';

// Run the following command
// - `flutter test`
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final container = ProviderContainer();
    final firebaseService = container.read(fakeFirebaseServiceProvider);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        firebaseServiceProvider.overrideWithValue(firebaseService),
      ],
      child: const MyApp(),
    ));



    // The first frame is a loading state.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Re-render. libraryControllerProvider should have finished fetching the books by now
    await tester.pump();

    // No-longer loading
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Rendered three ListTiles with the data returned by MockFirebaseService
    expect(tester.widgetList(find.byType(ListTile)), [
      isA<ListTile>(),
      isA<ListTile>(),
      isA<ListTile>(),
    ]);
  });
}
