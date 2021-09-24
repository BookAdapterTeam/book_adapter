import 'package:book_adapter/authentication/register_user.dart';
import 'package:book_adapter/authentication/restart_pass.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class login_page extends StatefulWidget{


  State<StatefulWidget> createState() => _LoginPageState();
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
  void validateandsubmmit() async{
    if(validateAndSave()){
      try {
         // FirebaseUser user = await FirebaseAuth.instance
         //    .signInWithEmailAndPassword(email: _email, password: _password);
        print('Signed in:'); //  ${user.uid}');
      }
      catch(e){
        print('Error: $e');
      }

    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("login"),
        ),
        body: Container(
            padding: EdgeInsets.all(25.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration( labelText: "Email" ),
                    validator: (value)=> value!.isEmpty ?'Email can\'t be empty': null,
                    onSaved: (value)=> _email=value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (value)=> value!.isEmpty ?'password can\'t be empty': null,
                    onSaved: (value)=> _password=value!,
                  ),
                  ElevatedButton(
                    child: const Text('Login', style: TextStyle(fontSize: 20.0)),
                    onPressed: validateAndSave,
                  ),
                  ElevatedButton(
                    child: const Text('Signup', style: TextStyle(fontSize: 20.0)),
                    onPressed : (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => register_user())
                      );
                    }
                  ),
                  ElevatedButton(
                    child: const Text('Reset Password', style: TextStyle(fontSize: 20.0)),
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

