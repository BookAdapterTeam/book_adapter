//Handles password change action

import 'package:flutter/material.dart';

import '../authentication/presentation/reset_password_view.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({Key? key}) : super(key: key);

  static const routeName = '/changePassword';
  @override
  Widget build(BuildContext context) => const ResetPasswordView();
}
