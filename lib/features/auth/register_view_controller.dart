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

  void updateData({String? username, String? email, String? password, String? verifyPassword}) {
    state = state.copyWith(username: username?.trim(), email: email?.trim(), password: password, verifyPassword: verifyPassword);

    validateInput();
  }

  // TODO: Implement choosing a profile image
  // void chooseProfileImage() async {
  //   String url = '';
  //   state = state.copyWith(photoUrl: url);
  // }

   String? validate({String? string, required String message}) {
    if (string == null) {
      return null;
    }
    if (string.isEmpty) {
      return message;
    }
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

    // Register
    final res = await _read(firebaseControllerProvider).signUp(
      email: state.email, password: state.password,
    );

    // Update with username
    final success = await _read(firebaseControllerProvider).setDisplayName(state.username);
    state = state.copyWith(isLoading: false);

    // Create default shelf
    _read(firebaseControllerProvider).addCollection('Default');
    
    if (res.isRight()) {
      state = const RegisterViewData();
    }

    return res.fold(
      (failure) => Left(failure),
      (user) => success ? Right(user) : Left(Failure('Set Display Name Failed'))
    );
  }
}

@immutable
class RegisterViewData {
  final String username;
  final String email;
  final String password;
  final String verifyPassword;
  // null if there is no photo chosen
  final String? photoUrl;
  final bool isLoading;
  final bool isButtonEnabled;

//<editor-fold desc="Data Methods">

  const RegisterViewData({
    this.username = '',
    this.email = '',
    this.password = '',
    this.verifyPassword = '',
    this.photoUrl,
    this.isLoading = false,
    this.isButtonEnabled = false,
  });

  RegisterViewData copyWith({
    String? username,
    String? email,
    String? password,
    String? verifyPassword,
    String? photoUrl,
    bool? isLoading,
    bool? isButtonEnabled,
  }) {
    return RegisterViewData(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      verifyPassword: verifyPassword ?? this.verifyPassword,
      photoUrl: photoUrl ?? this.photoUrl,
      isLoading: isLoading ?? this.isLoading,
      isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
    );
  }
//</editor-fold>
}