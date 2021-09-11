import 'package:book_adapter/model/user_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
final baseCommandProvider = Provider<BaseCommand>((ref) {
  return BaseCommand(ref);
});

// Provide quick lookup methods for all the top-level models and services. Keeps the Command code slightly cleaner.
class BaseCommand {
  BaseCommand(this.ref) {
    userModelNotifier = ref.watch(userModelProvider.notifier);
  }
  final ProviderRef ref;

  // Models
  late final UserModelNotifier userModelNotifier;
  
  // Services
  // TODO: Implement FirebaseService
  // late final FirebaseService firebaseService;
  
}