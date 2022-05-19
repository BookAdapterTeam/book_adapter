import 'package:book_adapter/src/common_widgets/async_value_widget.dart';
import 'package:book_adapter/src/controller/storage_controller.dart';
import 'package:book_adapter/src/service/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final providerForAuthInitFuture =
    StreamProvider.family.autoDispose<String, String>((ref, userId) async* {
  await ref.watch(storageServiceProvider).initQueueBox(userId);
  if (ref.read(storageControllerProvider).loggedIn) {
    await for (final message in ref
        .read(storageControllerProvider)
        .startBookUploadsFromStoredQueue()) {
      yield message;
    }
  }
});

class AuthInitWidget extends ConsumerWidget {
  const AuthInitWidget({
    Key? key,
    required this.child,
    required this.userId,
    this.loading,
  }) : super(key: key);

  final Widget child;
  final String userId;

  final Widget Function(String message)? loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(providerForAuthInitFuture(userId));
    return AsyncValueWidget<String?>(
      value: asyncValue,
      data: (message) {
        final SnackBar snackBar = SnackBar(content: Text(message!));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return child;
      },
    );
  }
}
