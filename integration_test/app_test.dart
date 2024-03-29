import 'package:book_adapter/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Launch an emulator, then run the following command
// `flutter test integration_test`

// Writing integration tests documentation
// https://flutter.dev/docs/cookbook/testing/integration/introduction
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('find the loading text', (tester) async {
      app.main();
      await tester.pump();
      expect(find.text('Loading...'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
