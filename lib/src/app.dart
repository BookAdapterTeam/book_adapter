import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_extension/i18n_widget.dart';

import 'features/authentication/presentation/auth_checker.dart';
import 'features/in_app_update/util/toast_utils.dart';
import 'features/initialization/presentation/init_widget.dart';
import 'features/initialization/presentation/update_checker.dart';
import 'features/library/presentation/library_view.dart';
import 'features/library/presentation/series_view.dart';
import 'features/profile/change_password_view.dart';
import 'features/profile/edit_profile_view.dart';
import 'features/profile/profile_view.dart';
import 'features/reader/book_reader_view.dart';

/// The Widget that configures your application.
class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool ignoreUpdate = false;

  @override
  Widget build(BuildContext context) => ToastUtils.init(
        child: MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',
          title: 'BookAdapter',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'), // English
          ],
          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          // home: I18n(child: const LibraryView()),
          onGenerateRoute: (RouteSettings routeSettings) => MaterialPageRoute<void>(
            settings: routeSettings,
            builder: (BuildContext context) {
              final Widget page;
              switch (routeSettings.name) {
                case ProfileView.routeName:
                  page = const ProfileView(key: ValueKey('profile_view'));
                  break;
                case EditProfileView.routeName:
                  page = const EditProfileView(key: ValueKey('edit_profile_view'));
                  break;
                case ChangePasswordView.routeName:
                  page = const ChangePasswordView(key: ValueKey('change_password_view'));
                  break;
                case BookReaderView.routeName:
                  page = const BookReaderView(key: ValueKey('book_item_details'));
                  break;
                case SeriesView.routeName:
                  page = const SeriesView(key: ValueKey('series_view'));
                  break;
                case LibraryView.routeName:
                default:
                  page = const LibraryView(key: ValueKey('library_view'));
              }

              return I18n(
                key: const ValueKey('I18n Initialization'),
                child: UpdateChecker(
                  ignoreUpdate: ignoreUpdate,
                  onIgnore: () {
                    ignoreUpdate = true;
                  },
                  onClose: () {
                    ignoreUpdate = true;
                  },
                  child: InitWidget(
                    key: const ValueKey('Initialize App'),
                    child: AuthChecker(child: page),
                  ),
                ),
              );
            },
          ),
        ),
      );
}
