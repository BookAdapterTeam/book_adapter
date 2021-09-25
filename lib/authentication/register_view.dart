import 'package:book_adapter/authentication/register_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final formKey = GlobalKey<FormState>();

class RegisterView extends ConsumerWidget {
  const RegisterView({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegisterViewData data = ref.read(registerViewController);
    final RegisterViewController viewController = ref.watch(registerViewController.notifier);

    return Scaffold(
         appBar: AppBar(),
        body: Container(
            padding: const EdgeInsets.all(25.0),
            child: Form(
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
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration( labelText: 'Email' ),
                    validator: (value) {
                      if (value == null) {
                        return null;
                      }
                      if (value.isEmpty) {
                        return 'Please Enter an Email';
                      }
                      if (!RegExp('^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]').hasMatch(value)) {
                        return 'Please use a valid Email';
                      }
                      return null;
                    },
                    onChanged: (newEmailValue) {
                      viewController.updateData(email: newEmailValue);
                    },
                  ),
                  TextFormField(
                    initialValue: data.password,
                    decoration: const InputDecoration(labelText: 'Enter Password'),
                    obscureText: true,
                    // validator: (value)=> value!.isEmpty ?'password can\'t be empty': null,
                    //onSaved: (value)=> _password1=value!,
                    onChanged: (newPasswordValue) {
                      viewController.updateData(password: newPasswordValue);
                    },
                  ),
                  TextFormField(
                    initialValue: data.verifyPassword,
                    decoration: const InputDecoration(labelText: 'Re-enter Password'),
                    obscureText: true,
                    // validator: (value)=> value!.isEmpty ?'password can\'t be empty': null,
                    // onSaved: (value)=> _password2=value!
                    onChanged: (newPasswordValue) {
                      viewController.updateData(verifyPassword: newPasswordValue);
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Register', style: TextStyle(fontSize: 20.0)),
                    onPressed: () => viewController.register(),
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
