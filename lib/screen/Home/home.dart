import 'package:book_adapter/app.dart';
import 'package:book_adapter/main.dart';
import 'package:book_adapter/screen/authenticate/sign_in.dart';
import 'package:book_adapter/screen/profile/profile.dart';
import 'package:flutter/material.dart';

import 'package:book_adapter/screen/Home/home.dart';
import 'package:book_adapter/widget/appbar_widget.dart';
import 'package:book_adapter/widget/button_widget.dart';
import "package:flutter/material.dart";

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final String title = "Home Page";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(context, title),
        body: ListView(
          physics: BouncingScrollPhysics(),
          children: [
           
            Center(child: buildLibraryButton()),
            const SizedBox(height: 24),
           
            Center(child: buildProfileButton()),
            const SizedBox(height: 24),

            Center(child: buildLogOutButton()),
            const SizedBox(height: 24),
            Center(
                child: Text(
                    "TODO: Build Home page which is a page through which we navigate each features")),
          ],
        ));
  }

  Widget buildProfileButton() => ButtonWidget(
        text: 'Profile Page',
        onClicked: () {
          // TODO sign in only if authenticated

          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfilePage()));
        },
      );

    Widget buildLibraryButton() => ButtonWidget(
        text: 'Library',
        onClicked: () {
          // TODO sign in only if authenticated

          Navigator.push(
              context, MaterialPageRoute(builder: (context) => MyApp()));
        },
      );
    Widget buildLogOutButton() => ButtonWidget(
        text: 'LogOut',
        onClicked: () {
          // TODO sign in only if authenticated

          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SignIn()));
        },
      );
}
