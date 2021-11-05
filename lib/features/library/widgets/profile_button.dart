import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/profile/profile_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class ProfileButton extends ConsumerWidget {
  const ProfileButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(userChangesProvider);
    final log = Logger();
    return userStreamAsyncValue.when(
      data: (user) {
        return IconButton(
          tooltip: 'Account Details',
          key: const ValueKey('profile'),
          icon: user != null
                ? _userLoggedIn(user)
                : const Icon(Icons.account_circle),
          onPressed: () {
            // Navigate to the settings page. If the user leaves and returns
            // to the app after it has been killed while running in the
            // background, the navigation stack is restored.
            Navigator.restorablePushNamed(context, ProfileView.routeName);
          },
        );
      },
      loading: () => IconButton(
          key: const ValueKey('profile'),
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.restorablePushNamed(context, ProfileView.routeName);
          },
        ),
      error: (e, st) {
        log.e('Error getting user data', e, st);
        return IconButton(
          key: const ValueKey('profile'),
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.restorablePushNamed(context, ProfileView.routeName);
          },
        );
      },
    );
  }

  Widget _userLoggedIn(User user) {
    return user.photoURL != null 
        ? CircleAvatar(
          backgroundImage:
            NetworkImage(user.photoURL!),
          backgroundColor: Colors.grey,
        )
        : const Icon(Icons.account_circle);
  }
}