import 'package:book_adapter/screen/Home/home.dart';
import 'package:book_adapter/widget/passwordfield_widget.dart';
import "package:flutter/material.dart";
import 'package:book_adapter/model/user.dart';
import 'package:book_adapter/utils/user_preferences.dart';
import 'package:book_adapter/widget/appbar_widget.dart';
import 'package:book_adapter/widget/button_widget.dart';
import 'package:book_adapter/widget/profile_widget.dart';
import 'package:book_adapter/widget/textfield_widget.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final String title = "Log In Page";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(context, title),
        body: ListView(
          physics: BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 24),
            TextFieldWidget(
              label: "Email",
              text: "someone@gmail.com",
              onChanged: (email) {},
            ),
            PasswordfieldWidget(
                label: "Password", text: "password", onChanged: (password) {}),
            const SizedBox(height: 24),
            Center(child: buildLogInButton()),
            Center(
              child: const Text(
                  "TODO: develop authentication system. For now you can log in without email and password"
              ),
            )
          ],
        ));
  }

  Widget buildLogInButton() => ButtonWidget(
        text: 'Log In',
        onClicked: () {
          // TODO sign in only if authenticated

          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Home()));
        },
      );
}
