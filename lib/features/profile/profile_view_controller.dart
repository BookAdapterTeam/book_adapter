import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../controller/firebase_controller.dart';

final profileViewController =
    StateNotifierProvider<ProfileViewController, bool>((ref) {
  return ProfileViewController(ref.read);
});

// State is if the view is loading
class ProfileViewController extends StateNotifier<bool> {
  ProfileViewController(this._read) : super(false);

  final Reader _read;

  Future<void> signOut() async {
    state = true;
    await _read(firebaseControllerProvider).signOut();
    state = false;
  }
}
