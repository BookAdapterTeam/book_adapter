import 'package:book_adapter/features/profile/change_password_view.dart';
import 'package:flutter/material.dart';

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