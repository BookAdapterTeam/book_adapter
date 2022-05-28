An admin command-line application for Appwrite

# Setup

- Copy `.env.example` and rename it to `.env`
- Change `VALUE` to your appwrite key with scopes for everything
- Run `dart run build_runner build`
- If you ever change the key in the `.env` file, run:

```dart
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```
