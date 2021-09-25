// Handles profile page information

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/profile/change_password.dart';
import 'package:book_adapter/features/profile/edit_profile_page.dart';
import 'package:book_adapter/utils/user_preferences.dart';
import 'package:book_adapter/widget/appbar_widget.dart';
import 'package:book_adapter/widget/button_widget.dart';
import 'package:book_adapter/widget/profile_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({Key? key}) : super(key: key);

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(firebaseControllerProvider).currentUser;
    // final user = UserPreferences.myUser;
    const String title = 'Profile Page';

    return Scaffold(
      appBar: buildAppBar(context, title),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          if (user != null) ... [
            const SizedBox(height: 24),
            if (user.photoURL != null) ... [
              ProfileWidget(
                imagePath: user.photoURL!,
                onClicked: () {
                  Navigator.restorablePushNamed(context, EditProfileView.routeName);
                },
              ),
              const SizedBox(height: 24),
            ],
            Center(child: _NameWidget(user: user)),
            const SizedBox(height: 24),
            const Center(child: SignOutButton()),
            const SizedBox(height: 24),
            const Center(child: ChangePasswordButton()),
          ]
        ],
      )
    );
  }
}

class ChangePasswordButton extends StatelessWidget {
  const ChangePasswordButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonWidget(
          text: 'Change Password',
          onClicked: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ChangePassword()));
          },
        );
  }
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonWidget(
      text: 'Log Out',
      onClicked: () {
        Navigator.of(context).pop();
        // TODO: Call logout function
      },
    );
  }
}

class _NameWidget extends StatelessWidget {
  const _NameWidget({
    Key? key,
    required this.user
  }) : super(key: key);
  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
//
