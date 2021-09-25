import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

// Launch an emulator, then run the following command
// `flutter drive --target=test_driver/app.dart`
void main() {
  group('BookAdapter App', () {
    // First, define the Finders and use them to locate widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys

    // final refreshLoadingIndicatorFinder = find.byValueKey('loading_refresh');
    // final booksLoadingIndicatorFinder = find.byValueKey('loading_books');
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

    // Add tests here, example tests are below

    // test('starts at 0', () async {
    //   // Use the `driver.getText` method to verify the counter starts at 0.
    //   expect(await driver.getText(counterTextFinder), "0");
    // });

    // test('increments the counter', () async {
    //   // First, tap the button.
    //   await driver.tap(buttonFinder);

    //   // Then, verify the counter text is incremented by 1.
    //   expect(await driver.getText(counterTextFinder), "1");
    // });

    // test('increments the counter during animation', () async {
    //   await driver.runUnsynchronized(() async {
    //     // First, tap the button.
    //     await driver.tap(buttonFinder);

    //     // Then, verify the counter text is incremented by 1.
    //     expect(await driver.getText(counterTextFinder), "1");
    //   });
    // });
  });
}