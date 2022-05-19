import 'package:book_adapter/src/features/authentication/controller/login_view_controller.dart';
import 'package:book_adapter/src/features/authentication/presentation/register_view.dart';
import 'package:book_adapter/src/features/authentication/presentation/reset_password_view.dart';
import 'package:book_adapter/src/shared/data/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class LoginView extends ConsumerWidget {
  LoginView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(loginViewController);

    return Scaffold(
        appBar: AppBar(
          title: const Text('BookAdapter'),
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Padding(
              padding: const EdgeInsets.all(35.0),
              child: Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 1 / 9,
                      ),
                      // Page title
                      const _LoginTitleText(),
                      const SizedBox(
                        height: 60,
                      ),

                      // Enter email
                      _EmailTextField(data: data),
                      const SizedBox(
                        height: 8,
                      ),

                      // Enter password
                      _PasswordTextField(data: data),
                      const SizedBox(
                        height: 4,
                      ),

                      const _LoginButton(),
                      const _SignupButton(),
                      const _ResetPasswordButton(),
                    ],
                  ),
                ),
              )),
        ));
  }
}

class _LoginTitleText extends StatelessWidget {
  const _LoginTitleText({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Login',
        style: Theme.of(context).textTheme.headline3,
      ),
    );
  }
}

class _EmailTextField extends ConsumerWidget {
  const _EmailTextField({
    Key? key,
    required this.data,
  }) : super(key: key);

  final LoginViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      initialValue: data.email,
      decoration: const InputDecoration(
          border: OutlineInputBorder(), labelText: 'Email'),
      validator: (email) =>
          ref.read(loginViewController.notifier).validateEmail(email),
      onChanged: (email) {
        ref.read(loginViewController.notifier).updateData(email: email);
      },
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
    );
  }
}

class _PasswordTextField extends ConsumerWidget {
  const _PasswordTextField({
    Key? key,
    required this.data,
  }) : super(key: key);

  final LoginViewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextFormField(
      initialValue: data.password,
      decoration: const InputDecoration(
          border: OutlineInputBorder(), labelText: 'Password'),
      onChanged: (password) {
        ref.read(loginViewController.notifier).updateData(password: password);
      },
      obscureText: true,
      validator: (password) =>
          ref.read(loginViewController.notifier).validatePassword(password),
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      onEditingComplete: TextInput.finishAutofillContext,
    );
  }
}

class _LoginButton extends ConsumerWidget {
  const _LoginButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = Logger();
    return ElevatedButton(
        child: const Text(
          'Login',
          style: TextStyle(fontSize: 20.0),
        ),
        onPressed: () async {
          final res = await ref.read(loginViewController.notifier).login();
          res.fold(
            (failure) {
              log.e(failure.message);
              final snackBar = SnackBar(
                  content: Text(failure is FirebaseFailure
                      ? '${failure.code}: ${failure.message}'
                      : failure.message));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            (user) => null,
          );
        });
  }
}

class _ResetPasswordButton extends StatelessWidget {
  const _ResetPasswordButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        child: const Text('Reset Password', style: TextStyle(fontSize: 12.0)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResetPasswordView()),
          );
        });
  }
}

class _SignupButton extends StatelessWidget {
  const _SignupButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        child: const Text('Signup', style: TextStyle(fontSize: 20.0)),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => RegisterView()));
        });
  }
}
