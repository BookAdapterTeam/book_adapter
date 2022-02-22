import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../controller/storage_controller.dart';
import '../../service/storage_service.dart';
import '../widgets/async_value_widget.dart';

final providerForAuthInitFuture =
    FutureProvider.family<void, String>((ref, userId) async* {
  await ref.watch(storageServiceProvider).initQueueBox(userId);
  if (ref.read(storageControllerProvider).loggedIn) {
    unawaited(
        ref.read(storageControllerProvider).startBookUploadsFromStoredQueue());
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
    return AsyncValueWidget<void>(
      value: asyncValue,
      data: (_) {
        return child;
      },
    );
  }
}
