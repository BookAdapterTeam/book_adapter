import 'package:book_adapter/controller/firebase_controller.dart';
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
    state = state.copyWith(email: email, password: password, verifyPassword: verifyPassword);
  }

  Future<void> register() async {
    state = state.copyWith(isLoading: true);
    await _read(firebaseControllerProvider).signUp(
      email: state.email, password: state.password,
    );
    state = state.copyWith(isLoading: false);
  }
}

@immutable
class RegisterViewData {
  final String email;
  final String password;
  final String verifyPassword;
  final bool isLoading;

//<editor-fold desc="Data Methods">

  const RegisterViewData({
    this.email = '',
    this.password = '',
    this.verifyPassword = '',
    this.isLoading = false,
  });

  RegisterViewData copyWith({
    String? email,
    String? password,
    String? verifyPassword,
    bool? isLoading,
  }) {
    return RegisterViewData(
      email: email ?? this.email,
      password: password ?? this.password,
      verifyPassword: verifyPassword ?? this.verifyPassword,
      isLoading: isLoading ?? this.isLoading,
    );
  }
//</editor-fold>
}