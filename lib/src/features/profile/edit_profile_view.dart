// Handles Profile edit action

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

import '../../constants/constants.dart';
import '../../shared/controller/firebase_controller.dart';
import 'edit_profile_view_controller.dart';
import 'widgets/profile_widget.dart';

class EditProfileView extends HookConsumerWidget {
  const EditProfileView({Key? key}) : super(key: key);

  static const routeName = '/editProfile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(userChangesProvider);
    final user = userStreamAsyncValue.asData?.value;
    final usernameController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // TODO: Will never show since there is no way to set the photo
              if (user != null && user.photoURL != null) ...[
                ProfileWidget(photoUrl: user.photoURL!, onPressed: () async {}),
                const SizedBox(height: 24),
              ],
              TextField(
                restorationId: 'change_username',
                controller: usernameController,
                autofocus: true,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Change Username',
                ),
                onChanged: (usernameValue) {
                  ref.read(editProfileViewController.notifier).updateData(username: usernameValue);
                },
              ),
              const SizedBox(height: 24),

              // TODO: Add change email. Will need to ask for current password
              // TextFieldWidget(
              //   label: 'Email',
              //   text: user.email ?? 'Signed in anonymously',
              //   onChanged: (email) {
              //   },
              // ),
              const _SubmitButton()
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends ConsumerStatefulWidget {
  const _SubmitButton({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __SubmitButtonState();
}

class __SubmitButtonState extends ConsumerState<_SubmitButton> {
  @override
  Widget build(BuildContext context) {
    final log = Logger();
    final data = ref.watch(editProfileViewController);
    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kCornerRadius),
          ),
        ),
      ),
      onPressed: () async {
        final success = await ref.read(editProfileViewController.notifier).submit();
        if (!mounted) return;

        if (!success) {
          const errorMessage = 'Updating Userdata Failed';
          log.e(errorMessage);
          const snackBar = SnackBar(content: Text(errorMessage));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          Navigator.of(context).pop();
          final message = 'Updated Username to ${data.username}';
          log.i(message);
          final snackBar = SnackBar(content: Text(message));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      },
      child: const Text('Submit'),
    );
  }
}
