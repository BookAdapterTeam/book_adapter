import 'package:book_adapter/authentication/register_view_controller.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final formKey = GlobalKey<FormState>();

class RegisterView extends ConsumerWidget {
  const RegisterView({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegisterViewData data = ref.watch(registerViewController);
    final RegisterViewController viewController = ref.watch(registerViewController.notifier);

    return Scaffold(
     appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          autovalidateMode: AutovalidateMode.always,
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // TextFormField(
              //   decoration: const InputDecoration( labelText: 'Username' ),
              //   onChanged: (newUsername){
              //     setState(() {
              //       _username = newUsername;
              //     });
              //   },
              //   validator: (username) => validate(string: username, message: "Username can't be empty"),
              // ),
              TextFormField(
                initialValue: data.email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration( labelText: 'Email' ),
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
                onChanged: (newEmailValue) {
                  viewController.updateData(email: newEmailValue);
                },
                onSaved: (newEmailValue) {
                  viewController.updateData(email: newEmailValue);
                },
              ),
              TextFormField(
                initialValue: data.password,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Enter Password'),
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
                onChanged: (newPasswordValue) {
                  viewController.updateData(password: newPasswordValue);
                },
                onSaved: (newPasswordValue) {
                  viewController.updateData(password: newPasswordValue);
                },
              ),
              TextFormField(
                initialValue: data.verifyPassword,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Re-enter Password'),
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
                onChanged: (newVerifyPasswordValue) {
                  viewController.updateData(verifyPassword: newVerifyPasswordValue);
                },
                onSaved: (newVerifyPasswordValue) {
                  viewController.updateData(verifyPassword: newVerifyPasswordValue);
                },
              ),
              ElevatedButton(
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
                    (failure) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          failure is FirebaseFailure
                            ? '${failure.code}: ${failure.message}'
                            : failure.message
                        )
                      )),
                    (user) => Navigator.of(context).pop(),
                  );
                },
              )
            ],
          ),

        )
      )
    );
  }

  String? validate({String? string, required String message}) {
    if (string == null) {
      return null;
    }
    if (string.isEmpty) {
      return message;
    }
  }

}
