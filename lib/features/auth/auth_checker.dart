import 'package:book_adapter/controller/firebase_controller.dart';
import 'package:book_adapter/features/auth/login_view.dart';
import 'package:book_adapter/features/widgets/async_value_widget.dart';
import 'package:book_adapter/features/widgets/loading_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({Key? key, required this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(authStateChangesProvider);

    return AsyncValueWidget<User?>(
      value: userStreamAsyncValue,
      data: (data) => data == null
        ? LoginView()
        : child,
    );
  }
}

