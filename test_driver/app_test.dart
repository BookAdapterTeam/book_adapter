import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

// Launch an emulator, then run the following command
// `flutter drive --target=test_driver/app.dart`

// Writing integration tests documentation
// https://flutter.dev/docs/cookbook/testing/integration/introduction
void main() {
  group('BookAdapter App', () {
    // First, define the Finders and use them to locate widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys

    // final settingsButtonFinder = find.byValueKey('settings');
    // final refreshButtonFinder = find.byValueKey('refresh');

    late FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      await driver.close();
    });

    // TODO: Add tests for navigating app routes (e.g.: Library -> Library Details -> Book Reader)
  });
}
