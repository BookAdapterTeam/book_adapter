import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/controller/firebase_controller.dart';

final editProfileViewController =
    StateNotifierProvider<EditProfileViewController, EditProfileViewData>(
  (ref) => EditProfileViewController(ref.read),
);

// State is if the view is loading
class EditProfileViewController extends StateNotifier<EditProfileViewData> {
  EditProfileViewController(this._read) : super(const EditProfileViewData());

  final Reader _read;

  void updateData({String? username, bool? isLoading}) {
    state = state.copyWith(username: username, isLoading: isLoading);
  }

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true);
    final result = await _read(firebaseControllerProvider).setDisplayName(state.username);
    state = state.copyWith(isLoading: false);
    return result;
  }
}

class EditProfileViewData {
  final String username;
  final bool isLoading;

  const EditProfileViewData({
    this.username = '',
    this.isLoading = false,
  });

  EditProfileViewData copyWith({
    String? username,
    bool? isLoading,
  }) =>
      EditProfileViewData(
        username: username ?? this.username,
        isLoading: isLoading ?? this.isLoading,
      );
}
