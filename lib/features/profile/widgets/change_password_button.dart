import 'package:flutter/material.dart';

import '../change_password_view.dart';

class ChangePasswordButton extends StatelessWidget {
  const ChangePasswordButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.password),
      label: Text(
        'Change Password',
        style: Theme.of(context).textTheme.button?.copyWith(
              color: Theme.of(context).buttonTheme.colorScheme?.primary,
            ),
      ),
      onPressed: () {
        Navigator.restorablePushNamed(context, ChangePasswordView.routeName);
      },
    );
  }
}
