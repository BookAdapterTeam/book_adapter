//Handles password change action

import 'package:book_adapter/src/features/authentication/presentation/reset_password_view.dart';
import 'package:flutter/material.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({Key? key}) : super(key: key);

  static const routeName = '/changePassword';
  @override
  Widget build(BuildContext context) {
    return const ResetPasswordView();
  }
}
