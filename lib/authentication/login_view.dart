
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/auth/login_view_controller.dart';
import 'package:book_adapter/features/auth/register_view.dart';
import 'package:book_adapter/features/auth/reset_password_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _formKey= GlobalKey<FormState>();

class LoginView extends ConsumerWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(loginViewController);
    final viewController = ref.watch(loginViewController.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('BookAdapter'),),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(35.0),
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 1/9,),
                Center(
                  child: Text('Login', style: Theme.of(context).textTheme.headline3,),
                ),
                const SizedBox(height: 60,),
                TextFormField(
                  initialValue: data.email,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email/Username' ),
                  validator: (email) => viewController.validateEmail(email),
                  onChanged: (email){
                    viewController.updateData(email: email);
                  },
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 8,),
                TextFormField(
                  initialValue: data.password,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Password'),
                  onChanged: (password){
                    viewController.updateData(password: password);
                  },
                  obscureText: true,
                  validator: (password) => viewController.validatePassword(password),
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 4,),
                ElevatedButton(
                  child: const Text('Login', style: TextStyle(fontSize: 20.0), ),
                  onPressed: () async {
                    final res = await viewController.login();
                    res.fold(
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
                      (user) => null,
                    );
                  }
                ),
                ElevatedButton(
                  child: const Text('Signup', style: TextStyle(fontSize: 20.0)),
                  onPressed : (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterView())
                    );
                  }
                ),
                TextButton(
                  child: const Text('Reset Password', style: TextStyle(fontSize: 12.0)),
                  onPressed : (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResetPasswordView()),
                    );
                  }
                ),
              ],
            ),
          )
        ),
      )
    );
  }
}

