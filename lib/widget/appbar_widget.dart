/*
This is the widget for app bar.
AppBar widget is used by each screen page
*/


import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";

//App Bar
AppBar buildAppBar(BuildContext context, String title) {
  final icon = CupertinoIcons.moon_stars;

  return AppBar(
    //Previous page
    leading: BackButton(),
    backgroundColor: Colors.blue,
    elevation: 0,
    title: Text(title),

    //TODO: for different themes i.e. Dark and light theme. 
    actions: [
      IconButton(
        onPressed: () {},
        icon: Icon(icon),
      )
    ],
  );
}
