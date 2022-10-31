import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../profile_view_controller.dart';

class LogOutButton extends ConsumerWidget {
  const LogOutButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
        key: const ValueKey('signOut'),
        icon: const Icon(
          Icons.logout,
          color: Colors.redAccent,
        ),
        label: Text(
          'Sign out',
          style: Theme.of(context).textTheme.button?.copyWith(color: Colors.redAccent),
        ),
        onPressed: () {
          // Log out the user
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Are you sure you want to sign out?'),
              content: const Text(
                'Downloaded books will remain on your device.',
              ),
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
                    ref.read(profileViewController.notifier).signOut();
                  },
                  child: Text(
                    'YES, LOGOUT',
                    style: DefaultTextStyle.of(context).style.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
