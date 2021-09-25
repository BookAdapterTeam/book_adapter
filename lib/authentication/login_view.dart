import 'package:book_adapter/authentication/register_view.dart';
import 'package:book_adapter/authentication/restart_pass.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class LoginView extends StatefulWidget{
  const LoginView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class _LoginPageState extends State<LoginView>{
  //final AuthService _auth =AuthService();
   String _email='';
   String _password='';

  final formKey= GlobalKey<FormState>();


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
                   // validator: (value)=> value!.isEmpty ?'Email can\'t be empty': null,
                    onChanged: (value){
                      setState(() {
                        _email=value;

                      });

                    },

                   //  validator: (value)=> value!.isEmpty ?'Email can\'t be empty': null,
                   //  onSaved: (value)=> _email=value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    onChanged: (value){
                      setState(() {
                        _password=value;

                      });

                    },
                    obscureText: true,
                   // validator: (value)=> value!.isEmpty ?'password can\'t be empty': null,
                    // onSaved: (value)=> _password=value!,
                  ),
                  ElevatedButton(
                    child: const Text('Login', style: TextStyle(fontSize: 20.0), ),

                    onPressed: () async {
                      print(_email);
                      print(_password);
                    }
                  ),
                  ElevatedButton(

                    child:
                    const Text('Signup', style: TextStyle(fontSize: 20.0) ),
                    onPressed : (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterView())
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

