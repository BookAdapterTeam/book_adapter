import 'package:book_adapter/app.dart';
import 'package:book_adapter/screen/authenticate/sign_in.dart';
import 'package:book_adapter/screen/profile/edit_profile_page.dart';
import 'package:book_adapter/screen/profile/profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  await init();
  runApp(const ProviderScope(child: App()));
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

//just for test so ignore
class App extends StatelessWidget {
  const App({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue.shade300,
      ),
      home: SignIn(),
      
    );
  }
}




