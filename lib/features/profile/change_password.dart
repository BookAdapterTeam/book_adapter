//Handles password change action

import 'package:book_adapter/features/profile/widgets/button_widget.dart';
import 'package:book_adapter/features/profile/widgets/passwordfield_widget.dart';
import 'package:book_adapter/features/profile/widgets/profile_widget.dart';
import 'package:book_adapter/model/user.dart';
import 'package:book_adapter/utils/user_preferences.dart';
import 'package:flutter/material.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  User user = UserPreferences.myUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Change Password'),),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 24),
            ProfileWidget(
                imagePath: user.imagePath,
                isEdit: true,
                onClicked: () async {}),
            const SizedBox(height: 24),
            PasswordfieldWidget(
              label: 'Old Password',
              text: user.name,
              onChanged: (name) {},
            ),
            const SizedBox(height: 24),
            PasswordfieldWidget(
              label: 'New Password',
              text: user.email,
              onChanged: (email) {},
            ),
            const SizedBox(height: 24),
            Center(child: submitButton()),
          ],
        ));
  }

  Widget submitButton() => ButtonWidget(
    text: 'Submit',
    onClicked: () {
      // TODO Save password
    });
}
