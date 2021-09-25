import 'package:book_adapter/authentication/homepage.dart';
import 'package:book_adapter/authentication/register_user.dart';
import 'package:book_adapter/authentication/restart_pass.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class login_page extends StatefulWidget{


  State<StatefulWidget> createState() => _LoginPageState();
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class _LoginPageState extends State<login_page>{
  late String _email;
  late String _password;

  final formKey= GlobalKey<FormState>();
  bool  validateAndSave()
  {
    final form= formKey.currentState;
    if(form!.validate()){
      form.save();
      return true;
    }
    return false;
  }
  void validateandsubmmit() {
    if(validateAndSave()){
      try {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => homepage()));
      }
      catch(e){
        print('Error: $e');
      }

    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(),
        body: Container(

            padding: EdgeInsets.all(35.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration( labelText: 'Email' ),
                    validator: (value)=> value!.isEmpty ?'Email can\'t be empty': null,
                    onSaved: (value)=> _email=value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value)=> value!.isEmpty ?'password can\'t be empty': null,
                    onSaved: (value)=> _password=value!,
                  ),
                  ElevatedButton(
                    child: const Text('Login', style: TextStyle(fontSize: 20.0), ),

                    onPressed: validateAndSave,
                  ),
                  ElevatedButton(

                    child:
                    const Text('Signup', style: TextStyle(fontSize: 20.0) ),
                    onPressed : (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => register_user())
                      );
                    }
                  ),
                  ElevatedButton(
                    child: const Text('Reset Password', style: TextStyle(fontSize: 12.0)),
                      onPressed : (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => restart_pass())
                        );
                      }
                  ),
                ],
              ),

            )
        )
    );
  }

}

