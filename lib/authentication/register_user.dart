import 'package:flutter/material.dart';

class register_user extends StatefulWidget{


  State<StatefulWidget> createState() => _registerPageState();
}
class _registerPageState extends State<register_user>{

  final formKey= GlobalKey<FormState>();
  void  validateAndSave()
  {
    final form= formKey.currentState;
    if(form!.validate()){

      print('Form is valid. Email $_email, password: $_password1');
    }else{
      print('Form is invalid. Email $_email, password: $_password1');
    }
  }

  late String _username;
  late String _email;
  late String _password1;
  late String _password2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
         appBar: AppBar(),
        body: Container(
            padding: const EdgeInsets.all(25.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration( labelText: 'Username' ),
                    validator: (value)=> value!.isEmpty ?'Username can\'t be empty': null,
                    onSaved: (value)=> _username=value!,
                  ),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration( labelText: "Email" ),
                    validator: ( value) {
                      if( value!.isEmpty) {
                        return 'Please a Enter';
                      }
                      if(!RegExp('^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]').hasMatch(value)){
                        return 'Please a valid Email';
                      }
                      return null;
                    },
                    onSaved: (value)=> _email=value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Enter Password'),
                    obscureText: true,
                    validator: (value)=> value!.isEmpty ?'password can\'t be empty': null,
                    onSaved: (value)=> _password1=value!,
                  ),
                  TextFormField(
                      decoration: const InputDecoration(labelText: 'Re-enter Password'),
                      obscureText: true,
                      validator: (value)=> value!.isEmpty ?'password can\'t be empty': null,
                      onSaved: (value)=> _password2=value!
                  ),

                  ElevatedButton(
                    child: const Text('Register', style: TextStyle(fontSize: 20.0)),
                    onPressed: validateAndSave,
                  )
                ],
              ),

            )
        )
    );
  }

}

