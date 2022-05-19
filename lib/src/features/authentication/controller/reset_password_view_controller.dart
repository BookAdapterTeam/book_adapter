import 'package:book_adapter/src/shared/controller/firebase_controller.dart';
import 'package:book_adapter/src/shared/data/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final resetPasswordViewController =
    StateNotifierProvider<ResetPasswordViewController, ResetPasswordViewData>(
        (ref) {
  return ResetPasswordViewController(ref.read);
});

// State is if the view is loading
class ResetPasswordViewController extends StateNotifier<ResetPasswordViewData> {
  ResetPasswordViewController(this._read)
      : super(const ResetPasswordViewData());

  final Reader _read;

  void updateData({String? email}) {
    state = state.copyWith(email: email?.trim());
  }

  String? validate(String? email) {
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

  Future<Either<Failure, void>> sendResetEmail() async {
    final res =
        await _read(firebaseControllerProvider).resetPassword(state.email);
    return res.fold(
      Left.new,
      (_) => const Right(null),
    );
  }
}

@immutable
class ResetPasswordViewData {
  final String email;

//<editor-fold desc="Data Methods">

  const ResetPasswordViewData({
    this.email = '',
  });

  ResetPasswordViewData copyWith({
    String? email,
  }) {
    return ResetPasswordViewData(
      email: email ?? this.email,
    );
  }
//</editor-fold>
}
