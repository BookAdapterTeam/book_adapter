import 'package:book_adapter/features/profile/profile_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LogOutButton extends ConsumerWidget {
  const LogOutButton({
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
                  child: Text(
                    'LOGOUT',
                    style: DefaultTextStyle.of(context).style.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).errorColor,
                        ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
