// Handles profile page information

import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/profile/edit_profile_view.dart';
import 'package:book_adapter/features/profile/widgets/change_password_button.dart';
import 'package:book_adapter/features/profile/widgets/log_out_button.dart';
import 'package:book_adapter/features/profile/widgets/profile_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info/package_info.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({Key? key}) : super(key: key);

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(userChangesProvider);
    final user = userStreamAsyncValue.asData?.value;
    const String title = 'Profile Page';

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              final packageInfo = await PackageInfo.fromPlatform();
              final version = packageInfo.version;
              showAboutDialog(
                context: context,
                applicationName: 'BookAdapter',
                applicationVersion: version,
                applicationIcon: const FlutterLogo(),
                applicationLegalese:
                    '(Temporary logo above) By using this app, you agree to only use it with books you own.',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                const SizedBox(height: 64),
                /*user.photoURL != null
                  ? */
                ProfileWidget(
                  photoUrl: user.photoURL ?? 'https://i.imgur.com/WxNkK7J.png',
                  onPressed: () {
                    Navigator.restorablePushNamed(
                        context, EditProfileView.routeName);
                  },
                ) /*: const Icon(Icons.account_circle, size: 128,)*/,
                const SizedBox(height: 24),
                const _NameWidget(),
                const SizedBox(height: 64),
                const ChangePasswordButton(),
                const LogOutButton(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _NameWidget extends ConsumerWidget {
  const _NameWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(userChangesProvider);
    final user = userStreamAsyncValue.asData?.value;
    return user != null
        ? Center(
            child: Column(
              children: [
                if (user.displayName != null) ...[
                  Text(
                    user.displayName!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 40),
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
          )
        : const SizedBox();
  }
}
