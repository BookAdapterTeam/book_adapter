import 'package:book_adapter/src/common_widgets/async_value_widget.dart';
import 'package:book_adapter/src/constants/constants.dart';
import 'package:book_adapter/src/features/auth/presentation/login_view.dart';
import 'package:book_adapter/src/shared/controller/firebase_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({Key? key, required this.child}) : super(key: key);
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreamAsyncValue = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: AsyncValueWidget<User?>(
        value: userStreamAsyncValue,
        data: (data) {
          return AnimatedSwitcher(
            switchInCurve: Curves.easeInCubic,
            switchOutCurve: Curves.easeOutCubic,
            duration: kTransitionDuration,
            child: data == null
                ? LoginView(
                    key: const ValueKey('login'),
                  )
                : child,
          );
        },
      ),
    );
  }
}
