# BookAdapter - ePub Reader & Library Management

A new Flutter project built for android. This project uses riverpod state management with MVC+S architecture.

Model – Holds the state of the application and provides an API to access/filter/manipulate that data. Its concern is data encapsulation and management. It contains logic to structure, validate or compare different pieces of data that we call Domain Logic. It also notifies the view of any changes in the data.

View – Views are all the Widgets and Pages within the Flutter Application. These views may contain a "view controller" themselves, but that is still considered part of the view application tier.

ViewController - A controller that handles UI state changes due to user interaction. ViewController makes calls on other controllers, it does not touch the model directly. If the view needs to handle UI state changes due to user interaction, use a view controller to manage and hold the state.

Controller – Contains the applications logic. They are used to complete any significant action within the app. Controllers managing UI state should be separated as a ViewController

Services – Services fetch data from the outside world, and return it to the app. Controllers call on services and inject the results into the model. Services do not touch the model directly.

Source: gskinner

[Example Usage](https://github.com/jpoh281/riverpod_mvcs_counter)

[Read about Riverpod](https://codewithandrea.com/videos/flutter-state-management-riverpod/)

Documentation is in the "docs" folder.

## Setup

Add your Google services file from Firebase to your app, [tutorial here](https://firebase.google.com/docs/flutter/setup?platform=ios)

If you need to connect to the official Firebase backend, contact @getBoolean for the GoogleService-Info.plist and google-services.json

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
