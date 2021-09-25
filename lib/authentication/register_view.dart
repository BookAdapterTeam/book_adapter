import 'package:book_adapter/authentication/register_view_controller.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _formKey = GlobalKey<FormState>();

class RegisterView extends ConsumerWidget {
  const RegisterView({Key? key}) : super(key: key);


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
                TextFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Username' ),
                  onChanged: (usernameValue){
                    viewController.updateData(username: usernameValue);
                  },
                  validator: (username) => validate(string: username, message: "Username can't be empty"),
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 8,),
                TextFormField(
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
                ),
                const SizedBox(height: 8,),
                TextFormField(
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
                ),
                const SizedBox(height: 8,),
                TextFormField(
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
                      (failure) {
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
                )
              ],
            ),
      
          )
        ),
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
