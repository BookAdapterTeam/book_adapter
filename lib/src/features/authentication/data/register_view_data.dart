import 'package:flutter/foundation.dart';

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
  }) =>
      RegisterViewData(
        username: username ?? this.username,
        email: email ?? this.email,
        password: password ?? this.password,
        verifyPassword: verifyPassword ?? this.verifyPassword,
        photoUrl: photoUrl ?? this.photoUrl,
        isLoading: isLoading ?? this.isLoading,
        isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
      );
//</editor-fold>
}
