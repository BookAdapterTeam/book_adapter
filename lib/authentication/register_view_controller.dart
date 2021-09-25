import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final registerViewController = StateNotifierProvider<RegisterViewController, RegisterViewData>((ref) {
  return RegisterViewController(ref.read);
});

// State is if the view is loading
class RegisterViewController extends StateNotifier<RegisterViewData> {
  RegisterViewController(this._read) : super(const RegisterViewData());

  final Reader _read;

  void updateData({String? email, String? password, String? verifyPassword}) {
    state = state.copyWith(email: email?.trim(), password: password, verifyPassword: verifyPassword);

    validateInput();
  }

  void validateInput() {
    bool isButtonEnabled = state.isButtonEnabled;
    if (
      state.password == state.verifyPassword
      && state.password.length >= 6
      && state.email.isNotEmpty
    ) {
      isButtonEnabled = true;
    } else {
      isButtonEnabled = false;
    }
    state = state.copyWith(isButtonEnabled: isButtonEnabled);
  }

  Future<Either<Failure, User>> register() async {
    state = state.copyWith(isLoading: true);
    final res = await _read(firebaseControllerProvider).signUp(
      email: state.email, password: state.password,
    );
    state = state.copyWith(isLoading: false);

    return res;
  }
}

@immutable
class RegisterViewData {
  final String email;
  final String password;
  final String verifyPassword;
  final bool isLoading;
  final bool isButtonEnabled;

//<editor-fold desc="Data Methods">

  const RegisterViewData({
    this.email = '',
    this.password = '',
    this.verifyPassword = '',
    this.isLoading = false,
    this.isButtonEnabled = false,
  });

  RegisterViewData copyWith({
    String? email,
    String? password,
    String? verifyPassword,
    bool? isLoading,
    bool? isButtonEnabled,
  }) {
    return RegisterViewData(
      email: email ?? this.email,
      password: password ?? this.password,
      verifyPassword: verifyPassword ?? this.verifyPassword,
      isLoading: isLoading ?? this.isLoading,
      isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
    );
  }
//</editor-fold>
}