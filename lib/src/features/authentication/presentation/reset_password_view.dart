import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../constants/constants.dart';
import '../../../shared/data/failure.dart';
import '../controller/reset_password_view_controller.dart';

final _formKey = GlobalKey<FormState>();

class ResetPasswordView extends ConsumerWidget {
  const ResetPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(resetPasswordViewController);
    final viewController = ref.watch(resetPasswordViewController.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Title and description
                SizedBox(
                  height: MediaQuery.of(context).size.height * 1 / 9,
                ),
                Center(
                  child: Text(
                    'Send Reset Email',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Center(
                  child: Text(
                    'Enter the email linked to your account',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),

                // Email text field
                _EmailTextField(
                  data: data,
                  viewController: viewController,
                ),
                const SizedBox(
                  height: 8,
                ),

                // Send reset email button
                _SendResetEmailButton(
                  viewController: viewController,
                  data: data,
                ),

                // Cancel button
                const _CancelButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => TextButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kCornerRadius),
            ),
          ),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      );
}

class _SendResetEmailButton extends StatelessWidget {
  const _SendResetEmailButton({
    Key? key,
    required this.viewController,
    required this.data,
  }) : super(key: key);

  final ResetPasswordViewController viewController;
  final ResetPasswordViewData data;

  @override
  Widget build(BuildContext context) {
    final log = Logger();
    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kCornerRadius),
          ),
        ),
      ),
      onPressed: () async {
        final res = await viewController.sendResetEmail();
        res.fold(
          (failure) {
            log.e(failure.message);
            final snackBar = SnackBar(
              content: Text(failure is FirebaseFailure
                  ? '${failure.code}: ${failure.message}'
                  : failure.message),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
          (succcess) {
            final snackBar = SnackBar(
              content: Text('''
Reset email was sent to ${data.email} from noreply@bookadapter.firebaseapp.com'''),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
        );
      },
      child: const Text('Send Email'),
    );
  }
}

class _EmailTextField extends StatelessWidget {
  const _EmailTextField({
    Key? key,
    required this.data,
    required this.viewController,
  }) : super(key: key);

  final ResetPasswordViewData data;
  final ResetPasswordViewController viewController;

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: data.email,
        autofocus: true,
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          labelText: 'Email',
        ),
        validator: viewController.validate,
        onChanged: (emailValue) => viewController.updateData(email: emailValue),
        autofillHints: const [AutofillHints.email],
      );
}
