import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseService();

  Future<UserCredential> login({required String email, required String password}) async {
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    return userCredential;
  }
}