import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/auth/register_view_controller.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class RegisterView extends ConsumerWidget {
  RegisterView({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegisterViewData data = ref.watch(registerViewController);
    final RegisterViewController viewController = ref.watch(registerViewController.notifier);

    return Scaffold(
     appBar: AppBar(title: const Text('Register Account'),),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            autovalidateMode: AutovalidateMode.always,
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 1/9,),
                // TODO: Add image picker for profile image, upload to Firebase Storage

                // Enter username
                _UsernameTextField(data: data, viewController: viewController),
                const SizedBox(height: 8,),
                
                // Enter email
                _EmailTextField(data: data, viewController: viewController),
                const SizedBox(height: 8,),
                
                // Enter password
                _PasswordTextField(data: data, viewController: viewController),
                const SizedBox(height: 8,),
                
                // Enter password again
                _VerifyPasswordTextField(data: data, viewController: viewController),
                
                // Submit
                _RegisterButton(data: data, viewController: viewController)
              ],
            ),
      
          )
        ),
      )
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({
    Key? key,
    required this.data,
    required this.viewController,
  }) : super(key: key);

  final RegisterViewData data;
  final RegisterViewController viewController;

  @override
  Widget build(BuildContext context) {
    final log = Logger();
    return ElevatedButton(
      child: const Text('Register', style: TextStyle(fontSize: 20.0)),
      style: !data.isButtonEnabled ? ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.black38)
      ) : null,
      onPressed: () async {
        if (!data.isButtonEnabled) {
          return;
        }
      
        final res = await viewController.register();
        return res.fold(
          (failure) {
            log.e(failure.message);
            final snackBar = SnackBar(
              content: Text(
                failure is FirebaseFailure
                  ? '${failure.code}: ${failure.message}'
                  : failure.message
              )
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
          (user) => Navigator.of(context).pop(),
        );
      },
    );
  }
}

class _VerifyPasswordTextField extends StatelessWidget {
  const _VerifyPasswordTextField({
    Key? key,
    required this.data,
    required this.viewController,
  }) : super(key: key);

  final RegisterViewData data;
  final RegisterViewController viewController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: data.verifyPassword,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Re-enter Password'),
      obscureText: true,
      // Validator is kinda broken for this one when stopping typing even though it matches
      // validator: (verifyPassword) {
      //   if (verifyPassword == null) {
      //     return null;
      //   }
      //   if (verifyPassword != data.verifyPassword) {
      //     return 'Passwords are not the same';
      //   }
      // },
      onChanged: (verifyPasswordValue) {
        viewController.updateData(verifyPassword: verifyPasswordValue);
      },
      autofillHints: const [AutofillHints.password],
    );
  }
}

class _PasswordTextField extends StatelessWidget {
  const _PasswordTextField({
    Key? key,
    required this.data,
    required this.viewController,
  }) : super(key: key);

  final RegisterViewData data;
  final RegisterViewController viewController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: data.password,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Enter Password'),
      obscureText: true,
      validator: (passwordValue){
        if (passwordValue == null) {
          return null;
        }
        if (passwordValue.isEmpty) {
          return 'Password cannot be empty';
        }
      
        if (passwordValue.length < 6) {
          return 'Password must be 6 or more characters';
        }
      },
      onChanged: (passwordValue) {
        viewController.updateData(password: passwordValue);
      },
      autofillHints: const [AutofillHints.password],
    );
  }
}

class _EmailTextField extends StatelessWidget {
  const _EmailTextField({
    Key? key,
    required this.data,
    required this.viewController,
  }) : super(key: key);

  final RegisterViewData data;
  final RegisterViewController viewController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: data.email,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email' ),
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
        viewController.updateData(email: emailValue);
      },
      autofillHints: const [AutofillHints.email],
    );
  }
}

class _UsernameTextField extends StatelessWidget {
  const _UsernameTextField({
    Key? key,
    required this.data,
    required this.viewController,
  }) : super(key: key);

  final RegisterViewData data;
  final RegisterViewController viewController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: data.username,
      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Username' ),
      onChanged: (usernameValue){
        viewController.updateData(username: usernameValue);
      },
      validator: (username) => viewController.validate(string: username, message: "Username can't be empty"),
      autofillHints: const [AutofillHints.username],
    );
  }
}
