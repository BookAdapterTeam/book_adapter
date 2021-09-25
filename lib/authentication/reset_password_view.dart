import 'package:book_adapter/authentication/reset_password_view_controller.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


final _formKey= GlobalKey<FormState>();

class ResetPasswordView extends ConsumerWidget {
  const ResetPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(resetPasswordViewController);
    final viewController = ref.watch(resetPasswordViewController.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'),),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 1/9,),
                Center(
                  child: Text('Send Reset Email', style: Theme.of(context).textTheme.headline5,),
                ),
                const SizedBox(height: 16,),
                Center(
                  child: Text('Enter the email linked to your account', style: Theme.of(context).textTheme.bodyText2,),
                ),
                const SizedBox(height: 20,),
                // Email text field
                TextFormField(
                  initialValue: data.email,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email' ),
                  validator: (email) => viewController.validate(email),
                  onChanged: (emailValue) => viewController.updateData(email: emailValue),
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 8,),
                // Send reset email button
                ElevatedButton(
                  child: const Text('Send Email', style: TextStyle(fontSize: 20.0)),
                  onPressed : () async {
                    final res = await viewController.sendResetEmail();
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
                      (succcess) {
                        final snackBar = SnackBar(
                          content: Text('Reset email was sent to ${data.email} from noreply@bookadapter.firebaseapp.com')
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    );
                    
                  }
                ),
      
                // Cancel button
                TextButton(
                  child: const Text('Cancel', style: TextStyle(fontSize: 20.0)),
                  onPressed : () {
                    Navigator.of(context).pop();
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

