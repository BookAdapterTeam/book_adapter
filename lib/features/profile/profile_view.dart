// Handles profile page information

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/profile/change_password_view.dart';
import 'package:book_adapter/features/profile/edit_profile_view.dart';
import 'package:book_adapter/features/profile/profile_view_controller.dart';
import 'package:book_adapter/features/profile/widgets/profile_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({Key? key}) : super(key: key);

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(firebaseControllerProvider).currentUser;
    const String title = 'Profile Page';

    // final isLoading = ref.watch(profileViewController);
    // final viewController = ref.watch(profileViewController.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        actions: const [
          _LogOutButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ... [
                const SizedBox(height: 64),
                /*user.photoURL != null
                  ? */ProfileWidget(
                    photoUrl: user.photoURL ?? 'https://i.imgur.com/WxNkK7J.png',
                    onPressed: () {
                      Navigator.restorablePushNamed(context, EditProfileView.routeName);
                    },
                  )
                  /*: const Icon(Icons.account_circle, size: 128,)*/,
                const SizedBox(height: 24),
                const _NameWidget(),
                const SizedBox(height: 64),
                const ChangePasswordButton(),
              ]
            ],
          ),
        ),
      )
    );
  }
}

class _LogOutButton extends ConsumerWidget {
  const _LogOutButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewController = ref.watch(profileViewController.notifier);
    return IconButton(
      key: const ValueKey('signOut'),
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
      onPressed: () {
        // Log out the user
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(ModalRoute.withName('/'));
                    viewController.signOut();
                  },
                  child: const Text('LOGOUT'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ChangePasswordButton extends StatelessWidget {
  const ChangePasswordButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Change Password'),
      onPressed: () {
        Navigator.restorablePushNamed(context, ChangePasswordView.routeName);
      },
    );
  }
}

class _NameWidget extends ConsumerWidget {
  const _NameWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseController = ref.watch(firebaseControllerProvider);
    final user = firebaseController.currentUser;
    return user != null ? Center(
      child: Column(
        children: [
          if (user.displayName != null) ... [
            Text(
              user.displayName!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
            ),
            const SizedBox(
              height: 4,
            ),
          ],
          Text(
            user.email ?? 'Signed in anonymously',
            style: const TextStyle(color: Colors.grey, fontSize: 25),
          ),
        ],
      ),
    ) : const SizedBox();
  }
}
