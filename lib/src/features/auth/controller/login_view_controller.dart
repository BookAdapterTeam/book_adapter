import 'package:book_adapter/src/shared/controller/firebase_controller.dart';
import 'package:book_adapter/src/shared/data/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final loginViewController =
    StateNotifierProvider<LoginViewController, LoginViewData>((ref) {
  return LoginViewController(ref.read);
});

// State is if the view is loading
class LoginViewController extends StateNotifier<LoginViewData> {
  LoginViewController(this._read) : super(const LoginViewData());

  final Reader _read;

  void updateData({String? email, String? password}) {
    state = state.copyWith(email: email?.trim(), password: password);
  }

  Future<Either<Failure, User>> login() async {
    state = state.copyWith(isLoading: true);
    final res = await _read(firebaseControllerProvider).signIn(
      email: state.email,
      password: state.password,
    );

    if (res.isRight()) {
      state = const LoginViewData();
    }

    state = state.copyWith(isLoading: false);

    return res;
  }

  String? validateEmail(String? email) {
    if (email == null) {
      return null;
    }
    if (email.isEmpty) {
      return 'Email cannot be empty';
    }
    if (!EmailValidator.validate(email)) {
      return 'Email must be valid';
    }

    return null;
  }

  String? validatePassword(String? password) {
    if (password == null) {
      return null;
    }
    if (password.isEmpty) {
      return 'Password must not be empty';
    }

    return null;
  }
}

@immutable
class LoginViewData {
  final String email;
  final String password;
  final bool isLoading;

//<editor-fold desc="Data Methods">

  const LoginViewData({
    this.email = '',
    this.password = '',
    this.isLoading = false,
  });

  LoginViewData copyWith({
    String? email,
    String? password,
    bool? isLoading,
  }) {
    return LoginViewData(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
    );
  }
//</editor-fold>
}
