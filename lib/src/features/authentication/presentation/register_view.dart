import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../shared/data/failure.dart';
import '../controller/register_view_controller.dart';
import '../data/register_view_data.dart';

class RegisterView extends ConsumerWidget {
  RegisterView({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registerViewController);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Register Account'),
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Form(
                autovalidateMode: AutovalidateMode.always,
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 1 / 9,
                      ),
                      // TODO: Add pfp image picker, upload to Firebase Storage

                      // Enter username
                      _UsernameTextField(data: data),
                      const SizedBox(
                        height: 8,
                      ),

                      // Enter email
                      _EmailTextField(data: data),
                      const SizedBox(
                        height: 8,
                      ),

                      // Enter password
                      _PasswordTextField(data: data),
                      const SizedBox(
                        height: 8,
                      ),

                      // Enter password again
                      _VerifyPasswordTextField(data: data),

                      // Submit
                      _RegisterButton(data: data)
                    ],
                  ),
                ),
              )),
        ));
  }
}

class _RegisterButton extends ConsumerWidget {
  const _RegisterButton({
    Key? key,
    required this.data,
  }) : super(key: key);

  final RegisterViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = Logger();
    return ElevatedButton(
      style: !data.isButtonEnabled
          ? ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.black38))
          : null,
      onPressed: () async {
        if (!data.isButtonEnabled) {
          return;
        }

        final res = await ref.read(registerViewController.notifier).register();
        return res.fold(
          (failure) {
            log.e(failure.message);
            final snackBar = SnackBar(
                content: Text(failure is FirebaseFailure
                    ? '${failure.code}: ${failure.message}'
                    : failure.message));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
          (user) => Navigator.of(context).pop(),
        );
      },
      child: const Text('Register', style: TextStyle(fontSize: 20.0)),
    );
  }
}

class _VerifyPasswordTextField extends ConsumerWidget {
  const _VerifyPasswordTextField({
    Key? key,
    required this.data,
  }) : super(key: key);

  final RegisterViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFormField(
        initialValue: data.verifyPassword,
        keyboardType: TextInputType.text,
        decoration:
            const InputDecoration(border: OutlineInputBorder(), labelText: 'Re-enter Password'),
        obscureText: true,
        validator: (verifyPassword) {
          if (verifyPassword == null) {
            return null;
          }
          if (verifyPassword.isEmpty) {
            return 'Verify password field is empty';
          }
          if (verifyPassword != data.password) {
            return 'Passwords are not the same';
          }

          return null;
        },
        onChanged: (verifyPasswordValue) {
          ref.read(registerViewController.notifier).updateData(verifyPassword: verifyPasswordValue);
        },
        autofillHints: const [AutofillHints.password],
        textInputAction: TextInputAction.done,
      );
}

class _PasswordTextField extends ConsumerWidget {
  const _PasswordTextField({
    Key? key,
    required this.data,
  }) : super(key: key);

  final RegisterViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFormField(
        initialValue: data.password,
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Password'),
        obscureText: true,
        validator: (passwordValue) {
          if (passwordValue == null) {
            return null;
          }
          if (passwordValue.isEmpty) {
            return 'Password cannot be empty';
          }

          if (passwordValue.length < 6) {
            return 'Password must be 6 or more characters';
          }

          return null;
        },
        onChanged: (passwordValue) {
          ref.read(registerViewController.notifier).updateData(password: passwordValue);
        },
        autofillHints: const [AutofillHints.password],
        onEditingComplete: TextInput.finishAutofillContext,
        textInputAction: TextInputAction.next,
      );
}

class _EmailTextField extends ConsumerWidget {
  const _EmailTextField({
    Key? key,
    required this.data,
  }) : super(key: key);

  final RegisterViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFormField(
        initialValue: data.email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email'),
        validator: (email) {
          if (email == null) {
            return null;
          }
          if (email.isEmpty) {
            return 'Please Enter an Email';
          }
          if (!EmailValidator.validate(email)) {
            return 'Please use a valid email';
          }
          return null;
        },
        onChanged: (emailValue) {
          ref.read(registerViewController.notifier).updateData(email: emailValue);
        },
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
      );
}

class _UsernameTextField extends ConsumerWidget {
  const _UsernameTextField({
    Key? key,
    required this.data,
  }) : super(key: key);

  final RegisterViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFormField(
        initialValue: data.username,
        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Username'),
        onChanged: (usernameValue) {
          ref.read(registerViewController.notifier).updateData(username: usernameValue);
        },
        validator: (username) => ref
            .read(registerViewController.notifier)
            .validate(string: username, message: "Username can't be empty"),
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username],
      );
}
