// Handles profile page information

import 'package:book_adapter/model/user.dart';
import 'package:book_adapter/screen/Home/home.dart';
import 'package:book_adapter/screen/authenticate/sign_in.dart';
import 'package:book_adapter/screen/profile/change_password.dart';
import 'package:book_adapter/screen/profile/edit_profile_page.dart';
import 'package:book_adapter/utils/user_preferences.dart';
import 'package:book_adapter/widget/appbar_widget.dart';
import 'package:book_adapter/widget/button_widget.dart';
import 'package:book_adapter/widget/profile_widget.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = UserPreferences.myUser;
    final String title = "Profile Page";

    return Scaffold(
        appBar: buildAppBar(context, title),
        body: ListView(
          physics: BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 24),
            ProfileWidget(
              imagePath: user.imagePath,
              onClicked: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => EditProfilePage()));
              },
            ),
            const SizedBox(height: 24),
            // buildName(user),
            const SizedBox(height: 24),
            Center(child: buildLogOutButton()),
            const SizedBox(height: 24),
            Center(child: ChangePasswordButton()),
          ],
        ));
  }

  Widget buildName(User user) => Column(
        children: [
          Text(
            user.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            user.email,
            style: TextStyle(color: Colors.grey, fontSize: 25),
          ),
        ],
      );

  Widget buildLogOutButton() => ButtonWidget(
        text: 'Log Out',
        onClicked: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SignIn()));
        },
      );

  Widget ChangePasswordButton() => ButtonWidget(
        text: 'Change Password',
        onClicked: () {
          // TODO sign in only if authenticated

          Navigator.push(context,
              MaterialPageRoute(builder: (context) => ChangePassword()));
        },
      );
}
//
