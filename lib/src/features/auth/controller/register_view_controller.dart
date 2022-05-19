import 'package:book_adapter/src/features/auth/data/register_view_data.dart';
import 'package:book_adapter/src/shared/controller/firebase_controller.dart';
import 'package:book_adapter/src/shared/data/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final registerViewController =
    StateNotifierProvider<RegisterViewController, RegisterViewData>((ref) {
  return RegisterViewController(ref.read);
});

// State is if the view is loading
class RegisterViewController extends StateNotifier<RegisterViewData> {
  RegisterViewController(this._read) : super(const RegisterViewData());

  final Reader _read;

  void updateData({
    String? username,
    String? email,
    String? password,
    String? verifyPassword,
  }) {
    state = state.copyWith(
      username: username?.trim(),
      email: email?.trim(),
      password: password,
      verifyPassword: verifyPassword,
    );

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

    return null;
  }

  void validateInput() {
    bool isButtonEnabled = state.isButtonEnabled;
    if (state.password == state.verifyPassword &&
        state.password.length >= 6 &&
        state.email.isNotEmpty) {
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
      email: state.email,
      password: state.password,
    );

    // Update with username
    final success =
        await _read(firebaseControllerProvider).setDisplayName(state.username);
    state = state.copyWith(isLoading: false);

    // Create default shelf
    await _read(firebaseControllerProvider).addCollection('Default');

    if (res.isRight()) {
      state = const RegisterViewData();
    }

    return res.fold(
        Left.new,
        (user) =>
            success ? Right(user) : Left(Failure('Set Display Name Failed')));
  }
}
