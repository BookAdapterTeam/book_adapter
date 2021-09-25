# BookAdapter - ePub Reader & Library Management

A new Flutter app built for android for reading ePub books.

Documentation is in the "docs" folder.

## Architecture

This project uses riverpod state management with MVC+S architecture.

> Domain Logic (rules around data storage, manipulation, and validation) and Application Logic (what your application actually does. How it behaves.) You also find that:

Domain Logic naturally belongs in the Model tier.

Application Logic naturally belongs in the Controller tier.

Model – Holds the state of the application and provides an API to access/filter/manipulate that data. Its concern is data encapsulation and management. It contains logic to structure, validate or compare different pieces of data that we call Domain Logic. It also notifies the view of any changes in the data.

View – Views are all the Widgets and Pages within the Flutter Application. These views may contain a "view controller" themselves, but that is still considered part of the view application tier.

ViewController - A controller that handles UI state changes due to user interaction. ViewController makes calls on other controllers, it does not touch the model directly. If the view needs to handle UI state changes due to user interaction, use a view controller to manage and hold the state.

Controller – Contains the applications logic. They are used to complete any significant action within the app. Controllers managing UI state should be separated as a ViewController

Services – Services fetch data from the outside world, and return it to the app. Controllers call on services and inject the results into the model. Services do not touch the model directly.

Source: [gskinner](https://blog.gskinner.com/archives/2020/09/flutter-state-management-with-mvcs.html)

[Example Usage](https://github.com/jpoh281/riverpod_mvcs_counter)

[Read about Riverpod](https://codewithandrea.com/videos/flutter-state-management-riverpod/)

## Setup

1. Clone the repo
2. Install Flutter
3. Open the project in VSCode, install the Flutter plugin
4. Run "flutter pub get" in terminal or press the button when prompted by VSCode
5. Setup Firebase for the app with analytics enabled, [tutorial here](https://firebase.google.com/docs/flutter/setup?platform=android)
   - If you need to connect to the official Firebase backend, contact @getBoolean for the (iOS) GoogleService-Info.plist or (Android) google-services.json. It is not guarenteed you will be given access.
6. Enable Email login in Firebase console "Authentication"
7. ...

## Testing

### Unit tests and widget tests

Run the following command

- `flutter test`

### Integration tests

Launch an emulator, then run the following command

- `flutter drive --target=test_driver/app.dart`

## Contributing

1. Choose an existing issue to fix/implement
2. Fork the 'main' branch and give it a relevant name
3. Implemement your changes. Do not make more changes than necessary
4. Resolve all linter problems (other than todos). It cannot merge otherwise
5. Open a Pull Request from your branch to main
6. The PR can be merged by an Admin if there are no issues

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
